import pygame
from pygame.locals import *
from OpenGL.GL import *
from OpenGL.GL import shaders
import numpy as np
import sounddevice as sd
import queue
import sys
import colorsys

# ------------------- CONFIGURACIÓN -------------------
SCREEN_WIDTH, SCREEN_HEIGHT = 1280, 720

# Audio
SAMPLERATE = 44100
DEVICE_NAME = "Mezcla estéreo"
NUM_SAMPLES = 2048

# Detección de ritmo (ahora en rango medio)
BEAT_FREQ_RANGE = (20, 500) # Rango para snares/claps
BEAT_THRESHOLD = 0.28       # Umbral más bajo para mayor frecuencia
BEAT_COOLDOWN = 0.15          # Cooldown más corto para ritmos rápidos

# Visualización
SENSITIVITY = 2.5
DECAY_RATE = 0.98
SHAPE_CHANGE_BEATS = 16
# ----------------------------------------------------

# --- Paleta de colores ---
COLOR_PALETTE = [colorsys.hsv_to_rgb(h / 12.0, 0.9, 1.0) for h in range(12)]

# --- Cola para el audio ---
audio_queue = queue.Queue()

# --- Shaders (con 13 efectos) ---
VERTEX_SHADER = """
#version 330
in vec2 position;
void main() {
    gl_Position = vec4(position, 0.0, 1.0);
}
"""
FRAGMENT_SHADER = """
#version 330
out vec4 outColor;

uniform vec2 u_resolution;
uniform float u_time;
uniform float u_amplitude;
uniform vec3 u_base_color;
uniform int u_pattern_index;

uniform vec2 u_drops_pos[10];
uniform float u_drops_time[10];

// --- FUNCIONES DE UTILIDAD ---
mat2 rotate2d(float _angle){
    return mat2(cos(_angle),-sin(_angle),
                sin(_angle),cos(_angle));
}

// --- EFECTOS VISUALES ---

// 1: Gotas de Agua
float pattern_raindrops(vec2 uv, float time) {
    float background_ripple = sin(uv.x * 30.0 + time * 0.5) * cos(uv.y * 20.0 - time * 0.5) * 0.03;
    float total_wave = 0.0;
    for (int i = 0; i < 10; i++) {
        float time_since_drop = time - u_drops_time[i];
        if (time_since_drop > 0.0 && time_since_drop < 4.0) {
            float dist = distance(uv, u_drops_pos[i]);
            float wave = sin(dist * 40.0 - time_since_drop * 6.0);
            float decay = pow(1.0 - (time_since_drop / 4.0), 2.0) / (1.0 + dist * dist * 100.0);
            total_wave += wave * decay;
        }
    }
    return background_ripple + total_wave;
}

// 2: Túnel Psicodélico
float pattern_tunnel(vec2 uv, float time) {
    vec2 p = 2.0 * uv - 1.0; p.x *= u_resolution.x / u_resolution.y;
    float r = length(p); float a = atan(p.y, p.x);
    float tunnel = 0.2 / r;
    tunnel += sin(a * 7.0 + time * 3.0) * 0.1;
    tunnel += cos(r * 20.0 - time * 5.0) * 0.5;
    return tunnel;
}

// 3: Espiral Glitch
float pattern_cosmic_zoom(vec2 uv, float time, float amplitude) {
    vec2 p = 2.0 * uv - 1.0; p.x *= u_resolution.x / u_resolution.y;
    float r = length(p); float a = atan(p.y, p.x);
    float glitch_factor = floor(r * 20.0 + amplitude * 50.0) / 20.0;
    float arms = 4.0;
    float spiral = sin(a * arms + glitch_factor * 5.0 - time * 2.0);
    float zoom = log(r);
    spiral *= cos(zoom * 5.0 - time);
    return spiral;
}

// 4: Rejilla Ondulante
float pattern_wobble_grid(vec2 uv, float time) {
    vec2 distorted_uv = uv;
    distorted_uv.x += sin(uv.y * 20.0 + time * 2.0) * 0.05 * u_amplitude;
    distorted_uv.y += cos(uv.x * 20.0 + time * 1.5) * 0.05 * u_amplitude;
    float grid_x = smoothstep(0.01, 0.02, abs(fract(distorted_uv.x * 15.0) - 0.5));
    float grid_y = smoothstep(0.01, 0.02, abs(fract(distorted_uv.y * 15.0) - 0.5));
    return 1.0 - (grid_x * grid_y);
}

// 5: Orbe Reactivo
float pattern_glitchy_orb(vec2 uv, float time, float amplitude) {
    vec2 p = uv - 0.5; p.x *= u_resolution.x / u_resolution.y;
    float r = length(p); float a = atan(p.y, p.x);
    float distorted_radius = 0.4 + sin(a * 5.0 + time) * 0.02 + cos(a * 12.0 - time * 1.5) * 0.01;
    distorted_radius -= amplitude * 0.1;
    float orb_core = 1.0 - smoothstep(distorted_radius, distorted_radius + 0.05, r);
    float total_rays = 0.0;
    for (int i = 0; i < 10; i++) {
        float time_since_beat = time - u_drops_time[i];
        if (time_since_beat > 0.0 && time_since_beat < 2.0) {
            vec2 ray_dir = normalize(u_drops_pos[i] - 0.5);
            float angle_diff = abs(atan(p.y, p.x) - atan(ray_dir.y, ray_dir.x));
            angle_diff = min(angle_diff, 2.0 * 3.14159 - angle_diff);
            float ray = smoothstep(0.1, 0.0, angle_diff) * pow(1.0 - time_since_beat / 2.0, 3.0);
            total_rays += ray;
        }
    }
    return orb_core + total_rays;
}

// --- NUEVOS EFECTOS ---

// 6: Cascada de Cuadrados (Reemplaza Cuadrado Rotatorio)
float pattern_square_cascade(vec2 uv, float time, float amplitude) {
    float final_shape = 0.0;
    // Creamos 5 capas de cuadrados que caen
    for(float i = 0.0; i < 5.0; i++){
        // Hacemos que cada capa se mueva a una velocidad y posición diferente
        float speed = 0.2 + i * 0.05;
        float offset = i * 0.4;
        vec2 p = uv;
        p.y = fract(p.y + time * speed + offset); // Movimiento vertical
        p -= 0.5;

        // Rotan y cambian de tamaño con la música
        p = rotate2d(time * 0.5 + i + amplitude * 5.0) * p;
        float size = 0.1 + sin(time + i) * 0.05 + amplitude * 0.2;
        
        final_shape += smoothstep(size, size - 0.01, max(abs(p.x), abs(p.y)));
    }
    return final_shape;
}

// 7: Cuadrados Fractales
float pattern_fractal_squares(vec2 uv, float time, float amplitude) {
    vec2 p = uv * 2.0 - 1.0;
    float final_shape = 0.0;
    float scale = 2.0;
    for (int i = 0; i < 5; i++) {
        p = abs(p) - 1.0;
        p = rotate2d(time * 0.2 + amplitude * float(i)) * p;
        p *= scale;
        final_shape += step(max(abs(p.x), abs(p.y)), 0.5);
    }
    return final_shape * 0.2;
}

// 8: Mandala de Pétalos (Reemplaza Flor Pulsante)
float pattern_petal_mandala(vec2 uv, float time, float amplitude) {
    vec2 p = uv - 0.5;
    p.x *= u_resolution.x / u_resolution.y;
    
    // Simetría de 8 puntas para el mandala
    float a = atan(p.y, p.x);
    float segments = 8.0;
    a = mod(a, 2.0 * 3.14159 / segments) - (3.14159 / segments);
    p = length(p) * vec2(cos(a), sin(a));

    // Dibujamos una forma de pétalo que rota y reacciona
    p = rotate2d(-time * 0.5 - amplitude * 2.0) * p;
    float petal = smoothstep(0.4, 0.1, length(p - vec2(0.3, 0.0)));
    return petal;
}

// 9: Jardín de Flores
float pattern_flower_garden(vec2 uv, float time, float amplitude) {
    float final_color = 0.0;
    vec2 p = fract(uv * 5.0) - 0.5;
    float r = length(p);
    float a = atan(p.y, p.x);
    float petals = 5.0 + floor(amplitude * 10.0);
    float flower = sin(a * petals) * 0.25 + 0.25;
    final_color = smoothstep(flower, flower + 0.1, r);
    return final_color;
}

// 10: Nido de Hexágonos
float pattern_hex_nest(vec2 uv, float time, float amplitude) {
    vec2 p = uv * 2.0 - 1.0; p.x *= u_resolution.x / u_resolution.y;
    p = rotate2d(time * 0.1) * p;
    p *= 5.0;
    vec2 q = abs(p);
    float hex = max(q.x, dot(q, normalize(vec2(1.0, 1.73))));
    hex = sin(hex * 5.0 - time * 2.0 + amplitude * 5.0);
    return hex;
}

// 11: Pulso Hexagonal
float pattern_hex_pulse(vec2 uv, float time, float amplitude) {
    vec2 p = uv - 0.5; p.x *= u_resolution.x / u_resolution.y;
    float size = 0.4 + sin(time) * 0.1;
    size -= amplitude * 0.3;
    float d = max(abs(p.x) * 0.866025 + abs(p.y) * 0.5, abs(p.y));
    return smoothstep(size, size - 0.1, d);
}

// 12: Caleidoscopio Mixto
float pattern_kaleidoscope(vec2 uv, float time, float amplitude) {
    vec2 p = uv - 0.5;
    p = rotate2d(time * 0.3) * p;
    p = abs(p);
    p = rotate2d(3.14159 / 4.0) * p;
    p = abs(p);
    float circle = length(p - 0.2);
    float box = max(abs(p.x), abs(p.y));
    return sin(circle * 10.0 + box * 10.0 - time * 2.0 + amplitude * 5.0);
}

// 13: Glitch Mixto
float pattern_mixed_glitch(vec2 uv, float time, float amplitude) {
    float h_glitch = floor(uv.y * 20.0 + time * 5.0) / 20.0;
    h_glitch = fract(h_glitch);
    uv.x += (h_glitch - 0.5) * amplitude * 0.2;
    float r_channel = sin(uv.x * 30.0 + time * 2.0) * 0.5 + 0.5;
    float g_channel = sin(uv.x * 31.0 + time * 2.1) * 0.5 + 0.5;
    float scanline = sin(uv.y * 800.0) * 0.1;
    return r_channel * g_channel + scanline;
}


void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;
    float effect_intensity = 0.0;

    // Selector de efectos actualizado
    if (u_pattern_index == 0)  effect_intensity = pattern_raindrops(uv, u_time);
    else if (u_pattern_index == 1) effect_intensity = pattern_tunnel(uv, u_time);
    else if (u_pattern_index == 2) effect_intensity = pattern_cosmic_zoom(uv, u_time, u_amplitude);
    else if (u_pattern_index == 3) effect_intensity = pattern_wobble_grid(uv, u_time);
    else if (u_pattern_index == 4) effect_intensity = pattern_glitchy_orb(uv, u_time, u_amplitude);
    else if (u_pattern_index == 5) effect_intensity = pattern_square_cascade(uv, u_time, u_amplitude); // NUEVO
    else if (u_pattern_index == 6) effect_intensity = pattern_fractal_squares(uv, u_time, u_amplitude);
    else if (u_pattern_index == 7) effect_intensity = pattern_petal_mandala(uv, u_time, u_amplitude); // NUEVO
    else if (u_pattern_index == 8) effect_intensity = pattern_flower_garden(uv, u_time, u_amplitude);
    else if (u_pattern_index == 9) effect_intensity = pattern_hex_nest(uv, u_time, u_amplitude);
    else if (u_pattern_index == 10) effect_intensity = pattern_hex_pulse(uv, u_time, u_amplitude);
    else if (u_pattern_index == 11) effect_intensity = pattern_kaleidoscope(uv, u_time, u_amplitude);
    else if (u_pattern_index == 12) effect_intensity = pattern_mixed_glitch(uv, u_time, u_amplitude);


    vec3 background_color = vec3(0.0, 0.0, 0.05);
    vec3 effect_color = u_base_color * effect_intensity * 1.5;
    vec3 final_color = background_color + effect_color;
    
    outColor = vec4(final_color, 1.0);
}
"""

def find_loopback_device():
    devices = sd.query_devices()
    for i, device in enumerate(devices):
        if DEVICE_NAME in device['name'] and device['max_input_channels'] > 0:
            print(f"✅ Dispositivo de Loopback encontrado: '{device['name']}' (ID: {i})")
            return i
    return None

def audio_callback(indata, frames, time, status):
    if status: print(status, file=sys.stderr)
    audio_queue.put(np.copy(indata[:, 0]))

def main():
    pygame.init()
    pygame.display.set_mode((SCREEN_WIDTH, SCREEN_HEIGHT), DOUBLEBUF | OPENGL)
    pygame.display.set_caption("Visualizador Generativo (13 Formas)")

    try:
        shader_program = shaders.compileProgram(
            shaders.compileShader(VERTEX_SHADER, GL_VERTEX_SHADER),
            shaders.compileShader(FRAGMENT_SHADER, GL_FRAGMENT_SHADER)
        )
    except Exception as e:
        print("\n!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!", file=sys.stderr)
        print("    ERROR GRAVE AL COMPILAR LOS SHADERS", file=sys.stderr); print(e, file=sys.stderr)
        input("\n--- Presiona Enter para cerrar la ventana... ---"); pygame.quit(); return

    # Configuración del VBO
    quad_vertices = np.array([-1, -1, 1, -1, 1, 1, -1, 1], dtype=np.float32)
    vbo = glGenBuffers(1); glBindBuffer(GL_ARRAY_BUFFER, vbo)
    glBufferData(GL_ARRAY_BUFFER, quad_vertices.nbytes, quad_vertices, GL_STATIC_DRAW)
    position_loc = glGetAttribLocation(shader_program, "position")
    glVertexAttribPointer(position_loc, 2, GL_FLOAT, GL_FALSE, 0, None)
    glEnableVertexAttribArray(position_loc)

    # Iniciar audio
    device_id = find_loopback_device() or sd.default.device['input']

    # Variables de estado
    current_amplitude = 0.0; beat_last_time = 0.0; beat_count = 0
    color_index = 0; pattern_index = 0; current_time = 0.0
    drop_positions = np.random.rand(10, 2).astype(np.float32)
    drop_times = np.zeros(10, dtype=np.float32)
    drop_index = 0

    # Bucle principal
    with sd.InputStream(device=device_id, channels=1, samplerate=SAMPLERATE,
                          blocksize=NUM_SAMPLES, callback=audio_callback):
        clock = pygame.time.Clock(); start_time = pygame.time.get_ticks()
        running = True
        while running:
            for event in pygame.event.get():
                if event.type == pygame.QUIT: running = False

            current_time = (pygame.time.get_ticks() - start_time) / 1000.0

            try:
                data = audio_queue.get_nowait()
                
                # Análisis de audio
                fft_data = np.abs(np.fft.rfft(data))
                fft_freqs = np.fft.rfftfreq(len(data), 1.0 / SAMPLERATE)
                bass_mask = (fft_freqs > BEAT_FREQ_RANGE[0]) & (fft_freqs < BEAT_FREQ_RANGE[1])
                bass_energy = np.sum(fft_data[bass_mask]) / np.sum(fft_data) if np.sum(fft_data) > 0 else 0

                if bass_energy > BEAT_THRESHOLD and (current_time - beat_last_time) > BEAT_COOLDOWN:
                    beat_last_time = current_time; beat_count += 1
                    color_index = (color_index + 1) % len(COLOR_PALETTE)
                    
                    rays_per_beat = 3
                    for i in range(rays_per_beat):
                        current_ray_index = (drop_index + i) % 10
                        drop_positions[current_ray_index] = np.random.rand(2)
                        drop_times[current_ray_index] = current_time
                    
                    drop_index = (drop_index + rays_per_beat) % 10

                    if beat_count >= SHAPE_CHANGE_BEATS:
                        beat_count = 0
                        # --- AJUSTE CLAVE ---
                        # Ahora rota entre 13 patrones (0 a 12)
                        pattern_index = (pattern_index + 1) % 13

                rms = np.sqrt(np.mean(data**2))
                current_amplitude = max(rms * SENSITIVITY, current_amplitude * DECAY_RATE)

            except queue.Empty:
                current_amplitude *= DECAY_RATE

            # Renderizado con OpenGL
            glClear(GL_COLOR_BUFFER_BIT); glUseProgram(shader_program)
            
            # Enviar uniforms al shader
            glUniform2f(glGetUniformLocation(shader_program, "u_resolution"), SCREEN_WIDTH, SCREEN_HEIGHT)
            glUniform1f(glGetUniformLocation(shader_program, "u_time"), current_time)
            glUniform1f(glGetUniformLocation(shader_program, "u_amplitude"), current_amplitude)
            glUniform3fv(glGetUniformLocation(shader_program, "u_base_color"), 1, COLOR_PALETTE[color_index])
            glUniform1i(glGetUniformLocation(shader_program, "u_pattern_index"), pattern_index)
            glUniform2fv(glGetUniformLocation(shader_program, "u_drops_pos"), 10, drop_positions)
            glUniform1fv(glGetUniformLocation(shader_program, "u_drops_time"), 10, drop_times)
            
            glDrawArrays(GL_QUADS, 0, 4); pygame.display.flip(); clock.tick(60)

    pygame.quit()

if __name__ == '__main__':
    main()