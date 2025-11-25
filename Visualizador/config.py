# ============================================================================
# CONFIG.PY - CONFIGURACIÓN PROFESIONAL DEL VISUALIZADOR DE MÚSICA
# ============================================================================
# Este archivo contiene todos los parámetros configurables del sistema.
# Modificar estos valores permite personalizar completamente el comportamiento
# del visualizador sin tocar el código principal.
# ============================================================================

import colorsys
import os
from typing import Tuple, List

# ============================================================================
# CONFIGURACIÓN DE PANTALLA
# ============================================================================

# Resolución de la ventana de renderizado (ancho x alto en píxeles)
# Estos valores se actualizarán automáticamente con la resolución de pantalla completa
SCREEN_WIDTH: int = 1920
SCREEN_HEIGHT: int = 1080

# Control de FPS (frames por segundo) objetivo
# Mayor FPS = animaciones más fluidas, pero mayor uso de CPU/GPU
TARGET_FPS: int = 60

# Activar/desactivar modo pantalla completa (siempre activado para la GUI)
FULLSCREEN: bool = True

# Activar VSync (sincronización vertical) para evitar screen tearing
VSYNC: bool = True

# ============================================================================
# CONFIGURACIÓN DE AUDIO
# ============================================================================

# Frecuencia de muestreo del audio (samples por segundo)
# 44100 Hz es el estándar de CD de audio
SAMPLERATE: int = 44100

# Nombre del dispositivo de captura de audio
# Para Windows: "Mezcla estéreo" o "Stereo Mix"
# Para capturar audio del sistema, necesitas habilitar este dispositivo
DEVICE_NAME: str = "Mezcla estéreo"

# Número de samples por buffer de audio
# Mayor valor = más latencia pero análisis más estable
# Debe ser potencia de 2 para FFT óptima (512, 1024, 2048, 4096)
NUM_SAMPLES: int = 2048

# Buffer de audio para suavizado (número de frames a promediar)
# Reduce variaciones bruscas en la amplitud
AUDIO_SMOOTHING_FRAMES: int = 3

# ============================================================================
# CONFIGURACIÓN DE ANÁLISIS FRECUENCIAL
# ============================================================================

# Rangos de frecuencia para análisis por bandas (en Hz)
# BASS: Frecuencias graves (bombo, bajo)
BASS_FREQ_RANGE: Tuple[int, int] = (20, 250)

# MID: Frecuencias medias (voces, guitarras, teclados)
MID_FREQ_RANGE: Tuple[int, int] = (250, 2000)

# TREBLE: Frecuencias agudas (platillos, hi-hats, brillos)
TREBLE_FREQ_RANGE: Tuple[int, int] = (2000, 8000)

# ============================================================================
# CONFIGURACIÓN DE DETECCIÓN DE RITMO (BEAT DETECTION)
# ============================================================================

# Rango de frecuencias para detección de golpes de ritmo (Hz)
# Se enfoca en frecuencias graves donde están los bombos y bajos
BEAT_FREQ_RANGE: Tuple[int, int] = (20, 500)

# Umbral de energía para considerar que hay un beat
# Valores más bajos = detección más sensible (más beats detectados)
# Valores más altos = detección más conservadora (solo beats fuertes)
# Rango típico: 0.15 - 0.35
BEAT_THRESHOLD: float = 0.28

# Tiempo mínimo entre beats consecutivos (en segundos)
# Previene detección de múltiples beats muy seguidos
# Valores típicos: 0.1 - 0.3 segundos
BEAT_COOLDOWN: float = 0.15

# Factor de adaptación del umbral de beat
# Permite que el sistema se adapte automáticamente a la intensidad de la música
BEAT_THRESHOLD_ADAPTATION: float = 0.02

# ============================================================================
# CONFIGURACIÓN DE EFECTOS VISUALES
# ============================================================================

# Sensibilidad general de los efectos al volumen de audio
# Mayor valor = reacción más exagerada a la música
SENSITIVITY: float = 2.5

# Velocidad de decaimiento de la amplitud cuando no hay audio (0.0 - 1.0)
# Valores cercanos a 1.0 = decaimiento lento (efectos persisten más)
# Valores cercanos a 0.0 = decaimiento rápido (efectos desaparecen rápido)
DECAY_RATE: float = 0.98

# --- ¡NUEVAS OPCIONES DE CAMBIO DE PATRÓN! ---

# Modo de cambio de patrón: "order" (en orden) o "random" (aleatorio)
PATTERN_ORDER_MODE: str = "random"

# Número de beats necesarios para cambiar (SOLO si PATTERN_ORDER_MODE = "order")
SHAPE_CHANGE_BEATS: int = 16

# Rango de beats para cambiar (SOLO si PATTERN_ORDER_MODE = "random")
# El programa elegirá un número aleatorio entre estos dos valores.
RANDOM_BEAT_RANGE: Tuple[int, int] = (30, 70)

# --- FIN DE NUEVAS OPCIONES ---

# Número total de patrones visuales disponibles en los shaders
# IMPORTANTE: Debe coincidir con el número de efectos en fragment.glsl
TOTAL_PATTERNS: int = 43

# Número de rayos/partículas/gotas generadas por cada beat detectado
# Mayor valor = efectos más densos y llamativos
RAYS_PER_BEAT: int = 8

# Transición suave entre patrones (segundos)
# 0 = cambio instantáneo, valores más altos = transición gradual
PATTERN_TRANSITION_TIME: float = 0.5

# ============================================================================
# CONFIGURACIÓN DE POST-PROCESAMIENTO
# ============================================================================

# Intensidad del efecto bloom (resplandor)
# 0.0 = desactivado, 1.0 = bloom máximo
BLOOM_INTENSITY: float = 0.3

# Intensidad de viñeta (oscurecimiento de bordes)
# 0.0 = sin viñeta, 1.0 = viñeta fuerte
VIGNETTE_INTENSITY: float = 0.2

# Contraste de la imagen final (1.0 = normal, >1.0 = más contraste)
CONTRAST: float = 1.1

# Saturación de color (1.0 = normal, >1.0 = más saturado, <1.0 = menos saturado)
SATURATION: float = 1.15

# ============================================================================
# PALETAS DE COLOR
# ============================================================================

# Paleta de colores principal (HSV convertido a RGB)
# Genera 12 colores distribuidos uniformemente en el círculo cromático
# Saturación: 0.9 (colores vibrantes), Brillo: 1.0 (máximo brillo)
COLOR_PALETTE: List[Tuple[float, float, float]] = [
    colorsys.hsv_to_rgb(h / 12.0, 0.9, 1.0) for h in range(12)
]

# Paletas alternativas predefinidas
# Paleta Cyberpunk (azules, morados, magentas, cianos)
PALETTE_CYBERPUNK: List[Tuple[float, float, float]] = [
    (0.0, 0.7, 1.0),   # Cian brillante
    (0.3, 0.0, 1.0),   # Azul eléctrico
    (0.6, 0.0, 1.0),   # Morado
    (1.0, 0.0, 0.7),   # Magenta
    (1.0, 0.0, 1.0),   # Rosa neón
    (0.0, 1.0, 1.0),   # Cian puro
]

# Paleta Fuego (rojos, naranjas, amarillos)
PALETTE_FIRE: List[Tuple[float, float, float]] = [
    (1.0, 0.0, 0.0),   # Rojo puro
    (1.0, 0.3, 0.0),   # Rojo-naranja
    (1.0, 0.5, 0.0),   # Naranja
    (1.0, 0.7, 0.0),   # Naranja-amarillo
    (1.0, 1.0, 0.0),   # Amarillo
    (1.0, 1.0, 0.5),   # Amarillo claro
]

# Paleta Océano (azules y verdes)
PALETTE_OCEAN: List[Tuple[float, float, float]] = [
    (0.0, 0.2, 0.5),   # Azul oscuro
    (0.0, 0.4, 0.7),   # Azul medio
    (0.0, 0.6, 0.9),   # Azul claro
    (0.0, 0.8, 1.0),   # Azul celeste
    (0.0, 1.0, 0.8),   # Turquesa
    (0.3, 1.0, 0.5),   # Verde azulado
]

# ============================================================================
# CONFIGURACIÓN DE DEPURACIÓN Y LOGGING
# ============================================================================

# Mostrar información de depuración en consola
DEBUG_MODE: bool = False

# Mostrar contador de FPS en pantalla
SHOW_FPS: bool = True

# Mostrar información de audio en tiempo real
SHOW_AUDIO_INFO: bool = False

# Nivel de logging (DEBUG, INFO, WARNING, ERROR, CRITICAL)
LOG_LEVEL: str = "INFO"

# ============================================================================
# CONFIGURACIÓN DE RENDIMIENTO
# ============================================================================

# Número máximo de partículas/gotas activas simultáneamente
MAX_PARTICLES: int = 10

# Usar threading para procesamiento de audio (mejora rendimiento)
USE_AUDIO_THREADING: bool = True

# ============================================================================
# VALIDACIÓN DE CONFIGURACIÓN
# ============================================================================

def validate_config() -> bool:
    """
    Valida que todos los parámetros de configuración sean correctos.
    Retorna True si la configuración es válida, False en caso contrario.
    """
    try:
        # Validar resolución
        assert SCREEN_WIDTH > 0 and SCREEN_HEIGHT > 0, "Resolución inválida"
        assert TARGET_FPS > 0, "FPS objetivo debe ser mayor que 0"
        
        # Validar audio
        assert SAMPLERATE > 0, "Sample rate inválido"
        assert NUM_SAMPLES > 0 and (NUM_SAMPLES & (NUM_SAMPLES - 1)) == 0, "NUM_SAMPLES debe ser potencia de 2"
        
        # Validar rangos de frecuencia
        assert BASS_FREQ_RANGE[0] < BASS_FREQ_RANGE[1], "Rango BASS inválido"
        assert MID_FREQ_RANGE[0] < MID_FREQ_RANGE[1], "Rango MID inválido"
        assert TREBLE_FREQ_RANGE[0] < TREBLE_FREQ_RANGE[1], "Rango TREBLE inválido"
        
        # Validar detección de beats
        assert 0.0 < BEAT_THRESHOLD < 1.0, "BEAT_THRESHOLD debe estar entre 0 y 1"
        assert BEAT_COOLDOWN > 0, "BEAT_COOLDOWN debe ser mayor que 0"
        
        # --- NUEVA VALIDACIÓN ---
        assert PATTERN_ORDER_MODE in ["order", "random"], "PATTERN_ORDER_MODE debe ser 'order' o 'random'"
        assert RANDOM_BEAT_RANGE[0] > 0 and RANDOM_BEAT_RANGE[1] >= RANDOM_BEAT_RANGE[0], "RANDOM_BEAT_RANGE inválido"
        
        # Validar efectos visuales
        assert 0.0 <= DECAY_RATE <= 1.0, "DECAY_RATE debe estar entre 0 y 1"
        assert TOTAL_PATTERNS > 0, "Debe haber al menos un patrón visual"
        assert len(COLOR_PALETTE) > 0, "La paleta de colores no puede estar vacía"
        
        return True
    except AssertionError as e:
        print(f"❌ Error de configuración: {e}")
        return False

# Ejecutar validación al importar el módulo
if __name__ != "__main__":
    if not validate_config():
        raise ValueError("Configuración inválida. Revisa los parámetros en config.py")

# ============================================================================
# INFORMACIÓN DEL SISTEMA
# ============================================================================

def print_config_info():
    """Imprime un resumen de la configuración actual."""
    print("\n" + "="*70)
    print("CONFIGURACIÓN DEL VISUALIZADOR DE MÚSICA")
    print("="*70)
    print(f"Resolución: {SCREEN_WIDTH}x{SCREEN_HEIGHT} @ {TARGET_FPS} FPS")
    print(f"Audio: {SAMPLERATE} Hz, {NUM_SAMPLES} samples/buffer")
    print(f"Dispositivo: {DEVICE_NAME}")
    print(f"Patrones visuales: {TOTAL_PATTERNS}")
    print(f"Paleta de colores: {len(COLOR_PALETTE)} colores")
    print(f"Detección de beats: Umbral={BEAT_THRESHOLD}, Cooldown={BEAT_COOLDOWN}s")
    
    # --- NUEVA INFORMACIÓN ---
    print(f"Modo de cambio de patrón: {PATTERN_ORDER_MODE}")
    if PATTERN_ORDER_MODE == "random":
        print(f"Rango de beats para cambio: {RANDOM_BEAT_RANGE[0]} a {RANDOM_BEAT_RANGE[1]} beats")
    else:
        print(f"Beats para cambio: {SHAPE_CHANGE_BEATS} beats")
        
    print("="*70 + "\n")