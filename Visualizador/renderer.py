# ============================================================================
# RENDERER.PY - MOTOR DE RENDERIZADO OPENGL CON SHADERS
# ============================================================================
# Este módulo maneja toda la parte gráfica del visualizador usando OpenGL.
# Compila shaders, gestiona buffers de geometría, envía uniforms al GPU,
# y renderiza cada frame con los efectos visuales definidos en GLSL.
# ============================================================================

import pygame
from pygame.locals import *
from OpenGL.GL import *
from OpenGL.GL import shaders
import numpy as np
import config
import sys
import time
from typing import Optional, Dict, Any

class Renderer:
    """
    Motor de renderizado OpenGL que gestiona shaders, geometría y dibujado.
    
    Características:
    - Compilación y validación de shaders GLSL
    - Renderizado en pantalla completa con quad (cuadrilátero)
    - Envío eficiente de uniforms al GPU
    - Contador de FPS en tiempo real
    - Manejo robusto de errores OpenGL
    - Soporte para transiciones suaves entre efectos
    """
    
    def __init__(self):
        """Inicializa Pygame, OpenGL, compila shaders y configura la geometría."""
        try:
            print("🎨 Inicializando motor de renderizado...")
            
            # Inicializar Pygame
            pygame.init()
            
            # Configurar flags de la ventana
            display_flags = DOUBLEBUF | OPENGL
            if config.FULLSCREEN:
                display_flags |= FULLSCREEN
            
            # Crear ventana con configuración especificada
            self.screen = pygame.display.set_mode(
                (config.SCREEN_WIDTH, config.SCREEN_HEIGHT), 
                display_flags
            )
            pygame.display.set_caption("Visualizador Generativo de Música - Premium Edition")
            
            # Configurar VSync si está habilitado
            if config.VSYNC:
                pygame.display.gl_set_attribute(pygame.GL_SWAP_CONTROL, 1)
            
            # Información sobre el contexto OpenGL
            print(f"   OpenGL Version: {glGetString(GL_VERSION).decode()}")
            print(f"   GLSL Version: {glGetString(GL_SHADING_LANGUAGE_VERSION).decode()}")
            print(f"   Renderer: {glGetString(GL_RENDERER).decode()}")
            
            # Compilar y linkear shaders
            self.shader_program: int = self._compile_shaders()
            
            # Configurar geometría (quad de pantalla completa)
            self._setup_quad()
            
            # Variables para cálculo de FPS
            self.frame_count: int = 0
            self.fps_timer: float = time.time()
            self.current_fps: float = 0.0
            self.frame_times: list = []  # Para calcular FPS promedio
            
            # Variables para transiciones suaves entre patrones
            self.pattern_transition_progress: float = 1.0  # 0.0 = transición activa, 1.0 = sin transición
            
            # Fuente para texto (FPS counter)
            if config.SHOW_FPS:
                try:
                    pygame.font.init()
                    self.font = pygame.font.SysFont('Arial', 24)
                except Exception as e:
                    print(f"⚠️  No se pudo cargar la fuente para FPS: {e}")
                    self.font = None
            else:
                self.font = None
            
            print("✅ Renderer inicializado correctamente")
            
        except Exception as e:
            print(f"❌ Error crítico al inicializar el renderer: {e}")
            self._emergency_shutdown()
            raise

    def _load_shader_source(self, filepath: str) -> str:
        """
        Carga el código fuente de un shader desde un archivo.
        
        Args:
            filepath: Ruta al archivo del shader (.glsl)
            
        Returns:
            String con el código fuente del shader
            
        Raises:
            FileNotFoundError: Si el archivo no existe
            UnicodeDecodeError: Si hay problemas de encoding
        """
        try:
            with open(filepath, 'r', encoding='utf-8') as f:
                source = f.read()
            print(f"   📄 Shader cargado: {filepath} ({len(source)} caracteres)")
            return source
        except FileNotFoundError:
            print(f"❌ ERROR: No se encontró el archivo de shader: {filepath}")
            print(f"   Verifica que el archivo existe en la ruta correcta")
            raise
        except UnicodeDecodeError as e:
            print(f"❌ ERROR: Problema de encoding en {filepath}")
            print(f"   Asegúrate de que el archivo esté guardado en UTF-8")
            raise

    def _compile_shaders(self) -> int:
        """
        Compila y linkea los shaders vertex y fragment.
        
        Returns:
            ID del programa de shader compilado y linkeado
            
        Raises:
            RuntimeError: Si hay errores de compilación o linkeo
        """
        try:
            print("   🔨 Compilando shaders...")
            
            # Cargar código fuente
            vertex_source = self._load_shader_source('shaders/vertex.glsl')
            fragment_source = self._load_shader_source('shaders/fragment.glsl')
            
            # Compilar shaders individuales
            vertex_shader = shaders.compileShader(vertex_source, GL_VERTEX_SHADER)
            fragment_shader = shaders.compileShader(fragment_source, GL_FRAGMENT_SHADER)
            
            # Crear programa y linkear shaders
            program = shaders.compileProgram(vertex_shader, fragment_shader)
            
            # Validar el programa
            glValidateProgram(program)
            if glGetProgramiv(program, GL_VALIDATE_STATUS) != GL_TRUE:
                print("⚠️  Advertencia: El programa de shaders no pasó la validación")
                info_log = glGetProgramInfoLog(program)
                if info_log:
                    print(f"   Info Log: {info_log.decode()}")
            
            print("   ✅ Shaders compilados correctamente")
            return program
            
        except Exception as e:
            # Error crítico: mostrar información detallada y salir
            print("\n" + "!" * 70)
            print("    ❌ ERROR CRÍTICO AL COMPILAR LOS SHADERS")
            print("!" * 70)
            print("\nDetalles del error:")
            print(str(e))
            print("\n" + "=" * 70)
            
            # Si hay información del log de OpenGL, mostrarla
            try:
                if 'vertex_shader' in locals():
                    log = glGetShaderInfoLog(vertex_shader)
                    if log:
                        print("Vertex Shader Log:")
                        print(log.decode())
                        
                if 'fragment_shader' in locals():
                    log = glGetShaderInfoLog(fragment_shader)
                    if log:
                        print("Fragment Shader Log:")
                        print(log.decode())
            except:
                pass
            
            print("=" * 70)
            input("\n--- Presiona Enter para cerrar el programa ---")
            self._emergency_shutdown()
            raise RuntimeError("Fallo al compilar shaders") from e

    def _setup_quad(self) -> None:
        """
        Configura un cuadrilátero (quad) de pantalla completa para renderizar.
        El quad cubre toda la pantalla y en él se dibujan los efectos del shader.
        """
        # Vértices del quad en coordenadas normalizadas (-1 a 1)
        # Forma un rectángulo que cubre toda la pantalla
        quad_vertices = np.array([
            -1.0, -1.0,  # Inferior izquierda
             1.0, -1.0,  # Inferior derecha
             1.0,  1.0,  # Superior derecha
            -1.0,  1.0   # Superior izquierda
        ], dtype=np.float32)
        
        # Crear VBO (Vertex Buffer Object) y cargar datos
        self.vbo = glGenBuffers(1)
        glBindBuffer(GL_ARRAY_BUFFER, self.vbo)
        glBufferData(GL_ARRAY_BUFFER, quad_vertices.nbytes, quad_vertices, GL_STATIC_DRAW)
        
        # Obtener ubicación del atributo de posición en el shader
        position_loc = glGetAttribLocation(self.shader_program, "position")
        
        # Configurar el atributo de vértices
        glVertexAttribPointer(
            position_loc,  # Índice del atributo
            2,             # Número de componentes (x, y)
            GL_FLOAT,      # Tipo de datos
            GL_FALSE,      # No normalizar
            0,             # Stride (0 = datos contiguos)
            None           # Offset
        )
        glEnableVertexAttribArray(position_loc)
        
        print("   📐 Geometría configurada (fullscreen quad)")

    def _calculate_fps(self) -> None:
        """
        Calcula los FPS (frames por segundo) actuales.
        Actualiza self.current_fps cada segundo aproximadamente.
        """
        self.frame_count += 1
        current_time = time.time()
        elapsed = current_time - self.fps_timer
        
        # Actualizar FPS cada segundo
        if elapsed >= 1.0:
            self.current_fps = self.frame_count / elapsed
            self.frame_count = 0
            self.fps_timer = current_time
            
            # Mantener historial para calcular FPS promedio
            self.frame_times.append(self.current_fps)
            if len(self.frame_times) > 10:
                self.frame_times.pop(0)

    def _draw_fps_counter(self) -> None:
        """
        Dibuja el contador de FPS en la esquina superior izquierda.
        Usa Pygame para renderizar texto sobre el contexto OpenGL.
        """
        if not self.font or not config.SHOW_FPS:
            return
        
        try:
            # Determinar color según FPS
            if self.current_fps >= config.TARGET_FPS * 0.9:
                color = (0, 255, 0)  # Verde: excelente
            elif self.current_fps >= config.TARGET_FPS * 0.6:
                color = (255, 255, 0)  # Amarillo: aceptable
            else:
                color = (255, 0, 0)  # Rojo: bajo
            
            # Renderizar texto
            fps_text = f"FPS: {self.current_fps:.1f}"
            text_surface = self.font.render(fps_text, True, color)
            text_data = pygame.image.tostring(text_surface, "RGBA", True)
            
            # Guardar estado OpenGL
            glPushAttrib(GL_ALL_ATTRIB_BITS)
            
            # Configurar para dibujo 2D
            glMatrixMode(GL_PROJECTION)
            glPushMatrix()
            glLoadIdentity()
            glOrtho(0, config.SCREEN_WIDTH, config.SCREEN_HEIGHT, 0, -1, 1)
            glMatrixMode(GL_MODELVIEW)
            glPushMatrix()
            glLoadIdentity()
            
            # Crear textura temporal para el texto
            texture_id = glGenTextures(1)
            glBindTexture(GL_TEXTURE_2D, texture_id)
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR)
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR)
            
            glTexImage2D(
                GL_TEXTURE_2D, 0, GL_RGBA,
                text_surface.get_width(), text_surface.get_height(),
                0, GL_RGBA, GL_UNSIGNED_BYTE, text_data
            )
            
            # Dibujar quad con la textura del texto
            glEnable(GL_TEXTURE_2D)
            glEnable(GL_BLEND)
            glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
            
            x, y = 10, 10
            w, h = text_surface.get_width(), text_surface.get_height()
            
            glBegin(GL_QUADS)
            glTexCoord2f(0, 0); glVertex2f(x, y)
            glTexCoord2f(1, 0); glVertex2f(x + w, y)
            glTexCoord2f(1, 1); glVertex2f(x + w, y + h)
            glTexCoord2f(0, 1); glVertex2f(x, y + h)
            glEnd()
            
            # Limpiar
            glDeleteTextures([texture_id])
            
            # Restaurar estado OpenGL
            glPopMatrix()
            glMatrixMode(GL_PROJECTION)
            glPopMatrix()
            glMatrixMode(GL_MODELVIEW)
            glPopAttrib()
            
        except Exception as e:
            if config.DEBUG_MODE:
                print(f"⚠️  Error dibujando FPS: {e}")

    def _update_pattern_transition(self, state: Dict[str, Any]) -> None:
        """
        Actualiza el progreso de la transición entre patrones visuales.
        
        Args:
            state: Diccionario con el estado global
        """
        if config.PATTERN_TRANSITION_TIME > 0:
            time_since_change = state['current_time'] - state.get('pattern_change_time', 0)
            self.pattern_transition_progress = min(time_since_change / config.PATTERN_TRANSITION_TIME, 1.0)
        else:
            self.pattern_transition_progress = 1.0

    def render(self, state: Dict[str, Any]) -> None:
        """
        Renderiza un frame completo con los efectos visuales.
        
        Este es el método principal de renderizado, llamado en cada frame.
        Envía todos los uniforms necesarios al shader y dibuja la geometría.
        
        Args:
            state: Diccionario con todo el estado actual del visualizador
        """
        try:
            # Calcular FPS
            self._calculate_fps()
            
            # Actualizar transición de patrón
            self._update_pattern_transition(state)
            
            # Limpiar buffers
            glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
            
            # Activar programa de shaders
            glUseProgram(self.shader_program)
            
            # ================================================================
            # ENVIAR UNIFORMS AL SHADER
            # ================================================================
            # Los uniforms son variables globales del shader que se mantienen
            # constantes durante el dibujado de la geometría.
            
            # Resolución de pantalla (para calcular coordenadas UV)
            u_resolution = glGetUniformLocation(self.shader_program, "u_resolution")
            glUniform2f(u_resolution, float(config.SCREEN_WIDTH), float(config.SCREEN_HEIGHT))
            
            # Tiempo actual (para animaciones temporales)
            u_time = glGetUniformLocation(self.shader_program, "u_time")
            glUniform1f(u_time, state['current_time'])
            
            # Amplitud de audio (volumen general)
            u_amplitude = glGetUniformLocation(self.shader_program, "u_amplitude")
            glUniform1f(u_amplitude, state['current_amplitude'])
            
            # Amplitud suavizada (para efectos más estables)
            u_smooth_amp = glGetUniformLocation(self.shader_program, "u_smooth_amplitude")
            glUniform1f(u_smooth_amp, state.get('smoothed_amplitude', state['current_amplitude']))
            
            # Bandas de frecuencia (bass, mid, treble)
            u_bass = glGetUniformLocation(self.shader_program, "u_bass")
            glUniform1f(u_bass, state.get('bass_energy', 0.0))
            
            u_mid = glGetUniformLocation(self.shader_program, "u_mid")
            glUniform1f(u_mid, state.get('mid_energy', 0.0))
            
            u_treble = glGetUniformLocation(self.shader_program, "u_treble")
            glUniform1f(u_treble, state.get('treble_energy', 0.0))
            
            # Color base actual
            u_base_color = glGetUniformLocation(self.shader_program, "u_base_color")
            glUniform3fv(u_base_color, 1, config.COLOR_PALETTE[state['color_index']])
            
            # Índices de patrones (actual y anterior para transición)
            u_pattern = glGetUniformLocation(self.shader_program, "u_pattern_index")
            glUniform1i(u_pattern, state['pattern_index'])
            
            u_prev_pattern = glGetUniformLocation(self.shader_program, "u_prev_pattern_index")
            glUniform1i(u_prev_pattern, state.get('prev_pattern_index', state['pattern_index']))
            
            # Progreso de transición (0.0 - 1.0)
            u_transition = glGetUniformLocation(self.shader_program, "u_transition_progress")
            glUniform1f(u_transition, self.pattern_transition_progress)
            
            # Intensidad del último beat
            u_beat_intensity = glGetUniformLocation(self.shader_program, "u_beat_intensity")
            glUniform1f(u_beat_intensity, state.get('beat_intensity', 0.0))
            
            # Posiciones y tiempos de partículas/gotas
            u_drops_pos = glGetUniformLocation(self.shader_program, "u_drops_pos")
            glUniform2fv(u_drops_pos, config.MAX_PARTICLES, state['drop_positions'])
            
            u_drops_time = glGetUniformLocation(self.shader_program, "u_drops_time")
            glUniform1fv(u_drops_time, config.MAX_PARTICLES, state['drop_times'])
            
            # Post-processing uniforms
            u_bloom = glGetUniformLocation(self.shader_program, "u_bloom_intensity")
            glUniform1f(u_bloom, config.BLOOM_INTENSITY)
            
            u_vignette = glGetUniformLocation(self.shader_program, "u_vignette_intensity")
            glUniform1f(u_vignette, config.VIGNETTE_INTENSITY)
            
            u_contrast = glGetUniformLocation(self.shader_program, "u_contrast")
            glUniform1f(u_contrast, config.CONTRAST)
            
            u_saturation = glGetUniformLocation(self.shader_program, "u_saturation")
            glUniform1f(u_saturation, config.SATURATION)
            
            # ================================================================
            # DIBUJAR GEOMETRÍA
            # ================================================================
            glDrawArrays(GL_QUADS, 0, 4)
            
            # Dibujar FPS counter sobre el renderizado
            self._draw_fps_counter()
            
            # Intercambiar buffers (mostrar el frame renderizado)
            pygame.display.flip()
            
            # Verificar errores de OpenGL (solo en modo debug)
            if config.DEBUG_MODE:
                error = glGetError()
                if error != GL_NO_ERROR:
                    print(f"⚠️  OpenGL Error: {error}")
        
        except Exception as e:
            print(f"❌ Error durante el renderizado: {e}")
            if config.DEBUG_MODE:
                import traceback
                traceback.print_exc()

    def close(self) -> None:
        """Limpia recursos y cierra Pygame de forma segura."""
        try:
            print("\n🎨 Cerrando renderer...")
            
            # Eliminar buffers de OpenGL
            if hasattr(self, 'vbo'):
                glDeleteBuffers(1, [self.vbo])
            
            # Eliminar programa de shaders
            if hasattr(self, 'shader_program'):
                glDeleteProgram(self.shader_program)
            
            # Cerrar Pygame
            pygame.quit()
            
            print("✅ Renderer cerrado correctamente")
        except Exception as e:
            print(f"⚠️  Error al cerrar el renderer: {e}")

    def _emergency_shutdown(self) -> None:
        """Shutdown de emergencia en caso de error crítico."""
        try:
            pygame.quit()
        except:
            pass
        sys.exit(1)