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
import sys
import traceback
from typing import Dict, Any

# ============================================================================
# FUNCIONES DE INICIALIZACIÓN
# ============================================================================

def initialize_state() -> Dict[str, Any]:
    """
    Inicializa el diccionario de estado que contiene toda la información
    del visualizador que cambia en cada frame.
    
    El estado es el núcleo del programa: contiene todas las variables que
    controlan los efectos visuales y se actualizan con el audio.
    
    Returns:
        Diccionario con el estado inicial del visualizador
    """
    return {
        # === TIEMPO ===
        'current_time': 0.0,              # Tiempo transcurrido en segundos desde el inicio
        
        # === AUDIO - AMPLITUD ===
        'current_amplitude': 0.0,          # Amplitud actual (volumen instantáneo)
        'smoothed_amplitude': 0.0,         # Amplitud suavizada (promediada)
        
        # === AUDIO - BANDAS DE FRECUENCIA ===
        'bass_energy': 0.0,                # Energía en frecuencias graves (20-250 Hz)
        'mid_energy': 0.0,                 # Energía en frecuencias medias (250-2000 Hz)
        'treble_energy': 0.0,              # Energía en frecuencias agudas (2000-8000 Hz)
        
        # === DETECCIÓN DE BEATS ===
        'beat_last_time': 0.0,             # Timestamp del último beat detectado
        'beat_count': 0,                   # Contador de beats desde el último cambio de patrón
        'beat_intensity': 0.0,             # Intensidad del último beat (relativa al umbral)
        
        # === COLORES ===
        'color_index': 0,                  # Índice del color actual en la paleta
        
        # === PATRONES VISUALES ===
        'pattern_index': 0,                # Índice del patrón visual actual
        'prev_pattern_index': 0,           # Índice del patrón anterior (para transiciones)
        'pattern_change_time': 0.0,        # Timestamp del último cambio de patrón
        
        # === PARTÍCULAS/GOTAS (efectos generados por beats) ===
        # Posiciones aleatorias de las partículas (coordenadas UV 0-1)
        'drop_positions': np.random.rand(config.MAX_PARTICLES, 2).astype(np.float32),
        
        # Timestamps de creación de cada partícula
        'drop_times': np.zeros(config.MAX_PARTICLES, dtype=np.float32),
        
        # Índice circular para colocar nuevas partículas
        'drop_index': 0,
        
        # === ESTADÍSTICAS ===
        'frames_rendered': 0,              # Contador de frames renderizados
    }

def print_welcome_message():
    """Imprime mensaje de bienvenida con información del programa."""
    print("\n" + "=" * 70)
    print("   🎵 VISUALIZADOR GENERATIVO DE MÚSICA - PREMIUM EDITION 🎵")
    print("=" * 70)
    print("\n📌 CONTROLES:")
    print("   • ESC o cerrar ventana: Salir del programa")
    print("   • Reproduce música para ver los efectos visuales")
    print("\n💡 CARACTERÍSTICAS:")
    print("   • Análisis de audio en tiempo real (bass, mid, treble)")
    print("   • Detección inteligente de beats con umbral adaptativo")
    print("   • 16 patrones visuales únicos generados por shaders")
    print("   • Transiciones suaves entre efectos")
    print("   • Post-processing (bloom, viñeta, contraste)")
    print("\n🎧 SELECCIÓN DE DISPOSITIVO DE AUDIO:")
    print("   • Sin argumentos: Menú interactivo de selección")
    print("   • --auto: Selección automática del dispositivo configurado")
    print("   • --device ID: Usar dispositivo específico por ID")
    print("\n" + "=" * 70)
    
    # Mostrar configuración actual
    if config.DEBUG_MODE:
        config.print_config_info()

def validate_environment() -> bool:
    """
    Valida que el entorno esté correctamente configurado.
    
    Returns:
        True si todo está OK, False si hay problemas
    """
    print("\n🔍 Validando entorno...")
    
    # Verificar que existen los archivos de shaders
    import os
    if not os.path.exists('shaders/vertex.glsl'):
        print("❌ ERROR: No se encuentra shaders/vertex.glsl")
        return False
    if not os.path.exists('shaders/fragment.glsl'):
        print("❌ ERROR: No se encuentra shaders/fragment.glsl")
        return False
    
    print("✅ Shaders encontrados")
    
    # Validar configuración
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
        # INICIALIZACIÓN DE COMPONENTES
        # ================================================================
        print("\n🚀 Iniciando componentes del visualizador...\n")
        
        # Inicializar renderer (OpenGL + Pygame)
        renderer = Renderer()
        
        # Inicializar manejador de audio con detección automática de loopback
        audio_handler = AudioHandler()
        
        # Iniciar captura de audio
        if not audio_handler.start_stream():
            print("\n❌ No se pudo iniciar la captura de audio")
            print("   Verifica:")
            print("   1. Que el dispositivo de audio esté configurado correctamente")
            print("   2. Que el dispositivo no esté siendo usado por otra aplicación")
            print("   3. Que tengas permisos para acceder al audio del sistema")
            renderer.close()
            input("\nPresiona Enter para salir...")
            return 1
        
        # Inicializar estado del visualizador
        state = initialize_state()
        
        # Reloj para controlar FPS
        clock = pygame.time.Clock()
        
        # Timestamp de inicio (para calcular tiempo transcurrido)
        start_time = pygame.time.get_ticks()
        
        # Variable de control del bucle principal
        running = True
        
        print("\n✅ Todos los componentes iniciados correctamente\n")
        
        # ================================================================
        # BUCLE PRINCIPAL
        # ================================================================
        # Este bucle se ejecuta aproximadamente TARGET_FPS veces por segundo
        # En cada iteración:
        # 1. Procesa eventos (teclado, mouse, cierre de ventana)
        # 2. Actualiza el tiempo
        # 3. Procesa datos de audio y actualiza el estado
        # 4. Renderiza el frame actual
        # 5. Controla el framerate
        
        while running:
            # ============================================================
            # 1. PROCESAMIENTO DE EVENTOS
            # ============================================================
            for event in pygame.event.get():
                # Evento de cierre de ventana
                if event.type == pygame.QUIT:
                    running = False
                    print("\n👋 Cerrando visualizador...")
                
                # Eventos de teclado
                elif event.type == pygame.KEYDOWN:
                    # ESC: Salir
                    if event.key == pygame.K_ESCAPE:
                        running = False
                        print("\n👋 Cerrando visualizador...")
                    
                    # F: Toggle fullscreen (funcionalidad futura)
                    elif event.key == pygame.K_f:
                        if config.DEBUG_MODE:
                            print("🖥️  Toggle fullscreen (funcionalidad futura)")
                    
                    # D: Toggle debug mode
                    elif event.key == pygame.K_d:
                        config.DEBUG_MODE = not config.DEBUG_MODE
                        print(f"🐛 Debug mode: {'ON' if config.DEBUG_MODE else 'OFF'}")
                    
                    # SPACE: Cambiar patrón manualmente
                    elif event.key == pygame.K_SPACE:
                        state['pattern_change_time'] = state['current_time']
                        state['prev_pattern_index'] = state['pattern_index']
                        state['pattern_index'] = (state['pattern_index'] + 1) % config.TOTAL_PATTERNS
                        print(f"🎨 Patrón cambiado manualmente a: {state['pattern_index']}")
                    
                    # C: Cambiar color manualmente
                    elif event.key == pygame.K_c:
                        state['color_index'] = (state['color_index'] + 1) % len(config.COLOR_PALETTE)
                        print(f"🎨 Color cambiado manualmente a: {state['color_index']}")
            
            # ============================================================
            # 2. ACTUALIZACIÓN DEL TIEMPO
            # ============================================================
            # Calcular tiempo transcurrido en segundos desde el inicio
            state['current_time'] = (pygame.time.get_ticks() - start_time) / 1000.0
            
            # ============================================================
            # 3. PROCESAMIENTO DE AUDIO
            # ============================================================
            # El audio_handler extrae datos de audio, los analiza (FFT),
            # detecta beats, y actualiza el estado con toda la información
            audio_handler.process_audio(state)
            
            # ============================================================
            # 4. RENDERIZADO
            # ============================================================
            # El renderer toma el estado y dibuja el frame correspondiente
            # usando los shaders GLSL con todos los efectos visuales
            renderer.render(state)
            
            # ============================================================
            # 5. CONTROL DE FRAMERATE
            # ============================================================
            # Limitar a TARGET_FPS frames por segundo
            # clock.tick() espera el tiempo necesario para mantener el framerate
            clock.tick(config.TARGET_FPS)
            
            # Incrementar contador de frames
            state['frames_rendered'] += 1
            
            # Mostrar información de debug periódicamente
            if config.DEBUG_MODE and state['frames_rendered'] % 300 == 0:
                print(f"\n📊 STATS - Frame {state['frames_rendered']}:")
                print(f"   Tiempo: {state['current_time']:.2f}s")
                print(f"   Patrón: {state['pattern_index']}")
                print(f"   Amplitud: {state['current_amplitude']:.3f}")
                print(f"   Bass: {state['bass_energy']:.3f}, "
                      f"Mid: {state['mid_energy']:.3f}, "
                      f"Treble: {state['treble_energy']:.3f}")
        
        # ================================================================
        # LIMPIEZA Y CIERRE
        # ================================================================
        print("\n🧹 Limpiando recursos...")
        
        # Detener captura de audio
        audio_handler.stop_stream()
        
        # Cerrar renderer y OpenGL
        renderer.close()
        
        # Estadísticas finales
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
        # El usuario presionó Ctrl+C
        print("\n\n⚠️  Interrupción del usuario (Ctrl+C)")
        print("🧹 Limpiando recursos...")
        
        try:
            # Limpieza segura de recursos
            pass
        except:
            pass
        
        print("👋 Visualizador cerrado")
        return 130  # Exit code para Ctrl+C
    
    except Exception as e:
        # Error inesperado
        print("\n" + "!" * 70)
        print("   ❌ ERROR CRÍTICO EN EL PROGRAMA")
        print("!" * 70)
        print(f"\nTipo de error: {type(e).__name__}")
        print(f"Mensaje: {str(e)}")
        print("\nTraceback completo:")
        traceback.print_exc()
        print("\n" + "!" * 70)
        
        # Intentar limpiar recursos
        try:
            # Limpieza segura de recursos
            pass
        except:
            pass
        
        input("\nPresiona Enter para salir...")
        return 1

# ============================================================================
# PUNTO DE ENTRADA
# ============================================================================

if __name__ == '__main__':
    """
    Punto de entrada del programa.
    Ejecuta main() y retorna el código de salida al sistema operativo.
    """
    try:
        exit_code = main()
        sys.exit(exit_code)
    except Exception as e:
        print(f"\n❌ Error fatal: {e}")
        traceback.print_exc()
        input("\nPresiona Enter para salir...")
        sys.exit(1)