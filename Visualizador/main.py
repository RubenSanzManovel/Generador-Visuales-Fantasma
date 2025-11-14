# ============================================================================
# MAIN.PY - VISUALIZADOR DE MÚSICA GENERATIVO EN TIEMPO REAL
# ============================================================================
# Programa principal que orquesta el visualizador de música.
# Integra análisis de audio en tiempo real con renderizado GPU mediante shaders.
# 
# Arquitectura:
# - AudioHandler: Captura y analiza audio del sistema
# - Renderer: Renderiza efectos visuales usando OpenGL/GLSL
# - Main Loop: Coordina todo y mantiene el estado sincronizado
# ============================================================================

import pygame
import numpy as np
import config
from renderer import Renderer
from audio_handler import AudioHandler
from gui import GUI
import sys
import traceback
from typing import Dict, Any
import random

# ============================================================================
# FUNCIONES DE INICIALIZACIÓN Y LÓGICA
# ============================================================================

def _get_next_beat_target(current_mode: str) -> int:
    """
    Obtiene el número de beats para el próximo cambio de patrón,
    según el modo seleccionado.
    """
    if current_mode == "random":
        # Devuelve un número aleatorio dentro del rango especificado en config.py
        return random.randint(config.RANDOM_BEAT_RANGE[0], config.RANDOM_BEAT_RANGE[1])
    else:
        # Devuelve el número fijo del modo "order"
        return config.SHAPE_CHANGE_BEATS

def initialize_state(pattern_mode: str, initial_pattern: int = 0) -> Dict[str, Any]:
    """
    Inicializa el diccionario de estado que contiene toda la información
    del visualizador que cambia en cada frame.
    
    Returns:
        Diccionario con el estado inicial del visualizador
    """
    state = {
        # === TIEMPO ===
        'current_time': 0.0,
        
        # === AUDIO - AMPLITUD ===
        'current_amplitude': 0.0,
        'smoothed_amplitude': 0.0,
        
        # === AUDIO - BANDAS DE FRECUENCIA ===
        'bass_energy': 0.0,
        'mid_energy': 0.0,
        'treble_energy': 0.0,
        
        # === DETECCIÓN DE BEATS ===
        'beat_last_time': 0.0,
        'beat_count': 0,
        'beat_intensity': 0.0,
        'current_beat_target': 0, # Se establecerá después de inicializar
        
        # === COLORES ===
        'color_index': 0,
        
        # === PATRONES VISUALES ===
        'pattern_mode': pattern_mode, # Almacena el modo elegido ('admin', 'random', 'order')
        'pattern_index': initial_pattern, # Usa el índice inicial (0 o el elegido por admin)
        'prev_pattern_index': initial_pattern,
        'pattern_change_time': 0.0,
        
        # === PARTÍCULAS/GOTAS (efectos generados por beats) ===
        'drop_positions': np.random.rand(config.MAX_PARTICLES, 2).astype(np.float32),
        'drop_times': np.zeros(config.MAX_PARTICLES, dtype=np.float32),
        'drop_index': 0,
        
        # === ESTADÍSTICAS ===
        'frames_rendered': 0,
    }
    # Establece el primer objetivo de beats
    state['current_beat_target'] = _get_next_beat_target(state['pattern_mode'])
    return state

def print_welcome_message():
    """Imprime mensaje de bienvenida con información del programa."""
    print("\n" + "=" * 70)
    print("   🎵 VISUALIZADOR GENERATIVO DE MÚSICA - PREMIUM EDITION 🎵")
    print("=" * 70)
    print("\n📌 CONTROLES:")
    print("   • ESC: Salir del programa")
    print("   • Reproduce música para ver los efectos visuales")
    print("\n💡 CARACTERÍSTICAS:")
    print("   • Análisis de audio en tiempo real (bass, mid, treble)")
    print("   • Detección inteligente de beats con umbral adaptativo")
    print(f"   • {config.TOTAL_PATTERNS} patrones visuales únicos generados por shaders")
    print("   • Transiciones suaves entre efectos")
    print("   • Post-processing (bloom, viñeta, contraste)")
    print("   • Pantalla completa automática")
    print("\n" + "=" * 70)

def validate_environment() -> bool:
    """
    Valida que el entorno esté correctamente configurado.
    """
    print("\n🔍 Validando entorno...")
    
    import os
    if not os.path.exists('shaders/vertex.glsl'):
        print("❌ ERROR: No se encuentra shaders/vertex.glsl")
        return False
    if not os.path.exists('shaders/fragment.glsl'):
        print("❌ ERROR: No se encuentra shaders/fragment.glsl")
        return False
    
    print("✅ Shaders encontrados")
    
    if not config.validate_config():
        print("❌ ERROR: Configuración inválida")
        return False
    
    print("✅ Configuración válida")
    return True

# ============================================================================
# BUCLE PRINCIPAL
# ============================================================================

def main():
    """
    Función principal del programa.
    Inicializa todos los componentes y ejecuta el bucle principal.
    """
    try:
        # Mostrar mensaje de bienvenida
        print_welcome_message()
        
        # Validar entorno
        if not validate_environment():
            print("\n❌ No se puede iniciar el programa debido a errores de configuración")
            input("Presiona Enter para salir...")
            return 1
        
        # ================================================================
        # MOSTRAR GUI PARA SELECCIONAR MODO
        # ================================================================
        gui = GUI()
        user_config = gui.show_main_menu()
        gui.close()
        
        # Si el usuario sale, terminar
        if user_config['mode'] == 'exit':
            print("\n👋 Saliendo del programa...")
            return 0
        
        # Extraer configuración seleccionada
        current_pattern_mode = user_config['mode']
        admin_pattern_index = user_config['pattern']
        
        # Configurar beats para modo order
        if current_pattern_mode == 'order':
            config.SHAPE_CHANGE_BEATS = user_config['beats']
        
        print("\n" + "=" * 70)
        print(f"⚙️  Modo seleccionado: '{current_pattern_mode.upper()}'")
        if current_pattern_mode == 'admin':
            print(f"   Patrón seleccionado: {admin_pattern_index}")
        elif current_pattern_mode == 'order':
            print(f"   Cambiando cada: {config.SHAPE_CHANGE_BEATS} beats")
        elif current_pattern_mode == 'random':
            print(f"   Cambiando cada: {config.RANDOM_BEAT_RANGE[0]} a {config.RANDOM_BEAT_RANGE[1]} beats")
        print("=" * 70)
        
        # ================================================================
        # INICIALIZACIÓN DE COMPONENTES
        # ================================================================
        print("\n🚀 Iniciando componentes del visualizador...\n")
        
        renderer = Renderer()
        audio_handler = AudioHandler()
        
        if not audio_handler.start_stream():
            print("\n❌ No se pudo iniciar la captura de audio")
            renderer.close()
            input("\nPresiona Enter para salir...")
            return 1
        
        # Inicializar estado (pasa el modo y el índice inicial elegido)
        state = initialize_state(current_pattern_mode, admin_pattern_index)
        
        if current_pattern_mode != 'admin':
            print(f"🔥 Modo de cambio: '{state['pattern_mode']}'. Próximo cambio en {state['current_beat_target']} beats.")
        
        clock = pygame.time.Clock()
        start_time = pygame.time.get_ticks()
        running = True
        
        print("\n✅ Todos los componentes iniciados correctamente\n")
        
        # ================================================================
        # BUCLE PRINCIPAL
        # ================================================================
        
        # Variable para controlar si la ventana tiene foco
        has_focus = True
        minimized = False
        
        while running:
            # Pump de eventos para asegurar respuesta del sistema operativo
            pygame.event.pump()
            
            # 1. PROCESAMIENTO DE EVENTOS
            events = pygame.event.get()
            for event in events:
                if event.type == pygame.QUIT:
                    running = False
                    print("\n👋 Cerrando visualizador...")
                
                # Manejar eventos de ventana para evitar bloqueos
                elif event.type == pygame.WINDOWFOCUSGAINED:
                    has_focus = True
                    minimized = False
                    if config.DEBUG_MODE:
                        print("🔍 Ventana recuperó el foco")
                elif event.type == pygame.WINDOWFOCUSLOST:
                    has_focus = False
                    if config.DEBUG_MODE:
                        print("🔍 Ventana perdió el foco")
                elif event.type == pygame.WINDOWMINIMIZED:
                    minimized = True
                    if config.DEBUG_MODE:
                        print("🔍 Ventana minimizada")
                elif event.type == pygame.WINDOWRESTORED:
                    minimized = False
                    if config.DEBUG_MODE:
                        print("🔍 Ventana restaurada")
                elif event.type in (pygame.WINDOWEXPOSED, pygame.WINDOWSHOWN):
                    # Ventana se volvió visible
                    pass
                
                elif event.type == pygame.KEYDOWN:
                    if event.key == pygame.K_ESCAPE:
                        running = False
                        print("\n👋 Cerrando visualizador...")
                    
                    elif event.key == pygame.K_d:
                        config.DEBUG_MODE = not config.DEBUG_MODE
                        print(f"🐛 Debug mode: {'ON' if config.DEBUG_MODE else 'OFF'}")
                    
                    # SPACE: Cambiar patrón manualmente (SOLO SI NO ES ADMIN)
                    elif event.key == pygame.K_SPACE and state['pattern_mode'] != 'admin':
                        state['beat_count'] = 0
                        state['pattern_change_time'] = state['current_time']
                        state['prev_pattern_index'] = state['pattern_index']
                        
                        if state['pattern_mode'] == "random":
                            new_index = np.random.randint(0, config.TOTAL_PATTERNS)
                            while new_index == state['pattern_index']:
                                new_index = np.random.randint(0, config.TOTAL_PATTERNS)
                            state['pattern_index'] = new_index
                        else:
                            state['pattern_index'] = (state['pattern_index'] + 1) % config.TOTAL_PATTERNS
                        
                        state['current_beat_target'] = _get_next_beat_target(state['pattern_mode'])
                        print(f"🎨 Patrón cambiado manualmente a: {state['pattern_index']}. Próximo en {state['current_beat_target']} beats.")
                    
                    # C: Cambiar color manualmente
                    elif event.key == pygame.K_c:
                        state['color_index'] = (state['color_index'] + 1) % len(config.COLOR_PALETTE)
                        print(f"🎨 Color cambiado manually a: {state['color_index']}")
            
            # 2. ACTUALIZACIÓN DEL TIEMPO
            state['current_time'] = (pygame.time.get_ticks() - start_time) / 1000.0
            
            # 3. PROCESAMIENTO DE AUDIO
            audio_handler.process_audio(state)
            
            # Si la ventana está minimizada, no renderizar (ahorra recursos)
            if minimized:
                clock.tick(10)  # Reducir FPS cuando está minimizado
                continue
            
            # --- LÓGICA DE CAMBIO DE PATRÓN AUTOMÁTICO ---
            # (Se salta si estamos en modo admin)
            if state['pattern_mode'] != 'admin':
                if state['beat_count'] >= state['current_beat_target']:
                    state['beat_count'] = 0
                    state['pattern_change_time'] = state['current_time']
                    state['prev_pattern_index'] = state['pattern_index']
                    
                    if state['pattern_mode'] == "random":
                        new_index = random.randint(0, config.TOTAL_PATTERNS - 1)
                        while new_index == state['pattern_index']:
                            new_index = random.randint(0, config.TOTAL_PATTERNS - 1)
                        state['pattern_index'] = new_index
                    else:
                        state['pattern_index'] = (state['pattern_index'] + 1) % config.TOTAL_PATTERNS
                    
                    state['current_beat_target'] = _get_next_beat_target(state['pattern_mode'])
                    
                    if config.DEBUG_MODE:
                        print(f"🎨 CAMBIO DE PATRÓN a: {state['pattern_index']}. Próximo cambio en {state['current_beat_target']} beats.")
            
            # 4. RENDERIZADO
            renderer.render(state)
            
            # 5. CONTROL DE FRAMERATE
            clock.tick(config.TARGET_FPS)
            state['frames_rendered'] += 1
            
            if config.DEBUG_MODE and state['frames_rendered'] % 300 == 0:
                debug_beat_info = f"Beats: {state['beat_count']} / {state['current_beat_target']}"
                if state['pattern_mode'] == 'admin':
                    debug_beat_info = "(Modo Admin: cambios bloqueados)"
                
                print(f"\n📊 STATS - Frame {state['frames_rendered']}:")
                print(f"   Patrón: {state['pattern_index']} {debug_beat_info}")
                print(f"   Amplitud: {state['current_amplitude']:.3f}")
                
        # ================================================================
        # LIMPIEZA Y CIERRE
        # ================================================================
        print("\n🧹 Limpiando recursos...")
        audio_handler.stop_stream()
        renderer.close()
        
        print(f"\n📊 ESTADÍSTICAS FINALES:")
        print(f"   Frames renderizados: {state['frames_rendered']}")
        print(f"   Tiempo total: {state['current_time']:.2f} segundos")
        if state['current_time'] > 0:
            avg_fps = state['frames_rendered'] / state['current_time']
            print(f"   FPS promedio: {avg_fps:.2f}")
        
        print("\n" + "=" * 70)
        print("   ✅ Visualizador cerrado correctamente")
        print("=" * 70 + "\n")
        
        return 0
    
    except KeyboardInterrupt:
        print("\n\n⚠️  Interrupción del usuario (Ctrl+C)")
        print("🧹 Limpiando recursos...")
        return 130
    
    except Exception as e:
        print("\n" + "!" * 70)
        print("   ❌ ERROR CRÍTICO EN EL PROGRAMA")
        print("!" * 70)
        print(f"\nTipo de error: {type(e).__name__}")
        print(f"Mensaje: {str(e)}")
        print("\nTraceback completo:")
        traceback.print_exc()
        print("\n" + "!" * 70)
        input("\nPresiona Enter para salir...")
        return 1

# ============================================================================
# PUNTO DE ENTRADA
# ============================================================================

if __name__ == '__main__':
    try:
        exit_code = main()
        sys.exit(exit_code)
    except Exception as e:
        print(f"\n❌ Error fatal: {e}")
        traceback.print_exc()
        input("\nPresiona Enter para salir...")
        sys.exit(1)