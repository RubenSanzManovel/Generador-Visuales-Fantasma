# 🎵 Visualizador Generativo de Música - Premium Edition

<div align="center">

![Version](https://img.shields.io/badge/version-2.0.0-blue)
![Python](https://img.shields.io/badge/python-3.8+-green)
![OpenGL](https://img.shields.io/badge/OpenGL-3.3-red)
![License](https://img.shields.io/badge/license-MIT-yellow)

**Visualizador de música en tiempo real con 16 efectos visuales únicos generados por shaders GLSL**

[Características](#características) • [Instalación](#instalación) • [Uso](#uso) • [Configuración](#configuración) • [Arquitectura](#arquitectura)

</div>

---

## 📋 Descripción

Este es un visualizador de música profesional que captura el audio del sistema en tiempo real y genera impresionantes efectos visuales reactivos. Utiliza análisis FFT avanzado, detección inteligente de beats, y renderizado GPU mediante shaders GLSL para crear experiencias visuales únicas y fluidas.

### ✨ Características Principales

- 🎵 **Análisis de Audio Avanzado**
  - Captura de audio del sistema en tiempo real (loopback)
  - Análisis FFT con ventana de Hann
  - Separación por bandas de frecuencia (Bass, Mid, Treble)
  - Detección inteligente de beats con umbral adaptativo
  - Suavizado temporal para estabilidad

- 🎨 **16 Efectos Visuales Únicos**
  - Gotas de Agua / Ondas Concéntricas
  - Túnel Psicodélico
  - Espiral Glitch
  - Rejilla Ondulante
  - Orbe Reactivo con Rayos
  - Trama de Cubos Isométricos
  - Tejido Rítmico
  - Rosa Giratoria
  - Jardín de Flores
  - Nido de Hexágonos
  - Rejilla Hexagonal Reactiva
  - Caleidoscopio Mixto
  - Glitch Digital
  - Triángulos Danzantes
  - Campo de Explosiones
  - Hiperimpulso Estelar

- 🚀 **Optimización y Rendimiento**
  - Renderizado GPU mediante OpenGL 3.3+
  - Shaders GLSL optimizados
  - Control de FPS con VSync opcional
  - Contador de FPS en tiempo real
  - Sistema de buffers eficiente

- 🎛️ **Post-Processing Profesional**
  - Efecto Bloom (resplandor)
  - Viñeta (oscurecimiento de bordes)
  - Ajuste de contraste
  - Control de saturación
  - Transiciones suaves entre efectos

- ⚙️ **Altamente Configurable**
  - Más de 40 parámetros configurables
  - Paletas de colores predefinidas (Cyberpunk, Fuego, Océano)
  - Ajustes de sensibilidad y reactividad
  - Modo debug con información detallada
  - Validación automática de configuración

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

### Selección de Dispositivo de Audio

Antes de ejecutar el visualizador, puedes listar todos los dispositivos de audio disponibles:

```bash
python listar_dispositivos.py
```

Esto mostrará todos los dispositivos de entrada y salida, identificando automáticamente:
- 🔊 **Mezcla estéreo** - Captura todo el audio del sistema
- 🎧 **Auriculares** - Dispositivos de auriculares específicos
- 🎤 **Micrófonos** - Entradas de micrófono
- 🔈 **Altavoces** - Dispositivos de salida

### Ejecución Básica

**Opción 1: Selector Interactivo (Recomendado)**
```bash
python main.py
```
Te mostrará un menú para elegir el dispositivo de audio.

**Opción 2: Selección Automática**
```bash
python main.py --auto
```
Usa el dispositivo configurado en `config.py` (por defecto: "Mezcla estéreo").

**Opción 3: Dispositivo Específico por ID**
```bash
python main.py --device 2
```
Usa el dispositivo con ID 2 (obtén el ID con `listar_dispositivos.py`).

### Controles

| Tecla | Acción |
|-------|--------|
| `ESC` | Salir del programa |
| `SPACE` | Cambiar patrón visual manualmente |
| `C` | Cambiar color manualmente |
| `D` | Activar/desactivar modo debug |
| `F` | Toggle pantalla completa (futuro) |

### Flujo de Trabajo

1. **Iniciar el programa** → Se abrirá una ventana con el visualizador
2. **Reproducir música** → Usa cualquier aplicación de audio (Spotify, YouTube, etc.)
3. **Disfrutar** → Los efectos visuales reaccionarán automáticamente
4. **Personalizar** → Modifica `config.py` según tus preferencias

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
BEAT_THRESHOLD = 0.28        # Umbral de detección (0.15 - 0.35)
BEAT_COOLDOWN = 0.15         # Tiempo mínimo entre beats (segundos)
BEAT_THRESHOLD_ADAPTATION = 0.02  # Factor de adaptación automática
```

### Efectos Visuales

```python
SENSITIVITY = 2.5            # Sensibilidad a la música (1.0 - 5.0)
DECAY_RATE = 0.98           # Velocidad de decaimiento (0.9 - 0.99)
SHAPE_CHANGE_BEATS = 16     # Beats para cambiar de patrón
RAYS_PER_BEAT = 8           # Partículas generadas por beat
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

## 🏗️ Arquitectura del Sistema

### Estructura de Archivos

```
Visualizador/
├── main.py              # Punto de entrada y bucle principal
├── config.py            # Configuración global
├── audio_handler.py     # Captura y análisis de audio
├── renderer.py          # Motor de renderizado OpenGL
├── shaders/
│   ├── vertex.glsl      # Vertex shader
│   └── fragment.glsl    # Fragment shader (efectos visuales)
├── requirements.txt     # Dependencias de Python
└── README.md           # Este archivo
```

### Flujo de Datos

```
Audio del Sistema
        ↓
  [AudioHandler]
    • Captura audio (sounddevice)
    • Análisis FFT
    • Detección de beats
    • Análisis por bandas
        ↓
    [Estado Global]
    • Amplitud
    • Frecuencias (bass/mid/treble)
    • Beat events
    • Posiciones de partículas
        ↓
    [Renderer]
    • Envío de uniforms al GPU
    • Ejecución de shaders
    • Post-processing
        ↓
   Pantalla (60 FPS)
```

### Componentes Principales

#### 1. AudioHandler (`audio_handler.py`)
- **Función**: Captura y procesa audio del sistema
- **Tecnologías**: sounddevice, numpy FFT
- **Características**:
  - Callback de audio en thread separado
  - Análisis FFT con ventana de Hann
  - Detección de beats con umbral adaptativo
  - Separación en bandas de frecuencia
  - Buffers de suavizado temporal

#### 2. Renderer (`renderer.py`)
- **Función**: Renderiza los efectos visuales usando OpenGL
- **Tecnologías**: Pygame, PyOpenGL
- **Características**:
  - Compilación y validación de shaders
  - Envío eficiente de uniforms al GPU
  - Contador de FPS
  - Manejo de errores OpenGL

#### 3. Fragment Shader (`shaders/fragment.glsl`)
- **Función**: Define los efectos visuales en el GPU
- **Lenguaje**: GLSL 3.30
- **Características**:
  - 16 patrones visuales únicos
  - Funciones matemáticas avanzadas (noise, fbm)
  - Transiciones suaves entre patrones
  - Post-processing (bloom, viñeta, etc.)

#### 4. Main Loop (`main.py`)
- **Función**: Coordina todos los componentes
- **Características**:
  - Gestión del estado global
  - Control de FPS
  - Manejo de eventos (teclado, cierre)
  - Manejo robusto de errores

---

## 🎨 Añadir Nuevos Efectos Visuales

### Paso 1: Crear la Función del Efecto en el Shader

Edita `shaders/fragment.glsl`:

```glsl
/**
 * PATRÓN 16: Tu Nuevo Efecto
 * Descripción de lo que hace
 */
float pattern_mi_efecto(vec2 uv, float time, float amplitude) {
    // Tu código aquí
    // Retorna un valor entre 0.0 y 1.0 (intensidad del efecto)
    
    return intensidad_del_efecto;
}
```

### Paso 2: Añadir al Selector de Patrones

En la función `main()` del shader:

```glsl
else if (u_pattern_index == 16) current_intensity = pattern_mi_efecto(uv, u_time, u_amplitude);
```

### Paso 3: Actualizar la Configuración

En `config.py`:

```python
TOTAL_PATTERNS = 17  # Incrementar el número total
```

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

## 🤝 Contribuciones

Las contribuciones son bienvenidas. Si quieres añadir nuevos efectos, mejorar el rendimiento, o corregir bugs:

1. Fork del repositorio
2. Crea una branch para tu feature (`git checkout -b feature/nueva-caracteristica`)
3. Commit de tus cambios (`git commit -am 'Añade nueva característica'`)
4. Push a la branch (`git push origin feature/nueva-caracteristica`)
5. Crea un Pull Request

---

## 📜 Licencia

Este proyecto está bajo la licencia MIT. Ver archivo `LICENSE` para más detalles.

---

## 👏 Créditos

**Desarrollado por**: [Tu Nombre]
**Versión**: 2.0.0 Premium Edition
**Fecha**: Octubre 2025

### Tecnologías Utilizadas
- Python 3.x
- OpenGL 3.3+ / GLSL
- Pygame
- NumPy
- SoundDevice

---

## 📞 Soporte

¿Problemas o preguntas?
- 📧 Email: [tu-email]
- 🐛 Issues: [GitHub Issues]
- 📖 Documentación: Este README

---

<div align="center">

**Hecho con ❤️ y mucha música 🎵**

⭐ Si te gusta este proyecto, dale una estrella en GitHub ⭐

</div>
