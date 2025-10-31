# 🎧 ¿POR QUÉ NO SE OYE LA MÚSICA DE MIS AURICULARES?

## ❓ El Problema

**Situación:**
- Tienes auriculares HyperX Cloud Flight Wireless 🎧
- Reproduces música en Spotify/YouTube
- El visualizador NO reacciona a la música
- Solo reacciona cuando hablas al micrófono 🎤

**¿Por qué pasa esto?**
- Los auriculares tienen **DOS partes separadas**:
  1. 🔊 **SALIDA** (speakers/altavoces) → Por aquí sale la música que OYES
  2. 🎤 **ENTRADA** (micrófono) → Por aquí entra tu VOZ

---

## 🔍 La Confusión

Cuando ves en la lista de dispositivos:

```
Micrófono (HyperX Cloud Flight Wireless)
```

**Esto NO es el audio que sale por los auriculares.**
**Esto ES el micrófono que capta tu voz.**

---

## ✅ LA SOLUCIÓN CORRECTA

### Para capturar la música que estás OYENDO:

**NO uses:**
```
❌ Micrófono (HyperX Cloud Flight Wireless)
❌ Micrófono (Realtek Audio)
❌ Varios micrófonos
```

**USA:**
```
✅ Mezcla estéreo (Realtek Audio)
✅ Stereo Mix
✅ Wave Out Mix
✅ Loopback
```

---

## 🎯 Paso a Paso

### 1️⃣ **Ejecutar el listado de dispositivos**

```bash
python listar_dispositivos.py
```

**Busca en la sección:**
```
🔊 === RECOMENDADOS: CAPTURAN TODO EL AUDIO DEL SISTEMA ===
```

**Ejemplo de salida:**
```
  ID: 2
  📛 Nombre: Mezcla estéreo (Realtek(R) Audi
      🔊 [MEZCLA ESTÉREO - Captura audio del sistema]  ← ¡USA ESTE!
  🎚️  Canales: 2 entrada(s)
  📊 Sample Rate: 44100 Hz

  ID: 17
  📛 Nombre: Mezcla estéreo (Realtek(R) Audio)
      🔊 [MEZCLA ESTÉREO - Captura audio del sistema]  ← O ESTE
  🎚️  Canales: 2 entrada(s)
  📊 Sample Rate: 48000 Hz  ✅ Alta calidad (48kHz)  ← MEJOR CALIDAD
```

---

### 2️⃣ **Ejecutar el visualizador**

```bash
python main.py
```

**Cuando te pregunte, elige uno con 🔊:**
```
👉 Selecciona un dispositivo [0-15] o [Q] para salir: 9
```

*(El número exacto depende de tu sistema, busca el que dice "Mezcla estéreo")*

---

### 3️⃣ **Reproducir música**

- Abre Spotify, YouTube, o cualquier app de música
- Reproduce una canción
- **¡El visualizador debería reaccionar! 🎉**

---

## 🤔 ¿Qué hace cada dispositivo?

### 🔊 **Mezcla Estéreo (Stereo Mix)**

**¿Qué captura?**
- TODO el audio que sale por tus altavoces/auriculares
- Música de Spotify ✅
- Videos de YouTube ✅
- Juegos ✅
- Notificaciones ✅
- ¡Todo! ✅

**¿Cómo funciona?**
- Es un dispositivo VIRTUAL
- Captura el audio ANTES de que salga por los auriculares
- Audio digital puro (sin pérdida de calidad)

**Ventajas:**
- ✅ Calidad perfecta
- ✅ Sin ruido
- ✅ Sin latencia
- ✅ Captura todo el sistema

---

### 🎤 **Micrófono (HyperX Cloud Flight)**

**¿Qué captura?**
- Tu VOZ cuando hablas al micrófono
- Sonidos del ambiente
- Música que suena CERCA del micrófono

**¿Qué NO captura?**
- ❌ La música que estás OYENDO en los auriculares
- ❌ Audio de Spotify
- ❌ Audio de YouTube
- ❌ Audio de juegos

**¿Cuándo usarlo?**
- Cuando quieres que reaccione a tu voz
- Para karaoke
- Para DJ en vivo
- Para instrumentos musicales en directo

---

## 🛠️ Si no aparece "Mezcla estéreo"

### En Windows 10/11:

1. **Clic derecho** en el icono de volumen (esquina inferior derecha)
2. **"Sonidos"**
3. Pestaña **"Grabación"**
4. **Clic derecho** en área vacía → **"Mostrar dispositivos deshabilitados"**
5. Debe aparecer **"Mezcla estéreo"**
6. **Clic derecho** en "Mezcla estéreo" → **"Habilitar"**
7. (Opcional) Clic derecho → **"Establecer como dispositivo predeterminado"**

### Si AÚN no aparece:

**Tu tarjeta de audio puede no soportarlo nativamente.**

**Solución: Usar software virtual**

1. **Descarga VB-Audio Virtual Cable** (GRATIS)
   - Web: https://vb-audio.com/Cable/
   - Descarga e instala

2. **Configura el cable virtual:**
   - Panel de Control → Sonido
   - Pestaña "Reproducción"
   - Establece "CABLE Input" como predeterminado
   - Pestaña "Grabación"
   - Usa "CABLE Output" en el visualizador

3. **Ahora el audio se captura por el cable virtual**

---

## 📊 Resumen Visual

```
┌─────────────────────────────────────────────────────┐
│  TU ORDENADOR                                       │
│                                                     │
│  ┌──────────┐                                       │
│  │ Spotify  │────┐                                  │
│  └──────────┘    │                                  │
│                  ▼                                  │
│  ┌──────────┐  ┌─────────────────┐                 │
│  │ YouTube  │─→│  MEZCLA ESTÉREO │→ [VISUALIZADOR] │
│  └──────────┘  │  (Stereo Mix)   │    ✅ Funciona  │
│                └─────────────────┘                  │
│  ┌──────────┐         │                             │
│  │  Juegos  │─────────┘                             │
│  └──────────┘         ▼                             │
│                  ┌──────────┐                       │
│                  │ Auriculares 🎧                   │
│                  │ (SALES)   │                      │
│                  └──────────┘                       │
│                                                     │
│  ┌─────────────────────┐                            │
│  │ Micrófono 🎤        │→ [VISUALIZADOR]            │
│  │ (ENTRADA)           │   ❌ NO funciona           │
│  │ Captura tu voz      │   (para música)           │
│  └─────────────────────┘                            │
└─────────────────────────────────────────────────────┘
```

---

## ✅ Checklist Final

Antes de ejecutar el visualizador, verifica:

- [ ] He ejecutado `python listar_dispositivos.py`
- [ ] He identificado un dispositivo con 🔊 "Mezcla estéreo"
- [ ] NO voy a usar un dispositivo con 🎤 "Micrófono"
- [ ] He anotado el ID del dispositivo "Mezcla estéreo"
- [ ] Voy a ejecutar `python main.py --device ID`
- [ ] Tengo música lista para reproducir en Spotify/YouTube

---

## 🎵 Ejemplo Real

**Tu sistema tiene:**
```
ID: 2  - Mezcla estéreo (44100 Hz)      ← Opción OK
ID: 9  - Mezcla estéreo (44100 Hz)      ← Opción OK
ID: 17 - Mezcla estéreo (48000 Hz)      ← MEJOR OPCIÓN (mayor calidad)
ID: 25 - Mezcla estéreo (48000 Hz)      ← MEJOR OPCIÓN (mayor calidad)
```

**Comandos recomendados:**

```bash
# Opción 1: Usar ID 17 (mejor calidad)
python main.py --device 17

# Opción 2: Usar selector interactivo
python main.py
# Luego elige [9] o [13] (los que dicen 48000 Hz)
```

---

## 🆘 Última Ayuda

**Si TODAVÍA no funciona después de usar "Mezcla estéreo":**

1. **Verifica que la música se esté reproduciendo:**
   - Abre el mezclador de volumen de Windows
   - Verifica que Spotify/YouTube tengan volumen

2. **Verifica el volumen de "Mezcla estéreo":**
   - Panel de Control → Sonido → Grabación
   - Clic en "Mezcla estéreo" → Propiedades
   - Pestaña "Niveles" → Sube a 100%

3. **Reproduce música con VOLUMEN ALTO:**
   - El visualizador necesita detectar el audio
   - Sube el volumen del sistema

4. **Prueba con otra aplicación:**
   - Si Spotify no funciona, prueba con YouTube
   - Reproduce una canción con MUCHO bajo

---

## 🎉 Resumen de 3 Líneas

1. **NO uses** "Micrófono (HyperX...)" ❌ → Ese es el micro, no la música
2. **USA** "Mezcla estéreo" ✅ → Captura TODO el audio del sistema
3. **Ejecuta:** `python main.py --device 17` (o el ID de "Mezcla estéreo")

---

**¡Ahora sí debería funcionar! 🎵✨**
