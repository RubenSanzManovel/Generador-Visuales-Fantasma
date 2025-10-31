# ============================================================================
# AUDIO_HANDLER.PY - PROCESAMIENTO Y ANÁLISIS DE AUDIO EN TIEMPO REAL
# ============================================================================
# Este módulo maneja toda la captura, análisis y procesamiento de audio.
# Implementa detección de beats, análisis frecuencial por bandas (bass, mid, treble),
# y suavizado temporal para obtener datos estables y reactivos a la música.
# ============================================================================

import sounddevice as sd
import numpy as np
import queue
import config
import sys
from collections import deque
from typing import Optional, Dict, Any

class AudioHandler:
    """
    Gestor de audio que captura sonido del sistema y lo analiza en tiempo real.
    
    Características:
    - Captura de audio mediante sounddevice (loopback)
    - Análisis FFT (Fast Fourier Transform) para obtener espectro de frecuencias
    - Detección inteligente de beats con umbral adaptativo
    - Análisis por bandas de frecuencia (bass, mid, treble)
    - Suavizado temporal para evitar cambios bruscos
    - Manejo robusto de errores
    """
    
    def __init__(self):
        """Inicializa el manejador de audio y encuentra el dispositivo de captura."""
        # Cola thread-safe para transferir datos de audio del callback al thread principal
        self.audio_queue: queue.Queue = queue.Queue(maxsize=10)
        
        # ID del dispositivo de audio a utilizar
        self.device_id: Optional[int] = self._find_loopback_device()
        
        # Stream de audio (inicializado en start_stream)
        self.stream: Optional[sd.InputStream] = None
        
        # Buffer circular para suavizado temporal de amplitud
        # Almacena los últimos N frames de amplitud para promediarlos
        self.amplitude_buffer: deque = deque(maxlen=config.AUDIO_SMOOTHING_FRAMES)
        
        # Buffer para el espectro de frecuencias (análisis por bandas)
        self.bass_buffer: deque = deque(maxlen=config.AUDIO_SMOOTHING_FRAMES)
        self.mid_buffer: deque = deque(maxlen=config.AUDIO_SMOOTHING_FRAMES)
        self.treble_buffer: deque = deque(maxlen=config.AUDIO_SMOOTHING_FRAMES)
        
        # Umbral adaptativo de beat detection
        # Se ajusta automáticamente según la energía promedio de la música
        self.adaptive_threshold: float = config.BEAT_THRESHOLD
        
        # Historial de energía de beats para adaptar el umbral
        self.beat_energy_history: deque = deque(maxlen=50)
        
        # Ventana de Hann para mejorar el análisis FFT
        # Reduce los artefactos espectrales ("spectral leakage")
        self.hann_window: np.ndarray = np.hanning(config.NUM_SAMPLES)
        
        # Contador de frames procesados (útil para debugging)
        self.frames_processed: int = 0
        
        # Sample rate actual del dispositivo (se configura en start_stream)
        self.actual_samplerate: int = config.SAMPLERATE
        
        print("🎵 AudioHandler inicializado correctamente")

    def _find_loopback_device(self) -> Optional[int]:
        """
        Busca el dispositivo de captura de audio especificado en config.
        
        Returns:
            ID del dispositivo encontrado, o None si hay error.
        """
        try:
            devices = sd.query_devices()
            
            # Buscar dispositivo que coincida con el nombre configurado
            for i, device in enumerate(devices):
                device_dict = device  # type: ignore
                if config.DEVICE_NAME in str(device_dict.get('name', '')) and device_dict.get('max_input_channels', 0) > 0:
                    print(f"✅ Dispositivo de audio encontrado: '{device_dict['name']}' (ID: {i})")
                    print(f"   Canales: {device_dict.get('max_input_channels', 0)}, "
                          f"Sample Rate: {device_dict.get('default_samplerate', 0)} Hz")
                    return i
            
            # Si no se encuentra, intentar usar dispositivo por defecto
            print(f"⚠️  No se encontró '{config.DEVICE_NAME}'. Intentando dispositivo predeterminado.")
            default_device_tuple = sd.default.device  # type: ignore
            if default_device_tuple and len(default_device_tuple) > 0:
                default_device = default_device_tuple[0] if isinstance(default_device_tuple, (list, tuple)) else default_device_tuple
                if default_device is not None:
                    print(f"   Usando dispositivo predeterminado (ID: {default_device})")
                    return int(default_device)
            
            print("❌ No hay dispositivos de entrada disponibles")
            return None
            
        except Exception as e:
            print(f"❌ Error buscando dispositivos de audio: {e}")
            print("   Verifica que tengas instalado sounddevice correctamente")
            return None

    def _audio_callback(self, indata: np.ndarray, frames: int, time: Any, status: sd.CallbackFlags) -> None:
        """
        Callback llamado por sounddevice cuando hay datos de audio disponibles.
        Se ejecuta en un thread separado de alta prioridad.
        
        Args:
            indata: Array numpy con los datos de audio capturados
            frames: Número de frames en este bloque
            time: Información temporal del callback
            status: Estado del stream (detecta overflows/underflows)
        """
        if status:
            # Reportar problemas del stream (buffer overflows, etc.)
            print(f"⚠️  Audio callback status: {status}", file=sys.stderr)
        
        try:
            # Extraer solo el canal mono (primer canal si es estéreo)
            # np.copy asegura que los datos persistan después del callback
            mono_data = np.copy(indata[:, 0])
            
            # Intentar agregar a la cola sin bloquear
            # Si la cola está llena, descartamos el frame más antiguo
            if self.audio_queue.full():
                try:
                    self.audio_queue.get_nowait()  # Descartar frame viejo
                except queue.Empty:
                    pass
            
            self.audio_queue.put_nowait(mono_data)
            
        except Exception as e:
            print(f"❌ Error en audio callback: {e}", file=sys.stderr)

    def start_stream(self) -> bool:
        """
        Inicia la captura de audio desde el dispositivo configurado.
        
        Returns:
            True si el stream se inició correctamente, False en caso contrario.
        """
        if self.device_id is None:
            print("❌ No se puede iniciar el stream sin un dispositivo válido.")
            print("   Verifica la configuración DEVICE_NAME en config.py")
            return False
        
        try:
            # Obtener información del dispositivo para usar su sample rate nativo
            device_info = sd.query_devices(self.device_id)
            native_samplerate = int(device_info['default_samplerate'])  # type: ignore
            self.actual_samplerate = native_samplerate  # Guardar para usar en process_audio
            
            print(f"📊 Configurando captura de audio:")
            print(f"   Sample Rate: {native_samplerate} Hz")
            print(f"   Block Size: {config.NUM_SAMPLES} samples")
            
            # Crear e iniciar el stream de entrada con el sample rate nativo del dispositivo
            self.stream = sd.InputStream(
                device=self.device_id,
                channels=1,  # Mono (convertiremos estéreo a mono si es necesario)
                samplerate=native_samplerate,  # Usar sample rate nativo del dispositivo
                blocksize=config.NUM_SAMPLES,
                callback=self._audio_callback,
                dtype=np.float32  # Formato de datos de audio
            )
            
            self.stream.start()
            print("=" * 70)
            print("🎵 VISUALIZADOR EN MARCHA - Reproduce música para ver los efectos")
            print("=" * 70)
            return True
            
        except Exception as e:
            print(f"❌ Error al iniciar el stream de audio: {e}")
            print("   Verifica que el dispositivo no esté siendo usado por otra aplicación")
            return False

    def stop_stream(self) -> None:
        """Detiene y cierra el stream de audio de forma segura."""
        if self.stream:
            try:
                self.stream.stop()
                self.stream.close()
                print("🛑 Stream de audio detenido correctamente")
            except Exception as e:
                print(f"⚠️  Error al detener el stream: {e}")

    def _calculate_band_energy(self, fft_data: np.ndarray, fft_freqs: np.ndarray, 
                               freq_range: tuple) -> float:
        """
        Calcula la energía en un rango específico de frecuencias.
        
        Args:
            fft_data: Magnitudes del espectro FFT
            fft_freqs: Frecuencias correspondientes a cada bin del FFT
            freq_range: Tupla (freq_min, freq_max) en Hz
            
        Returns:
            Energía normalizada en ese rango de frecuencias (0.0 - 1.0)
        """
        # Crear máscara para el rango de frecuencias
        mask = (fft_freqs >= freq_range[0]) & (fft_freqs <= freq_range[1])
        
        # Calcular energía total en ese rango
        band_energy = np.sum(fft_data[mask])
        
        # Normalizar por la energía total del espectro
        total_energy = np.sum(fft_data)
        if total_energy > 0:
            return band_energy / total_energy
        return 0.0

    def _adapt_beat_threshold(self, current_energy: float) -> None:
        """
        Adapta dinámicamente el umbral de detección de beats según el historial.
        Esto permite que el sistema se ajuste automáticamente a música más suave o más fuerte.
        
        Args:
            current_energy: Energía actual de la banda de frecuencias de beat
        """
        self.beat_energy_history.append(current_energy)
        
        if len(self.beat_energy_history) >= 10:
            # Calcular promedio y desviación estándar del historial
            mean_energy = np.mean(self.beat_energy_history)
            std_energy = np.std(self.beat_energy_history)
            
            # El nuevo umbral es el promedio + una fracción de la desviación estándar
            # Esto hace que se adapte a la dinámica de la canción
            target_threshold = mean_energy + (std_energy * 0.5)
            
            # Suavizar el cambio del umbral para evitar saltos bruscos
            self.adaptive_threshold = (
                self.adaptive_threshold * (1.0 - config.BEAT_THRESHOLD_ADAPTATION) +
                target_threshold * config.BEAT_THRESHOLD_ADAPTATION
            )
            
            # Limitar el umbral a valores razonables
            self.adaptive_threshold = np.clip(self.adaptive_threshold, 0.1, 0.5)

    def process_audio(self, state: Dict[str, Any]) -> None:
        """
        Procesa los datos de audio disponibles y actualiza el estado del visualizador.
        
        Este es el método principal llamado en cada frame del programa.
        Extrae datos de audio, realiza análisis FFT, detecta beats, y actualiza
        todas las variables del estado que controlan los efectos visuales.
        
        Args:
            state: Diccionario con el estado global del visualizador (se modifica in-place)
        """
        try:
            # Intentar obtener datos de audio sin bloquear
            data = self.audio_queue.get_nowait()
            self.frames_processed += 1
            
            # ================================================================
            # ANÁLISIS FFT (Fast Fourier Transform)
            # ================================================================
            # Aplicar ventana de Hann para reducir artefactos espectrales
            windowed_data = data * self.hann_window
            
            # Calcular FFT y obtener magnitudes (valores absolutos)
            fft_data = np.abs(np.fft.rfft(windowed_data))
            
            # Obtener las frecuencias correspondientes a cada bin del FFT
            # Usar el sample rate actual del dispositivo, no el de config
            fft_freqs = np.fft.rfftfreq(len(data), 1.0 / self.actual_samplerate)
            
            # ================================================================
            # ANÁLISIS POR BANDAS DE FRECUENCIA
            # ================================================================
            # Calcular energía en cada banda (bass, mid, treble)
            bass_energy = self._calculate_band_energy(fft_data, fft_freqs, config.BASS_FREQ_RANGE)
            mid_energy = self._calculate_band_energy(fft_data, fft_freqs, config.MID_FREQ_RANGE)
            treble_energy = self._calculate_band_energy(fft_data, fft_freqs, config.TREBLE_FREQ_RANGE)
            
            # Agregar a buffers de suavizado
            self.bass_buffer.append(bass_energy)
            self.mid_buffer.append(mid_energy)
            self.treble_buffer.append(treble_energy)
            
            # Calcular promedios suavizados
            state['bass_energy'] = np.mean(self.bass_buffer) if self.bass_buffer else 0.0
            state['mid_energy'] = np.mean(self.mid_buffer) if self.mid_buffer else 0.0
            state['treble_energy'] = np.mean(self.treble_buffer) if self.treble_buffer else 0.0
            
            # ================================================================
            # DETECCIÓN DE BEATS
            # ================================================================
            # Calcular energía en el rango de frecuencias de beats (graves)
            beat_mask = (fft_freqs >= config.BEAT_FREQ_RANGE[0]) & (fft_freqs <= config.BEAT_FREQ_RANGE[1])
            beat_energy = np.sum(fft_data[beat_mask]) / np.sum(fft_data) if np.sum(fft_data) > 0 else 0
            
            # Adaptar el umbral dinámicamente
            self._adapt_beat_threshold(beat_energy)
            
            # Verificar si hay un beat:
            # 1. La energía supera el umbral adaptativo
            # 2. Ha pasado suficiente tiempo desde el último beat (cooldown)
            time_since_last_beat = state['current_time'] - state['beat_last_time']
            is_beat = (beat_energy > self.adaptive_threshold and 
                      time_since_last_beat > config.BEAT_COOLDOWN)
            
            if is_beat:
                # ¡Beat detectado! Actualizar estado
                state['beat_last_time'] = state['current_time']
                state['beat_count'] += 1
                state['beat_intensity'] = min(beat_energy / self.adaptive_threshold, 2.0)  # Intensidad relativa
                
                # Cambiar color en cada beat
                state['color_index'] = (state['color_index'] + 1) % len(config.COLOR_PALETTE)
                
                # Generar nuevas partículas/rayos/gotas en posiciones aleatorias
                for i in range(config.RAYS_PER_BEAT):
                    idx = (state['drop_index'] + i) % config.MAX_PARTICLES
                    state['drop_positions'][idx] = np.random.rand(2).astype(np.float32)
                    state['drop_times'][idx] = state['current_time']
                
                state['drop_index'] = (state['drop_index'] + config.RAYS_PER_BEAT) % config.MAX_PARTICLES
                
                # Cambiar patrón visual cada N beats
                if state['beat_count'] >= config.SHAPE_CHANGE_BEATS:
                    state['beat_count'] = 0
                    state['pattern_change_time'] = state['current_time']
                    state['prev_pattern_index'] = state['pattern_index']
                    state['pattern_index'] = (state['pattern_index'] + 1) % config.TOTAL_PATTERNS
                    
                    if config.DEBUG_MODE:
                        print(f"🎨 Cambiando a patrón {state['pattern_index']}")
            
            # ================================================================
            # CÁLCULO DE AMPLITUD (Volumen General)
            # ================================================================
            # RMS (Root Mean Square) es una medida del volumen promedio
            rms = np.sqrt(np.mean(data**2))
            
            # Aplicar sensibilidad configurada
            new_amplitude = rms * config.SENSITIVITY
            
            # Suavizar la amplitud: tomar el máximo entre el nuevo valor y el anterior con decay
            # Esto hace que la amplitud suba rápidamente pero baje suavemente
            state['current_amplitude'] = max(new_amplitude, 
                                            state['current_amplitude'] * config.DECAY_RATE)
            
            # Agregar al buffer de suavizado
            self.amplitude_buffer.append(state['current_amplitude'])
            
            # Calcular amplitud suavizada (promedio del buffer)
            state['smoothed_amplitude'] = np.mean(self.amplitude_buffer) if self.amplitude_buffer else 0.0
            
            # Información de debug (si está activado)
            if config.DEBUG_MODE and self.frames_processed % 60 == 0:
                print(f"📊 Audio - Amp: {state['current_amplitude']:.3f}, "
                      f"Bass: {state['bass_energy']:.3f}, "
                      f"Mid: {state['mid_energy']:.3f}, "
                      f"Treble: {state['treble_energy']:.3f}, "
                      f"Beat Thr: {self.adaptive_threshold:.3f}")
        
        except queue.Empty:
            # No hay datos de audio disponibles en este frame
            # Aplicar decay a la amplitud para que se desvanezca gradualmente
            state['current_amplitude'] *= config.DECAY_RATE
            state['smoothed_amplitude'] *= config.DECAY_RATE
            
            # Decay también a las bandas de frecuencia
            if 'bass_energy' in state:
                state['bass_energy'] *= config.DECAY_RATE
                state['mid_energy'] *= config.DECAY_RATE
                state['treble_energy'] *= config.DECAY_RATE
        
        except Exception as e:
            # Error inesperado en el procesamiento
            print(f"❌ Error procesando audio: {e}", file=sys.stderr)
            # Aplicar decay de emergencia
            state['current_amplitude'] *= config.DECAY_RATE