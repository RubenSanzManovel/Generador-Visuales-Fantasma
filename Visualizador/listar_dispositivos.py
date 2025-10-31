#!/usr/bin/env python3
# ============================================================================
# LISTAR_DISPOSITIVOS.PY - UTILIDAD PARA LISTAR DISPOSITIVOS DE AUDIO
# ============================================================================
# Script de utilidad que lista todos los dispositivos de audio disponibles
# en el sistema, mostrando sus características principales.
# 
# Uso:
#   python listar_dispositivos.py
# 
# Útil para:
# - Identificar el ID de un dispositivo específico
# - Ver qué dispositivos están disponibles
# - Detectar problemas de configuración de audio
# ============================================================================

import sounddevice as sd
from typing import List, Dict, Any

def listar_todos_dispositivos() -> List[Dict[str, Any]]:
    """
    Lista todos los dispositivos de audio del sistema.
    
    Returns:
        Lista de diccionarios con información de cada dispositivo.
    """
    try:
        devices = sd.query_devices()
        dispositivos_info = []
        
        for i, device in enumerate(devices):
            device_dict = device  # type: ignore
            dispositivos_info.append({
                'id': i,
                'name': device_dict.get('name', 'Unknown'),
                'max_input_channels': device_dict.get('max_input_channels', 0),
                'max_output_channels': device_dict.get('max_output_channels', 0),
                'default_samplerate': device_dict.get('default_samplerate', 0),
                'hostapi': device_dict.get('hostapi', 0)
            })
        
        return dispositivos_info
        
    except Exception as e:
        print(f"❌ Error al listar dispositivos: {e}")
        return []

def clasificar_dispositivo(nombre: str) -> str:
    """
    Clasifica un dispositivo según su nombre.
    
    Args:
        nombre: Nombre del dispositivo
        
    Returns:
        Emoji y tipo del dispositivo
    """
    nombre_lower = nombre.lower()
    
    # Detectar tipo de dispositivo
    if any(keyword in nombre_lower for keyword in ['mezcla', 'stereo mix', 'wave out', 'loopback', 'what u hear', 'what you hear', 'wave', 'sum']):
        return "🔊 [MEZCLA ESTÉREO - Captura audio del sistema]"
    elif any(keyword in nombre_lower for keyword in ['auricular', 'headphone', 'headset', 'cascos']):
        return "🎧 [AURICULARES]"
    elif any(keyword in nombre_lower for keyword in ['micrófono', 'microphone', 'mic']):
        return "🎤 [MICRÓFONO]"
    elif any(keyword in nombre_lower for keyword in ['altavoz', 'speaker', 'parlante']):
        return "🔈 [ALTAVOCES]"
    elif any(keyword in nombre_lower for keyword in ['line', 'entrada', 'input']):
        return "🔌 [ENTRADA DE LÍNEA]"
    else:
        return ""

def main():
    """Función principal del script."""
    print("\n" + "="*80)
    print("🎵 LISTA DE DISPOSITIVOS DE AUDIO DEL SISTEMA 🎵".center(80))
    print("="*80)
    
    # Obtener dispositivos
    dispositivos = listar_todos_dispositivos()
    
    if not dispositivos:
        print("\n❌ No se encontraron dispositivos de audio")
        return
    
    # Obtener dispositivos predeterminados
    try:
        default_input = sd.default.device[0] if sd.default.device else None  # type: ignore
        default_output = sd.default.device[1] if sd.default.device else None  # type: ignore
    except:
        default_input = None
        default_output = None
    
    # Separar por tipo
    dispositivos_entrada = [d for d in dispositivos if d['max_input_channels'] > 0]
    dispositivos_salida = [d for d in dispositivos if d['max_output_channels'] > 0]
    
    # Separar dispositivos de entrada por tipo
    loopback_devs = []
    mic_devs = []
    other_input_devs = []
    
    for d in dispositivos_entrada:
        tipo = clasificar_dispositivo(d['name'])
        if '🔊' in tipo:  # Mezcla estéreo
            loopback_devs.append(d)
        elif '🎤' in tipo or '🎧' in tipo:  # Micrófonos/auriculares
            mic_devs.append(d)
        else:
            other_input_devs.append(d)
    
    # Mostrar dispositivos de ENTRADA (para capturar audio)
    print(f"\n📥 DISPOSITIVOS DE ENTRADA ({len(dispositivos_entrada)} disponibles):")
    print("-"*80)
    
    # Mostrar loopback primero (RECOMENDADOS)
    if loopback_devs:
        print("\n🔊 === RECOMENDADOS: CAPTURAN TODO EL AUDIO DEL SISTEMA ===")
        print("    (Perfecto para música de Spotify, YouTube, juegos, etc.)")
        print()
        for d in loopback_devs:
            tipo = clasificar_dispositivo(d['name'])
            default_marker = " ⭐ [PREDETERMINADO]" if d['id'] == default_input else ""
            quality_marker = " ✅ Alta calidad (48kHz)" if d['default_samplerate'] >= 48000 else ""
            
            print(f"  ID: {d['id']}{default_marker}")
            print(f"  📛 Nombre: {d['name']}")
            print(f"      {tipo}")
            print(f"  🎚️  Canales: {d['max_input_channels']} entrada(s)")
            print(f"  📊 Sample Rate: {d['default_samplerate']:.0f} Hz{quality_marker}")
            print(f"  🖥️  Host API: {d['hostapi']}")
            print()
    
    # Mostrar micrófonos (NO capturan la música que escuchas)
    if mic_devs:
        print("\n🎤 === MICRÓFONOS / ENTRADA DE AURICULARES ===")
        print("    (⚠️  ESTOS CAPTURAN EL MICRÓFONO, NO LA MÚSICA QUE OYES)")
        print()
        for d in mic_devs:
            tipo = clasificar_dispositivo(d['name'])
            default_marker = " ⭐ [PREDETERMINADO]" if d['id'] == default_input else ""
            
            print(f"  ID: {d['id']}{default_marker}")
            print(f"  📛 Nombre: {d['name']}")
            print(f"      {tipo}")
            if '🎧' in tipo:
                print(f"      ⚠️  Este es el MICRÓFONO de los auriculares, no captura la música")
            print(f"  🎚️  Canales: {d['max_input_channels']} entrada(s)")
            print(f"  📊 Sample Rate: {d['default_samplerate']:.0f} Hz")
            print(f"  🖥️  Host API: {d['hostapi']}")
            print()
    
    # Otros dispositivos
    if other_input_devs:
        print("\n📊 === OTROS DISPOSITIVOS ===")
        print()
        for d in other_input_devs:
            tipo = clasificar_dispositivo(d['name'])
            default_marker = " ⭐ [PREDETERMINADO]" if d['id'] == default_input else ""
            
            print(f"  ID: {d['id']}{default_marker}")
            print(f"  📛 Nombre: {d['name']}")
            if tipo:
                print(f"      {tipo}")
            print(f"  🎚️  Canales: {d['max_input_channels']} entrada(s)")
            print(f"  📊 Sample Rate: {d['default_samplerate']:.0f} Hz")
            print(f"  🖥️  Host API: {d['hostapi']}")
            print()
    
    if not dispositivos_entrada:
        print("\n  ⚠️  No hay dispositivos de entrada disponibles")
    
    # Mostrar dispositivos de SALIDA (para referencia)
    print(f"\n\n📤 DISPOSITIVOS DE SALIDA ({len(dispositivos_salida)} disponibles):")
    print("-"*80)
    
    if dispositivos_salida:
        for d in dispositivos_salida:
            tipo = clasificar_dispositivo(d['name'])
            default_marker = " ⭐ [PREDETERMINADO]" if d['id'] == default_output else ""
            
            print(f"\n  ID: {d['id']}{default_marker}")
            print(f"  📛 Nombre: {d['name']}")
            if tipo:
                print(f"      {tipo}")
            print(f"  🎚️  Canales: {d['max_output_channels']} salida(s)")
            print(f"  📊 Sample Rate: {d['default_samplerate']:.0f} Hz")
            print(f"  🖥️  Host API: {d['hostapi']}")
    else:
        print("\n  ⚠️  No hay dispositivos de salida disponibles")
    
    # Recomendaciones
    print("\n\n" + "="*80)
    print("💡 RECOMENDACIONES PARA EL VISUALIZADOR:")
    print("="*80)
    print("\n1. 🔊 Para capturar la MÚSICA que sale por tus auriculares/altavoces:")
    print("   ✅ USA: 'Mezcla estéreo' (Stereo Mix) o 'Wave Out Mix'")
    print("   ✅ Captura TODO el audio del sistema (Spotify, YouTube, juegos, etc.)")
    print("   ⚠️  Si no aparece, habilítalo en:")
    print("      Panel de Control → Sonido → Grabación → Mostrar dispositivos deshabilitados")
    
    print("\n2. ❌ NO uses 'Micrófono (HyperX...)' para capturar música:")
    print("   ❌ Esos dispositivos capturan tu VOZ (el micrófono)")
    print("   ❌ NO capturan la música que estás escuchando")
    print("   ❌ Solo útiles si quieres reaccionar a tu voz o música en vivo")
    
    print("\n3. 🎤 Para capturar tu VOZ o instrumentos en vivo:")
    print("   → Entonces SÍ usa el micrófono")
    print("   → Útil para cantantes, DJs, músicos en directo")
    
    print("\n4. ⚙️  Para usar un dispositivo específico en el visualizador:")
    print("   → Opción A: python main.py (selector interactivo)")
    print("   → Opción B: python main.py --device ID")
    print("   → Opción C: python main.py --auto (usa el configurado en config.py)")
    
    print("\n" + "="*80 + "\n")

if __name__ == "__main__":
    main()
