# 🎵 Visualizador Generativo de Música

**Visualizador de música en tiempo real con 36 efectos visuales únicos en pantalla completa**

---

## 📋 Descripción

Visualizador de música profesional con interfaz gráfica que captura el audio del sistema en tiempo real y genera impresionantes efectos visuales reactivos. Utiliza análisis FFT avanzado, detección inteligente de beats, y renderizado GPU mediante shaders GLSL.

### ✨ Características

- 🖥️ **Interfaz Gráfica Completa**
  - Menú visual para selección de modo
  - Pantalla completa automática
  - 3 modos de visualización: Admin, Order, Random

- 🎵 **Análisis de Audio Avanzado**
  - Captura de audio del sistema en tiempo real
  - Análisis FFT con separación por bandas (Bass, Mid, Treble)
  - Detección inteligente de beats con umbral adaptativo

- 🎨 **36 Efectos Visuales Únicos**
  - Renderizado GPU mediante OpenGL 3.3+ y shaders GLSL
  - Post-processing profesional (Bloom, Viñeta, Contraste)
  - Transiciones suaves entre efectos
  - Paletas de colores predefinidas

- ⚙️ **Altamente Configurable**
  - Configuración completa en `config.py`
  - Ajustes de sensibilidad y reactividad
  - Control de FPS y calidad visual

---

## 🔧 Requisitos del Sistema

### Software
- **Python**: 3.8 o superior
- **Sistema Operativo**: Windows, Linux, macOS
- **GPU**: Compatible con OpenGL 3.3 o superior

### Hardware Recomendado
- **CPU**: Procesador moderno (Intel i5 / AMD Ryzen 5 o superior)
- **GPU**: Tarjeta gráfica dedicada recomendada
- **RAM**: 4 GB mínimo, 8 GB recomendado
- **Audio**: Dispositivo de captura de audio (loopback/stereo mix)

---

## 📦 Instalación

### 1. Clonar o Descargar el Repositorio

```bash
git clone <repository-url>
cd Visualizador
```

### 2. Instalar Dependencias

```bash
pip install -r requirements.txt
```

**Dependencias principales:**
- `pygame` - Manejo de ventanas y eventos
- `PyOpenGL` - Bindings de OpenGL para Python
- `numpy` - Cálculos numéricos y arrays
- `sounddevice` - Captura de audio del sistema

### 3. Configurar Dispositivo de Audio

#### Windows
1. Haz clic derecho en el icono de volumen → "Sonidos"
2. Pestaña "Grabación"
3. Haz clic derecho → "Mostrar dispositivos deshabilitados"
4. Activa "Mezcla estéreo" o "Stereo Mix"
5. Establécelo como dispositivo predeterminado

#### Linux (PulseAudio)
```bash
pactl load-module module-loopback
```

#### macOS
Requiere software adicional como [BlackHole](https://github.com/ExistentialAudio/BlackHole) o [Soundflower](https://github.com/mattingalls/Soundflower)

---

## 🚀 Uso

### Ejecución

```bash
python main.py
```

Se abrirá la interfaz gráfica con las siguientes opciones:

- **MODO ADMIN**: Selecciona un patrón visual específico (0-35) para probarlo
- **MODO ORDER**: Los patrones cambian cada X beats (configurable: 8, 16, 24, 32, 48, 64)
- **MODO RANDOM**: Los patrones cambian aleatoriamente cada 30-70 beats
- **SALIR**: Cierra la aplicación

### Listar Dispositivos de Audio

Si tienes problemas de audio, lista los dispositivos disponibles:

```bash
python listar_dispositivos.py
```

### Controles Durante la Visualización

| Tecla | Acción |
|-------|--------|
| `ESC` | Salir del programa |
| `SPACE` | Cambiar patrón manualmente (excepto en modo Admin) |
| `C` | Cambiar color manualmente |
| `D` | Activar/desactivar modo debug |

---

## ⚙️ Configuración

Todos los parámetros configurables están en `config.py`. A continuación, los más importantes:

### Configuración de Pantalla

```python
SCREEN_WIDTH = 1280          # Ancho de ventana (píxeles)
SCREEN_HEIGHT = 720          # Alto de ventana (píxeles)
TARGET_FPS = 60              # Frames por segundo objetivo
FULLSCREEN = False           # Modo pantalla completa
VSYNC = True                 # Sincronización vertical
```

### Configuración de Audio

```python
SAMPLERATE = 44100           # Frecuencia de muestreo (Hz)
DEVICE_NAME = "Mezcla estéreo"  # Nombre del dispositivo de audio
NUM_SAMPLES = 2048           # Tamaño del buffer de audio
AUDIO_SMOOTHING_FRAMES = 3   # Frames de suavizado
```

### Detección de Beats

```python
BEAT_THRESHOLD = 0.28                    # Umbral de detección
BEAT_COOLDOWN = 0.15                     # Tiempo mínimo entre beats
BEAT_THRESHOLD_ADAPTATION = 0.02         # Adaptación automática
```

### Modos de Cambio de Patrón

```python
PATTERN_ORDER_MODE = "random"            # "order" o "random"
SHAPE_CHANGE_BEATS = 16                  # Beats para cambiar (modo order)
RANDOM_BEAT_RANGE = (30, 70)            # Rango aleatorio (modo random)
```

### Efectos Visuales

```python
SENSITIVITY = 2.5                        # Sensibilidad a la música
DECAY_RATE = 0.98                       # Velocidad de decaimiento
RAYS_PER_BEAT = 8                       # Partículas por beat
TOTAL_PATTERNS = 36                     # Total de patrones disponibles
```

### Post-Processing

```python
BLOOM_INTENSITY = 0.3        # Resplandor (0.0 - 1.0)
VIGNETTE_INTENSITY = 0.2     # Viñeta (0.0 - 1.0)
CONTRAST = 1.1               # Contraste (0.5 - 2.0)
SATURATION = 1.15            # Saturación (0.0 - 2.0)
```

### Paletas de Colores

```python
# Usar paleta personalizada
COLOR_PALETTE = PALETTE_CYBERPUNK  # También: PALETTE_FIRE, PALETTE_OCEAN

# O crear tu propia paleta
COLOR_PALETTE = [
    (1.0, 0.0, 0.0),  # Rojo
    (0.0, 1.0, 0.0),  # Verde
    (0.0, 0.0, 1.0),  # Azul
]
```

---

## 🏗️ Estructura del Proyecto

```
Visualizador/
├── main.py                  # Punto de entrada y bucle principal
├── gui.py                   # Interfaz gráfica de usuario
├── config.py                # Configuración global
├── audio_handler.py         # Captura y análisis de audio
├── renderer.py              # Motor de renderizado OpenGL
├── listar_dispositivos.py   # Utilidad para listar dispositivos de audio
├── shaders/
│   ├── vertex.glsl          # Vertex shader
│   └── fragment.glsl        # Fragment shader (36 efectos visuales)
├── requirements.txt         # Dependencias de Python
└── README.md               # Este archivo
```



---

---

## 🐛 Solución de Problemas

### El audio no se captura

**Síntoma**: Los efectos no reaccionan a la música

**Soluciones**:
1. Verifica que "Mezcla estéreo" / "Stereo Mix" esté habilitado
2. Asegúrate de que está configurado como dispositivo predeterminado
3. Revisa el nombre del dispositivo en `config.py` → `DEVICE_NAME`
4. Ejecuta el programa y verifica los mensajes de consola

### Bajo rendimiento / FPS bajos

**Síntoma**: La animación se ve entrecortada

**Soluciones**:
1. Reduce la resolución en `config.py`
2. Desactiva VSync: `VSYNC = False`
3. Reduce `BLOOM_INTENSITY` y otros efectos de post-processing
4. Asegúrate de tener los drivers de GPU actualizados
5. Cierra otras aplicaciones que usen GPU

### Error al compilar shaders

**Síntoma**: El programa se cierra con error de shader

**Soluciones**:
1. Verifica que tu GPU soporte OpenGL 3.3+
2. Actualiza los drivers de tu tarjeta gráfica
3. Revisa que no hayas modificado incorrectamente los archivos .glsl
4. Mira el error específico en la consola para más detalles

### No se encuentra el dispositivo de audio

**Síntoma**: "No se encontró Mezcla estéreo"

**Soluciones**:
1. Windows: Habilita "Mezcla estéreo" en configuración de sonido
2. Linux: Instala y configura PulseAudio loopback
3. macOS: Instala BlackHole o Soundflower
4. Modifica `DEVICE_NAME` en `config.py` con el nombre correcto

---

## 📊 Rendimiento y Optimización

### Benchmarks Típicos

| Resolución | GPU | FPS Promedio |
|-----------|-----|--------------|
| 1280x720  | GTX 1060 | 60 (VSync) |
| 1920x1080 | GTX 1060 | 60 (VSync) |
| 2560x1440 | RTX 3060 | 60 (VSync) |
| 3840x2160 | RTX 3080 | 55-60 |

### Consejos de Optimización

1. **Resolución**: Usa 1280x720 o 1920x1080 para mejor balance
2. **VSync**: Actívalo para evitar screen tearing
3. **Post-processing**: Reduce intensidades si tienes GPU débil
4. **Buffer de audio**: `NUM_SAMPLES = 2048` es óptimo (no cambiar)
5. **Modo debug**: Desactívalo en producción (`DEBUG_MODE = False`)

---

---

## 🎵 ¡Disfruta!

Reproduce tu música favorita y observa los efectos visuales reaccionar en tiempo real en pantalla completa.
