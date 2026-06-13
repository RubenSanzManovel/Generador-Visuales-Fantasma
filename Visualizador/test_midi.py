import mido
import sys

# 1. Listar los puertos para asegurarnos de que Python ve tu puente virtual
print("--- PUERTOS MIDI DETECTADOS ---")
input_ports = mido.get_input_names()
for port in input_ports:
    print(f"-> Dispositivo encontrado: {port}")
print("-------------------------------\n")

# 2. Buscar el puerto de Bome (Visuales_Bridge)
# Usamos un filtro simple por si el nombre varía ligeramente según el sistema
target_port = None
for port in input_ports:
    if "Visuales_Bridge" in port:
        target_port = port
        break

if not target_port:
    print("❌ ERROR: No se encontró el puerto virtual 'Visuales_Bridge'.")
    print("Asegúrate de que loopMIDI está corriendo y que Bome tiene el puerto abierto.")
    sys.exit()

print(f"🟢 Conectado con éxito a: {target_port}")
print("Escuchando... Presiona el Pad en tu Pioneer DDJ-SB2.\n")

# 3. Bucle principal de escucha
try:
    with mido.open_input(target_port) as inport:
        for msg in inport:
            # Los mensajes "Raw MIDI" de Bome suelen entrar como tipo 'note_on' o 'unknown'
            # Convertimos el mensaje a sus bytes nativos en hexadecimal
            msg_bytes = msg.bytes()
            
            # Formateamos los bytes para que se vean igual que en Bome (ej: "97 00 7F")
            hex_string = " ".join(f"{b:02X}" for b in msg_bytes)
            
            print(f"[Datos Recibidos]: {hex_string}")

            # 4. Condición exacta para tu Pad configurado (97 00 7F)
            # En decimal: 97 hex = 151, 00 hex = 0, 7F hex = 127
            if len(msg_bytes) >= 3 and msg_bytes[0] == 0x97 and msg_bytes[1] == 0x00 and msg_bytes[2] == 0x7F:
                print("\n" + "="*40)
                print("💥 ¡BOOM! ¡PAD DETECTADO EN PYTHON! 💥")
                print("Aquí es donde lanzarás el cambio de tus visuales.")
                print("="*40 + "\n")

except KeyboardInterrupt:
    print("\nPrueba finalizada por el usuario. ¡A seguir programando!")