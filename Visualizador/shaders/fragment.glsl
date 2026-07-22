#version 120

uniform vec2 u_resolution;
uniform float u_time;
uniform vec3 u_base_color;
uniform float u_amplitude;
uniform int u_pattern_index;
uniform vec2 u_drops_pos[10];
uniform float u_drops_time[10];
uniform float u_smooth_amplitude;
uniform float u_bass;
uniform float u_mid;
uniform float u_treble;
uniform float u_beat_intensity;
uniform float u_last_beat_time;
uniform int u_prev_pattern_index;
uniform float u_transition_progress;
uniform float u_bloom_intensity;
uniform float u_vignette_intensity;
uniform float u_contrast;
uniform float u_saturation;
uniform float u_zoom;
uniform float u_reactive_time;

mat2 rotate2d(float angle) {
    return mat2(cos(angle), -sin(angle), sin(angle), cos(angle));
}

float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

float pattern_raindrops(vec2 uv, float time) {
    // 30.0, 20.0: Frecuencia del fondo | 0.5: Velocidad de animación | 0.03: Intensidad fondo
    float bg = sin(uv.x * 30.0 + time * 0.5) * cos(uv.y * 20.0 - time * 0.5) * 0.03;
    float wave = 0.0;
    for (int i = 0; i < 10; i++) {
        float t = time - u_drops_time[i];
        if (t > 0.0 && t < 4.0) { // 4.0: Duración de cada onda
            float d = distance(uv, u_drops_pos[i]);
            // 40.0: Frecuencia de ondas | 6.0: Velocidad expansión | 100.0: Atenuación distancia
            wave += sin(d * 40.0 - t * 6.0) * pow(1.0 - t / 6.0, 2.0) / (1.0 + d * d * 100.0);
        }
    }
    return bg + wave;
}

float pattern_tunnel(vec2 uv, float time) {
    vec2 p = 2.0 * uv - 1.0;
    p.x *= u_resolution.x / u_resolution.y;
    float r = length(p);
    float a = atan(p.y, p.x);
    a += 6.28318; // Evita corte visual en la discontinuidad angular
    // 0.2: Brillo del túnel | 9.0: Número de espirales | 5.0: Velocidad rotación | 10.0: Reacción bass
    // 30.0: Frecuencia anillos | 5.0: Velocidad anillos | 0.1, 0.5: Intensidades
    return 0.2 / r + sin(a * 9.0 + time * 5.0 + u_bass * 10.0) * 0.1 + cos(r * 30.0 - time * 5.0) * 0.5;
}

float pattern_cosmic_zoom(vec2 uv, float time, float amp) {
    vec2 p = 2.0 * uv - 1.0; p.x *= u_resolution.x / u_resolution.y;
    float r = length(p); float a = atan(p.y, p.x);
    // 20.0: Segmentación radial | 50.0: Reacción a música
    float glitch_factor = floor(r * 20.0 + amp * 50.0) / 20.0;
    float arms = 4.0; // 4.0: Número de brazos espirales
    // 5.0: Densidad espiral | 2.0: Velocidad rotación
    float spiral = sin(a * arms + glitch_factor * 5.0 - time * 2.0);
    float zoom = log(r);
    spiral *= cos(zoom * 5.0 - time); // 5.0: Intensidad zoom
    return spiral;
}

float pattern_wobble_grid(vec2 uv, float time, float amp) {
    vec2 d = uv;
    // 20.0: Frecuencia ondulación | 2.0, 1.5: Velocidades | 0.05: Amplitud distorsión
    d.x += sin(uv.y * 20.0 + time * 2.0) * 0.05 * amp;
    d.y += cos(uv.x * 20.0 + time * 1.5) * 0.05 * amp;
    // 20.0: Número de líneas | 10.0: Grosor de líneas (más alto = más delgadas)
    float lx = pow(abs(sin(d.x * 3.14159 * 20.0)), 10.0);
    float ly = pow(abs(sin(d.y * 3.14159 * 20.0)), 10.0);
    return 1.0 - max(lx, ly);
}

float pattern_glitchy_orb(vec2 uv, float time, float amp) {
    vec2 p = uv - 0.5;
    p.x *= u_resolution.x / u_resolution.y;
    float r = length(p);
    float a = atan(p.y, p.x);
    float rad = 0.35 + sin(a * 7.0 + time) * 0.02 - u_bass * 0.15;
    float core = 1.0 - smoothstep(rad, rad + 0.05, r);
    float bg = sin(p.x * 12.0 + time * 0.4 + u_mid * 2.0) * cos(p.y * 10.0 - time * 0.6 + u_bass * 3.0);
    bg = bg * 0.12 + 0.16;
    float rays = 0.0;
    for (int i = 0; i < 10; i++) {
        float t = time - u_drops_time[i];
        if (t > 0.0 && t < 4.0) {
            vec2 dir = normalize(u_drops_pos[i] - 0.5);
            float diff = abs(atan(p.y, p.x) - atan(dir.y, dir.x));
            diff = min(diff, 6.28318 - diff);
            rays += smoothstep(0.2, 0.0, diff) * pow(1.0 - t / 2.0, 3.0);
        }
    }
    return core + rays + bg;
}

float pattern_cube_lattice(vec2 uv, float time, float amp) {
    vec2 p = uv * 8.0;
    p = rotate2d(time * 0.5 + u_bass * 2.5) * (p - 4.0) + 4.0;
    vec2 grid = fract(p) - 0.5;
    grid = rotate2d(time * 0.8 + u_mid * 2.0) * grid;
    vec2 iso;
    iso.x = (grid.x - grid.y) * 0.866;
    iso.y = (grid.x + grid.y) * 0.5;
    float size = 0.25 + u_beat_intensity * 0.15;
    float cube = smoothstep(size, size - 0.02, max(abs(iso.x), abs(iso.y)));
    float glow = pow(1.0 - max(abs(iso.x), abs(iso.y)) / 0.5, 3.0) * u_treble * 0.5;
    return cube + glow;
}

float pattern_woven_fabric(vec2 uv, float time, float amp) {
    float dist = sin(uv.y * 10.0 + time * 0.5) * cos(uv.x * 10.0 + time * 0.5);
    vec2 d = uv + dist * amp * 0.5;
    return sin(d.x * 40.0) * cos(d.y * 40.0) + sin(d.x * 80.0 + time) * u_treble * 0.3;
}

float pattern_spinning_rose(vec2 uv, float time, float amp) {
    vec2 p = uv - 0.5;
    p.x *= u_resolution.x / u_resolution.y;
    float r = length(p);
    float a = atan(p.y, p.x);
    float pet = 6.0 + u_mid * 4.0;
    float swirl = sin(a * 18.0 + time * 1.1) * 0.08;
    float core = 0.32 + sin(time * 0.6 + u_bass * 2.0) * 0.04;
    float rad = core + 0.18 * cos(pet * a + time * 0.9) + swirl;
    float bloom = smoothstep(rad, rad - 0.08, r);
    float edge = smoothstep(rad + 0.02, rad - 0.02, r);
    float glow = pow(max(0.0, 1.0 - r / 0.65), 2.0) * (0.3 + u_treble * 0.7);
    float bg = sin(a * 6.0 + time * 0.4 + u_mid * 2.0) * cos(r * 12.0 - time * 0.6 + u_bass * 4.0);
    bg = bg * 0.15 + 0.2;
    float pulse = 1.0 + u_beat_intensity * 0.4;
    return (bloom * 0.8 + edge * 0.6 + glow * 0.5) * pulse + bg;
}

float pattern_flower_garden(vec2 uv, float time, float amp) {
    vec2 p = fract(uv * 5.0) - 0.5;
    float r = length(p);
    float a = atan(p.y, p.x);
    float pet = 5.0 + floor(u_bass * 10.0);
    float f = sin(a * pet + time) * 0.25 + 0.25;
    return smoothstep(f, f + 0.1, r) + smoothstep(0.1, 0.0, r) * u_mid;
}

float pattern_hex_nest(vec2 uv, float time, float amp) {
    vec2 p = (uv * 2.0 - 1.0) * 5.0;
    p.x *= u_resolution.x / u_resolution.y;
    p = rotate2d(time * 0.6 + u_bass * 2.0) * p;
    vec2 q = abs(p);
    return sin(max(q.x, dot(q, normalize(vec2(1.0, 1.73)))) * 5.0 - time * 4.0 + u_mid * 7.0);
}

float pattern_reactive_hex_grid(vec2 uv, float time, float amp) {
    vec2 p = uv - 0.5;
    p.x *= u_resolution.x / u_resolution.y;
    
    // Escala del suelo de la discoteca (baldosas cuadradas retro)
    float grid_scale = 10.0;
    vec2 grid_pos = p * grid_scale;
    vec2 tile_id = floor(grid_pos);
    vec2 q = fract(grid_pos) - 0.5;
    
    // 1. Efecto de relieve y bombilla interna para cada baldosa de cristal
    float dist_edge = max(abs(q.x), abs(q.y));
    
    // Bisel de la baldosa (líneas divisorias negras y limpias en los bordes)
    float bevel = smoothstep(0.48, 0.40, dist_edge);
    
    // Destello de la bombilla central debajo del cristal
    float bulb = exp(-dot(q, q) * 15.0) * 0.45;
    float tile_surface = (0.55 + bulb) * bevel;
    
    // 2. Alternancia de tablero de ajedrez retro (Checkered Pattern)
    float checker = mod(tile_id.x + tile_id.y, 2.0);
    
    // Parpadeo alternante rápido que acelera con los bajos (Bass)
    float blink_speed = 3.5 + u_bass * 4.0;
    float blink = sin(time * blink_speed + checker * 3.14159) * 0.35 + 0.65;
    
    // 3. Parpadeo sutil individual y asíncrono para dar realismo a los paneles
    float tile_random = random(tile_id);
    float tile_flicker = sin(time * 2.0 + tile_random * 6.2831) * 0.15 + 0.85;
    
    // 4. Onda reactiva del Beat (anillo de luz brillante que viaja por la pista)
    float pulse = time - u_drops_time[0];
    float wave_dist = abs(length(p) - pulse * 1.3);
    float beat_ring = smoothstep(0.35, 0.0, wave_dist) * u_beat_intensity * 0.55;
    
    // 5. Brillo base del suelo combinando el volumen de la música
    float ambient_glow = 0.20 + u_amplitude * 0.40;
    
    // 6. Mezcla de brillo total
    float brightness = ambient_glow * blink * tile_flicker + beat_ring;
    
    // Capamos el brillo para evitar que se sature al 100% y se pierdan las baldosas
    brightness = min(brightness, 0.86);
    
    // Combinamos la iluminación con la textura de la baldosa
    return tile_surface * brightness;
}

float pattern_kaleidoscope(vec2 uv, float time, float amp) {
    vec2 p = uv - 0.5;
    p = rotate2d(time * 0.3 + u_bass * 1.5) * p;
    p = abs(p);
    p = rotate2d(0.785398) * p;
    p = abs(p);
    float c = length(p - 0.2);
    float b = max(abs(p.x), abs(p.y));
    return sin(c * 20.0 + b * 10.0 - time * 4.0 + u_mid * 5.0);
}

float pattern_mixed_glitch(vec2 uv, float time, float amp) {
    float beat_push = smoothstep(0.15, 0.9, u_bass);
    float tilt = (beat_push + u_beat_intensity * 0.35) * 0.45;
    vec2 d = uv - 0.5;
    d = rotate2d(tilt) * d;
    d += 0.5;
    float g = fract(floor(d.y * 18.0 + time * 2.5) / 18.0);
    d.x += (g - 0.5) * (0.18 + beat_push * 0.25);
    d.y += sin(time * 0.6 + u_mid * 2.0) * 0.01;

    float r = sin(d.x * 24.0 + time * 1.6 + beat_push * 2.0) * 0.5 + 0.5;
    float gr = sin(d.x * 25.0 + time * 1.7 + beat_push * 2.2) * 0.5 + 0.5;
    float flicker = sin(uv.y * 220.0 + time * 14.0 + u_treble * 8.0) * 0.08;
    float scan = smoothstep(0.9, 0.95, fract(uv.y * 6.0 + time * 0.4));

    return r * gr + flicker + scan * 0.15 + u_treble * 0.35;
}

float pattern_dancing_triangles(vec2 uv, float time, float amp) {
    vec2 p = uv * 12.0;
    p = rotate2d(time * 0.3 + u_bass * 1.5) * (p - 6.0) + 6.0;
    vec2 grid = fract(p) - 0.5;
    float angle = time * 2.0 + length(floor(p)) + u_beat_intensity * 6.0;
    grid = rotate2d(angle) * grid;
    float tri = max(abs(grid.x) * 1.732 + grid.y, -grid.y);
    float size = 0.35 + sin(length(floor(p)) + time * 3.0 + u_mid * 5.0) * 0.15;
    float shape = smoothstep(size, size - 0.05, tri);
    float pulse = pow(1.0 - tri / 0.5, 2.0) * u_treble * 0.3;
    return shape + pulse;
}

float pattern_explosion_field(vec2 uv, float time) {
    float ex = 0.0;
    for (int i = 0; i < 10; i++) {
        float t = time - u_drops_time[i];
        if (t > 0.0 && t < 1.5) {
            float d = distance(uv, u_drops_pos[i]);
            float rad = t * 0.9;
            ex += smoothstep(rad, rad - 0.1, d) * pow(1.0 - t / 1.5, 2.0);
        }
    }
    
    // Fondo muy tenue pero visible a través de los filtros de contraste del visualizador
    // Rango de brillo de 5.5% a 9.5% según el volumen (suficiente para no ser tapado por el contraste)
    float waves = sin(uv.x * 2.0 + time * 0.15) * cos(uv.y * 2.0 - time * 0.1) * 0.5 + 0.5;
    float background = waves * (0.055 + u_amplitude * 0.04);
    
    return ex + background;
}

// PATRÓN 15: Hiperimpulso Estelar
float pattern_star_hyperspace(vec2 uv, float time, float amp) {
    vec2 p = uv - 0.5;
    p.x *= u_resolution.x / u_resolution.y;
 
    // --- LÓGICA DE ROTACIÓN "EN SECO" ---
    float time_since_beat = time - u_drops_time[0];
    float spin_duration = 0.45;
    float spin_progress = clamp(time_since_beat / spin_duration, 0.0, 1.0);
    float spin_amount = (1.0 - pow(spin_progress, 3.0)) * 6.28318; 
    float base_angle = floor(u_drops_time[0] * 12.0); 
    float rotation_angle = base_angle + spin_amount;
    
    // Rotación principal (estrellas de frente)
    vec2 p_rot = rotate2d(rotation_angle) * p;
    
    // Rotación de fondo para efecto paralaje (giro lento en dirección opuesta)
    vec2 p_rot_bg = rotate2d(-rotation_angle * 0.35 + time * 0.04) * p;

    // --- EFECTO DE AVANCE HACIA ADELANTE (ZOOM ADELANTE Y BEAT BREATHING) ---
    // Aceleración reactiva en los beats
    float speed_fast = time * 0.08 + amp * 3.5 + u_beat_intensity * 0.4;
    float speed_slow = time * 0.03 + amp * 1.5 + u_beat_intensity * 0.15;
    
    // Rango de z para que las estrellas empiecen más cerca (evita puntos microscópicos en el centro)
    float z_min = 0.35;
    float z_max = 1.15;

    // --- CAPA 1: Estrellas de Frente (Rápidas y Estiradas por Velocidad) ---
    float stars_fast_total = 0.0;
    float radial_density = max(5.0, 15.0 - u_bass * 8.0);
    
    for (int i = 0; i < 3; i++) {
        float f_fast = fract(speed_fast * 0.12 + float(i) / 3.0);
        float z_fast = f_fast * (z_max - z_min) + z_min + u_bass * 0.08;
        
        vec2 uv_fast = p_rot / z_fast;
        float r_fast = length(uv_fast);
        float a_fast = atan(uv_fast.y, uv_fast.x);
        
        float stars_fast = random(vec2(floor(a_fast * 24.0), floor(r_fast * radial_density)));
        stars_fast = pow(stars_fast, 15.0) * 1.6;
        
        // Desvanecimiento suave en el inicio/final del bucle para que sea infinito/continuo
        float slice_fade = smoothstep(0.0, 0.2, f_fast) * smoothstep(1.0, 0.8, f_fast);
        float stretch_fast = slice_fade * smoothstep(1.0, 0.75, r_fast);
        
        stars_fast_total += stars_fast * stretch_fast;
    }

    // --- CAPA 2: Estrellas de Fondo (Lentas y Densas) ---
    float stars_slow_total = 0.0;
    
    for (int i = 0; i < 3; i++) {
        float f_slow = fract(speed_slow * 0.10 + float(i) / 3.0);
        float z_slow = f_slow * (z_max - z_min) + z_min;
        
        vec2 uv_slow = p_rot_bg / z_slow;
        float r_slow = length(uv_slow);
        float a_slow = atan(uv_slow.y, uv_slow.x);
        
        float stars_slow = random(vec2(floor(a_slow * 48.0), floor(r_slow * 22.0)));
        stars_slow = pow(stars_slow, 20.0) * 0.7;
        
        // Desvanecimiento suave en el inicio/final del bucle para que sea infinito/continuo
        float slice_fade = smoothstep(0.0, 0.2, f_slow) * smoothstep(1.0, 0.8, f_slow);
        float stretch_slow = slice_fade * smoothstep(1.0, 0.75, r_slow);
        
        stars_slow_total += stars_slow * stretch_slow;
    }

    // --- GLOW CENTRAL Y REACCIÓN AL BASS ---
    float bass_boost = 1.0 + u_bass * 1.3 + u_beat_intensity * 0.7;
    float core_glow = exp(-length(p) * 6.5) * (0.12 + u_beat_intensity * 0.35);
    
    // Combinación de ambas capas
    float intensity = (stars_slow_total * 0.45) + (stars_fast_total * bass_boost) + core_glow;
    
    return intensity;
}

float pattern_wave_distortion(vec2 uv, float time, float amp) {
    vec2 d = uv;
    // 8.0, 6.0: Frecuencias de onda | 3.0, 2.0: Velocidades | 10.0, 8.0: Reacción bass/mid | 0.1: Amplitud distorsión
    d.x += sin(uv.y * 8.0 + time * 3.0 + u_bass * 10.0) * 0.1 * amp;
    d.y += cos(uv.x * 6.0 + time * 2.0 + u_mid * 8.0) * 0.1 * amp;
    // 20.0: Densidad del patrón | 15.0: Densidad diagonal | 2.0: Velocidad | 5.0: Reacción treble
    float pattern1 = sin(d.x * 20.0 + time) * cos(d.y * 20.0 - time);
    float pattern2 = sin((d.x + d.y) * 15.0 - time * 2.0 + u_treble * 5.0);
    return (pattern1 + pattern2) * 0.5 + 0.5;
}

float pattern_circular_waves(vec2 uv, float time, float amp) {
    vec2 p = uv - 0.5;
    p.x *= u_resolution.x / u_resolution.y;
    float r = length(p);
    float a = atan(p.y, p.x);
    // 30.0: Frecuencia ondas circulares | 5.0: Velocidad | 15.0: Reacción bass
    float waves = sin(r * 30.0 - time * 5.0 + u_bass * 15.0) * 0.5 + 0.5;
    // 8.0: Brazos espiral | 10.0: Densidad radial | 3.0: Velocidad | 7.0: Reacción mid
    float spiral = sin(a * 8.0 + r * 10.0 - time * 3.0 + u_mid * 7.0) * 0.5 + 0.5;
    // 5.0: Frecuencia pulsos | 2.0: Velocidad pulsos
    float pulse = pow(sin(r * 5.0 - time * 2.0) * 0.5 + 0.5, 2.0) * u_beat_intensity;
    return waves * spiral + pulse;
}

float pattern_plasma_flow(vec2 uv, float time, float amp) {
    vec2 p = uv * 3.0; // 3.0: Escala general del plasma
    float plasma = 0.0;
    // 4.0, 3.0, 2.0: Frecuencias de capas | 2.0, 1.5, 3.0: Velocidades | 5.0, 4.0, 6.0: Reacciones a frecuencias
    plasma += sin(p.x * 4.0 + time * 2.0 + u_bass * 5.0);
    plasma += sin(p.y * 3.0 - time * 1.5 + u_mid * 4.0);
    plasma += sin((p.x + p.y) * 2.0 + time * 3.0 + u_treble * 6.0);
    // 5.0: Frecuencia capa circular | 2.5: Velocidad | 8.0: Reacción a amplitud
    plasma += cos(length(p - 1.5) * 5.0 - time * 2.5 + amp * 8.0);
    return plasma * 0.25 + 0.5; // 0.25: Contraste
}

float pattern_morphing_tiles(vec2 uv, float time, float amp) {
    // 1. Dinámica de rejilla que respira y rota con el ritmo
    float density = 8.0 - u_bass * 1.5;
    vec2 p = uv - 0.5;
    p.x *= u_resolution.x / u_resolution.y;
    
    // Rotación suave del plano que acelera con el beat
    float grid_angle = time * 0.08 + u_bass * 0.5 + u_beat_intensity * 0.25;
    p = rotate2d(grid_angle) * p;
    
    vec2 grid_pos = p * density;
    vec2 tile_id = floor(grid_pos);
    vec2 grid = fract(grid_pos) - 0.5;
    
    // 2. Rotación interna individual de cada baldosa reactiva
    float tile_random = random(tile_id);
    float tile_angle = sin(time * 0.8 + tile_random * 6.28) * 0.25 + u_mid * 0.8;
    grid = rotate2d(tile_angle) * grid;
    
    // 3. Distancias para las formas (Cuadrado, Círculo, Diamante)
    float d_square = max(abs(grid.x), abs(grid.y));
    float d_circle = length(grid);
    float d_diamond = abs(grid.x) + abs(grid.y);
    
    // 4. Ciclo de metamorfosis (Morphing) reactivo al ritmo
    // Transiciona suavemente: Cuadrado -> Círculo -> Diamante -> Cuadrado
    float morph_time = time * 0.5 + u_bass * 0.6;
    float morph_phase = mod(morph_time, 3.0);
    float dist = 0.0;
    
    if (morph_phase < 1.0) {
        dist = mix(d_square, d_circle, smoothstep(0.0, 1.0, fract(morph_phase)));
    } else if (morph_phase < 2.0) {
        dist = mix(d_circle, d_diamond, smoothstep(0.0, 1.0, fract(morph_phase)));
    } else {
        dist = mix(d_diamond, d_square, smoothstep(0.0, 1.0, fract(morph_phase)));
    }
    
    // 5. Sombreado 3D falso (Phong/Biselado)
    // Calculamos la normal en base a la distancia al centro de la baldosa
    vec2 grad = normalize(grid + vec2(1e-5)) * dist;
    vec3 normal = normalize(vec3(-grad * 2.2, 0.45)); // 0.45 controla el relieve
    
    // Iluminación
    vec3 light_dir = normalize(vec3(0.5, 0.5, 0.8)); // Dirección de la luz
    float diffuse = max(dot(normal, light_dir), 0.0);
    
    vec3 view_dir = vec3(0.0, 0.0, 1.0);
    vec3 reflect_dir = reflect(-light_dir, normal);
    float specular = pow(max(dot(reflect_dir, view_dir), 0.0), 12.0) * 0.5;
    float fresnel = pow(1.0 - max(dot(normal, view_dir), 0.0), 3.0) * 0.35;
    
    // Máscara de baldosa con bisel limpio en los bordes
    float tile_mask = smoothstep(0.46, 0.38, dist);
    
    // 6. Onda de luz propagándose desde el centro
    float dist_center = length(uv - 0.5);
    float wave = sin(dist_center * 10.0 - time * 3.5 + u_bass * 4.0) * 0.4 + 0.6;
    
    // Reactividad general y mezcla
    float brightness = (diffuse * 0.75 + specular + fresnel) * wave * (0.6 + u_beat_intensity * 0.5);
    
    // Asegurar bordes oscuros limpios y limitar el brillo máximo
    float intensity = tile_mask * brightness;
    
    return min(intensity, 0.88);
}

float pattern_liquid_metal(vec2 uv, float time, float amp) {
    vec2 p = (uv - 0.5) * 3.0;
    p.x *= u_resolution.x / u_resolution.y;
    float liquid = 0.0;
    
    // Generamos dos semillas pseudoaleatorias usando el tiempo del último beat.
    // Esto hace que la estructura cambie aleatoriamente en cada golpe de ritmo,
    // variando la simetría y el tamaño de los círculos para evitar repeticiones.
    float beat_rand = fract(sin(u_last_beat_time * 43.13) * 927.43);
    float beat_rand2 = fract(sin(u_last_beat_time * 91.71) * 314.15);
    
    for (int i = 0; i < 4; i++) {
        float fi = float(i);
        
        // Introducemos una ligera asimetría angular aleatoria en cada beat para deformar las órbitas
        float angle = (time * 0.45 + u_mid * 0.4) + fi * 1.57079 + (fi * (beat_rand - 0.5) * 0.18);
        
        // Modulamos aleatoriamente el radio base con el beat para que el tamaño cambie dinámicamente
        float base_radius = 0.65 + beat_rand2 * 0.25;
        float radius = base_radius + u_bass * 0.40;
        vec2 offset = vec2(cos(angle), sin(angle)) * radius;
        
        // Plegado de espacio fractal (fractal space folding)
        p = abs(p) / dot(p, p) - offset;
        
        // Rotación interna reactiva para dar dinamismo a las órbitas
        p = rotate2d(time * 0.22 + fi * 0.8 + u_mid * 0.6) * p;
        
        liquid += length(p) * (0.3 + u_beat_intensity * 0.2);
    }
    
    // Hacemos el efecto mucho más limpio (sharper) aplicando una potencia alta
    // a la oscilación, reduciendo el degradado ancho (blur/haz) a líneas finas y nítidas
    float rings = sin(liquid * 1.8 + time * 2.0 + u_treble * 3.0) * 0.5 + 0.5;
    return pow(rings, 5.0);
}

float pattern_electric_storm(vec2 uv, float time, float amp) {
    vec2 p = uv * 6.0;
    float storm = 0.0;
    for (int i = 0; i < 3; i++) {
        float fi = float(i);
        float wave1 = sin(p.x * (2.0 + fi) + sin(p.y * (3.0 + fi) + time * (2.0 + fi * 0.5) + u_bass * 6.0) * 2.0);
        float wave2 = cos(p.y * (2.5 + fi) + cos(p.x * (2.0 + fi) - time * (1.5 + fi * 0.3) + u_mid * 5.0) * 2.0);
        storm += (wave1 + wave2) / (fi + 2.0);
    }
    float bolts = sin(p.x * 80.0 + time * 15.0) * sin(p.y * 80.0 - time * 15.0);
    bolts = pow(max(bolts, 0.0), 10.0) * u_beat_intensity * 3.0;
    float energy = sin(length(p) * 5.0 - time * 3.0 + u_treble * 8.0) * 0.3;
    return (storm * 0.3 + 0.5) + bolts + energy;
}

float pattern_hypnotic_spiral(vec2 uv, float time, float amp) {
    vec2 p = uv - 0.5;
    p.x *= u_resolution.x / u_resolution.y;
    float r = length(p);
    float a = atan(p.y, p.x);
    // 5.0: Brazos espiral | 20.0: Densidad radial | 4.0: Velocidad rotación | 12.0: Reacción bass
    float spiral = sin(a * 5.0 + r * 20.0 - time * 4.0 - u_bass * 12.0);
    // 30.0: Frecuencia anillos | 3.0: Velocidad anillos | 8.0: Reacción mid
    float rings = sin(r * 30.0 - time * 3.0 + u_mid * 8.0);
    // 10.0: Frecuencia pulsos radiales | 0.5: Intensidad pulsos
    float pulse = 1.0 + u_beat_intensity * sin(r * 10.0) * 0.5;
    return (spiral * rings) * pulse * 0.5 + 0.5;
}

float pattern_matrix_rain(vec2 uv, float time, float amp) {
    vec2 p = uv * vec2(40.0, 50.0); // 40.0, 50.0: Densidad de columnas/filas
    float col = floor(p.x);
    float speed = 1.2 + u_bass * 1.5; // 1.2: Velocidad base | 1.5: Aceleración con bass
    float offset = sin(col * 3.0 + time * 0.5) * 10.0; // 3.0, 0.5: Variación entre columnas | 10.0: Amplitud offset
    float row = p.y + time * speed + offset;
    // 0.25: Espaciado gotas | 0.6, 0.0: Difuminado | 0.7: Reacción amplitud
    float drops = smoothstep(0.6, 0.0, fract(row * 0.25)) * (1.0 + amp * 0.7);
    // 0.6, 0.35, 0.15: Intensidades de trails
    float trail1 = smoothstep(1.0, 0.0, fract(row * 0.25 + 0.25)) * 0.6;
    float trail2 = smoothstep(1.0, 0.0, fract(row * 0.25 + 0.5)) * 0.35;
    float trail3 = smoothstep(1.0, 0.0, fract(row * 0.25 + 0.75)) * 0.15;
    // 0.95: Probabilidad glitch | 2.0: Frecuencia cambios | 2.5: Intensidad
    float glitch = step(0.95, random(vec2(col, floor(time * 2.0)))) * u_beat_intensity * 2.5;
    float flicker = sin(col * 5.0 + time * 20.0) * 0.03; // 5.0, 20.0: Parpadeo | 0.03: Intensidad
    float scan = sin(uv.y * 200.0 + time * 30.0) * 0.04; // 200.0: Frecuencia scan | 30.0: Velocidad | 0.04: Intensidad
    float grid = smoothstep(0.015, 0.0, fract(p.x)) * 0.15; // 0.015: Grosor líneas | 0.15: Brillo grid
    float highlight = smoothstep(0.9, 1.0, drops) * u_treble * 0.5; // 0.5: Intensidad highlights
    return drops + trail1 + trail2 + trail3 + glitch + flicker + scan + grid + highlight;
}

float pattern_geometric_dance(vec2 uv, float time, float amp) {
    vec2 p = uv * 6.0;
    p = rotate2d(time * 0.5 + u_bass * 2.0) * (p - 3.0) + 3.0;
    vec2 grid = fract(p) - 0.5;
    float shape = max(abs(grid.x), abs(grid.y));
    float morph = sin(time * 3.0 + length(p) + u_mid * 5.0) * 0.5 + 0.5;
    float size = 0.3 + morph * 0.2 + u_treble * 0.15;
    return smoothstep(size, size - 0.05, shape);
}

float pattern_aurora_flow(vec2 uv, float time, float amp) {
    vec2 p = uv;
    float flow = 0.0;
    for (int i = 0; i < 5; i++) {
        float fi = float(i);
        float wave = sin(p.x * (2.0 + fi * 0.5) + fi * 2.0 + time * (1.5 + fi * 0.4) + u_bass * 4.0);
        wave += cos(p.y * (1.5 + fi * 0.3) + fi * 1.5 - time * (1.2 + fi * 0.3) + u_mid * 3.0);
        p.y += wave * 0.08 * amp;
        p.x += sin(p.y * 3.0 + time + fi) * 0.05 * amp;
        float layer = sin(p.y * (6.0 + fi * 2.0) - time * 2.0 + fi * 1.5) * exp(-fi * 0.3);
        flow += layer;
    }
    float shimmer = sin(p.x * 50.0 + time * 10.0) * sin(p.y * 50.0 - time * 8.0) * u_treble * 0.2;
    return flow * 0.25 + 0.5 + shimmer;
}

float pattern_fractal_noise(vec2 uv, float time, float amp) {
    vec2 p = uv * 4.0;
    float noise = 0.0;
    float amplitude = 1.0;
    for (int i = 0; i < 5; i++) {
        noise += sin(p.x * amplitude + time + u_bass * 3.0) * cos(p.y * amplitude - time + u_mid * 3.0) / amplitude;
        p = rotate2d(0.5 + u_treble) * p * 2.0;
        amplitude *= 2.0;
    }
    return noise * 0.5 + 0.5;
}

float pattern_voronoi_cells(vec2 uv, float time, float amp) {
    vec2 p = uv * 8.0; // 8.0: Densidad de células
    vec2 i = floor(p);
    vec2 f = fract(p);
    float min_dist = 1.0;
    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {
            vec2 neighbor = vec2(float(x), float(y));
            // 2.0: Velocidad movimiento puntos | 3.0: Reacción bass/mid a posición
            vec2 point = 0.5 + 0.5 * sin(time * 2.0 + 6.2831 * random(i + neighbor) + vec2(u_bass * 3.0, u_mid * 3.0));
            float d = length(neighbor + point - f);
            min_dist = min(min_dist, d);
        }
    }
    // 0.5: Intensidad reacción a beats
    return smoothstep(0.0, 1.0, min_dist) * (1.0 + u_beat_intensity * 0.5);
}

float pattern_oscillating_bars(vec2 uv, float time, float amp) {
    // 1. Inicializar coordenadas deformadas
    vec2 deformed_uv = uv;
    
    // 2. Distorsiones de espacio localizadas (vórtices / pellizcos tridimensionales) en los puntos de golpeo (u_drops_pos)
    for (int i = 0; i < 6; i++) {
        float t = time - u_drops_time[i];
        if (t > 0.0 && t < 1.4) {
            vec2 drop_pos = u_drops_pos[i];
            vec2 delta = deformed_uv - drop_pos;
            float r = length(delta);
            
            // Decaimiento temporal suave
            float progress = t / 1.4;
            float decay = pow(1.0 - progress, 2.5);
            
            // Fuerza de distorsión reactiva
            float strength = (0.28 + u_beat_intensity * 0.22) * decay;
            
            // Área de influencia localizada
            float influence = exp(-r * 12.0);
            
            // Giro tipo vórtice (twist)
            float twist = strength * influence * 6.5;
            vec2 rotated = rotate2d(twist) * delta;
            
            // Pellizco gravitatorio hacia el centro del golpe (pinch)
            vec2 pinch = normalize(delta + vec2(1e-5)) * strength * influence * 0.06;
            
            deformed_uv = drop_pos + rotated - pinch;
        }
    }
    
    // 3. Distorsión ondulatoria global reactiva al bass
    float dist_center = length(deformed_uv - 0.5);
    if (dist_center > 0.001) {
        float wave = sin(dist_center * 7.5 - time * 3.5) * (0.01 + u_bass * 0.038);
        deformed_uv += normalize(deformed_uv - 0.5) * wave;
    }
    
    // 4. Desplazamiento reactivo de las líneas (lasers)
    float bass_shake = smoothstep(0.25, 0.8, u_bass);
    float offset1 = sin(time * 0.35 + u_bass * 1.5) * (0.08 + bass_shake * 0.18);
    float offset2 = cos(time * 0.4 + u_mid * 1.2) * (0.08 + bass_shake * 0.18);
    
    // 5. Moduladores de guiones sci-fi (efecto de flujo de datos viajando por la red)
    float h_dashes = smoothstep(-0.25, 0.25, sin(deformed_uv.x * 20.0 - time * 7.0)) * 0.35 + 0.65;
    float v_dashes = smoothstep(-0.25, 0.25, cos(deformed_uv.y * 18.0 + time * 6.0)) * 0.35 + 0.65;
    
    // 6. Parámetro de ancho de brillo reactivo a frecuencias medias y agudas (glow de neón)
    float glow_width = 0.065 + u_mid * 0.10 + u_treble * 0.07;
    float glow_mult = 0.22 + u_beat_intensity * 0.28;
    
    // --- LÍNEAS HORIZONTALES ---
    float d_horiz = abs(sin((deformed_uv.y + offset1) * 12.0 + time * 0.6 + u_treble * 2.0) - 0.5);
    float horiz_core = smoothstep(0.022, 0.0, d_horiz);
    float horiz_glow = smoothstep(glow_width, 0.0, d_horiz) * glow_mult;
    float horiz_laser = (horiz_core + horiz_glow) * h_dashes;
    
    // --- LÍNEAS VERTICALES ---
    float d_vert = abs(sin((deformed_uv.x + offset2) * 10.0 - time * 0.5 + u_bass * 2.0) - 0.5);
    float vert_core = smoothstep(0.022, 0.0, d_vert);
    float vert_glow = smoothstep(glow_width, 0.0, d_vert) * glow_mult;
    float vert_laser = (vert_core + vert_glow) * v_dashes;
    
    // --- LÍNEAS DIAGONALES ---
    vec2 diag = rotate2d(0.785398) * (deformed_uv - 0.5);
    float d_diag = abs(sin((diag.y - offset1) * 8.0 + time * 0.5 + u_mid * 1.5) - 0.5);
    float diag_core = smoothstep(0.022, 0.0, d_diag);
    float diag_glow = smoothstep(glow_width * 1.2, 0.0, d_diag) * glow_mult;
    float diag_laser = (diag_core + diag_glow) * 0.6;
    
    // Suma de lasers
    float bars = horiz_laser + vert_laser + diag_laser;
    
    // 7. Destellos neón adicionales en las intersecciones de la rejilla principal
    float intersections = horiz_laser * vert_laser;
    bars += intersections * (0.5 + u_beat_intensity * 0.8);
    
    // 8. Pulso de brillo y viñeteado reactivo a la música
    float pulse = (1.0 + sin(dist_center * 5.0 - time * 1.5) * 0.18) * (1.0 + u_beat_intensity * 0.45);
    
    return min(bars * pulse, 2.0);
}

float pattern_radial_burst(vec2 uv, float time, float amp) {
    // Escalar y centrar coordenadas a [-0.5, 0.5] y corregir aspect ratio
    vec2 p = uv - 0.5;
    p.x *= u_resolution.x / u_resolution.y;
    
    float r = length(p);
    float a = atan(p.y, p.x);
    
    // --- SIMETRÍA VERTICAL (BAJOS EN HORIZONTAL, RESTO ALREDEDOR) ---
    // Usamos pow(abs(sin(a)), 2.0) para que las frecuencias bajas (graves) se ensanchen angularmente
    // en el eje horizontal, haciendo que los rayos del bajo sean más "gorditos", anchos y prominentes.
    float shifted_a = a;
    float angle_norm = pow(abs(sin(shifted_a)), 2.0);
    
    // Muestrear de forma simétrica
    float fft_val = texture1D(u_fft_texture, angle_norm * 0.5).r;
    
    // --- RAYOS ESPIRALES GRANDES (BASS/BEATS) ---
    float ray_limit = 0.32 + fft_val * (0.6 + u_beat_intensity * 0.5);
    
    // Torsión radial en espiral reactiva a los graves y al tiempo
    float twist_factor = (3.5 + u_bass * 4.5) * sin(time * 0.4);
    float ray_angle = a - r * twist_factor;
    
    float num_rays = 28.0;
    float ray_pattern = sin(ray_angle * num_rays + time * 3.0) * 0.5 + 0.5;
    ray_pattern = pow(ray_pattern, 5.0); // Rayos muy afilados
    float rays = smoothstep(ray_limit, 0.05, r) * ray_pattern * (0.5 + u_amplitude * 2.0);
    
    // --- AGUJAS ELÉCTRICAS DE AGUDOS ---
    // Agujas finas, rápidas y densas en 360 grados que vibran fuertemente con u_treble
    float needle_pattern = sin(a * 75.0 - time * 15.0) * cos(a * 35.0 + time * 10.0) * 0.5 + 0.5;
    needle_pattern = pow(needle_pattern, 12.0) * u_treble * 1.5;
    float needles = smoothstep(0.48 + u_treble * 0.15, 0.05, r) * needle_pattern;
    
    // --- DOBLE ANILLO DE NEÓN ---
    // ANILLO INTERIOR (Reactivo al Bajo y FFT)
    // Subimos la ganancia base de graves a 3.5 para darles un protagonismo masivo en la horizontal,
    // y mantenemos el boost de medios/agudos en 8.0 para que sigan teniendo crestas gigantes.
    float freq_index = angle_norm * 0.5;
    float fft_boosted = fft_val * (3.5 + smoothstep(0.02, 0.5, freq_index) * 8.0);
    float inner_radius = 0.25 + fft_boosted * 0.32;
    float inner_circle_dist = abs(r - inner_radius);
    float inner_glow = 0.004 / (inner_circle_dist + 0.006) * (0.8 + u_bass * 0.6);
    
    // ANILLO EXTERIOR (Reactivo a Medios y Agudos)
    float outer_radius = 0.45 + u_mid * 0.12 + u_treble * 0.06;
    float outer_circle_dist = abs(r - outer_radius);
    float outer_glow = 0.0025 / (outer_circle_dist + 0.007) * (0.4 + u_treble * 1.2);
    
    // --- PARTÍCULAS EN ÓRBITA RÁPIDA (SPARKLES) ---
    float orbit_speed = 4.5 + u_treble * 3.0;
    float orbit_angle = a - time * orbit_speed;
    float sparkles = sin(orbit_angle * 6.0) * 0.5 + 0.5;
    sparkles = pow(sparkles, 38.0);
    
    float sparkle_ring = smoothstep(0.045, 0.0, abs(r - (outer_radius + 0.04)));
    float outer_sparkles = sparkles * sparkle_ring * (0.2 + u_treble * 2.5);
    
    // --- FONDO REACTIVO ---
    float background = 0.03 + u_bass * 0.06;
    
    // Combinar todo
    float result = rays + needles + inner_glow + outer_glow + outer_sparkles + background;
    return clamp(result, 0.0, 1.0);
}

float pattern_triangle_tessellation(vec2 uv, float time, float amp) {
    vec2 p = uv * 15.0;
    p = rotate2d(time * 0.2 + u_bass * 1.0) * (p - 7.5) + 7.5;
    p.y += mod(floor(p.x), 2.0) * 0.5;
    vec2 f = fract(p) - 0.5;
    float angle = time * 3.0 + length(floor(p)) * 0.5 + u_mid * 4.0;
    f = rotate2d(angle) * f;
    float tri = max(abs(f.x) * 1.732 + f.y, -f.y);
    float size = 0.35 + sin(length(floor(p)) * 0.8 + time * 2.0 + u_treble * 5.0) * 0.15;
    float shape = smoothstep(size, size - 0.05, tri);
    float glow = u_beat_intensity * exp(-tri * 4.0);
    float edge = smoothstep(0.02, 0.0, abs(tri - size)) * 0.5;
    return shape + glow + edge;
}

// PATRÓN 31: Túnel de Distorsión
float pattern_warp_tunnel(vec2 uv, float time, float amp) {
    vec2 p = uv - 0.5;
    p.x *= u_resolution.x / u_resolution.y;
    float r = length(p);
    float a = atan(p.y, p.x);

    // Factor digital segmentado en anillos concéntricos que pulsan con la amplitud general
    float glitch_factor = floor(r * (18.0 - u_bass * 6.0) + amp * 10.0) / 18.0;
    
    // El túnel fluye y avanza hacia adelante
    float depth = glitch_factor * 12.0 - time * 1.5 - u_mid * 2.0; 
    
    // Torsión espiral continua que se intensifica dinámicamente con los golpes de bajos
    float twist = sin(r * 5.0 - time * 1.0) * (0.8 + u_bass * 1.6);
    
    // Haces espirales del túnel
    float tunnel = sin(a * 6.0 + depth + twist);
    
    // Anillos concéntricos digitales que viajan a lo largo del túnel reactivos a agudos
    float rings = sin(glitch_factor * 24.0 - time * 2.0 - u_treble * 3.0) * 0.5 + 0.5;
    
    // Glow neón central en el punto ciego del túnel que late con el beat
    float center_glow = exp(-r * 7.5) * (0.15 + u_beat_intensity * 0.55);
    
    // Mezcla final de rejilla de túnel modulada por el bajo + destello central
    float intensity = (tunnel * 0.5 + 0.5) * rings * (0.7 + u_bass * 0.6) + center_glow;
    
    return clamp(intensity, 0.0, 1.0);
}

// PATRÓN 32: Sueños Pixelados (Versión LENTA Y MENOS EPILÉPTICA)
float pattern_pixelated_dreams(vec2 uv, float time, float amp) {
    float bass_pulse = smoothstep(0.15, 0.8, u_bass);
    float slow_time = time * 0.015;

    // 1. Tamaño de píxel reactivo y lento
    float pixelSize = 28.0 + sin(slow_time + u_bass * 1.5) * (6.0 + bass_pulse * 6.0);
    vec2 pixelated = floor(uv * pixelSize) / pixelSize;

    // 2. Patrones base (muy lentos)
    float pattern1 = sin(pixelated.x * 35.0 + slow_time * 0.6 + u_mid * 2.0);
    float pattern2 = cos(pixelated.y * 35.0 - slow_time * 0.5 + u_treble * 1.8);

    // 3. Combinación más suave
    float combined_pattern = pow(abs(pattern1 * pattern2), 4.0);

    // 4. Ruido que cambia con los bajos (pulsos)
    float noise_time = floor(time * (0.5 + bass_pulse * 3.0));
    float noise = random(pixelated + noise_time) * (0.2 + bass_pulse * 0.8);

    // 5. Rejilla de píxeles sutil
    float grid = (smoothstep(0.02, 0.0, fract(uv.x * pixelSize)) + smoothstep(0.02, 0.0, fract(uv.y * pixelSize))) * 0.04;

    // 6. Combinación final
    return (combined_pattern * 0.8 + noise * 0.6) * (0.9 + amp * 1.1) + grid;
}

float pattern_concentric_squares(vec2 uv, float time, float amp) {
    vec2 p = abs(uv - 0.5) * 2.0;
    p.x *= u_resolution.x / u_resolution.y;
    // 0.8: Velocidad rotación | 2.5: Reacción bass a rotación
    p = rotate2d(time * 0.8 + u_bass * 2.5) * p;
    float square = max(abs(p.x), abs(p.y));
    // 30.0: Frecuencia anillos | 4.0: Velocidad expansión | 8.0: Reacción mid
    float rings = sin(square * 30.0 - time * 4.0 + u_mid * 8.0) * 0.5 + 0.5;
    // 3.0: Exponente (mayor = esquinas más marcadas) | 0.3: Intensidad esquinas
    float corners = pow(square, 3.0) * u_beat_intensity;
    return rings + corners * 0.3;
}

float pattern_infinity_mirror(vec2 uv, float time, float amp) {
    vec2 p = uv - 0.5;
    p.x *= u_resolution.x / u_resolution.y;
    for (int i = 0; i < 4; i++) {
        p = abs(p) / dot(p, p) - vec2(0.8, 0.6);
        p = rotate2d(time * 0.3 + float(i) * 0.5 + u_bass * 1.5) * p;
    }
    float mirror = sin(length(p) * 5.0 + time * 2.0 + u_mid * 4.0);
    return mirror * 0.5 + 0.5 + u_beat_intensity * 0.2;
}

// PATRÓN 35: Ecualizador Estilizado - Centrado y Simétrico (Espejo Arriba/Abajo)
float pattern_equalizer(vec2 uv, float time, float amp) {
    float num_bars = 80.0; // Número de barras
    float bar_index = floor(uv.x * num_bars);
    float bar_fract = fract(uv.x * num_bars);
    
    // Posición normalizada de la barra en el rango [0, 1]
    float bar_pos = (bar_index + 0.5) / num_bars;

    // --- CADA BARRA REACCIONA SEGÚN SU POSICIÓN EN EL ESPECTRO ---
    // Interpolación suave: bass -> mid -> treble
    float height = 0.0;
    
    if (bar_pos < 0.5) {
        // Primera mitad: interpolar de bass a mid
        float t = bar_pos / 0.5; // 0 a 1
        height = mix(u_bass, u_mid, t);
    } else {
        // Segunda mitad: interpolar de mid a treble
        float t = (bar_pos - 0.5) / 0.5; // 0 a 1
        height = mix(u_mid, u_treble, t);
    }
    
    // --- NORMALIZACIÓN DINÁMICA DE BANDAS ---
    float max_band = max(max(u_bass, u_mid), u_treble);
    max_band = max(max_band, 0.15); // Límite inferior para evitar amplificar silencio
    
    // Normalizar la altura interpolada
    float normalized_height = height / max_band;
    
    // Ondulación MÁS SUAVE
    normalized_height += sin(time * 0.5 + bar_index * 0.3) * 0.008;
    normalized_height = clamp(normalized_height, 0.0, 1.0);
    
    // Exponencial para dar contraste
    float shape_val = pow(normalized_height, 1.25);
    
    // Escalar al rango de pantalla deseado
    float target_max = 0.42 + u_beat_intensity * 0.05;
    height = shape_val * target_max;

    // --- FONDO TEXTURIZADO SUTIL ---
    // 1. Rejilla digital muy fina que se desplaza lentamente
    vec2 grid_uv = uv + time * 0.015;
    float grid = sin(grid_uv.x * 60.0) * sin(grid_uv.y * 60.0);
    grid = smoothstep(0.98, 1.0, grid) * 0.035;
    
    // 2. Brillo central difuso reactivo al bajo (reacción de solo el 25%)
    float center_glow = exp(-abs(uv.y - 0.5) * 3.5) * 0.035 * (1.0 + u_bass * 0.25);
    
    // 3. Neblina/oleaje de fondo muy lento (reacción de solo el 20%)
    float waves = sin(uv.x * 3.0 + time * 0.1) * cos(uv.y * 2.5 - time * 0.08) * 0.5 + 0.5;
    float nebula = waves * 0.04 * (1.0 + u_amplitude * 0.2);
    
    float background = center_glow + grid + nebula;
    
    // --- CENTRO EN MITAD DE LA PANTALLA CON EFECTO ESPEJO ---
    float center = 0.5;
    float abs_distance = abs(uv.y - center);
    
    // Suavización de bordes para el ecualizador
    float bar_fill = smoothstep(height + 0.02, height - 0.02, abs_distance);
    
    // Gradiente del ecualizador
    float gradient = 0.15 + (1.0 - abs_distance / max(height, 0.01)) * 0.85;
    
    // Combinar ecualizador con fondo
    float result = mix(background, bar_fill * gradient, bar_fill);
    
    return result;
}


// PATRÓN 36: Pelo Cayendo (Falling Hair) - OPTIMIZADO
float pattern_falling_hair(vec2 uv, float time, float amp) {
    float hair = 0.0;
    // Número fijo de mechones (estable, sin bugs)
    float num_strands = 100.0;
    
    for (float i = 0.0; i < num_strands; i += 1.0) {
        // Posición horizontal de cada mechón
        float x_base = i / (num_strands);
        
        // Semilla única para cada mechón
        float strand_seed = random(vec2(x_base * 234.567, 789.123));
        
        // Velocidad de caída con MÁS VARIEDAD entre mechones
        // 0.03: velocidad base | 0.05: MAYOR variación (antes 0.03)
        float fall_speed = 0.03 + strand_seed * 0.05;
        
        // Tiempo de ciclo
        float cycle_time = time * fall_speed + strand_seed * 100.0;
        float y_progress = fract(cycle_time) * 1.5 - 0.3;
        
        // Longitud del mechón con MÁS VARIEDAD
        // 0.2: longitud base | 0.25: MAYOR variación (antes 0.15)
        float strand_length = 0.2 + strand_seed * 0.25;
        
        // Parámetros de curva con MÁS VARIEDAD
        // 2.5 + 3.5: MAYOR rango de frecuencias (antes 3.0 + 2.0)
        float wave_freq = 2.5 + strand_seed * 3.5;
        // 0.05 + 0.08: MAYOR rango de amplitudes (antes 0.07 + 0.03)
        float wave_amp = 0.05 + strand_seed * 0.08;
        // Ondula un POQUITO más con ritmo rápido (0.2 = muy sutil)
        wave_amp *= (1.0 + u_bass * 0.2);
        
        // Posición vertical relativa al mechón (0 = arriba, 1 = abajo)
        float y_top = 1.3 - y_progress;
        float y_bottom = y_top - strand_length;
        
        // Solo procesar si el mechón está cerca verticalmente
        if (uv.y < y_top + 0.02 && uv.y > y_bottom - 0.02) {
            // Normalizar posición vertical dentro del mechón (0-1)
            float t = (y_top - uv.y) / strand_length;
            t = clamp(t, 0.0, 1.0);
            
            // Calcular ondulación en este punto (con movimiento suave y constante)
            float wave_offset = sin(t * strand_length * wave_freq + time * 0.5 + strand_seed* 6.28)* wave_amp;
            
            // Posición X esperada del mechón en esta altura
            float expected_x = x_base + wave_offset;
            
            // Distancia horizontal al mechón
            float dist_x = abs(uv.x - expected_x);
            
            // Grosor (más fino en las puntas)
            float thickness = 0.004 * (1.0 - t*strand_seed * 1.1) * (1.0 + u_mid *strand_seed* 0.55);
            
            // Si estamos cerca del mechón
            if (dist_x < thickness) {
                // Intensidad basada en distancia
                float intensity = 1.0 - (dist_x / thickness);
                intensity = pow(intensity, 1.5); // Concentrar el brillo
                
                // Degradado a lo largo del mechón
                float length_fade = 1.0 - t * 0.6*u_bass;
                
                // Fade suave en inicio y fin
                float fade = smoothstep(0.0, 0.08, t) * smoothstep(1.0, 0.92, t);
                
                hair += intensity * length_fade * fade * 2.0;
            }
            
            // Brillo en la punta (solo si estamos cerca del final)
            if (t > 0.85) {
                float tip_dist = length(uv - vec2(expected_x, y_bottom));
                float tip_glow = smoothstep(0.015, 0.0, tip_dist) * u_beat_intensity * 1.5;
                hair += u_bass*tip_glow;
            }
        }
    }
    
    // --- FONDO DE CASCADA Y ONDULACIONES SUTIL ---
    // 1. Columnas verticales de luz que fluyen hacia abajo lentamente (cascada)
    float cols = sin(uv.x * 12.0 + sin(time * 0.3) * 0.5) * cos(uv.x * 6.0 - time * 0.1) * 0.5 + 0.5;
    float flow = sin(uv.y * 8.0 + time * 1.5 + cols * 2.0);
    float cascade = cols * (flow * 0.5 + 0.5) * 0.06;
    
    // 2. Ondulaciones circulares desde el centro reactivas al bajo
    float dist_center = length(uv - 0.5);
    float ripple = sin(dist_center * 16.0 - time * 1.2) * 0.5 + 0.5;
    float ripple_effect = ripple * 0.045 * (0.5 + u_bass * 1.0);
    
    // 3. Brillo de neblina reactiva suave
    float glow = (0.05 + u_amplitude * 0.08) * (1.0 - dist_center * 0.6);
    
    float background = cascade + ripple_effect + glow;
    
    // Combinar cabello con fondo
    float result = mix(background, hair, clamp(hair, 0.0, 1.0));
    
    return result;
}

// Auxiliar para hash estable en GPU (evita artefactos y agrupamientos por precisión de punto flotante)
float rising_smoke_hash(float p) {
    return fract(sin(p * 91.345) * 43758.5453123);
}

// Auxiliar para simular turbulencia de humo
float rising_smoke_noise(vec2 p, float t) {
    float n = sin(p.x * 4.0 + t * 1.5) * cos(p.y * 3.0 - t * 1.0) * 0.5;
    n += sin(p.x * 12.0 - t * 3.0) * cos(p.y * 9.0 + t * 2.0) * 0.25;
    n += sin(p.x * 28.0 + t * 6.0) * cos(p.y * 22.0 - t * 4.0) * 0.125;
    return n * 0.57 + 0.5;
}

// PATRÓN 37: Humo Ascendente - REACTIVO AL RITMO
float pattern_rising_smoke(vec2 uv, float time, float amp) {
    float smoke = 0.0;
    
    // Factor de volumen adaptativo: base muy baja para que desaparezca en silencio ("no q esten siempre")
    // y alta ganancia con música para reaccionar nítidamente al volumen
    float volume_factor = 0.04 + u_amplitude * 2.3;
    
    // Crear 12 columnas dinámicas
    for (float layer = 0.0; layer < 12.0; layer += 1.0) {
        
        // Fase de visibilidad temporal: ritmo de oscilación de la columna
        float pos_phase = time * 1.4 + layer * 1.7;
        
        // Cálculo del ciclo actual de reaparición
        // La columna cambia de posición solo cuando su visibilidad es exactamente 0
        float phase_normalized = (pos_phase - 4.712389) / 6.283185;
        float cycle = floor(phase_normalized);
        
        // Generar una posición X pseudoaleatoria única para este ciclo y columna
        // Evita que los grosores se agrupen y dispersa las columnas por toda la pantalla de forma aleatoria
        float seed = (layer + 1.0) * 17.3 + (cycle + 1.0) * 53.7;
        float rand_x = rising_smoke_hash(seed);
        float x_base = 0.08 + 0.84 * rand_x;
        
        // Añadir una deriva lateral muy suave y lenta
        x_base += sin(time * 0.05 + layer * 1.5) * 0.015;
        
        float rise_speed = 0.3;
        float thickness_mult = 0.05;
        float band_energy = 0.0;
        
        if (layer < 4.0) {
            // Bajos (Bass) -> Columnas anchas y lentas (gordas)
            rise_speed = 0.22 + layer * 0.02;
            band_energy = u_bass * 1.5 + u_beat_intensity * 0.4;
            thickness_mult = 0.045 * (0.8 + u_bass * 0.4);
        } else if (layer < 8.0) {
            // Medios (Mid) -> Columnas medianas y velocidad media (medios)
            rise_speed = 0.35 + (layer - 4.0) * 0.03;
            band_energy = u_mid * 1.8;
            thickness_mult = 0.028 * (0.8 + u_mid * 0.4);
        } else {
            // Agudos (Treble) -> Columnas muy finas y rápidas (delgadas)
            rise_speed = 0.55 + (layer - 8.0) * 0.05;
            band_energy = u_treble * 2.0;
            thickness_mult = 0.014 * (0.8 + u_treble * 0.4);
        }
        
        // Visibilidad de campana (sube y baja a 0 en los extremos del ciclo)
        float temp_visibility = sin(pos_phase) * 0.5 + 0.5;
        temp_visibility = pow(temp_visibility, 2.5); // Perfil más afilado y mayor tiempo apagada
        
        // Reactividad instantánea combinada con volumen general
        // Aplicamos una no-linealidad para silenciar ruidos y hacer que los golpes de música resalten más
        float reactivity = pow(band_energy, 1.25) * volume_factor * temp_visibility;
        
        // Ruido de distorsión de la columna: aumenta con la altura (uv.y)
        float noise_coord_x = uv.x * 2.0;
        float noise_coord_y = uv.y * 4.0 - time * rise_speed * 2.0;
        float noise_val = rising_smoke_noise(vec2(noise_coord_x, noise_coord_y), time * 1.2 + layer);
        
        // Distorsión del centro de la columna
        float distortion = (noise_val - 0.5) * 0.12 * uv.y;
        
        // Ondulación lateral general (más reactiva a medios/agudos para dar gracia)
        float sway = sin(uv.y * 3.5 - time * rise_speed * 3.0 + layer * 1.5) * (0.025 + u_mid * 0.03);
        
        float center_x = x_base + distortion + sway;
        
        // Distancia horizontal modificada
        float dist_x = abs(uv.x - center_x);
        
        // Dispersión horizontal de humo (se ensancha suavemente al subir)
        float dispersion = 0.6 + uv.y * 0.8;
        float smoke_radius = thickness_mult * dispersion;
        
        // Textura interna del humo para que no parezca un neón sólido
        float density_noise = rising_smoke_noise(uv * vec2(4.0, 10.0) + vec2(0.0, -time * rise_speed * 4.0), time * 2.0 + layer);
        float density = 0.45 + 0.55 * density_noise;
        
        // Forma Gaussiana de la columna
        float intensity = exp(-dist_x * dist_x / (smoke_radius * smoke_radius)) * density;
        
        // Desvanecimiento vertical clásico (el humo se disipa paulatinamente arriba, pero la columna es entera)
        float vertical_fade = 1.0 - uv.y * 0.45;
        
        // Opacidad final de la columna de humo
        float audio_intensity = reactivity * 28.0;
        intensity *= audio_intensity * vertical_fade;
        
        smoke += intensity * 1.6;
    }
    
    // --- FONDO DE VÓRTICE HIPNÓTICO ---
    vec2 bg_p = uv - 0.5;
    bg_p.x *= u_resolution.x / u_resolution.y;
    float bg_r = length(bg_p);
    float bg_a = atan(bg_p.y, bg_p.x);
    
    // Torsión espiral hipnótica que gira y reacciona al bajo
    float rot_speed = time * 0.35 + u_bass * 0.5;
    float spiral_twist = bg_r * 8.0 - rot_speed;
    
    // Brazos del vórtice
    float spiral = sin(bg_a * 3.0 + spiral_twist) * 0.5 + 0.5;
    
    // Textura de humo de fondo usando rising_smoke_noise
    vec2 fbm_uv = rotate2d(time * 0.04 + u_mid * 0.2) * bg_p;
    float cosmic_noise = rising_smoke_noise(fbm_uv * 4.0, time * 0.1);
    
    // Glow central del núcleo del vórtice reactivo al beat
    float center_glow = exp(-bg_r * 5.0) * (0.07 + u_beat_intensity * 0.1);
    
    // Mezcla final de neblina espiral
    float spiral_glow = spiral * cosmic_noise * 0.15 * (0.8 + u_amplitude * 0.7);
    float background = center_glow + spiral_glow + 0.045;
    
    float result = max(smoke, background);
    
    return clamp(result, 0.0, 1.0);
}

// PATRÓN 38: Confeti Cayendo
float pattern_confetti(vec2 uv, float time, float amp) {
    float confetti = 0.0;
    float num_pieces = 80.0; // Reducido para optimizar y dar mayor tamaño individual
    
    for (float i = 0.0; i < num_pieces; i += 1.0) {
        float x_base = i / num_pieces;
        float piece_seed = random(vec2(x_base * 456.789, 123.456));
        
        // Velocidad de caída reactiva más suave (reacción a graves reducida para evitar saltos bruscos)
        float fall_speed = 0.08 + piece_seed * 0.07;
        fall_speed *= (1.0 + u_bass * 0.25);
        
        float cycle_time = time * fall_speed + piece_seed * 10.0;
        float y_progress = fract(cycle_time);
        
        // Posición vertical (entra por arriba, sale por abajo)
        float y_pos = 1.2 - y_progress * 1.4;
        
        // Oscilación lateral dinámica reactiva a los graves (apenas oscila en partes calmadas)
        float sway_speed = 1.0 + piece_seed * 1.2;
        float sway_amp = 0.015 + u_bass * 0.045;
        float sway = sin(y_progress * 5.0 + time * sway_speed) * sway_amp;
        float x_pos = x_base + sway + u_mid * 0.015 * sin(time * 2.0 + piece_seed);
        
        // Coordenadas relativas corregidas por aspecto de pantalla
        vec2 local_p = uv - vec2(x_pos, y_pos);
        local_p.x *= u_resolution.x / u_resolution.y;
        
        // Rotación 2D reactiva a graves (gira despacio por defecto, acelera con los bombos)
        float rot_speed = (0.2 + u_bass * 1.4) * (1.0 + piece_seed * 0.5);
        float rot_angle = time * rot_speed + piece_seed * 6.28;
        vec2 rot_p = rotate2d(rot_angle) * local_p;
        
        // Simulación de volteo 3D (Tumbling) reactiva a graves (permanece plano por defecto, tambalea con bombos)
        float tumble_amp = 0.05 + u_bass * 0.55;
        float tumble = abs(sin(time * 1.2 + piece_seed * 8.0)) * tumble_amp + (1.0 - tumble_amp);
        rot_p.y /= tumble;
        
        // Dimensiones del papel de confeti (Aumentadas sustancialmente para mayor visibilidad)
        float size_x = 0.035 + piece_seed * 0.020;
        float size_y = 0.018 + piece_seed * 0.015;
        
        // Forma con bordes suaves (antialiasing adaptado)
        float dx = abs(rot_p.x);
        float dy = abs(rot_p.y);
        float shape = smoothstep(size_x, size_x - 0.004, dx) * smoothstep(size_y, size_y - 0.004, dy);
        
        // Destello / Glow reactivo a agudos suavizado y destello más lento
        float d_len = length(rot_p);
        float sparkle = exp(-d_len * 60.0) * (0.8 + u_treble * 0.8) * (0.5 + 0.5 * sin(time * 8.0 + piece_seed * 50.0));
        
        // Sumar brillo del papel + destello (reactividad al beat más templada para evitar parpadeos agresivos)
        float piece_val = shape * (2.2 + u_beat_intensity * 0.5) + sparkle * 1.2;
        
        confetti += piece_val;
    }
    
    // --- FONDO DE PANTALLA CIBERNÉTICA SUAVE ---
    vec2 bg_p = uv - 0.5;
    bg_p.x *= u_resolution.x / u_resolution.y;
    
    // 1. Rejilla flotante ondulada
    float bg_grid = sin(uv.x * 25.0 + sin(time * 0.2) * 2.0) * sin(uv.y * 25.0 + cos(time * 0.25) * 2.0);
    bg_grid = smoothstep(0.97, 1.0, abs(bg_grid)) * 0.035 * (1.0 + u_bass * 0.5);
    
    // 2. Ondas concéntricas de brillo central
    float r = length(bg_p);
    float ripple = sin(r * 20.0 - time * 0.8) * 0.5 + 0.5;
    float bg_glow = ripple * 0.04 * (1.0 + u_amplitude * 0.5) + exp(-r * 3.5) * 0.05;
    
    float background = bg_grid + bg_glow;
    
    float result = max(confetti, background);
    
    return clamp(result, 0.0, 1.0);
}

// PATRÓN 39: Estrellas Fugaces
float pattern_shooting_stars(vec2 uv, float time, float amp) {
    float stars = 0.0;
    float num_stars = 42.0;

    for (float i = 0.0; i < num_stars; i += 1.0) {
        float star_seed = random(vec2(i * 731.337, 119.531));

        float speed = 0.025 + star_seed * 0.05 + u_bass * 0.04;
        float base_progress = fract(time * speed + star_seed * 3.7);
        float beat_age = max(time - u_last_beat_time, 0.0);
        float beat_kick = exp(-beat_age * 8.0) * (0.08 + u_bass * 0.06);
        float progress = fract(base_progress + beat_kick);

        vec2 start = vec2(fract(star_seed * 17.3), 1.05 + star_seed * 0.2);
        vec2 dir = normalize(vec2(-0.35 + star_seed * 0.7, -1.0));
        float travel = 1.1 + star_seed * 0.8;
        vec2 star_pos = start + dir * progress * travel;

        float tail_len = 0.05 + star_seed * 0.08 + u_beat_intensity * 0.08;
        float tail_steps = 10.0;

        for (float t = 0.0; t < 10.0; t += 1.0) {
            float tail_offset = (t / tail_steps) * tail_len;
            vec2 tail_pos = star_pos - dir * tail_offset;

            float dist = length(uv - tail_pos);
            float tail_fade = 1.0 - t / tail_steps;
            float flicker = 0.85 + 0.15 * sin(time * 3.0 + star_seed * 6.28 + t);
            float glow = smoothstep(0.03, 0.0, dist) * tail_fade * 2.0;

            stars += glow * flicker * (1.2 + u_treble * 0.8);
        }
    }

    float twinkle = random(vec2(floor(uv.x * 110.0), floor(uv.y * 90.0)));
    twinkle = pow(twinkle, 13.0) * (0.55 + u_treble * 0.75);
    stars += twinkle;

    return stars;
}

// PATRÓN 40: Caleidoscopio de Cristales Fractales
float pattern_crystal_kaleidoscope(vec2 uv, float time, float amp) {
    vec2 p = uv - 0.5;
    p.x *= u_resolution.x / u_resolution.y;
    p *= 1.0 - u_bass * 0.15;
    for (int i = 0; i < 5; i++) {
        p = abs(p);
        float d2 = dot(p, p) + 0.001;
        p = p / d2 - vec2(0.55 + u_bass * 0.1, 0.75 + u_mid * 0.1);
        float angle = time * 0.25 + float(i) * 0.6 + u_treble * 1.2;
        p = rotate2d(angle) * p;
    }
    float crystal_x = abs(sin(p.x * 4.0 + time));
    float crystal_y = abs(cos(p.y * 4.0 - time));
    float val = smoothstep(0.12, 0.0, crystal_x * crystal_y);
    float glow = exp(-length(p) * 0.18) * 0.4;
    return val * (0.8 + u_beat_intensity * 0.6) + glow;
}

// PATRÓN 41: Vórtice Caleidoscópico Espiral
float pattern_spiral_kaleidoscope(vec2 uv, float time, float amp) {
    vec2 p = uv - 0.5;
    p.x *= u_resolution.x / u_resolution.y;
    
    // Rotación global reactiva al beat
    p = rotate2d(time * 0.12 + u_beat_intensity * 0.3) * p;
    
    // Zoom reactivo suave
    p *= 1.0 - u_bass * 0.12;
    
    float accum = 0.0;
    
    for (int i = 0; i < 5; i++) {
        // 1. Simetría hexagonal (6 sectores)
        float a = atan(p.y, p.x);
        float r = length(p);
        float sector = 3.14159 / 3.0; // 60 grados
        a = mod(a, sector) - (sector * 0.5);
        p = vec2(cos(a), sin(a)) * r;
        
        // 2. Desplazamiento simétrico reactivo al bajo
        p.x -= 0.35 + u_bass * 0.1;
        p = abs(p);
        
        // 3. Inversión de espejo infinito
        float d2 = dot(p, p) + 0.005;
        p = p / d2;
        
        // 4. Rotación helicoidal progresiva
        p = rotate2d(0.5 + float(i) * 0.4 + time * 0.2) * p;
        
        // Acumular trazos de coordenadas (genera el entramado sci-fi de líneas finas)
        accum += exp(-abs(p.x) * 1.5) + exp(-abs(p.y) * 1.5);
    }
    
    // Normalizar la acumulación de trazos
    accum /= 10.0;
    
    // Ondas concéntricas de energía líquida reactiva a los medios y agudos
    float ripples = sin(length(p) * 2.5 - time * 3.5 + u_mid * 4.0);
    ripples = smoothstep(0.12, 0.0, abs(ripples));
    
    // Combinación de la estructura del fractal con las ondas reactivas
    float final_intensity = accum * 0.65 + ripples * 0.55;
    
    // Brillo en los golpes de ritmo (beats)
    final_intensity *= (0.7 + u_beat_intensity * 0.8);
    
    // Glow central holográfico
    float center_glow = 0.18 / (length(uv - 0.5) + 0.25);
    
    return clamp(final_intensity + center_glow * 0.25, 0.0, 1.0);
}

// PATRÓN 42: Caleidoscopio de Hyper-Mirror Cósmico
float pattern_hypermirror_kaleidoscope(vec2 uv, float time, float amp) {
    vec2 p = uv - 0.5;
    p.x *= u_resolution.x / u_resolution.y;
    for (int i = 0; i < 5; i++) {
        p = rotate2d(time * 0.1 + float(i) * 1.2) * p;
        float d2 = dot(p, p) + 0.001;
        p = abs(p) / d2 - vec2(0.95 + u_bass * 0.15, 0.35 + u_treble * 0.15);
    }
    float r = length(p);
    float a = atan(p.y, p.x);
    float wave1 = sin(r * 8.0 + time * 2.5 + u_mid * 3.0);
    float wave2 = cos(a * 8.0 - time * 1.5 + u_bass * 2.0);
    float pattern = wave1 * wave2;
    float intensity = smoothstep(-0.2, 0.6, pattern) * (0.6 + u_beat_intensity * 0.6);
    float glow = 0.25 / (r + 0.4);
    return clamp(intensity + glow * 0.4, 0.0, 1.0);
}

// PATRÓN 43: Túnel de Log-Espiral Infinito Premium "Vórtice Dimensional"
float pattern_log_tunnel(vec2 uv, float time, float amp) {
    vec2 p = uv - 0.5;
    p.x *= u_resolution.x / u_resolution.y;
    
    // Rotación global impulsada por el tiempo reactivo
    float rot_angle = u_reactive_time * 0.15 + u_bass * 0.1;
    p = rotate2d(rot_angle) * p;
    
    float r = length(p);
    float a = atan(p.y, p.x);
    
    // Evitar log(0) indeterminado
    float r_safe = max(r, 0.0001);
    
    // Distorsión reactiva de coordenadas (Domain Warping)
    // El túnel se deforma y ondulea orgánicamente al ritmo de graves y medios
    float distort = sin(a * 5.0 + u_reactive_time * 2.0) * (0.05 + u_bass * 0.12) +
                    cos(a * 3.0 - u_reactive_time * 1.5) * (0.03 + u_mid * 0.08);
    
    // Coordenadas Log-Polares base con velocidad de avance acumulada (u_reactive_time)
    // Se añade un desplazamiento directo de bajos (u_bass * 0.35) para dar un efecto de rebote/pulsación elástica
    float log_r = log(r_safe) - u_reactive_time * 2.2 - u_bass * 0.35 + distort;
    
    // Torsión espiral reactiva según la profundidad
    float twist = sin(log_r * 0.45 + u_reactive_time * 0.8) * (0.4 + u_bass * 0.8);
    float angle1 = a + twist;
    float angle2 = a - twist * 0.7; // Contragiro para crear patrones de interferencia
    
    // 1. Rejillas de Neón Cruzadas (Espiral Doble)
    // Usamos dos espirales desfasadas para crear una cuadrícula romboidal infinita
    // Añadimos ondulación reactiva en las líneas (vibración como cuerdas de guitarra)
    float wave_ripple = sin(log_r * 8.0 - u_reactive_time * 5.0) * (0.05 + u_bass * 0.25);
    float grid1 = sin(log_r * 3.0 + angle1 * 4.0 + wave_ripple);
    float grid2 = sin(log_r * 2.0 - angle2 * 5.0 - wave_ripple);
    
    float lines1 = smoothstep(0.12 + u_treble * 0.08, 0.0, abs(grid1));
    float lines2 = smoothstep(0.12 + u_mid * 0.06, 0.0, abs(grid2));
    float lattice = max(lines1, lines2) * (0.45 + u_bass * 0.55);
    
    // 2. Anillos Pulsantes Volumétricos (Glow)
    // Anillos concéntricos de neón que explotan hacia el espectador
    float ring_val = sin(log_r * 4.0 - u_reactive_time * 4.0);
    float ring_glow = exp(-abs(ring_val) * (7.0 - u_bass * 4.0)); // Se ensancha y brilla con bajos
    float rings = ring_glow * (0.3 + u_beat_intensity * 0.7);
    
    // 3. Estrellas / Sparks voladoras (Polvo Cósmico en el túnel)
    // Partículas veloces generadas de forma procedural en el espacio log-polar
    vec2 star_uv = vec2(log_r * 3.5, (a + u_reactive_time * 0.2) * 8.0 / 3.14159);
    vec2 star_id = floor(star_uv);
    vec2 star_fract = fract(star_uv) - 0.5;
    
    // Hash pseudo-aleatorio para cada celda
    float h = fract(sin(dot(star_id, vec2(127.1, 311.7))) * 43758.5453123);
    
    // Dibujar estrellas en un 25% de las celdas
    float star_active = step(0.75, h);
    float star_pulse = sin(u_reactive_time * 4.0 + h * 6.283) * 0.4 + 0.6;
    float star_dist = length(star_fract);
    // El brillo/tamaño de las estrellas responde a los agudos (hi-hats)
    float star_glow = smoothstep(0.08 + u_treble * 0.15, 0.0, star_dist) * star_pulse * star_active;
    
    // 4. Portal central brillante (Vórtice / Agujero de gusano)
    // Un núcleo brillante de luz en el fondo del túnel
    float portal = exp(-r * 6.0) * (0.8 + u_beat_intensity * 1.8);
    
    // 5. Cintas helicoidales de barrido lateral (Ribbons)
    float ribbon = sin(a * 3.0 + log_r * 1.5 + u_reactive_time * 3.0) * 0.5 + 0.5;
    ribbon = pow(ribbon, 6.0) * (0.3 + u_mid * 0.7);
    
    // Niebla / Oscurecimiento atmosférico hacia el centro para dar profundidad
    float depth_fade = smoothstep(0.02, 0.75, r);
    
    // Mezcla de componentes
    float composition = lattice * 0.65 + rings * 0.5 + star_glow * 0.85 + portal * 0.9 + ribbon * 0.4;
    
    // Salida final escalada por el beat general de la música
    return clamp(composition * depth_fade * (1.0 + u_beat_intensity * 0.35), 0.0, 1.0);
}

// PATRÓN 44: Interferencia Moiré Premium "Lava Lamp de Neón"
float pattern_moire_interference(vec2 uv, float time, float amp) {
    vec2 p = uv - 0.5;
    p.x *= u_resolution.x / u_resolution.y;
    
    // 1. Escala reactiva global (efecto Zoom de Bombo)
    // El visual entero respira y hace zoom con el bajo
    float zoom_factor = 1.0 - u_bass * 0.25;
    vec2 p_zoomed = p * zoom_factor;
    
    // 2. Centros Orbitales con Rebote Violento (Beat Snap)
    // Los centros se repelen fuertemente en cada golpe de ritmo,
    // lo que hace que las franjas de interferencia se muevan rápidamente
    float separation = 0.05 + u_beat_intensity * 0.35 + u_bass * 0.15;
    vec2 center_a = vec2(sin(time * 0.8), cos(time * 0.5)) * separation;
    vec2 center_b = vec2(cos(time * 0.7), sin(time * 0.9)) * -separation;
    
    // 3. Deformación Líquida Reactiva (Domain Warping Dinámico)
    // En silencio es muy sutil, en los beats se ondula con gran fuerza
    float warp_intensity = 0.06 + u_bass * 0.25 + u_beat_intensity * 0.15;
    vec2 warp = vec2(
        sin(p_zoomed.y * 3.0 + time * 1.5) * 0.2,
        cos(p_zoomed.x * 3.0 - time * 1.2) * 0.2
    ) * warp_intensity;
    
    vec2 p_a = p_zoomed + warp - center_a;
    vec2 p_b = p_zoomed + warp - center_b;
    
    float dist_a = length(p_a);
    float dist_b = length(p_b);
    
    // 4. Modulación de Frecuencia por Beats (Compresión Radial)
    // En los beats las ondas se multiplican y aprietan, en silencio se dilatan
    float freq_a = 5.0 + u_bass * 8.0;
    float freq_b = 4.5 + u_mid * 6.0;
    
    // 5. Ondas base continuas
    float wave_a = sin(dist_a * freq_a - time * 2.5);
    float wave_b = sin(dist_b * freq_b + time * 2.0);
    
    // 6. Interferencia por ADICIÓN (crea bandas continuas gigantes)
    float sum_wave = (wave_a + wave_b) * 0.5;
    float moire_bands = abs(sum_wave);
    
    // Brillo de neón de las bandas modulado por los bajos
    float glow = smoothstep(0.08, 0.82, moire_bands) * (0.3 + u_bass * 0.7);
    
    // Envolvente Moiré de frecuencia ultra-baja (blobs de interferencia)
    float phase_diff = (dist_a * freq_a - time * 2.5) - (dist_b * freq_b + time * 2.0);
    float moire_envelope = cos(phase_diff) * 0.5 + 0.5;
    
    // Nubes volumétricas que se encienden con el ritmo general de la música
    float volumetric = pow(moire_envelope, 2.5) * (0.4 + u_amplitude * 1.2);
    
    // 7. Núcleos de luz explosivos en los centros (flashes con los beats)
    // El radio del núcleo se expande y su brillo estalla con los bajos
    float core_a = exp(-dist_a * (14.0 - u_bass * 7.0)) * (0.2 + u_bass * 1.8);
    float core_b = exp(-dist_b * (14.0 - u_bass * 7.0)) * (0.2 + u_bass * 1.8);
    
    float final_val = (glow * 0.65 + volumetric * 0.85) * (1.0 + u_beat_intensity * 0.4) + core_a + core_b;
    
    // Atenuación suave hacia los bordes de la pantalla
    float edge_fade = smoothstep(0.95, 0.2, length(p));
    
    return clamp(final_val * edge_fade, 0.0, 1.0);
}

// PATRÓN 45: Droste Feedback Recursivo Premium (100% Sin Costuras y Reactivo)
float pattern_droste_feedback(vec2 uv, float time, float amp) {
    vec2 p = uv - 0.5;
    p.x *= u_resolution.x / u_resolution.y;
    
    // Rotación global impulsada por el tiempo reactivo (lento en silencio, rápido en beats)
    p = rotate2d(u_reactive_time * 0.06) * p;
    
    // Convertir a coordenadas polares
    float r = length(p);
    float a = atan(p.y, p.x);
    
    // Evitar log(0) indeterminado
    float r_safe = max(r, 0.0001);
    float log_r = log(r_safe);
    
    // Constantes matemáticas para garantizar una Droste sin costuras (seam-free)
    // El número de brazos/espirales (arms) DEBE ser un entero
    float arms = 6.0; 
    
    // Modulación del rebote del zoom/escala por los bajos de la música
    float scale = 1.15 + u_bass * 0.45;
    
    // Torsión angular instantánea en los beats (efecto de sacudida/giro)
    float twist = u_bass * 0.25;
    
    // Mapeo Droste Periódico usando u_reactive_time para la velocidad de avance
    // (Avanza lento en silencio, se dispara a velocidad luz con los bombos)
    float u = log_r * scale + (a + twist) * (arms / 6.2831853) - u_reactive_time * 0.8;
    float v = (a + twist) * (arms / 6.2831853) - log_r * scale + u_reactive_time * 0.15;
    
    // Generar la repetición periódica de la rejilla
    vec2 cell = vec2(fract(u), fract(v));
    cell = abs(cell - 0.5) * 2.0;
    
    // Geometría interna (baldosas espirales redondeadas con relieve de neón)
    float val = sin(cell.x * 3.141592) * cos(cell.y * 3.141592);
    
    // Ancho de línea neón reactivo a los agudos (hi-hats)
    float lines = smoothstep(0.08 + u_treble * 0.12, 0.0, abs(val) - 0.015);
    
    // Iluminación interna de cada celda (efecto bombilla interna que pulsa con el volumen)
    float cell_glow = pow(max(0.0, val), 2.0) * u_amplitude * 0.7;
    
    // Brillo reactivo y glow volumétrico del núcleo central (explota con los bajos)
    float core_intensity = 3.2 - u_bass * 1.5;
    float glow = exp(-r * core_intensity) * (0.45 + u_bass * 1.85);
    float pulse = (0.75 + u_beat_intensity * 0.45);
    
    // Composición final
    float composition = lines * pulse + cell_glow + glow * 0.4;
    
    return clamp(composition, 0.0, 1.0);
}

// PATRÓN 46: Flujo de Plasma Líquido
float pattern_liquid_plasma(vec2 uv, float time, float amp) {
    vec2 p = uv - 0.5;
    p.x *= u_resolution.x / u_resolution.y;
    float time_scale = time * 0.6;
    vec2 q = vec2(
        sin(p.x * 3.0 + time_scale * 0.8) + cos(p.y * 2.0 + time_scale * 0.5),
        sin(p.y * 3.0 - time_scale * 0.7) + cos(p.x * 2.0 + time_scale * 0.9)
    ) * (0.6 + u_bass * 0.4);
    vec2 r = vec2(
        sin(p.x + q.x * 2.5 + time_scale * 1.2),
        cos(p.y + q.y * 2.5 - time_scale * 1.0)
    );
    float val = sin(length(p + r) * 5.0 - time_scale * 2.0 + u_mid * 3.0);
    val = val * 0.5 + 0.5;
    float ridges = pow(val, 4.0) * 1.5;
    float soft = val * 0.4;
    float final_plasma = ridges + soft;
    final_plasma *= (0.8 + u_beat_intensity * 0.5);
    return clamp(final_plasma, 0.0, 1.0);
}

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;
    uv = (uv - 0.5) / u_zoom + 0.5;
    float intensity = 0.0;

    if (u_pattern_index == 0)       intensity = pattern_raindrops(uv, u_time);
    else if (u_pattern_index == 1)  intensity = pattern_tunnel(uv, u_time);
    else if (u_pattern_index == 2)  intensity = pattern_cosmic_zoom(uv, u_time, u_amplitude);
    else if (u_pattern_index == 3)  intensity = pattern_wobble_grid(uv, u_time, u_amplitude);
    else if (u_pattern_index == 4)  intensity = pattern_glitchy_orb(uv, u_time, u_amplitude);
    else if (u_pattern_index == 5)  intensity = pattern_cube_lattice(uv, u_time, u_amplitude);
    else if (u_pattern_index == 6)  intensity = pattern_woven_fabric(uv, u_time, u_amplitude);
    else if (u_pattern_index == 7)  intensity = pattern_spinning_rose(uv, u_time, u_amplitude);
    else if (u_pattern_index == 8)  intensity = pattern_flower_garden(uv, u_time, u_amplitude);
    else if (u_pattern_index == 9)  intensity = pattern_hex_nest(uv, u_time, u_amplitude);
    else if (u_pattern_index == 10) intensity = pattern_reactive_hex_grid(uv, u_time, u_amplitude);
    else if (u_pattern_index == 11) intensity = pattern_kaleidoscope(uv, u_time, u_amplitude);
    else if (u_pattern_index == 12) intensity = pattern_mixed_glitch(uv, u_time, u_amplitude);
    else if (u_pattern_index == 13) intensity = pattern_dancing_triangles(uv, u_time, u_amplitude);
    else if (u_pattern_index == 14) intensity = pattern_explosion_field(uv, u_time);
    else if (u_pattern_index == 15) intensity = pattern_star_hyperspace(uv, u_time, u_amplitude);
    else if (u_pattern_index == 16) intensity = pattern_wave_distortion(uv, u_time, u_amplitude);
    else if (u_pattern_index == 17) intensity = pattern_circular_waves(uv, u_time, u_amplitude);
    else if (u_pattern_index == 18) intensity = pattern_plasma_flow(uv, u_time, u_amplitude);
    else if (u_pattern_index == 19) intensity = pattern_morphing_tiles(uv, u_time, u_amplitude);
    else if (u_pattern_index == 20) intensity = pattern_liquid_metal(uv, u_time, u_amplitude);
    else if (u_pattern_index == 21) intensity = pattern_electric_storm(uv, u_time, u_amplitude);
    else if (u_pattern_index == 22) intensity = pattern_hypnotic_spiral(uv, u_time, u_amplitude);
    else if (u_pattern_index == 23) intensity = pattern_matrix_rain(uv, u_time, u_amplitude);
    else if (u_pattern_index == 24) intensity = pattern_geometric_dance(uv, u_time, u_amplitude);
    else if (u_pattern_index == 25) intensity = pattern_aurora_flow(uv, u_time, u_amplitude);
    else if (u_pattern_index == 26) intensity = pattern_fractal_noise(uv, u_time, u_amplitude);
    else if (u_pattern_index == 27) intensity = pattern_voronoi_cells(uv, u_time, u_amplitude);
    else if (u_pattern_index == 28) intensity = pattern_oscillating_bars(uv, u_time, u_amplitude);
    else if (u_pattern_index == 29) intensity = pattern_radial_burst(uv, u_time, u_amplitude);
    else if (u_pattern_index == 30) intensity = pattern_triangle_tessellation(uv, u_time, u_amplitude);
    else if (u_pattern_index == 31) intensity = pattern_warp_tunnel(uv, u_time, u_amplitude);
    else if (u_pattern_index == 32) intensity = pattern_pixelated_dreams(uv, u_time, u_amplitude);
    else if (u_pattern_index == 33) intensity = pattern_concentric_squares(uv, u_time, u_amplitude);
    else if (u_pattern_index == 34) intensity = pattern_infinity_mirror(uv, u_time, u_amplitude);
    else if (u_pattern_index == 35) intensity = pattern_equalizer(uv, u_time, u_amplitude);
    else if (u_pattern_index == 36) intensity = pattern_falling_hair(uv, u_time, u_amplitude);
    else if (u_pattern_index == 37) intensity = pattern_rising_smoke(uv, u_time, u_amplitude);
    else if (u_pattern_index == 38) intensity = pattern_confetti(uv, u_time, u_amplitude);
    else if (u_pattern_index == 39) intensity = pattern_shooting_stars(uv, u_time, u_amplitude);
    else if (u_pattern_index == 40) intensity = pattern_crystal_kaleidoscope(uv, u_time, u_amplitude);
    else if (u_pattern_index == 41) intensity = pattern_spiral_kaleidoscope(uv, u_time, u_amplitude);
    else if (u_pattern_index == 42) intensity = pattern_hypermirror_kaleidoscope(uv, u_time, u_amplitude);
    else if (u_pattern_index == 43) intensity = pattern_log_tunnel(uv, u_time, u_amplitude);
    else if (u_pattern_index == 44) intensity = pattern_moire_interference(uv, u_time, u_amplitude);
    else if (u_pattern_index == 45) intensity = pattern_droste_feedback(uv, u_time, u_amplitude);
    else if (u_pattern_index == 46) intensity = pattern_liquid_plasma(uv, u_time, u_amplitude);

    vec3 bg = vec3(0.0, 0.0, 0.05);
    vec3 color = u_base_color * intensity * 1.5;
    
    color.r += u_treble * 0.3;
    color.g += u_mid * 0.3;
    color.b += u_bass * 0.3;
    
    vec3 final = bg + color;
    
    if (u_bloom_intensity > 0.0) {
        vec3 bright = max(final - 0.7, 0.0) * 2.0;
        final += bright * length(bright) * u_bloom_intensity;
    }
    
    if (u_vignette_intensity > 0.0) {
        float dist = length(uv - 0.5);
        float vig = smoothstep(0.8, 0.3, dist);
        vig = mix(1.0, vig, u_vignette_intensity);
        final *= vig;
    }
    
    final = clamp((final - 0.5) * u_contrast + 0.5, 0.0, 1.0);
    
    float lum = dot(final, vec3(0.299, 0.587, 0.114));
    final = mix(vec3(lum), final, u_saturation);
    
    final = clamp(final, 0.0, 1.0);
    
    gl_FragColor = vec4(final, 1.0);
}
