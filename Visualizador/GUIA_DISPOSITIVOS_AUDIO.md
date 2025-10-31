# 🎧 GUÍA DE SELECCIÓN DE DISPOSITIVOS DE AUDIO

Esta guía te ayudará a configurar correctamente el dispositivo de audio para que el visualizador pueda capturar y reaccionar a tu música.

---

## 📋 Índice

1. [Conceptos Básicos](#conceptos-básicos)
2. [Listar Dispositivos Disponibles](#listar-dispositivos-disponibles)
3. [Tipos de Dispositivos](#tipos-de-dispositivos)
4. [Métodos de Selección](#métodos-de-selección)
5. [Configuración por Sistema Operativo](#configuración-por-sistema-operativo)
6. [Solución de Problemas](#solución-de-problemas)

---

## 🎯 Conceptos Básicos

### ¿Qué es un dispositivo de captura de audio?

Un **dispositivo de captura** (o entrada) es cualquier hardware que puede grabar/capturar audio:
- 🎤 **Micrófonos** - Capturan audio del ambiente
- 🔊 **Mezcla Estéreo** (Stereo Mix) - Captura TODO el audio que reproduce tu PC
- 🎧 **Auriculares con micrófono** - Capturan tanto del micro como de la salida
- 🔌 **Entradas de línea** - Capturan desde dispositivos externos

### ¿Cuál dispositivo debo usar?

**Para reaccionar a música reproducida en tu PC:**
- ✅ Usa **"Mezcla estéreo"** (Stereo Mix, Wave Out Mix, Loopback)
- ✅ Captura TODA la música sin importar la aplicación (Spotify, YouTube, etc.)

**Para reaccionar a audio externo:**
- ✅ Usa un **micrófono**
- ✅ Ideal para música en vivo, instrumentos, o voz

**Para reaccionar a auriculares específicos:**
- ✅ Algunos auriculares tienen entrada de "monitoreo"
- ✅ Verifica si tu dispositivo tiene canal de entrada

---

## 📊 Listar Dispositivos Disponibles

### Ejecutar el Script de Listado

```bash
python listar_dispositivos.py
```

**Salida de ejemplo:**

```
🎵 LISTA DE DISPOSITIVOS DE AUDIO DEL SISTEMA 🎵

📥 DISPOSITIVOS DE ENTRADA (4 disponibles):
--------------------------------------------------------------------------------

  ID: 0 ⭐ [PREDETERMINADO]
  📛 Nombre: Micrófono (Realtek Audio)
      🎤 [MICRÓFONO]
  🎚️  Canales: 2 entrada(s)
  📊 Sample Rate: 48000 Hz

  ID: 2
  📛 Nombre: Mezcla estéreo (Realtek Audio)
      🔊 [MEZCLA ESTÉREO - Captura audio del sistema]
  🎚️  Canales: 2 entrada(s)
  📊 Sample Rate: 48000 Hz

  ID: 5
  📛 Nombre: Auriculares (USB Audio Device)
      🎧 [AURICULARES]
  🎚️  Canales: 1 entrada(s)
  📊 Sample Rate: 44100 Hz
```

**¿Qué significa cada campo?**

- **ID**: Número único del dispositivo (usa este para `--device`)
- **⭐ PREDETERMINADO**: El dispositivo activo por defecto en tu sistema
- **Canales**: Número de canales de audio (2 = estéreo, 1 = mono)
- **Sample Rate**: Frecuencia de muestreo en Hz (mayor = mejor calidad)

---

## 🎵 Tipos de Dispositivos

### 🔊 Mezcla Estéreo (Stereo Mix)

**¿Qué es?**
- Dispositivo virtual que captura TODO el audio de tu PC
- Mezcla todas las aplicaciones en un solo stream

**Ventajas:**
- ✅ Captura música de Spotify, YouTube, juegos, etc.
- ✅ Calidad perfecta (digital puro, sin pérdida)
- ✅ Sin ruido ambiental

**Desventajas:**
- ❌ Puede estar deshabilitado por defecto en Windows
- ❌ Captura TODOS los sonidos (notificaciones, etc.)

**Nombres comunes:**
- "Mezcla estéreo"
- "Stereo Mix"
- "Wave Out Mix"
- "What U Hear"
- "Loopback"

---

### 🎧 Auriculares

**¿Qué es?**
- Entrada de audio desde auriculares con monitoreo
- Algunos modelos tienen canal de entrada además de salida

**Ventajas:**
- ✅ Captura solo el audio de los auriculares
- ✅ Ideal si usas auriculares específicos

**Desventajas:**
- ❌ No todos los auriculares tienen entrada
- ❌ Puede requerir configuración adicional

---

### 🎤 Micrófono

**¿Qué es?**
- Captura audio del ambiente a través del micrófono

**Ventajas:**
- ✅ Ideal para música en vivo
- ✅ Reacciona a instrumentos reales
- ✅ Reacciona a tu voz

**Desventajas:**
- ❌ Capta ruido ambiental
- ❌ Calidad depende del micrófono
- ❌ Puede tener latencia

---

## 🎮 Métodos de Selección

### Método 1: Selector Interactivo (Recomendado)

**Comando:**
```bash
python main.py
```

**Descripción:**
- Se abre un menú interactivo al inicio
- Muestra TODOS los dispositivos disponibles
- Marca los dispositivos especiales (🔊 Mezcla, 🎧 Auriculares)
- Permite elegir fácilmente

**Ejemplo:**
```
🎵 SELECCIÓN DE DISPOSITIVO DE AUDIO 🎵

📋 Dispositivos de entrada disponibles:

  [0] Micrófono (Realtek Audio) 🎤 [MICRÓFONO]
      ID: 0 | Canales: 2 | Sample Rate: 48000 Hz

  [1] Mezcla estéreo (Realtek Audio) 🔊 [MEZCLA ESTÉREO]
      ID: 2 | Canales: 2 | Sample Rate: 48000 Hz

  [2] Auriculares (USB) 🎧 [AURICULARES]
      ID: 5 | Canales: 1 | Sample Rate: 44100 Hz

👉 Selecciona un dispositivo [0-2] o [Q] para salir: _
```

---

### Método 2: Selección Automática

**Comando:**
```bash
python main.py --auto
```

**Descripción:**
- Busca automáticamente el dispositivo configurado en `config.py`
- Por defecto busca "Mezcla estéreo"
- Rápido pero menos flexible

**Configuración en config.py:**
```python
DEVICE_NAME = "Mezcla estéreo"  # Cambiar según tu sistema
```

---

### Método 3: ID Específico

**Comando:**
```bash
python main.py --device 2
```

**Descripción:**
- Usa directamente un dispositivo por su ID
- Más rápido una vez que conoces el ID
- Ideal para scripts automatizados

**Paso a paso:**
1. Ejecuta `python listar_dispositivos.py`
2. Anota el ID del dispositivo deseado
3. Ejecuta `python main.py --device ID`

---

## 💻 Configuración por Sistema Operativo

### 🪟 Windows 10/11

#### Habilitar "Mezcla estéreo"

1. **Clic derecho** en el icono de volumen (esquina inferior derecha)
2. Selecciona **"Sonidos"**
3. Ve a la pestaña **"Grabación"**
4. **Clic derecho** en el área vacía → **"Mostrar dispositivos deshabilitados"**
5. Aparecerá **"Mezcla estéreo"** o **"Stereo Mix"**
6. **Clic derecho** → **"Habilitar"**
7. (Opcional) **Clic derecho** → **"Establecer como dispositivo predeterminado"**

**Captura de pantalla de ubicación:**
```
Panel de Control
  └─ Hardware y Sonido
      └─ Sonido
          └─ Pestaña "Grabación"
              └─ Clic derecho → "Mostrar dispositivos deshabilitados"
```

#### Si no aparece "Mezcla estéreo"

**Posible causa:** Tu tarjeta de audio no lo soporta nativamente.

**Soluciones:**
1. Actualiza los drivers de audio desde el sitio del fabricante
2. Usa software de terceros:
   - [VB-Audio Virtual Cable](https://vb-audio.com/Cable/) (Gratis)
   - [Voicemeeter](https://vb-audio.com/Voicemeeter/) (Gratis, más completo)

---

### 🐧 Linux (PulseAudio)

#### Habilitar Loopback

```bash
# Cargar módulo de loopback
pactl load-module module-loopback

# Verificar que se cargó
pactl list short modules | grep loopback
```

#### Hacer permanente

Edita `/etc/pulse/default.pa` y agrega:
```
load-module module-loopback
```

#### Usando PipeWire (Sistemas modernos)

```bash
# Verificar que PipeWire está activo
systemctl --user status pipewire

# Crear loopback virtual
pw-loopback
```

---

### 🍎 macOS

#### Usar BlackHole (Recomendado)

1. **Descargar** [BlackHole](https://existential.audio/blackhole/)
2. **Instalar** el archivo `.pkg`
3. **Abrir** "Audio MIDI Setup" (Configuración de Audio MIDI)
4. **Crear** un dispositivo multi-salida:
   - Clic en **+** → **"Crear dispositivo de salida múltiple"**
   - Marca **"BlackHole 2ch"** y tus altavoces
5. **Usar** este dispositivo como salida de sistema
6. En el visualizador, selecciona **"BlackHole 2ch"** como entrada

#### Alternativa: Soundflower

Similar a BlackHole pero más antiguo:
```bash
brew install soundflower
```

---

## 🔧 Solución de Problemas

### ❌ "No se encontró dispositivo de audio"

**Posibles causas:**
1. No hay dispositivos de entrada habilitados
2. El nombre configurado no coincide

**Soluciones:**
1. Ejecuta `python listar_dispositivos.py` para ver qué hay disponible
2. Habilita "Mezcla estéreo" en Windows
3. Usa el selector interactivo: `python main.py`

---

### ❌ "El visualizador no reacciona a la música"

**Posibles causas:**
1. Dispositivo incorrecto seleccionado
2. Volumen del dispositivo muy bajo
3. Aplicación de música en pausa

**Soluciones:**
1. Verifica que elegiste "Mezcla estéreo" o un dispositivo de loopback
2. Revisa el volumen del dispositivo en configuración de audio
3. Reproduce música y verifica que se esté reproduciendo
4. Activa el modo debug (`D`) para ver los valores de audio en tiempo real

---

### ❌ "El audio se escucha con eco"

**Causa:**
- Tienes "Mezcla estéreo" como dispositivo de reproducción Y grabación

**Solución:**
- "Mezcla estéreo" debe ser SOLO dispositivo de grabación
- Usa tus altavoces/auriculares como dispositivo de reproducción

---

### ❌ "Error: Device not found (ID: X)"

**Causa:**
- El ID especificado no existe

**Solución:**
1. Ejecuta `python listar_dispositivos.py`
2. Verifica que el ID existe
3. Usa el ID correcto con `--device`

---

## 💡 Consejos Avanzados

### Mejor Calidad de Audio

Para máxima calidad de captura:
1. Usa "Mezcla estéreo" (captura digital directa)
2. Configura sample rate alto (48000 Hz o superior)
3. Usa formato de 24 bits si está disponible

### Múltiples Dispositivos

Para usar múltiples dispositivos simultáneamente:
1. **Windows:** Usa software como Voicemeeter
2. **Linux:** Configura un sink virtual con PulseAudio
3. **macOS:** Crea un dispositivo agregado en Audio MIDI Setup

### Automatización

Para lanzar siempre con el mismo dispositivo:

**Windows (PowerShell):**
```powershell
# Guardar en "ejecutar_visualizador.ps1"
python main.py --device 2
```

**Linux/macOS (Bash):**
```bash
#!/bin/bash
# Guardar en "ejecutar_visualizador.sh" y hacer ejecutable
python3 main.py --device 2
```

---

## 📞 Soporte

Si sigues teniendo problemas:

1. Ejecuta `python listar_dispositivos.py` y guarda la salida
2. Verifica que `sounddevice` está instalado: `pip show sounddevice`
3. Prueba el selector interactivo: `python main.py`
4. Revisa el archivo `config.py` y asegúrate de que `DEVICE_NAME` sea correcto

---

**¡Disfruta del visualizador! 🎵✨**
