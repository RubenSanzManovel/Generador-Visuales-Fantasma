# 🚀 GUÍA DE INICIO RÁPIDO

## ⚡ Instalación en 3 Pasos

### 1. Instalar Dependencias
```bash
pip install pygame PyOpenGL PyOpenGL-accelerate numpy sounddevice
```

### 2. Configurar Audio (Windows)
1. Click derecho en icono de volumen
2. "Sonidos" → Pestaña "Grabación"
3. Click derecho → "Mostrar dispositivos deshabilitados"
4. Activar "Mezcla estéreo" / "Stereo Mix"

### 3. Ejecutar
```bash
python main.py
```

---

## 🎮 Controles

| Tecla | Función |
|-------|---------|
| `ESC` | Salir |
| `SPACE` | Cambiar efecto |
| `C` | Cambiar color |
| `D` | Modo debug |

---

## ⚙️ Configuración Rápida

Edita `config.py`:

```python
# Cambiar resolución
SCREEN_WIDTH = 1920
SCREEN_HEIGHT = 1080

# Ajustar sensibilidad (1.0-5.0)
SENSITIVITY = 3.0

# Usar paleta diferente
COLOR_PALETTE = PALETTE_CYBERPUNK  # o PALETTE_FIRE, PALETTE_OCEAN

# Efectos más intensos
BLOOM_INTENSITY = 0.5
VIGNETTE_INTENSITY = 0.3
```

---

## 🐛 Problemas Comunes

### No reacciona a la música
- ✅ Verifica que "Mezcla estéreo" esté activo
- ✅ Reproduce música (Spotify, YouTube, etc.)
- ✅ Sube el volumen del sistema

### FPS bajos
- ✅ Reduce resolución en config.py
- ✅ Desactiva BLOOM y VIGNETTE
- ✅ Cierra otras aplicaciones

### No encuentra dispositivo de audio
- ✅ Cambia `DEVICE_NAME` en config.py
- ✅ Windows: "Mezcla estéreo"
- ✅ Verifica en Panel de Control → Sonido

---

## 📖 Más Información

- **README.md**: Documentación completa
- **MEJORAS.md**: Lista de mejoras implementadas
- **config.py**: Todos los parámetros explicados

---

## 🎵 ¡Disfruta!

Reproduce tu música favorita y observa los efectos visuales reaccionar en tiempo real.

**¡100 Millones de Euros en visuales!** 💰✨
