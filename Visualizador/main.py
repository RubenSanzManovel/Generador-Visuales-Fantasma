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
from midi_handler import MidiHandler
import sys
import traceback
from typing import Dict, Any
import random
import math

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

        # === MIDI ===
        'midi_gain_left': 1.0,
        'midi_gain_right': 1.0,
        'midi_filter_lpf_left': 0.0,
        'midi_filter_hpf_left': 0.0,
        'midi_filter_lpf_right': 0.0,
        'midi_filter_hpf_right': 0.0,
        'midi_low_left': 0.5,
        'midi_low_right': 0.5,
        'midi_mid_left': 0.5,
        'midi_mid_right': 0.5,
        'midi_high_left': 0.5,
        'midi_high_right': 0.5,
        'midi_eff1': False,
        'midi_eff2': False,
        'midi_eff3': False,
        'midi_fadeff_left': 0.0,
        'midi_fadeff_right': 0.0,
        'midi_auto_pattern': True,
        'midi_color_lock': False,
        'midi_locked_color': 0,
        'midi_fx_glitch_until': 0.0,
        'midi_fx_strobe_until': 0.0,
        'midi_fx_flash_until': 0.0,
        'midi_last_glitch_time': 0.0,
        'midi_pattern_override_time': 0.0,
        'midi_hotcue_fx': None,
        'midi_hotcue_fx_start': 0.0,
        'midi_hotcue_fx_until': 0.0,
        'midi_hotcue_fx_seed': 0.0,
        'pattern_history': [initial_pattern],

        # === RENDER OVERRIDES ===
        'render_bloom': config.BLOOM_INTENSITY,
        'render_vignette': config.VIGNETTE_INTENSITY,
        'render_contrast': config.CONTRAST,
        'render_saturation': config.SATURATION,
        'render_base_color': None,
        'render_zoom': 1.0,
        'color_grading_style': 0,
    }
    # Establece el primer objetivo de beats
    state['current_beat_target'] = _get_next_beat_target(state['pattern_mode'])
    return state

def _clamp(value: float, min_value: float, max_value: float) -> float:
    return max(min_value, min(max_value, value))

def apply_midi_modifiers(state: Dict[str, Any]) -> None:
    """
    Aplica la influencia MIDI al estado antes de renderizar.
    """
    gain_left = _clamp(state.get('midi_gain_left', 1.0), 0.0, 1.0)
    gain_right = _clamp(state.get('midi_gain_right', 1.0), 0.0, 1.0)

    # Escala de intensidad general
    state['current_amplitude'] *= gain_left
    state['smoothed_amplitude'] *= gain_left

    # Escala por bandas
    state['bass_energy'] *= gain_left
    state['mid_energy'] *= (gain_left * 0.7 + gain_right * 0.3)
    state['treble_energy'] *= gain_right

    left_weight = gain_left + 1e-6
    right_weight = gain_right + 1e-6
    weight_sum = left_weight + right_weight

    lpf = (
        state.get('midi_filter_lpf_left', 0.0) * left_weight +
        state.get('midi_filter_lpf_right', 0.0) * right_weight
    ) / weight_sum
    hpf = (
        state.get('midi_filter_hpf_left', 0.0) * left_weight +
        state.get('midi_filter_hpf_right', 0.0) * right_weight
    ) / weight_sum

    # Filtro fuerte: LPF = mas suave/oscuro, HPF = mas nitido/contrastado
    state['treble_energy'] *= (1.0 - 0.85 * lpf) * (1.0 + 0.6 * hpf)
    state['mid_energy'] *= (1.0 - 0.5 * lpf) * (1.0 + 0.3 * hpf)
    state['bass_energy'] *= (1.0 + 0.3 * lpf) * (1.0 - 0.2 * hpf)

    bloom = config.BLOOM_INTENSITY + gain_right * 0.4 + hpf * 0.2
    vignette = config.VIGNETTE_INTENSITY + lpf * 0.65
    contrast = config.CONTRAST + hpf * 1.1 - lpf * 0.8
    saturation = config.SATURATION + hpf * 1.0 - lpf * 0.8

    current_time = state['current_time']
    flicker_amount = max(lpf, hpf)
    state['render_base_color'] = None
    state['render_zoom'] = 1.0
    if flicker_amount > 0.01:
        # Curva suave: poco al inicio, mucho al final
        flicker_curve = flicker_amount * flicker_amount
        flicker_rate = 1.5 + flicker_curve * 20.0
        flicker = (1.0 + math.sin(current_time * flicker_rate * 6.28318)) * 0.5
        flash_strength = 0.15 + flicker_curve * 1.6
        flash_gate = 0.75 - flicker_curve * 0.45
        if flicker > flash_gate:
            # White flash overlay driven by filter position
            state['render_base_color'] = (1.0, 1.0, 1.0)
            bloom += flash_strength * 0.9
            contrast += flash_strength * 0.6
        else:
            bloom += flash_strength * 0.15

    # FX: glitch
    if current_time < state.get('midi_fx_glitch_until', 0.0):
        if current_time - state.get('midi_last_glitch_time', 0.0) > 0.08:
            state['color_index'] = random.randint(0, len(config.COLOR_PALETTE) - 1)
            state['midi_last_glitch_time'] = current_time
        contrast += 0.3
        bloom += 0.2

    # FX: strobe
    if current_time < state.get('midi_fx_strobe_until', 0.0):
        if int(current_time * 15) % 2 == 0:
            state['current_amplitude'] *= 1.8
            state['smoothed_amplitude'] *= 1.4
            state['beat_intensity'] = max(state.get('beat_intensity', 0.0), 1.5)
            bloom += 0.4
            contrast += 0.4
        else:
            state['current_amplitude'] *= 0.4
            state['smoothed_amplitude'] *= 0.6

    # FX: flash
    if current_time < state.get('midi_fx_flash_until', 0.0):
        bloom += 0.6
        contrast += 0.4
        saturation += 0.4

    # FX: hotcue random
    if current_time < state.get('midi_hotcue_fx_until', 0.0):
        fx_type = state.get('midi_hotcue_fx')
        fx_seed = state.get('midi_hotcue_fx_seed', 0.0)
        fx_start = state.get('midi_hotcue_fx_start', current_time)
        fx_until = state.get('midi_hotcue_fx_until', current_time)
        fx_duration = max(fx_until - fx_start, 0.05)
        fx_progress = _clamp((current_time - fx_start) / fx_duration, 0.0, 1.0)
        fx_intensity = 1.0 - fx_progress

        # Parpadeo frenético de color (siempre activo en hotcue)
        flicker_rate = 10.0 + fx_intensity * 22.0
        flicker = (1.0 + math.sin(current_time * flicker_rate * 6.28318 + fx_seed * 6.0)) * 0.5
        if flicker > 0.25:
            state['color_index'] = random.randint(0, len(config.COLOR_PALETTE) - 1)
        bloom += 0.4 * fx_intensity * flicker
        contrast += 0.3 * fx_intensity * flicker

        if fx_type in ('zoom_in', 'zoom_out'):
            zoom_curve = 1.0 - abs(2.0 * fx_progress - 1.0)
            zoom_peak = 1.35 if fx_type == 'zoom_in' else 0.75
            state['render_zoom'] = 1.0 + (zoom_peak - 1.0) * zoom_curve
            bloom += 0.25 * fx_intensity
            contrast += 0.2 * fx_intensity

    # Bloqueo de color
    if state.get('midi_color_lock', False):
        state['color_index'] = state.get('midi_locked_color', state['color_index'])

    # --- APLICAR CONTROLES MIDI EQ Y FADERS DE EFECTO ---
    midi_low_left = state.get('midi_low_left', 0.5)
    midi_low_right = state.get('midi_low_right', 0.5)
    midi_low = (midi_low_left + midi_low_right) * 0.5

    midi_high_left = state.get('midi_high_left', 0.5)
    midi_high_right = state.get('midi_high_right', 0.5)
    midi_high = (midi_high_left + midi_high_right) * 0.5

    midi_fadeff_left = state.get('midi_fadeff_left', 0.0)
    midi_fadeff_right = state.get('midi_fadeff_right', 0.0)
    midi_fadeff = (midi_fadeff_left + midi_fadeff_right) * 0.5
    state['midi_fadeff'] = midi_fadeff  # Guardar en estado para el renderer y audio handler

    # 1. Low controla el tamaño base/zoom (de 0.03 a 3.2 veces el original)
    state['render_zoom'] = state.get('render_zoom', 1.0) * (midi_low * 2.0)

    # 2. High controla el resplandor de Bloom (reposo en el centro 0.5, efecto espejo al girar a cualquier lado)
    high_diff = abs(midi_high - 0.5) * 2.0
    bloom_modifier = 1.0 + high_diff * 8.0 # 0.5 -> 1.0 (neutro) | 0.0 o 1.0 -> 9.0 (brillo extremo)
    bloom = bloom * bloom_modifier

    state['render_bloom'] = _clamp(bloom, 0.0, 5.5)
    state['render_vignette'] = _clamp(vignette, 0.0, 1.0)
    state['render_contrast'] = _clamp(contrast, 0.3, 2.5)
    state['render_saturation'] = _clamp(saturation, 0.0, 2.5)
    state['render_zoom'] = _clamp(state['render_zoom'], 0.03, 3.2)

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
        print("[ERROR] ERROR: No se encuentra shaders/vertex.glsl")
        return False
    if not os.path.exists('shaders/fragment.glsl'):
        print("[ERROR] ERROR: No se encuentra shaders/fragment.glsl")
        return False
    
    print("[OK] Shaders encontrados")
    
    if not config.validate_config():
        print("[ERROR] ERROR: Configuración inválida")
        return False
    
    print("[OK] Configuración válida")
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
            print("\n[ERROR] No se puede iniciar el programa debido a errores de configuración")
            input("Presiona Enter para salir...")
            return 1
            
        from gui import GUI
        
        # Bucle exterior para permitir volver al menú principal al pulsar ESC
        while True:
            # ================================================================
            # MOSTRAR GUI PARA SELECCIONAR MODO
            # ================================================================
            gui = GUI()
            user_config = gui.show_main_menu()
            gui.close()
            
            # Si el usuario sale, terminar
            if user_config['mode'] == 'exit':
                print("\n[*] Saliendo del programa...")
                break
            
            # Extraer configuración seleccionada
            current_pattern_mode = user_config['mode']
            admin_pattern_index = user_config['pattern']
            
            # Configurar beats para modo order
            if current_pattern_mode == 'order':
                config.SHAPE_CHANGE_BEATS = user_config['beats']
            
            print("\n" + "=" * 70)
            print(f"[+]  Modo seleccionado: '{current_pattern_mode.upper()}'")
            if current_pattern_mode == 'admin':
                print(f"   Patrón seleccionado: {admin_pattern_index}")
            elif current_pattern_mode == 'order':
                print(f"   Cambiando cada: {config.SHAPE_CHANGE_BEATS} beats")
            elif current_pattern_mode == 'random':
                print(f"   Cambio automático desactivado (control manual vía MIDI/Teclado)")
            print("=" * 70)
            
            # ================================================================
            # INICIALIZACIÓN DE COMPONENTES
            # ================================================================
            print("\n🚀 Iniciando componentes del visualizador...\n")
            
            renderer = Renderer()
            audio_handler = AudioHandler()
            
            if not audio_handler.start_stream():
                print("\n[ERROR] No se pudo iniciar la captura de audio")
                renderer.close()
                input("\nPresiona Enter para salir...")
                return 1
            
            # Inicializar estado (pasa el modo y el índice inicial elegido)
            state = initialize_state(current_pattern_mode, admin_pattern_index)
    
            # Inicializar MIDI (si el puerto virtual esta disponible)
            midi_handler = MidiHandler()
            
            if current_pattern_mode not in ('admin', 'random'):
                print(f"[*] Modo de cambio: '{state['pattern_mode']}'. Próximo cambio en {state['current_beat_target']} beats.")
            elif current_pattern_mode == 'random':
                print(f"[*] Modo de cambio: '{state['pattern_mode']}'. Cambio automático desactivado (control manual vía MIDI/Teclado).")
            
            clock = pygame.time.Clock()
            start_time = pygame.time.get_ticks()
            running = True
            
            print("\n[OK] Todos los componentes iniciados correctamente\n")
            
            # ================================================================
            # BUCLE PRINCIPAL DE RENDERIZADO
            # ================================================================
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
                        print("\n[*] Cerrando visualizador y saliendo...")
                        # Limpieza inmediata y salida del programa
                        audio_handler.stop_stream()
                        midi_handler.close()
                        renderer.close()
                        return 0
                    
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
                        pass
                    
                    elif event.type == pygame.KEYDOWN:
                        if event.key == pygame.K_ESCAPE:
                            running = False
                            print("\n[*] Volviendo al menu principal...")
                        
                        elif event.key == pygame.K_d:
                            config.DEBUG_MODE = not config.DEBUG_MODE
                            print(f"[*] Debug mode: {'ON' if config.DEBUG_MODE else 'OFF'}")
                        
                        # SPACE: Cambiar patrón manualmente (SOLO SI NO ES ADMIN)
                        elif event.key == pygame.K_SPACE and state['pattern_mode'] != 'admin':
                            state['beat_count'] = 0
                            state['pattern_change_time'] = state['current_time']
                            state['prev_pattern_index'] = state['pattern_index']
                            
                            if state['pattern_mode'] == "random":
                                total = config.TOTAL_PATTERNS
                                current = state['pattern_index']
                                history = state.get('pattern_history', [])
                                excluded = set(history[-20:])
                                excluded.add(current)
                                
                                candidates = [idx for idx in range(total) if idx not in excluded]
                                
                                history_limit = 20
                                while not candidates and history_limit > 0:
                                    history_limit -= 1
                                    excluded = set(history[-history_limit:])
                                    excluded.add(current)
                                    candidates = [idx for idx in range(total) if idx not in excluded]
                                    
                                if candidates:
                                    new_index = random.choice(candidates)
                                else:
                                    new_index = random.randint(0, total - 1)
                                    while new_index == current and total > 1:
                                        new_index = random.randint(0, total - 1)
                                
                                state['pattern_index'] = new_index
                                # Registrar en historial
                                history = state.setdefault('pattern_history', [])
                                history.append(new_index)
                                if len(history) > 50:
                                    state['pattern_history'] = history[-50:]
                            else:
                                state['pattern_index'] = (state['pattern_index'] + 1) % config.TOTAL_PATTERNS
                            
                            state['current_beat_target'] = _get_next_beat_target(state['pattern_mode'])
                            print(f"[*] Patrón cambiado manualmente a: {state['pattern_index']}. Próximo en {state['current_beat_target']} beats.")
                        
                        # C: Cambiar color manualmente
                        elif event.key == pygame.K_c:
                            state['color_index'] = (state['color_index'] + 1) % len(config.COLOR_PALETTE)
                            print(f"[*] Color cambiado manually a: {state['color_index']}")
                        
                        # V: Cambiar estilo de graduación de color (LUT)
                        elif event.key == pygame.K_v:
                            state['color_grading_style'] = (state.get('color_grading_style', 0) + 1) % 5
                            luts = ["Sin LUT (Normal)", "Teal & Orange", "Cyberpunk", "Vintage Warm", "Monocromatico de Alto Contraste"]
                            print(f"[*] Filtro de color (LUT) cambiado a: {luts[state['color_grading_style']]}")
                
                # 2. ACTUALIZACIÓN DEL TIEMPO
                prev_time = state.get('current_time', 0.0)
                state['current_time'] = (pygame.time.get_ticks() - start_time) / 1000.0
                dt = state['current_time'] - prev_time if prev_time > 0.0 else 0.016
    
                # 2.1 PROCESAMIENTO MIDI
                midi_handler.poll(state, state['current_time'])
                
                # 3. PROCESAMIENTO DE AUDIO
                audio_handler.process_audio(state)
                
                # 3.0 ACUMULAR TIEMPO REACTIVO PARA SHADERS
                # El tiempo avanza lento (0.45x) en calma y acelera drásticamente (hasta 5x) con los bombos (bass_energy)
                bass_energy = state.get('bass_energy', 0.0)
                speed_factor = 0.45 + bass_energy * 4.5
                state['reactive_time'] = state.get('reactive_time', 0.0) + dt * speed_factor
    
                # 3.1 APLICAR MODIFICADORES MIDI
                apply_midi_modifiers(state)
                
                # Si la ventana está minimizada, no renderizar (ahorra recursos)
                if minimized:
                    clock.tick(10)  # Reducir FPS cuando está minimizado
                    continue
                
                # --- LÓGICA DE CAMBIO DE PATRÓN AUTOMÁTICO ---
                # (Se salta si estamos en modo admin)
                if state['pattern_mode'] not in ('admin', 'random'):
                    override_age = state['current_time'] - state.get('midi_pattern_override_time', 0.0)
                    if (state.get('midi_auto_pattern', True) and
                        override_age > 0.1 and
                        state['beat_count'] >= state['current_beat_target']):
                        state['beat_count'] = 0
                        state['pattern_change_time'] = state['current_time']
                        state['prev_pattern_index'] = state['pattern_index']
                        
                        if state['pattern_mode'] == "random":
                            total = config.TOTAL_PATTERNS
                            current = state['pattern_index']
                            history = state.get('pattern_history', [])
                            excluded = set(history[-20:])
                            excluded.add(current)
                            
                            candidates = [idx for idx in range(total) if idx not in excluded]
                            
                            history_limit = 20
                            while not candidates and history_limit > 0:
                                history_limit -= 1
                                excluded = set(history[-history_limit:])
                                excluded.add(current)
                                candidates = [idx for idx in range(total) if idx not in excluded]
                                
                            if candidates:
                                new_index = random.choice(candidates)
                            else:
                                new_index = random.randint(0, total - 1)
                                while new_index == current and total > 1:
                                    new_index = random.randint(0, total - 1)
                            
                            state['pattern_index'] = new_index
                            # Registrar en historial
                            history = state.setdefault('pattern_history', [])
                            history.append(new_index)
                            if len(history) > 50:
                                state['pattern_history'] = history[-50:]
                        else:
                            state['pattern_index'] = (state['pattern_index'] + 1) % config.TOTAL_PATTERNS
                        
                        state['current_beat_target'] = _get_next_beat_target(state['pattern_mode'])
                        
                        if config.DEBUG_MODE:
                            print(f"[*] CAMBIO DE PATRÓN a: {state['pattern_index']}. Próximo cambio en {state['current_beat_target']} beats.")
                
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
            # LIMPIEZA DE ESTE CICLO
            # ================================================================
            print("\n[*] Limpiando recursos del ciclo actual...")
            audio_handler.stop_stream()
            midi_handler.close()
            renderer.close()
            
            print(f"\n📊 ESTADÍSTICAS DEL CICLO:")
            print(f"   Frames renderizados: {state['frames_rendered']}")
            print(f"   Tiempo transcurrido: {state['current_time']:.2f} segundos")
            if state['current_time'] > 0:
                avg_fps = state['frames_rendered'] / state['current_time']
                print(f"   FPS promedio: {avg_fps:.2f}")
            print("\n" + "=" * 70 + "\n")
            
        return 0
        
    except KeyboardInterrupt:
        print("\n\n[!]  Interrupción del usuario (Ctrl+C)")
        return 130
        
    except Exception as e:
        print("\n" + "!" * 70)
        print("   [ERROR] ERROR CRÍTICO EN EL PROGRAMA")
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
        print(f"\n[ERROR] Error fatal: {e}")
        traceback.print_exc()
        input("\nPresiona Enter para salir...")
        sys.exit(1)