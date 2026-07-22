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
    
    # Shaders de utilidad para el pipeline de post-procesado (FBO)
    BLEND_FS = """#version 120
    uniform sampler2D u_scene_tex;
    uniform sampler2D u_history_tex;
    uniform vec2 u_resolution;
    uniform float u_fade_rate;
    void main() {
        vec2 uv = gl_FragCoord.xy / u_resolution;
        // Zoom sutil del feedback para efecto túnel
        vec2 uv_history = (uv - 0.5) * 0.994 + 0.5;
        vec3 scene = texture2D(u_scene_tex, uv).rgb;
        vec3 history = texture2D(u_history_tex, uv_history).rgb;
        vec3 final = mix(history * 0.95, scene, u_fade_rate);
        gl_FragColor = vec4(final, 1.0);
    }
    """

    BRIGHT_FS = """#version 120
    uniform sampler2D u_tex;
    uniform vec2 u_resolution;
    void main() {
        vec2 uv = gl_FragCoord.xy / u_resolution;
        vec3 color = texture2D(u_tex, uv).rgb;
        float lum = dot(color, vec3(0.299, 0.587, 0.114));
        vec3 bright = max(color - 0.6, 0.0) * 1.5;
        gl_FragColor = vec4(bright, 1.0);
    }
    """
    
    BLUR_H_FS = """#version 120
    uniform sampler2D u_tex;
    uniform vec2 u_resolution;
    void main() {
        vec2 uv = gl_FragCoord.xy / u_resolution;
        float texel = 1.0 / u_resolution.x;
        vec3 color = vec3(0.0);
        color += texture2D(u_tex, uv).rgb * 0.2270270270;
        color += texture2D(u_tex, uv + vec2(1.3846153846 * texel, 0.0)).rgb * 0.3162162162;
        color += texture2D(u_tex, uv - vec2(1.3846153846 * texel, 0.0)).rgb * 0.3162162162;
        color += texture2D(u_tex, uv + vec2(3.2307692308 * texel, 0.0)).rgb * 0.0702702703;
        color += texture2D(u_tex, uv - vec2(3.2307692308 * texel, 0.0)).rgb * 0.0702702703;
        gl_FragColor = vec4(color, 1.0);
    }
    """
    
    BLUR_V_FS = """#version 120
    uniform sampler2D u_tex;
    uniform vec2 u_resolution;
    void main() {
        vec2 uv = gl_FragCoord.xy / u_resolution;
        float texel = 1.0 / u_resolution.y;
        vec3 color = vec3(0.0);
        color += texture2D(u_tex, uv).rgb * 0.2270270270;
        color += texture2D(u_tex, uv + vec2(0.0, 1.3846153846 * texel)).rgb * 0.3162162162;
        color += texture2D(u_tex, uv - vec2(0.0, 1.3846153846 * texel)).rgb * 0.3162162162;
        color += texture2D(u_tex, uv + vec2(0.0, 3.2307692308 * texel)).rgb * 0.0702702703;
        color += texture2D(u_tex, uv - vec2(0.0, 3.2307692308 * texel)).rgb * 0.0702702703;
        gl_FragColor = vec4(color, 1.0);
    }
    """
    
    def __init__(self):
        """Inicializa Pygame, OpenGL, compila shaders y configura la geometría."""
        try:
            print("[*] Inicializando motor de renderizado...")
            
            # Inicializar Pygame
            pygame.init()
            
            # Configurar DPI awareness para Windows antes de crear la ventana
            import ctypes
            try:
                ctypes.windll.shcore.SetProcessDpiAwareness(2)
            except Exception:
                try:
                    ctypes.windll.user32.SetProcessDPIAware()
                except Exception:
                    pass
            
            # Configurar flags (sin bordes NOFRAME para evitar minimización al perder foco)
            display_flags = DOUBLEBUF | OPENGL | NOFRAME
            
            try:
                # Crear ventana sin bordes que cubra la pantalla física nativa real
                self.screen = pygame.display.set_mode((0, 0), display_flags)
            except pygame.error as e:
                print(f"[!] No se pudo iniciar en modo sin bordes: {e}. Probando modo ventana...")
                # Fallback: Modo ventana estándar
                display_flags = DOUBLEBUF | OPENGL
                self.screen = pygame.display.set_mode((1280, 720), display_flags)
            
            screen_width, screen_height = self.screen.get_size()
            
            # Actualizar config con la resolución real obtenida
            config.SCREEN_WIDTH = screen_width
            config.SCREEN_HEIGHT = screen_height
            
            pygame.display.set_caption("Visualizador Generativo de Música - Premium Edition")
            
            # Configurar OpenGL viewport correctamente con la resolución física real
            glViewport(0, 0, screen_width, screen_height)
            glMatrixMode(GL_PROJECTION)
            glLoadIdentity()
            glOrtho(-1, 1, -1, 1, -1, 1)
            glMatrixMode(GL_MODELVIEW)
            glLoadIdentity()
            
            # Ocultar cursor para experiencia inmersiva
            pygame.mouse.set_visible(False)
            
            # Configurar VSync si está habilitado
            if config.VSYNC:
                pygame.display.gl_set_attribute(pygame.GL_SWAP_CONTROL, 1)
            
            # Permitir todos los eventos importantes de ventana
            pygame.event.set_allowed([pygame.QUIT, pygame.KEYDOWN, pygame.KEYUP, 
                                     pygame.WINDOWFOCUSGAINED, pygame.WINDOWFOCUSLOST,
                                     pygame.WINDOWMINIMIZED, pygame.WINDOWRESTORED,
                                     pygame.WINDOWEXPOSED, pygame.WINDOWSHOWN, pygame.WINDOWHIDDEN,
                                     pygame.MOUSEMOTION, pygame.MOUSEBUTTONDOWN])
            
            # Configurar la ventana para que responda a eventos del sistema
            pygame.display.set_allow_screensaver(True)
            
            # Información sobre el contexto OpenGL
            print(f"   OpenGL Version: {glGetString(GL_VERSION).decode()}")
            print(f"   GLSL Version: {glGetString(GL_SHADING_LANGUAGE_VERSION).decode()}")
            print(f"   Renderer: {glGetString(GL_RENDERER).decode()}")
            
            # Inicialización de shaders modulares y caché
            self.patterns_dir = 'shaders/patterns'
            self.compiled_programs = {}
            self.pattern_files = {}
            self.pattern_mtimes = {}
            self.common_mtime = 0.0
            
            # Textura FFT de audio 1D
            self.fft_texture = glGenTextures(1)
            glBindTexture(GL_TEXTURE_1D, self.fft_texture)
            glTexParameteri(GL_TEXTURE_1D, GL_TEXTURE_MIN_FILTER, GL_LINEAR)
            glTexParameteri(GL_TEXTURE_1D, GL_TEXTURE_MAG_FILTER, GL_LINEAR)
            glTexParameteri(GL_TEXTURE_1D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE)
            glBindTexture(GL_TEXTURE_1D, 0)
            
            # Escanear patrones modulares disponibles
            self._scan_patterns()
            
            # Compilar patrón por defecto inicialmente (índice 0)
            self.shader_program = self.get_or_compile_program(0)
            
            # Configurar geometría (quad de pantalla completa usando attribute location 0 fijo)
            self._setup_quad()
            
            # Inicialización de variables FBO y shader de post-procesamiento
            self.fbo_scene = None
            self.tex_scene = None
            self.fbo_bright = None
            self.tex_bright = None
            self.fbo_blur_h = None
            self.tex_blur_h = None
            self.fbo_blur_v = None
            self.tex_blur_v = None
            self.fbo_history_ping = None
            self.tex_history_ping = None
            self.fbo_history_pong = None
            self.tex_history_pong = None
            self.fbo_width = 0
            self.fbo_height = 0
            
            # Compilar shaders de utilidad para post-procesado
            self.bright_program = self._compile_utility_shader(self.BRIGHT_FS)
            self.blur_h_program = self._compile_utility_shader(self.BLUR_H_FS)
            self.blur_v_program = self._compile_utility_shader(self.BLUR_V_FS)
            self.blend_program = self._compile_utility_shader(self.BLEND_FS)
            
            # Cargar y compilar composite program
            self.composite_mtime = 0.0
            self.composite_program = self._compile_composite_shader()
            
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
                    print(f"[!] No se pudo cargar la fuente para FPS: {e}")
                    self.font = None
            else:
                self.font = None
            
            print("[OK] Renderer inicializado correctamente")
            
        except Exception as e:
            print(f"[ERROR] Error critico al inicializar el renderer: {e}")
            self._emergency_shutdown()
            raise

    def _load_shader_source(self, filepath: str) -> str:
        """
        Carga el código fuente de un shader desde un archivo.
        """
        try:
            with open(filepath, 'r', encoding='utf-8') as f:
                source = f.read()
            return source
        except FileNotFoundError:
            print(f"[ERROR] No se encontró el archivo de shader: {filepath}")
            raise
        except UnicodeDecodeError as e:
            print(f"[ERROR] Problema de encoding en {filepath}")
            raise

    def _scan_patterns(self) -> None:
        """Busca todos los archivos de patrones en la carpeta de shaders/patterns."""
        import os
        self.pattern_files = {}
        if not os.path.exists(self.patterns_dir):
            print(f"[!] La carpeta de patrones '{self.patterns_dir}' no existe")
            return
        
        for filename in os.listdir(self.patterns_dir):
            if filename.startswith('pattern_') and filename.endswith('.glsl'):
                parts = filename.split('_')
                if len(parts) >= 2:
                    try:
                        idx = int(parts[1])
                        self.pattern_files[idx] = os.path.join(self.patterns_dir, filename)
                    except ValueError:
                        pass
        print(f"   [+] Escaneo completado: {len(self.pattern_files)} patrones encontrados en '{self.patterns_dir}'")

    def get_or_compile_program(self, pattern_index: int) -> int:
        """Devuelve el ID del programa para el patrón especificado, compilando si es necesario."""
        import os
        
        # Validar índice del patrón
        if pattern_index not in self.pattern_files:
            # Si no existe, intentar re-escanear
            self._scan_patterns()
            if pattern_index not in self.pattern_files:
                # Si sigue sin existir, usar patrón 0 por defecto
                print(f"[!] Patrón {pattern_index} no encontrado, usando Patrón 0")
                pattern_index = 0
                
        # Verificar si hay cambios en common.glsl
        common_path = os.path.join('shaders', 'common.glsl')
        common_mtime = os.path.getmtime(common_path) if os.path.exists(common_path) else 0.0
        
        # Verificar cambios en el archivo del patrón
        pattern_path = self.pattern_files.get(pattern_index)
        pattern_mtime = os.path.getmtime(pattern_path) if pattern_path and os.path.exists(pattern_path) else 0.0
        
        # Si se modificó common.glsl o el archivo del patrón, invalidamos la caché
        if common_mtime > self.common_mtime or pattern_mtime > self.pattern_mtimes.get(pattern_index, 0.0):
            if pattern_index in self.compiled_programs:
                print(f"[*] Detectados cambios en el código de patrón {pattern_index} o en cabeceras. Recompilando...")
                glDeleteProgram(self.compiled_programs[pattern_index])
                del self.compiled_programs[pattern_index]
            self.common_mtime = common_mtime
            if pattern_path:
                self.pattern_mtimes[pattern_index] = pattern_mtime
                
        # Si ya está compilado, usarlo
        if pattern_index in self.compiled_programs:
            return self.compiled_programs[pattern_index]
            
        # Compilar en caliente
        try:
            program = self._compile_pattern_shader(pattern_index)
            self.compiled_programs[pattern_index] = program
            return program
        except Exception as e:
            print(f"[ERROR] ERROR AL COMPILAR EL PATRÓN {pattern_index}: {e}")
            if pattern_index != 0:
                print("[*] Rebotando a Patrón 0 de seguridad...")
                return self.get_or_compile_program(0)
            else:
                # Si el patrón 0 también falla, levantar excepción
                raise

    def _compile_pattern_shader(self, pattern_index: int) -> int:
        """Ensambla y compila el shader modular para un patrón individual."""
        import os
        import re
        
        # Cargar el código común
        common_path = os.path.join('shaders', 'common.glsl')
        common_source = self._load_shader_source(common_path)
        
        # Cargar el código del patrón
        pattern_path = self.pattern_files[pattern_index]
        pattern_source = self._load_shader_source(pattern_path)
        
        # Detección de versión moderna de GLSL
        is_glsl330 = '#version 330' in pattern_source
        
        # Limpiar declaraciones duplicadas de #version
        pattern_source = re.sub(r'#version\s+\d+\s*(core)?', '', pattern_source)
        common_source = re.sub(r'#version\s+\d+\s*(core)?', '', common_source)
        
        # Buscar el nombre y los parámetros de la función del patrón
        fn_match = re.search(r'float\s+(pattern_[a-zA-Z0-9_]+)\s*\(([^)]+)\)', pattern_source)
        if not fn_match:
            raise RuntimeError(f"El archivo {pattern_path} no declara una función de patrón válida")
            
        fn_name = fn_match.group(1)
        params_str = fn_match.group(2)
        params = [p.strip() for p in params_str.split(',') if p.strip()]
        
        # Construir la llamada correspondiente al patrón
        if len(params) == 2:
            pattern_call = f"{fn_name}(uv, u_time)"
        elif len(params) == 3:
            pattern_call = f"{fn_name}(uv, u_time, u_amplitude)"
        else:
            raise RuntimeError(f"Firma de parámetros inesperada en {fn_name}: {params_str}")
            
        # Encabezado de versión
        version_header = "#version 330 core\n" if is_glsl330 else "#version 120\n"
        
        # Declarar uniformes agregados (textura FFT y parámetros MIDI)
        extra_uniforms = "uniform sampler1D u_fft_texture;\nuniform float u_midi_mid;\nuniform float u_midi_reverb;\nuniform float u_midi_high;\n"
        
        # Ensamblar función main correspondiente a la versión de GLSL
        if is_glsl330:
            main_body = f"""
out vec4 fragColor;
void main() {{
    vec2 uv = gl_FragCoord.xy / u_resolution;
    
    // 1. Reverb dispersion (Eff2): dispersa el renderizado en una nube de puntos
    if (u_midi_reverb > 0.01) {{
        float noise = fract(sin(dot(uv * 135.0, vec2(12.9898, 78.233)) + u_time) * 43758.5453);
        vec2 noise_dir = vec2(sin(noise * 6.28318), cos(noise * 6.28318));
        uv += noise_dir * u_midi_reverb * 0.14;
    }}
    
    // 2. Mid deformation (Deformación de silueta líquida y temblorosa)
    if (u_midi_mid > 0.01) {{
        float warp = u_midi_mid * 0.06;
        uv.x += sin(uv.y * 18.0 + u_time * 6.0) * warp;
        uv.y += cos(uv.x * 18.0 - u_time * 6.0) * warp;
    }}
    
    uv = (uv - 0.5) / u_zoom + 0.5;
    float intensity = {pattern_call};
    
    vec3 bg = vec3(0.0, 0.0, 0.05);
    vec3 color = u_base_color * intensity * 1.5;
    
    color.r += u_treble * 0.3;
    color.g += u_mid * 0.3;
    color.b += u_bass * 0.3;
    
    // 3. Capa global de chispas (High EQ): se desprenden en cada beat, flotan hacia arriba y sisean
    vec3 sparks = vec3(0.0);
    if (u_midi_high > 0.01) {{
        for (int i = 0; i < 10; i++) {{
            float age = u_time - u_drops_time[i];
            if (age > 0.0 && age < 3.0) {{
                vec2 particle_pos = u_drops_pos[i];
                // Flotan hacia arriba. La velocidad aumenta con u_midi_high
                particle_pos.y += age * (0.12 + u_midi_high * 0.28);
                // Balanceo horizontal
                particle_pos.x += sin(age * 5.0 + float(i)) * 0.025;
                
                float dist = distance(uv, particle_pos);
                // El tamaño se expande con el High EQ
                float size = 0.001 + u_midi_high * 0.012;
                float brightness = exp(-dist / size) * (1.0 - age / 3.0);
                
                // Color amarillo/dorado ardiente
                vec3 spark_color = vec3(1.0, 0.55 + sin(float(i) + u_time) * 0.25, 0.1) * brightness * u_midi_high * 2.5;
                sparks += spark_color;
            }}
        }}
    }}
    
    vec3 final = bg + color + sparks;
    fragColor = vec4(clamp(final, 0.0, 1.0), 1.0);
}}
"""
        else:
            main_body = f"""
void main() {{
    vec2 uv = gl_FragCoord.xy / u_resolution;
    
    // 1. Reverb dispersion (Eff2): dispersa el renderizado en una nube de puntos
    if (u_midi_reverb > 0.01) {{
        float noise = fract(sin(dot(uv * 135.0, vec2(12.9898, 78.233)) + u_time) * 43758.5453);
        vec2 noise_dir = vec2(sin(noise * 6.28318), cos(noise * 6.28318));
        uv += noise_dir * u_midi_reverb * 0.14;
    }}
    
    // 2. Mid deformation (Deformación de silueta líquida y temblorosa)
    if (u_midi_mid > 0.01) {{
        float warp = u_midi_mid * 0.06;
        uv.x += sin(uv.y * 18.0 + u_time * 6.0) * warp;
        uv.y += cos(uv.x * 18.0 - u_time * 6.0) * warp;
    }}
    
    uv = (uv - 0.5) / u_zoom + 0.5;
    float intensity = {pattern_call};
    
    vec3 bg = vec3(0.0, 0.0, 0.05);
    vec3 color = u_base_color * intensity * 1.5;
    
    color.r += u_treble * 0.3;
    color.g += u_mid * 0.3;
    color.b += u_bass * 0.3;
    
    // 3. Capa global de chispas (High EQ): se desprenden en cada beat, flotan hacia arriba y sisean
    vec3 sparks = vec3(0.0);
    if (u_midi_high > 0.01) {{
        for (int i = 0; i < 10; i++) {{
            float age = u_time - u_drops_time[i];
            if (age > 0.0 && age < 3.0) {{
                vec2 particle_pos = u_drops_pos[i];
                // Flotan hacia arriba. La velocidad aumenta con u_midi_high
                particle_pos.y += age * (0.12 + u_midi_high * 0.28);
                // Balanceo horizontal
                particle_pos.x += sin(age * 5.0 + float(i)) * 0.025;
                
                float dist = distance(uv, particle_pos);
                // El tamaño se expande con el High EQ
                float size = 0.001 + u_midi_high * 0.012;
                float brightness = exp(-dist / size) * (1.0 - age / 3.0);
                
                // Color amarillo/dorado ardiente
                vec3 spark_color = vec3(1.0, 0.55 + sin(float(i) + u_time) * 0.25, 0.1) * brightness * u_midi_high * 2.5;
                sparks += spark_color;
            }}
        }}
    }}
    
    vec3 final = bg + color + sparks;
    gl_FragColor = vec4(clamp(final, 0.0, 1.0), 1.0);
}}
"""
        # Ensamblar código de fragment shader completo
        fragment_shader_source = version_header + extra_uniforms + common_source + "\n" + pattern_source + "\n" + main_body
        
        # Ensamblar vertex shader correspondiente
        vertex_version = "#version 330 core\n" if is_glsl330 else "#version 120\n"
        vertex_body = """
in vec2 position;
void main() {
    gl_Position = vec4(position, 0.0, 1.0);
}
""" if is_glsl330 else """
attribute vec2 position;
void main() {
    gl_Position = vec4(position, 0.0, 1.0);
}
"""
        vertex_shader_source = vertex_version + vertex_body
        
        # Compilar shaders individuales
        vertex_shader = shaders.compileShader(vertex_shader_source, GL_VERTEX_SHADER)
        fragment_shader = shaders.compileShader(fragment_shader_source, GL_FRAGMENT_SHADER)
        
        # Crear programa y vincular índice 0 a "position" antes de linkear
        program = glCreateProgram()
        glAttachShader(program, vertex_shader)
        glAttachShader(program, fragment_shader)
        
        glBindAttribLocation(program, 0, "position")
        
        glLinkProgram(program)
        
        # Verificar errores de enlazado
        if glGetProgramiv(program, GL_LINK_STATUS) != GL_TRUE:
            info_log = glGetProgramInfoLog(program)
            raise RuntimeError(f"Error de enlazado: {info_log.decode() if info_log else 'Error desconocido'}")
            
        return program

    def _setup_quad(self) -> None:
        """Configura el quad de pantalla completa vinculándolo a la ubicación 0 fija."""
        quad_vertices = np.array([
            -1.0, -1.0,  # Inferior izquierda
             1.0, -1.0,  # Inferior derecha
             1.0,  1.0,  # Superior derecha
            -1.0,  1.0   # Superior izquierda
        ], dtype=np.float32)
        
        self.vbo = glGenBuffers(1)
        glBindBuffer(GL_ARRAY_BUFFER, self.vbo)
        glBufferData(GL_ARRAY_BUFFER, quad_vertices.nbytes, quad_vertices, GL_STATIC_DRAW)
        
        # Usamos ubicación 0 fija configurada por glBindAttribLocation
        position_loc = 0
        glVertexAttribPointer(
            position_loc,
            2,
            GL_FLOAT,
            GL_FALSE,
            0,
            None
        )
        glEnableVertexAttribArray(position_loc)
        print("   [+] Geometría configurada (fullscreen quad en location 0)")

    def _create_fbo(self, width: int, height: int):
        """Crea un Framebuffer Object (FBO) con una textura de color adjunta."""
        fbo = glGenFramebuffers(1)
        glBindFramebuffer(GL_FRAMEBUFFER, fbo)
        
        tex = glGenTextures(1)
        glBindTexture(GL_TEXTURE_2D, tex)
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, width, height, 0, GL_RGB, GL_UNSIGNED_BYTE, None)
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR)
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR)
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE)
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE)
        
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, tex, 0)
        
        status = glCheckFramebufferStatus(GL_FRAMEBUFFER)
        if status != GL_FRAMEBUFFER_COMPLETE:
            raise RuntimeError(f"Framebuffer incompleto: {status}")
            
        glBindFramebuffer(GL_FRAMEBUFFER, 0)
        return fbo, tex

    def _delete_fbos(self) -> None:
        """Elimina de forma segura todos los recursos de FBOs."""
        if hasattr(self, 'fbo_scene') and self.fbo_scene:
            glDeleteFramebuffers(1, [self.fbo_scene])
            glDeleteTextures([self.tex_scene])
        if hasattr(self, 'fbo_bright') and self.fbo_bright:
            glDeleteFramebuffers(1, [self.fbo_bright])
            glDeleteTextures([self.tex_bright])
        if hasattr(self, 'fbo_blur_h') and self.fbo_blur_h:
            glDeleteFramebuffers(1, [self.fbo_blur_h])
            glDeleteTextures([self.tex_blur_h])
        if hasattr(self, 'fbo_blur_v') and self.fbo_blur_v:
            glDeleteFramebuffers(1, [self.fbo_blur_v])
            glDeleteTextures([self.tex_blur_v])
        if hasattr(self, 'fbo_history_ping') and self.fbo_history_ping:
            glDeleteFramebuffers(1, [self.fbo_history_ping])
            glDeleteTextures([self.tex_history_ping])
        if hasattr(self, 'fbo_history_pong') and self.fbo_history_pong:
            glDeleteFramebuffers(1, [self.fbo_history_pong])
            glDeleteTextures([self.tex_history_pong])
        self.fbo_scene = self.tex_scene = None
        self.fbo_bright = self.tex_bright = None
        self.fbo_blur_h = self.tex_blur_h = None
        self.fbo_blur_v = self.tex_blur_v = None
        self.fbo_history_ping = self.tex_history_ping = None
        self.fbo_history_pong = self.tex_history_pong = None
        self.fbo_width = 0
        self.fbo_height = 0

    def _compile_utility_shader(self, fs_source: str) -> int:
        """Compila un shader de utilidad simple (versión 120) para el post-procesado."""
        vs_source = """#version 120
        attribute vec2 position;
        void main() {
            gl_Position = vec4(position, 0.0, 1.0);
        }
        """
        vertex_shader = shaders.compileShader(vs_source, GL_VERTEX_SHADER)
        fragment_shader = shaders.compileShader(fs_source, GL_FRAGMENT_SHADER)
        program = glCreateProgram()
        glAttachShader(program, vertex_shader)
        glAttachShader(program, fragment_shader)
        glBindAttribLocation(program, 0, "position")
        glLinkProgram(program)
        if glGetProgramiv(program, GL_LINK_STATUS) != GL_TRUE:
            info_log = glGetProgramInfoLog(program)
            raise RuntimeError(f"Error de enlazado en utility shader: {info_log.decode() if info_log else 'Desconocido'}")
        return program

    def _compile_composite_shader(self) -> int:
        """Carga y compila el sombreador de composición final."""
        import os
        composite_path = os.path.join('shaders', 'composite.glsl')
        fs_source = self._load_shader_source(composite_path)
        
        # Guardar la fecha de modificación al compilar exitosamente
        self.composite_mtime = os.path.getmtime(composite_path) if os.path.exists(composite_path) else 0.0
        return self._compile_utility_shader(fs_source)

    def _draw_fullscreen_quad(self) -> None:
        """Dibuja un quad que cubre toda la pantalla usando el VBO configurado."""
        glBindBuffer(GL_ARRAY_BUFFER, self.vbo)
        glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 0, None)
        glEnableVertexAttribArray(0)
        glDrawArrays(GL_QUADS, 0, 4)

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
                print(f"[!]  Error dibujando FPS: {e}")

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
        Realiza el pipeline multipaso FBO:
        1. Renderiza el patrón a self.fbo_scene.
        2. Extrae las partes brillantes a self.fbo_bright.
        3. Difumina horizontalmente a self.fbo_blur_h.
        4. Difumina verticalmente a self.fbo_blur_v.
        5. Compone la escena original con el bloom, aberración cromática, LUTs y viñeta.
        
        Args:
            state: Diccionario con todo el estado actual del visualizador
        """
        try:
            # Calcular FPS
            self._calculate_fps()
            
            # Actualizar transición de patrón
            self._update_pattern_transition(state)
            
            # 0. Asegurar que los FBOs tengan la resolución correcta
            if self.fbo_width != config.SCREEN_WIDTH or self.fbo_height != config.SCREEN_HEIGHT:
                print(f"[*] Configurando Framebuffers para resolución {config.SCREEN_WIDTH}x{config.SCREEN_HEIGHT}...")
                self._delete_fbos()
                self.fbo_scene, self.tex_scene = self._create_fbo(config.SCREEN_WIDTH, config.SCREEN_HEIGHT)
                
                # History FBOs for temporal feedback loop (Trails)
                self.fbo_history_ping, self.tex_history_ping = self._create_fbo(config.SCREEN_WIDTH, config.SCREEN_HEIGHT)
                self.fbo_history_pong, self.tex_history_pong = self._create_fbo(config.SCREEN_WIDTH, config.SCREEN_HEIGHT)
                
                # Inicializar a negro/oscuro
                glBindFramebuffer(GL_FRAMEBUFFER, self.fbo_history_ping)
                glClearColor(0.0, 0.0, 0.05, 1.0)
                glClear(GL_COLOR_BUFFER_BIT)
                glBindFramebuffer(GL_FRAMEBUFFER, self.fbo_history_pong)
                glClear(GL_COLOR_BUFFER_BIT)
                glBindFramebuffer(GL_FRAMEBUFFER, 0)
                
                # Bloom a 1/4 de resolución para optimizar rendimiento
                bloom_w = max(1, config.SCREEN_WIDTH // 4)
                bloom_h = max(1, config.SCREEN_HEIGHT // 4)
                self.fbo_bright, self.tex_bright = self._create_fbo(bloom_w, bloom_h)
                self.fbo_blur_h, self.tex_blur_h = self._create_fbo(bloom_w, bloom_h)
                self.fbo_blur_v, self.tex_blur_v = self._create_fbo(bloom_w, bloom_h)
                
                self.fbo_width = config.SCREEN_WIDTH
                self.fbo_height = config.SCREEN_HEIGHT

            # Verificar si composite.glsl ha cambiado en caliente
            import os
            composite_path = os.path.join('shaders', 'composite.glsl')
            composite_mtime = os.path.getmtime(composite_path) if os.path.exists(composite_path) else 0.0
            if composite_mtime > self.composite_mtime:
                print("[*] Detectados cambios en shaders/composite.glsl. Recompilando...")
                try:
                    new_prog = self._compile_composite_shader()
                    if hasattr(self, 'composite_program') and self.composite_program:
                        glDeleteProgram(self.composite_program)
                    self.composite_program = new_prog
                    self.composite_mtime = composite_mtime
                    print("[OK] Sombreador composite.glsl recompilado con éxito")
                except Exception as e:
                    print(f"[ERROR] Error al recompilar composite.glsl: {e}")

            # ================================================================
            # PASO 1: Renderizar el patrón a self.fbo_scene
            # ================================================================
            glBindFramebuffer(GL_FRAMEBUFFER, self.fbo_scene)
            glViewport(0, 0, config.SCREEN_WIDTH, config.SCREEN_HEIGHT)
            glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
            
            # Obtener y activar el programa para el patrón actual
            self.shader_program = self.get_or_compile_program(state['pattern_index'])
            glUseProgram(self.shader_program)
            
            # Cargar y subir datos de FFT a la textura 1D (unidad de textura 0)
            fft_data = state.get('fft_data')
            if fft_data is not None:
                fft_512 = fft_data[:512]
                fft_normalized = np.clip(fft_512 * config.SENSITIVITY * 0.1, 0.0, 1.0).astype(np.float32)
            else:
                fft_normalized = np.zeros(512, dtype=np.float32)
                
            # Aplicar decaimiento temporal asimétrico (subida instantánea, bajada suave con factor 0.95)
            if not hasattr(self, 'fft_smoothed') or self.fft_smoothed.shape != fft_normalized.shape:
                self.fft_smoothed = np.zeros_like(fft_normalized)
            self.fft_smoothed = np.where(fft_normalized > self.fft_smoothed, fft_normalized, self.fft_smoothed * 0.95)
                
            glActiveTexture(GL_TEXTURE0)
            glBindTexture(GL_TEXTURE_1D, self.fft_texture)
            glTexImage1D(GL_TEXTURE_1D, 0, GL_LUMINANCE, 512, 0, GL_LUMINANCE, GL_FLOAT, self.fft_smoothed)
            
            # Enviar el uniform de la textura FFT al shader
            u_fft_texture = glGetUniformLocation(self.shader_program, "u_fft_texture")
            glUniform1i(u_fft_texture, 0)
            
            # Enviar uniforms al shader de patrón
            u_resolution = glGetUniformLocation(self.shader_program, "u_resolution")
            glUniform2f(u_resolution, float(config.SCREEN_WIDTH), float(config.SCREEN_HEIGHT))
            
            u_time = glGetUniformLocation(self.shader_program, "u_time")
            glUniform1f(u_time, state['current_time'])
            
            u_reactive_time = glGetUniformLocation(self.shader_program, "u_reactive_time")
            if u_reactive_time != -1:
                glUniform1f(u_reactive_time, state.get('reactive_time', state['current_time']))
            
            u_amplitude = glGetUniformLocation(self.shader_program, "u_amplitude")
            glUniform1f(u_amplitude, state['current_amplitude'])
            
            u_smooth_amp = glGetUniformLocation(self.shader_program, "u_smooth_amplitude")
            glUniform1f(u_smooth_amp, state.get('smoothed_amplitude', state['current_amplitude']))
            
            u_bass = glGetUniformLocation(self.shader_program, "u_bass")
            glUniform1f(u_bass, state.get('bass_energy', 0.0))
            
            u_mid = glGetUniformLocation(self.shader_program, "u_mid")
            glUniform1f(u_mid, state.get('mid_energy', 0.0))
            
            u_treble = glGetUniformLocation(self.shader_program, "u_treble")
            glUniform1f(u_treble, state.get('treble_energy', 0.0))
            
            u_base_color = glGetUniformLocation(self.shader_program, "u_base_color")
            base_color = state.get('render_base_color')
            if base_color is None:
                base_color = config.COLOR_PALETTE[state['color_index']]
            glUniform3fv(u_base_color, 1, base_color)
            
            u_pattern = glGetUniformLocation(self.shader_program, "u_pattern_index")
            glUniform1i(u_pattern, state['pattern_index'])
            
            u_prev_pattern = glGetUniformLocation(self.shader_program, "u_prev_pattern_index")
            glUniform1i(u_prev_pattern, state.get('prev_pattern_index', state['pattern_index']))
            
            u_transition = glGetUniformLocation(self.shader_program, "u_transition_progress")
            glUniform1f(u_transition, self.pattern_transition_progress)
            
            u_beat_intensity = glGetUniformLocation(self.shader_program, "u_beat_intensity")
            glUniform1f(u_beat_intensity, state.get('beat_intensity', 0.0))

            u_last_beat_time = glGetUniformLocation(self.shader_program, "u_last_beat_time")
            glUniform1f(u_last_beat_time, state.get('beat_last_time', 0.0))
            
            u_drops_pos = glGetUniformLocation(self.shader_program, "u_drops_pos")
            glUniform2fv(u_drops_pos, config.MAX_PARTICLES, state['drop_positions'])
            
            u_drops_time = glGetUniformLocation(self.shader_program, "u_drops_time")
            glUniform1fv(u_drops_time, config.MAX_PARTICLES, state['drop_times'])
            
            u_zoom = glGetUniformLocation(self.shader_program, "u_zoom")
            glUniform1f(u_zoom, state.get('render_zoom', 1.0))
            
            # --- SUBIR PARÁMETROS MIDI ADICIONALES ---
            u_midi_mid = glGetUniformLocation(self.shader_program, "u_midi_mid")
            if u_midi_mid != -1:
                midi_mid_left = state.get('midi_mid_left', 0.5)
                midi_mid_right = state.get('midi_mid_right', 0.5)
                midi_mid = (midi_mid_left + midi_mid_right) * 0.5
                # Reposo (estático) en el centro (0.5). Gire para donde gire (espejo) incrementa el efecto.
                deform_val = abs(midi_mid - 0.5) * 2.0
                glUniform1f(u_midi_mid, deform_val)
                
            u_midi_reverb = glGetUniformLocation(self.shader_program, "u_midi_reverb")
            if u_midi_reverb != -1:
                reverb_active = state.get('midi_eff2', False)
                reverb_intensity = state.get('midi_fadeff', 0.0)
                glUniform1f(u_midi_reverb, reverb_intensity if reverb_active else 0.0)

            u_midi_high = glGetUniformLocation(self.shader_program, "u_midi_high")
            if u_midi_high != -1:
                midi_high_left = state.get('midi_high_left', 0.5)
                midi_high_right = state.get('midi_high_right', 0.5)
                midi_high = (midi_high_left + midi_high_right) * 0.5
                # Reposo (cero chispas extras) en el centro (0.5). Efecto espejo simétrico.
                deform_high = abs(midi_high - 0.5) * 2.0
                glUniform1f(u_midi_high, deform_high)
            
            # Dibujar el patrón
            self._draw_fullscreen_quad()
            
            # ================================================================
            # PASO 1.5: Mezclar escena nueva con el historial (Temporal Feedback Loop)
            # ================================================================
            glBindFramebuffer(GL_FRAMEBUFFER, self.fbo_history_pong)
            glViewport(0, 0, config.SCREEN_WIDTH, config.SCREEN_HEIGHT)
            glClearColor(0.0, 0.0, 0.05, 1.0)
            glClear(GL_COLOR_BUFFER_BIT)
            
            glUseProgram(self.blend_program)
            
            glActiveTexture(GL_TEXTURE0)
            glBindTexture(GL_TEXTURE_2D, self.tex_scene)
            
            glActiveTexture(GL_TEXTURE1)
            glBindTexture(GL_TEXTURE_2D, self.tex_history_ping)
            
            glUniform1i(glGetUniformLocation(self.blend_program, "u_scene_tex"), 0)
            glUniform1i(glGetUniformLocation(self.blend_program, "u_history_tex"), 1)
            glUniform2f(glGetUniformLocation(self.blend_program, "u_resolution"), float(config.SCREEN_WIDTH), float(config.SCREEN_HEIGHT))
            
            # La tasa de desvanecimiento (fade_rate) responde al Efecto 1 (Echo) y al Fader de intensidad MIDI
            if state.get('midi_eff1', False):
                fade_rate = 0.35 - state.get('midi_fadeff', 0.0) * 0.33
                fade_rate = max(0.01, min(0.35, fade_rate))
            else:
                fade_rate = 0.99 # Apagado: movimiento nítido instantáneo sin rastro
            glUniform1f(glGetUniformLocation(self.blend_program, "u_fade_rate"), fade_rate)
            
            self._draw_fullscreen_quad()
            
            # Desvincular textura en unidad 1 y programa
            glActiveTexture(GL_TEXTURE1)
            glBindTexture(GL_TEXTURE_2D, 0)
            glActiveTexture(GL_TEXTURE0)
            glBindTexture(GL_TEXTURE_2D, 0)
            glUseProgram(0)
            
            # Intercambiar ping y pong
            self.fbo_history_ping, self.fbo_history_pong = self.fbo_history_pong, self.fbo_history_ping
            self.tex_history_ping, self.tex_history_pong = self.tex_history_pong, self.tex_history_ping

            # ================================================================
            # PASO 2: Extraer partes brillantes a self.fbo_bright (1/4 res)
            # ================================================================
            glBindFramebuffer(GL_FRAMEBUFFER, self.fbo_bright)
            bloom_w = config.SCREEN_WIDTH // 4
            bloom_h = config.SCREEN_HEIGHT // 4
            glViewport(0, 0, bloom_w, bloom_h)
            glClear(GL_COLOR_BUFFER_BIT)
            
            glUseProgram(self.bright_program)
            glActiveTexture(GL_TEXTURE0)
            glBindTexture(GL_TEXTURE_2D, self.tex_history_ping)
            
            glUniform1i(glGetUniformLocation(self.bright_program, "u_tex"), 0)
            glUniform2f(glGetUniformLocation(self.bright_program, "u_resolution"), float(bloom_w), float(bloom_h))
            
            self._draw_fullscreen_quad()
            
            # ================================================================
            # PASO 3: Desenfoque Horizontal (fbo_bright -> fbo_blur_h)
            # ================================================================
            glBindFramebuffer(GL_FRAMEBUFFER, self.fbo_blur_h)
            glClear(GL_COLOR_BUFFER_BIT)
            
            glUseProgram(self.blur_h_program)
            glActiveTexture(GL_TEXTURE0)
            glBindTexture(GL_TEXTURE_2D, self.tex_bright)
            
            glUniform1i(glGetUniformLocation(self.blur_h_program, "u_tex"), 0)
            glUniform2f(glGetUniformLocation(self.blur_h_program, "u_resolution"), float(bloom_w), float(bloom_h))
            
            self._draw_fullscreen_quad()
            
            # ================================================================
            # PASO 4: Desenfoque Vertical (fbo_blur_h -> fbo_blur_v)
            # ================================================================
            glBindFramebuffer(GL_FRAMEBUFFER, self.fbo_blur_v)
            glClear(GL_COLOR_BUFFER_BIT)
            
            glUseProgram(self.blur_v_program)
            glActiveTexture(GL_TEXTURE0)
            glBindTexture(GL_TEXTURE_2D, self.tex_blur_h)
            
            glUniform1i(glGetUniformLocation(self.blur_v_program, "u_tex"), 0)
            glUniform2f(glGetUniformLocation(self.blur_v_program, "u_resolution"), float(bloom_w), float(bloom_h))
            
            self._draw_fullscreen_quad()
            
            # ================================================================
            # PASO 5: Composición final en pantalla completa
            # ================================================================
            glBindFramebuffer(GL_FRAMEBUFFER, 0)
            glViewport(0, 0, config.SCREEN_WIDTH, config.SCREEN_HEIGHT)
            glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
            
            glUseProgram(self.composite_program)
            
            # Enlazar texturas
            glActiveTexture(GL_TEXTURE0)
            glBindTexture(GL_TEXTURE_2D, self.tex_history_ping)
            
            glActiveTexture(GL_TEXTURE1)
            glBindTexture(GL_TEXTURE_2D, self.tex_blur_v)
            
            glUniform1i(glGetUniformLocation(self.composite_program, "u_scene_tex"), 0)
            glUniform1i(glGetUniformLocation(self.composite_program, "u_bloom_tex"), 1)
            glUniform2f(glGetUniformLocation(self.composite_program, "u_resolution"), float(config.SCREEN_WIDTH), float(config.SCREEN_HEIGHT))
            
            # Parámetros del post-procesado
            glUniform1f(glGetUniformLocation(self.composite_program, "u_bloom_intensity"), state.get('render_bloom', config.BLOOM_INTENSITY))
            glUniform1f(glGetUniformLocation(self.composite_program, "u_vignette_intensity"), state.get('render_vignette', config.VIGNETTE_INTENSITY))
            glUniform1f(glGetUniformLocation(self.composite_program, "u_contrast"), state.get('render_contrast', config.CONTRAST))
            glUniform1f(glGetUniformLocation(self.composite_program, "u_saturation"), state.get('render_saturation', config.SATURATION))
            glUniform1i(glGetUniformLocation(self.composite_program, "u_color_grading"), state.get('color_grading_style', 0))
            
            # Reactividad de aberración cromática
            glUniform1f(glGetUniformLocation(self.composite_program, "u_amplitude"), state['current_amplitude'])
            glUniform1f(glGetUniformLocation(self.composite_program, "u_treble"), state.get('treble_energy', 0.0))
            
            # Subir parámetros MIDI para el Phaser/Flanger (Efecto 3)
            u_midi_phaser_loc = glGetUniformLocation(self.composite_program, "u_midi_phaser")
            if u_midi_phaser_loc != -1:
                phaser_active = state.get('midi_eff3', False)
                phaser_intensity = state.get('midi_fadeff', 0.0)
                glUniform1f(u_midi_phaser_loc, phaser_intensity if phaser_active else 0.0)
                
            u_time_loc = glGetUniformLocation(self.composite_program, "u_time")
            if u_time_loc != -1:
                glUniform1f(u_time_loc, state['current_time'])
            
            self._draw_fullscreen_quad()
            
            # Desvincular texturas y programa
            glActiveTexture(GL_TEXTURE1)
            glBindTexture(GL_TEXTURE_2D, 0)
            glActiveTexture(GL_TEXTURE0)
            glBindTexture(GL_TEXTURE_2D, 0)
            glUseProgram(0)
            
            # Dibujar FPS counter sobre el renderizado
            self._draw_fps_counter()
            
            # Intercambiar buffers (mostrar el frame renderizado)
            pygame.display.flip()
            
            # Verificar errores de OpenGL (solo en modo debug)
            if config.DEBUG_MODE:
                error = glGetError()
                if error != GL_NO_ERROR:
                    print(f"[!]  OpenGL Error: {error}")
        
        except Exception as e:
            print(f"[ERROR] Error durante el renderizado: {e}")
            if config.DEBUG_MODE:
                import traceback
                traceback.print_exc()

    def close(self) -> None:
        """Limpia recursos y cierra Pygame de forma segura."""
        try:
            print("\n[*] Cerrando renderer...")
            
            # Eliminar framebuffers y texturas
            self._delete_fbos()
            
            # Eliminar utility shaders
            if hasattr(self, 'bright_program') and self.bright_program:
                glDeleteProgram(self.bright_program)
            if hasattr(self, 'blur_h_program') and self.blur_h_program:
                glDeleteProgram(self.blur_h_program)
            if hasattr(self, 'blur_v_program') and self.blur_v_program:
                glDeleteProgram(self.blur_v_program)
            if hasattr(self, 'fade_program') and self.fade_program:
                glDeleteProgram(self.fade_program)
            if hasattr(self, 'composite_program') and self.composite_program:
                glDeleteProgram(self.composite_program)
                
            # Eliminar buffers de OpenGL
            if hasattr(self, 'vbo'):
                glDeleteBuffers(1, [self.vbo])
            
            # Eliminar programas de shaders compilados y texturas
            if hasattr(self, 'compiled_programs'):
                for prog_id in self.compiled_programs.values():
                    glDeleteProgram(prog_id)
            if hasattr(self, 'fft_texture'):
                glDeleteTextures([self.fft_texture])
            
            pygame.quit()
            print("[OK] Renderer cerrado correctamente")
        except Exception as e:
            print(f"[!]  Error al cerrar el renderer: {e}")

    def _emergency_shutdown(self) -> None:
        """Shutdown de emergencia en caso de error crítico."""
        try:
            pygame.quit()
        except:
            pass
        sys.exit(1)