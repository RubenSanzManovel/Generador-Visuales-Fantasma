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
# No se necesita 'random' aquí

class AudioHandler:
    """
    Gestor de audio que captura sonido del sistema y lo analiza en tiempo real.
    """
    
    def __init__(self):
        """Inicializa el manejador de audio y encuentra el dispositivo de captura."""
        self.audio_queue: queue.Queue = queue.Queue(maxsize=10)
        self.device_id: Optional[int] = self._find_loopback_device()
        self.stream: Optional[sd.InputStream] = None
        
        self.amplitude_buffer: deque = deque(maxlen=config.AUDIO_SMOOTHING_FRAMES)
        self.bass_buffer: deque = deque(maxlen=config.AUDIO_SMOOTHING_FRAMES)
        self.mid_buffer: deque = deque(maxlen=config.AUDIO_SMOOTHING_FRAMES)
        self.treble_buffer: deque = deque(maxlen=config.AUDIO_SMOOTHING_FRAMES)
        
        self.adaptive_threshold: float = config.BEAT_THRESHOLD
        self.beat_energy_history: deque = deque(maxlen=50)
        self.hann_window: np.ndarray = np.hanning(config.NUM_SAMPLES)
        self.frames_processed: int = 0
        
        print("🎵 AudioHandler inicializado correctamente")

    def _find_loopback_device(self) -> Optional[int]:
        """
        Busca el dispositivo de captura de audio especificado en config.
        """
        try:
            devices = sd.query_devices()
            
            for i, device in enumerate(devices):
                device_dict = device  # type: ignore
                if config.DEVICE_NAME in str(device_dict.get('name', '')) and device_dict.get('max_input_channels', 0) > 0:
                    print(f"✅ Dispositivo de audio encontrado: '{device_dict['name']}' (ID: {i})")
                    print(f"   Canales: {device_dict.get('max_input_channels', 0)}, "
                          f"Sample Rate: {device_dict.get('default_samplerate', 0)} Hz")
                    return i
            
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
            return None

    def _audio_callback(self, indata: np.ndarray, frames: int, time: Any, status: sd.CallbackFlags) -> None:
        """
        Callback llamado por sounddevice cuando hay datos de audio disponibles.
        """
        if status:
            print(f"⚠️  Audio callback status: {status}", file=sys.stderr)
        
        try:
            mono_data = np.copy(indata[:, 0])
            if self.audio_queue.full():
                try:
                    self.audio_queue.get_nowait()
                except queue.Empty:
                    pass
            self.audio_queue.put_nowait(mono_data)
        except Exception as e:
            print(f"❌ Error en audio callback: {e}", file=sys.stderr)

    def start_stream(self) -> bool:
        """
        Inicia la captura de audio desde el dispositivo configurado.
        """
        if self.device_id is None:
            print("❌ No se puede iniciar el stream sin un dispositivo válido.")
            return False
        
        try:
            self.stream = sd.InputStream(
                device=self.device_id,
                channels=1,
                samplerate=config.SAMPLERATE,
                blocksize=config.NUM_SAMPLES,
                callback=self._audio_callback,
                dtype=np.float32
            )
            self.stream.start()
            print("=" * 70)
            print("🎵 VISUALIZADOR EN MARCHA - Reproduce música para ver los efectos")
            print("=" * 70)
            return True
        except Exception as e:
            print(f"❌ Error al iniciar el stream de audio: {e}")
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
        """
        mask = (fft_freqs >= freq_range[0]) & (fft_freqs <= freq_range[1])
        band_energy = np.sum(fft_data[mask])
        total_energy = np.sum(fft_data)
        if total_energy > 0:
            return band_energy / total_energy
        return 0.0

    def _adapt_beat_threshold(self, current_energy: float) -> None:
        """
        Adapta dinámicamente el umbral de detección de beats según el historial.
        """
        self.beat_energy_history.append(current_energy)
        
        if len(self.beat_energy_history) >= 10:
            mean_energy = np.mean(self.beat_energy_history)
            std_energy = np.std(self.beat_energy_history)
            target_threshold = mean_energy + (std_energy * 0.5)
            
            self.adaptive_threshold = (
                self.adaptive_threshold * (1.0 - config.BEAT_THRESHOLD_ADAPTATION) +
                target_threshold * config.BEAT_THRESHOLD_ADAPTATION
            )
            self.adaptive_threshold = np.clip(self.adaptive_threshold, 0.1, 0.5)

    def process_audio(self, state: Dict[str, Any]) -> None:
        """
        Procesa los datos de audio disponibles y actualiza el estado del visualizador.
        """
        try:
            data = self.audio_queue.get_nowait()
            self.frames_processed += 1
            
            # ANÁLISIS FFT
            windowed_data = data * self.hann_window
            fft_data = np.abs(np.fft.rfft(windowed_data))
            fft_freqs = np.fft.rfftfreq(len(data), 1.0 / config.SAMPLERATE)
            
            # ANÁLISIS POR BANDAS
            bass_energy = self._calculate_band_energy(fft_data, fft_freqs, config.BASS_FREQ_RANGE)
            mid_energy = self._calculate_band_energy(fft_data, fft_freqs, config.MID_FREQ_RANGE)
            treble_energy = self._calculate_band_energy(fft_data, fft_freqs, config.TREBLE_FREQ_RANGE)
            
            self.bass_buffer.append(bass_energy)
            self.mid_buffer.append(mid_energy)
            self.treble_buffer.append(treble_energy)
            
            state['bass_energy'] = np.mean(self.bass_buffer) if self.bass_buffer else 0.0
            state['mid_energy'] = np.mean(self.mid_buffer) if self.mid_buffer else 0.0
            state['treble_energy'] = np.mean(self.treble_buffer) if self.treble_buffer else 0.0
            
            # DETECCIÓN DE BEATS
            beat_mask = (fft_freqs >= config.BEAT_FREQ_RANGE[0]) & (fft_freqs <= config.BEAT_FREQ_RANGE[1])
            beat_energy = np.sum(fft_data[beat_mask]) / np.sum(fft_data) if np.sum(fft_data) > 0 else 0
            
            self._adapt_beat_threshold(beat_energy)
            
            time_since_last_beat = state['current_time'] - state['beat_last_time']
            is_beat = (beat_energy > self.adaptive_threshold and 
                      time_since_last_beat > config.BEAT_COOLDOWN)
            
            if is_beat:
                # ¡Beat detectado! Actualizar estado
                state['beat_last_time'] = state['current_time']
                state['beat_count'] += 1 # <--- SOLO INCREMENTA EL CONTADOR
                state['beat_intensity'] = min(beat_energy / self.adaptive_threshold, 2.0)
                
                state['color_index'] = (state['color_index'] + 1) % len(config.COLOR_PALETTE)
                
                for i in range(config.RAYS_PER_BEAT):
                    idx = (state['drop_index'] + i) % config.MAX_PARTICLES
                    state['drop_positions'][idx] = np.random.rand(2).astype(np.float32)
                    state['drop_times'][idx] = state['current_time']
                
                state['drop_index'] = (state['drop_index'] + config.RAYS_PER_BEAT) % config.MAX_PARTICLES
                
                # --- LA LÓGICA DE CAMBIO DE PATRÓN SE HA MOVIDO A MAIN.PY ---
            
            # CÁLCULO DE AMPLITUD
            rms = np.sqrt(np.mean(data**2))
            new_amplitude = rms * config.SENSITIVITY
            state['current_amplitude'] = max(new_amplitude, state['current_amplitude'] * config.DECAY_RATE)
            self.amplitude_buffer.append(state['current_amplitude'])
            state['smoothed_amplitude'] = np.mean(self.amplitude_buffer) if self.amplitude_buffer else 0.0
            
        except queue.Empty:
            # No hay datos de audio
            state['current_amplitude'] *= config.DECAY_RATE
            state['smoothed_amplitude'] *= config.DECAY_RATE
            
            if 'bass_energy' in state:
                state['bass_energy'] *= config.DECAY_RATE
                state['mid_energy'] *= config.DECAY_RATE
                state['treble_energy'] *= config.DECAY_RATE
        
        except Exception as e:
            print(f"❌ Error procesando audio: {e}", file=sys.stderr)
            state['current_amplitude'] *= config.DECAY_RATE