# 🎧 SELECTOR DE DISPOSITIVOS DE AUDIO - GUÍA RÁPIDA

## 🚀 Inicio Rápido

### Ver todos los dispositivos disponibles:
```bash
python listar_dispositivos.py
```

### Ejecutar con selector interactivo (RECOMENDADO):
```bash
python main.py
```

### Ejecutar con dispositivo específico:
```bash
python main.py --device 2
```

### Ejecutar con selección automática:
```bash
python main.py --auto
```

---

## 🎯 ¿Qué dispositivo debo elegir?

### Para capturar TODA la música del sistema
→ **Busca:** 🔊 "Mezcla estéreo" o "Stereo Mix"
→ **Ejemplo:** ID 2, 9, 17 o 25
→ **Perfecto para:** Spotify, YouTube, juegos, cualquier app

### Para capturar audio de auriculares HyperX
→ **Busca:** 🎧 "HyperX Cloud Flight Wireless"
→ **Ejemplo:** ID 3, 10, 18 o 27
→ **Perfecto para:** Audio específico de tus auriculares

### Para capturar micrófono
→ **Busca:** 🎤 "Micrófono" o "Microphone"
→ **Ejemplo:** ID 1, 24 o 26
→ **Perfecto para:** Música en vivo, voz, instrumentos

---

## 📊 Ejemplo Real del Selector

```
🎵 SELECCIÓN DE DISPOSITIVO DE AUDIO 🎵

📋 Dispositivos de entrada disponibles:

  [0] Asignador de sonido Microsoft - Input
      ID: 0 | Canales: 2 | Sample Rate: 44100.0 Hz

  [2] Mezcla estéreo (Realtek(R) Audi 🔊 [MEZCLA ESTÉREO]
      ID: 2 | Canales: 2 | Sample Rate: 44100.0 Hz  ← ¡Usa este!

  [3] Micrófono (HyperX Cloud Flight 🎧 [AURICULARES]
      ID: 3 | Canales: 1 | Sample Rate: 44100.0 Hz

👉 Selecciona un dispositivo [0-15] o [Q] para salir: 2
```

---

## ⚡ Comandos Rápidos

```bash
# 1. Ver dispositivos
python listar_dispositivos.py

# 2. Copiar el ID que quieras (ej: 2)

# 3. Ejecutar con ese ID
python main.py --device 2

# ¡Listo! 🎉
```

---

## 🆘 Solución Rápida de Problemas

**Problema:** No aparece "Mezcla estéreo"
**Solución:**
1. Abre "Panel de Control" → "Sonido"
2. Pestaña "Grabación"
3. Clic derecho → "Mostrar dispositivos deshabilitados"
4. Clic derecho en "Mezcla estéreo" → "Habilitar"

**Problema:** El visualizador no reacciona
**Solución:**
- Asegúrate de elegir "Mezcla estéreo" (🔊)
- Reproduce música de cualquier aplicación
- Verifica que el volumen no esté en mute

**Problema:** Muchos dispositivos repetidos
**Solución:**
- Es normal (diferentes Host APIs)
- Elige el que tenga mejor Sample Rate (48000 Hz mejor que 44100 Hz)

---

## 📖 Documentación Completa

Para guías detalladas, consulta:
- **GUIA_DISPOSITIVOS_AUDIO.md** - Guía completa (380+ líneas)
- **README.md** - Documentación general del proyecto
- **MEJORA_SELECTOR_AUDIO.md** - Detalles técnicos de la mejora

---

**¡Disfruta del visualizador! 🎵✨**
