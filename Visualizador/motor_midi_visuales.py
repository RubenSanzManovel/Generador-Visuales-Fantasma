import mido
import sys

# --- CONFIGURACIÓN DE TU LIBRERÍA DE 50 VISUALES ---
# Cambia estos strings o números por tus funciones reales de renderizado
MIS_VISUALES = [f"Visual_Fantasma_{i}" for i in range(1, 51)]
visual_actual_index = 0

def cambiar_tipo_visual(index):
    global visual_actual_index
    # Aseguramos que no se salga del rango de tus 50 visuales
    visual_actual_index = index % len(MIS_VISUALES)
    print(f"🔮 [EVENTO VISUAL] Cambiando al fantasma: {MIS_VISUALES[visual_actual_index]}")

def aplicar_efecto_temporal(tipo_efecto):
    print(f"💥 [EFECTO TEMPORAL] ¡Disparando {tipo_efecto} en el visual!")

def actualizar_audio_visual(parametro, valor_normalizado):
    # Aquí es donde pasas los datos del fader/filtro a tus Shaders, Partículas o escala
    # valor_normalizado siempre será un flotante entre 0.0 y 1.0
    print(f"🎛️ [PROCESO DINÁMICO] Parámetro: {parametro} -> {valor_normalizado:.2f}")


# --- DICCIONARIOS DE MAPEO DE TU DDJ-SB2 ---

# 1. Mapeo de Botones (Mensajes Tipo Note On)
MAPEO_BOTONES = {
    # Play / Cue (Canales 90 y 91)
    (0x90, 0x0B): {"action": "play_izq",   "type": "state"},
    (0x90, 0x0C): {"action": "cue_izq",    "type": "state"},
    (0x91, 0x0B): {"action": "play_der",   "type": "state"},
    (0x91, 0x0C): {"action": "cue_der",    "type": "state"},
    
    # HotCues Deck Izquierdo (97) -> Cambian a los visuales del 0 al 3
    (0x97, 0x00): {"action": "visual_0",   "type": "change", "index": 0},
    (0x97, 0x01): {"action": "visual_1",   "type": "change", "index": 1},
    (0x97, 0x02): {"action": "visual_2",   "type": "change", "index": 2},
    (0x97, 0x03): {"action": "visual_3",   "type": "change", "index": 3},
    
    # HotCues Deck Derecho (98) -> Cambian a los visuales del 4 al 7
    (0x98, 0x00): {"action": "visual_4",   "type": "change", "index": 4},
    (0x98, 0x01): {"action": "visual_5",   "type": "change", "index": 5},
    (0x98, 0x02): {"action": "visual_6",   "type": "change", "index": 6},
    (0x98, 0x03): {"action": "visual_7",   "type": "change", "index": 7},
    
    # AutoLoops (Efectos momentáneos / glitches visuales)
    (0x97, 0x10): {"action": "glitch_1",   "type": "fx"},
    (0x97, 0x11): {"action": "glitch_2",   "type": "fx"},
    (0x97, 0x12): {"action": "glitch_4",   "type": "fx"},
    (0x97, 0x13): {"action": "glitch_8",   "type": "fx"},
    (0x98, 0x10): {"action": "strobe_1",   "type": "fx"},
    (0x98, 0x11): {"action": "strobe_2",   "type": "fx"},
    (0x98, 0x12): {"action": "strobe_4",   "type": "fx"},
    (0x98, 0x13): {"action": "strobe_8",   "type": "fx"},
}


# --- CONEXIÓN AL PUERTO VIRTUAL ---
target_port = None
for port in mido.get_input_names():
    if "Visuales_Bridge" in port:
        target_port = port
        break

if not target_port:
    print("❌ ERROR: No se encontró 'Visuales_Bridge'. Abre loopMIDI y Bome primero.")
    sys.exit()

print(f"🟢 SISTEMA DE VISUALES CONECTADO A: {target_port}")
print("Listo para mezclar en Serato y renderizar...\n")


# --- BUCLE DE ESCUCHA EN TIEMPO REAL ---
try:
    with mido.open_input(target_port) as inport:
        for msg in inport:
            msg_bytes = msg.bytes()
            if len(msg_bytes) < 3:
                continue
                
            status, data1, data2 = msg_bytes[0], msg_bytes[1], msg_bytes[2]
            
            # -------------------------------------------------------------
            # LOGICA A: PROCESAR BOTONES (Pulsación Note On / 7F)
            # -------------------------------------------------------------
            if data2 == 0x7F: 
                boton = MAPEO_BOTONES.get((status, data1))
                if boton:
                    if boton["type"] == "change":
                        cambiar_tipo_visual(boton["index"])
                    elif boton["type"] == "fx":
                        aplicar_efecto_temporal(boton["action"])
                    elif boton["type"] == "state":
                        print(f"🎵 Estado de Serato: {boton['action'].upper()} presionado.")

            # -------------------------------------------------------------
            # LOGICA B: PROCESAR CONTROLES CONTINUOS (Faders y Knobs / B0, B1, B6)
            # -------------------------------------------------------------
            elif (status & 0xF0) == 0xB0:
                # Normalizamos el valor de pp (0-127) a un float cómodo (0.0 a 1.0)
                valor_normalizado = data2 / 127.0
                
                # Volúmenes
                if status == 0xB0 and data1 == 0x13:
                    actualizar_audio_visual("opacidad_fantasma_izq", valor_normalizado)
                elif status == 0xB1 and data1 == 0x13:
                    actualizar_audio_visual("opacidad_fantasma_der", valor_normalizado)
                    
                # Filtros (Lógica matemática del punto medio 0x40 / 64)
                elif status == 0xB6 and (data1 == 0x17 or data1 == 0x18):
                    deck_side = "Izq" if data1 == 0x17 else "Der"
                    
                    if data2 == 0x40:
                        print(f"🎛️ Filtro {deck_side}: CENTRADO (Sin efecto)")
                    elif data2 < 0x40:
                        # LPF: Mapeamos de 63 a 0 -> a un rango de 0.0 a 1.0 de intensidad de corte
                        intensidad_lpf = (0x40 - data2) / 64.0
                        actualizar_audio_visual(f"filtro_LPF_{deck_side}", intensidad_lpf)
                    else:
                        # HPF: Mapeamos de 65 a 127 -> a un rango de 0.0 a 1.0 de intensidad de corte
                        intensidad_hpf = (data2 - 0x40) / 63.0
                        actualizar_audio_visual(f"filtro_HPF_{deck_side}", intensidad_hpf)

except KeyboardInterrupt:
    print("\nCierre del sistema de visuales.")