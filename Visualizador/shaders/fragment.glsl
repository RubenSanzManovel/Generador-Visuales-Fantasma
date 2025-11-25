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
uniform int u_prev_pattern_index;
uniform float u_transition_progress;
uniform float u_bloom_intensity;
uniform float u_vignette_intensity;
uniform float u_contrast;
uniform float u_saturation;

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
    return core + rays;
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
    float pet = 7.0 + u_mid * 3.0;
    float rad = 0.5 * cos(pet * a + time * 0.85) + sin(a * 80.0 + time) * u_treble * 0.5;
    return 1.0 - smoothstep(abs(rad), abs(rad) + 0.06, r);
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
    float pulse = time - u_drops_time[0];
    float ring = smoothstep(pulse * 1.5, pulse * 0.8 - 0.5, length(p));
    vec2 q = abs(fract(p * 10.0) - 0.5);
    return (1.0 - max(q.x * 0.866 + q.y * 0.5, q.y)) * ring * (1.0 + u_beat_intensity);
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
    float g = fract(floor(uv.y * 20.0 + time * 5.0) / 20.0);
    vec2 d = uv;
    d.x += (g - 0.5) * u_bass * 0.3;
    float r = sin(d.x * 30.0 + time * 2.0) * 0.5 + 0.5;
    float gr = sin(d.x * 31.0 + time * 2.1) * 0.5 + 0.5;
    return r * gr + sin(uv.y * 800.0 + time * 50.0) * 0.1 + u_treble * 0.5;
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
    return ex;
}

// PATRÓN 15: Hiperimpulso Estelar (Giro "en Seco" con Beat)
float pattern_star_hyperspace(vec2 uv, float time, float amp) {
    vec2 p = uv - 0.5;
    p.x *= u_resolution.x / u_resolution.y;

    // --- NUEVA LÓGICA DE ROTACIÓN "EN SECO" ---
    // 1. 'u_drops_time[0]' es el timestamp del último beat.
    float time_since_beat = time - u_drops_time[0];
    
    // 2. Definimos cuánto dura el giro (ej. 0.4 segundos).
    float spin_duration = 0.4; // 0.4: Duración del giro en segundos.
    
    // 3. 'spin_progress' va de 0.0 (justo en el beat) a 1.0 (0.4s después).
    float spin_progress = clamp(time_since_beat / spin_duration, 0.0, 1.0);
    
    // 4. Creamos una curva de "frenado". pow(..., 3.0) hace que frene más bruscamente al final.
    // 'spin_amount' es la cantidad total de rotación extra que se añade.
    // 6.28 = una vuelta completa (2*PI). Aumenta este número para más vueltas.
    float spin_amount = (1.0 - pow(spin_progress, 3.0)) * 6.28; 
    
    // 5. El ángulo base "salta" con cada beat (usando el timestamp como "semilla")
    // y le sumamos el giro extra que se frena.
    float base_angle = floor(u_drops_time[0] * 10.0); // Salto a una nueva posición.
    float rotation_angle = base_angle + spin_amount;
    
    p = rotate2d(rotation_angle) * p;

    // --- LÓGICA DE ZOOM (sin cambios) ---
    float speed = time * 0.05 + amp * 5.0;
    vec2 distorted_uv = p / (1.0 - fract(speed * 0.1));
    float r = length(distorted_uv);
    float a = atan(distorted_uv.y, distorted_uv.x);

    // --- LÓGICA DE ESTRELLAS (sin cambios) ---
    float stars = random(vec2(floor(a * 40.0), floor(r * 20.0)));
    stars = pow(stars, 50.0);
    float stretch = 1.0 - smoothstep(0.0, 0.5, r * (1.0 - amp * 0.9));
    
    return stars * stretch;
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
    vec2 p = uv * 8.0;
    p.x += sin(p.y * 2.0 + time + u_bass * 3.0) * 0.3 * amp;
    p.y += cos(p.x * 2.0 - time + u_mid * 3.0) * 0.3 * amp;
    vec2 grid = fract(p) - 0.5;
    float tile = max(abs(grid.x), abs(grid.y));
    float morph = sin(time * 2.0 + u_treble * 5.0) * 0.5 + 0.5;
    return smoothstep(0.4 - morph * 0.2, 0.35 - morph * 0.2, tile);
}

float pattern_liquid_metal(vec2 uv, float time, float amp) {
    vec2 p = (uv - 0.5) * 3.0;
    p.x *= u_resolution.x / u_resolution.y;
    float liquid = 0.0;
    for (int i = 0; i < 4; i++) {
        float fi = float(i);
        vec2 offset = vec2(sin(time * 0.8 + fi * 2.0) * 0.5, cos(time * 0.6 + fi * 1.5) * 0.5);
        p = abs(p) / dot(p, p) - offset * (0.8 + u_bass * 0.4);
        p = rotate2d(time * 0.3 + fi * 0.8 + u_mid * 1.5) * p;
        liquid += length(p) * (0.3 + u_beat_intensity * 0.3);
    }
    return sin(liquid * 1.5 + time * 2.0 + u_treble * 4.0) * 0.5 + 0.5;
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
    float bars = 0.0;
    float offset1 = sin(time * 1.2 + u_bass * 3.0) * 0.3;
    float offset2 = cos(time * 1.5 + u_mid * 3.0) * 0.3;
    bars += smoothstep(0.012, 0.0, abs(sin((uv.y + offset1) * 12.0 + time * 1.5 + u_treble * 4.0) - 0.5));
    bars += smoothstep(0.012, 0.0, abs(sin((uv.x + offset2) * 10.0 - time * 1.2 + u_bass * 4.0) - 0.5));
    vec2 diag = rotate2d(0.785398) * (uv - 0.5);
    bars += smoothstep(0.012, 0.0, abs(sin((diag.y - offset1) * 8.0 + time * 1.0 + u_mid * 3.0) - 0.5)) * 0.5;
    float pulse = (1.0 + sin(length(uv - 0.5) * 10.0 - time * 3.0) * 0.3) * (1.0 + u_beat_intensity * 0.5);
    return bars * pulse;
}

float pattern_radial_burst(vec2 uv, float time, float amp) {
    vec2 p = uv - 0.5;
    p.x *= u_resolution.x / u_resolution.y;
    float r = length(p);
    float a = atan(p.y, p.x);
    // 16.0: Número de rayos | 2.0: Velocidad rotación | 8.0: Reacción bass
    float rays = sin(a * 16.0 + time * 2.0 + u_bass * 8.0) * 0.5 + 0.5;
    // 15.0: Frecuencia ondas radiales | 5.0: Velocidad | 10.0: Reacción mid
    float pulse = sin(r * 15.0 - time * 5.0 + u_mid * 10.0) * 0.5 + 0.5;
    // 0.8: Radio explosión | 2.0: Exponente (más alto = más concentrado en centro)
    float burst = pow(1.0 - smoothstep(0.0, 0.8, r), 2.0) * u_beat_intensity;
    return rays * pulse + burst;
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

// PATRÓN 31: Túnel de Distorsión (REACCIÓN DE MÚSICA REDUCIDA)
float pattern_warp_tunnel(vec2 uv, float time, float amp) {
    vec2 p = uv - 0.5;
    p.x *= u_resolution.x / u_resolution.y;
    float r = length(p);
    float a = atan(p.y, p.x);

    // Reacción al volumen reducida (de 40.0 a 5.0)
    float glitch_factor = floor(r * 20.0 + amp * 5.0) / 20.0; // Antes amp * 40.0
    
    // --- AJUSTE DE VELOCIDAD Y REACCIÓN ---
    // Mantenemos las velocidades de 'time' bajas
    
    // Reducimos la influencia de la música (u_mid)
    // Antes: u_mid * 2.0. Ahora: u_mid * 0.2
    float depth = glitch_factor * 5.0 + time * 0.03 + u_mid * 0.2; 
    
    // Reducimos la influencia de la música (u_bass)
    // Antes: u_bass * 4.0. Ahora: u_bass * 0.4
    float tunnel = sin(a * 8.0 + depth) * cos(glitch_factor * 20.0 - time * 0.04 + u_bass * 0.4);
    
    // Reducimos la influencia de la música (u_treble)
    // Antes: u_treble * 5.0. Ahora: u_treble * 0.5
    float rings = sin(glitch_factor * 30.0 - time * 0.06 + u_treble * 0.5) * 0.5 + 0.5;
    
    return (tunnel * 0.5 + 0.5) * rings;
}

// PATRÓN 32: Sueños Pixelados (Versión LENTA Y MENOS EPILÉPTICA)
float pattern_pixelated_dreams(vec2 uv, float time, float amp) {
    // 1. Tamaño de píxel reactivo (velocidad muy reducida)
    float pixelSize = 25.0 + sin(time * 0.02 + u_bass * 2.0) * 10.0; // Antes: time * 0.1
    vec2 pixelated = floor(uv * pixelSize) / pixelSize;

    // 2. Patrones base (velocidad muy reducida)
    float pattern1 = sin(pixelated.x * 40.0 + time * 0.05 + u_mid * 4.0); // Antes: time * 0.2
    float pattern2 = cos(pixelated.y * 40.0 - time * 0.03 + u_treble * 3.0); // Antes: time * 0.15
    
    // 3. Combinación de patrones para un efecto glitch más nítido
    float combined_pattern = pow(abs(pattern1 * pattern2), 5.0);
    
    // 4. Ruido aleatorio (velocidad DRÁSTICAMENTE reducida)
    // Este es el cambio principal. 'time * 0.1' hace que los píxeles cambien
    // 5 veces más lento que antes (que era 'time * 0.5').
    float noise = random(pixelated + floor(time * 0.01)) * u_beat_intensity * 0.5; // Antes: time * 0.5
    
    // 5. Rejilla de píxeles (la mantenemos muy sutil)
    float grid = (smoothstep(0.02, 0.0, fract(uv.x * pixelSize)) + smoothstep(0.02, 0.0, fract(uv.y * pixelSize))) * 0.05;

    // 6. Combinación final
    return (combined_pattern + noise) * amp * 2.0 + grid;
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

// PATRÓN 35: Ecualizador Estilizado (Sin "pared" y más bajo)
float pattern_equalizer(vec2 uv, float time, float amp) {
    float num_bars = 40.0; // 40.0: Número de barras.
    float bar_index = floor(uv.x * num_bars);
    float bar_x_normalized = bar_index / num_bars;

    // --- LÓGICA DE ALTURA ---
    float height = 0.0;
    if (bar_x_normalized < 0.4) {
        height = u_bass * (bar_x_normalized / 0.4);
    } else if (bar_x_normalized < 0.8) {
        height = mix(u_bass, u_mid, (bar_x_normalized - 0.4) / 0.4);
    } else {
        height = mix(u_mid, u_treble, (bar_x_normalized - 0.8) / 0.2);
    }
    height += sin(time * 2.0 + bar_index) * 0.02; // Ondulación base
    
    // --- AJUSTE CLAVE: Reducimos la sensibilidad general ---
    // Antes era (amp * 2.0 + u_beat_intensity * 0.5)
    // Ahora es la mitad, para que las barras no suban tanto.
    height *= (amp * 1.0 + u_beat_intensity * 0.3); // 1.0: Sensibilidad. 0.3: Salto con beat.

    // --- AJUSTE DE POSICIÓN (CON BASE, SIN TECHO) ---
    // 1. Definimos una base fija para que se vea la parte de abajo.
    float base_height = 0.05; // Las barras empiezan al 5% de la altura.
    
    // 2. La altura final es la base + la altura calculada.
    // Ya no hay 'max_height' ni 'clamp'. La altura es libre y natural.
    float final_bar_height = base_height + height;

    // 3. Dibujamos la barra SÓLO entre la base y la altura final.
    float top = smoothstep(final_bar_height - 0.01, final_bar_height, uv.y); // Borde suave arriba
    float bottom = smoothstep(base_height - 0.01, base_height, uv.y); // Borde suave abajo
    float bar_fill = bottom - top; // Relleno

    // 4. Ajustamos el degradado para que empiece en la base de la barra.
    float bar_relative_y = (uv.y - base_height) / (final_bar_height - base_height);
    float gradient = 0.3 + bar_relative_y * 0.7; // 0.3: Brillo base. 0.7: Intensidad del degradado.
    
    return bar_fill * gradient;
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
    
    return hair;
}

// PATRÓN 37: Humo Ascendente
float pattern_rising_smoke(vec2 uv, float time, float amp) {
    float smoke = 0.0;
    
    // Ruido base para textura de humo
    float noise1 = sin(uv.x * 10.0 + time * 0.5) * cos(uv.y * 8.0 - time * 0.3);
    float noise2 = sin(uv.x * 15.0 - time * 0.4) * cos(uv.y * 12.0 + time * 0.6);
    float turbulence = (noise1 + noise2) * 0.015;
    
    // Múltiples columnas de humo CONTINUAS con ciclos desfasados
    for (float i = 0.0; i < 20.0; i += 1.0) {
        float x_base = (i + 0.5) / 15.0;
        float col_seed = random(vec2(x_base * 567.89, 234.56));
        
        // Velocidad de subida variable
        float rise_speed = 0.06 + col_seed * 0.03;
        rise_speed *= (1.0 + u_mid * 0.3);
        
        // DESFASE ÚNICO para cada columna - CRUCIAL para evitar sincronización
        float time_offset = i * 7.5 + col_seed * 20.0;
        
        // Ciclo cada 2.5 unidades - MÁS LARGO para más continuidad
        float cycle_height = 2.5;
        float animated_time = (time + time_offset) * rise_speed;
        float y_base = mod(animated_time, cycle_height) - 0.3;
        
        // Calcular distancia vertical al píxel desde la base de este ciclo
        float y_from_base = uv.y - y_base;
        
        // El humo existe en una ventana de altura MÁS AMPLIA
        if (y_from_base > 0.0 && y_from_base < cycle_height) {
            // Progreso en el ciclo (0 = base, 1 = arriba)
            float progress = y_from_base / cycle_height;
            
            // Ondulación lateral (aumenta con altura)
            float sway_amount = progress * 0.1;
            float sway = sin(uv.y * 4.0 + time + col_seed * 6.28) * sway_amount;
            sway += cos(uv.y * 2.5 - time * 0.7 + col_seed * 3.14) * sway_amount * 0.6;
            
            // Posición X con turbulencia
            float x_pos = x_base + sway + turbulence;
            float dist_x = abs(uv.x - x_pos);
            
            // Grosor aumenta con la altura
            float width = 0.012 * (1.0 + progress * progress * 5.0);
            
            // Intensidad con distribución suave
            float intensity = exp(-dist_x * dist_x / (width * width * 0.5));
            
            // Fade: aparece suave abajo, desaparece suave arriba
            float fade = smoothstep(0.0, 0.05, progress) * smoothstep(1.0, 0.85, progress);
            
            smoke += intensity * fade * 2.5;
        }
    }
    
    return smoke;
}

// PATRÓN 38: Confeti Cayendo
float pattern_confetti(vec2 uv, float time, float amp) {
    float confetti = 0.0;
    float num_pieces = 40.0;
    
    for (float i = 0.0; i < num_pieces; i += 1.0) {
        float x_base = i / num_pieces;
        float piece_seed = random(vec2(x_base * 456.789, 123.456));
        
        // Velocidad errática
        float fall_speed = 0.05 + piece_seed * 0.04;
        fall_speed *= (1.0 + u_beat_intensity * 0.8);
        
        float cycle_time = time * fall_speed + piece_seed * 100.0;
        float y_progress = fract(cycle_time) * 1.5 - 0.3;
        float y_pos = 1.3 - y_progress;
        
        // Movimiento caótico horizontal
        float spin_time = time * (2.0 + piece_seed * 3.0);
        float x_drift = sin(y_progress * 5.0 + spin_time) * 0.15;
        float x_pos = x_base + x_drift;
        
        // Rotación del confeti (simula forma rectangular)
        float rotation = spin_time + piece_seed * 6.28;
        float size_x = 0.015 * abs(cos(rotation)) + 0.003;
        float size_y = 0.008 * abs(sin(rotation)) + 0.002;
        
        vec2 piece_pos = vec2(x_pos, y_pos);
        vec2 dist = abs(uv - piece_pos);
        
        if (dist.x < size_x && dist.y < size_y) {
            float intensity = (1.0 - dist.x / size_x) * (1.0 - dist.y / size_y);
            confetti += intensity * 4.0;
        }
    }
    
    return confetti;
}

// PATRÓN 39: Estrellas Fugaces
float pattern_shooting_stars(vec2 uv, float time, float amp) {
    float stars = 0.0;
    float num_stars = 8.0;
    
    for (float i = 0.0; i < num_stars; i += 1.0) {
        float star_seed = random(vec2(i * 678.901, 234.567));
        
        // Velocidad muy rápida
        float speed = 0.3 + star_seed * 0.2;
        speed *= (1.0 + u_bass * 0.5);
        
        float cycle_time = time * speed + star_seed * 50.0;
        float progress = fract(cycle_time);
        
        // Trayectoria diagonal
        float start_x = 0.2 + star_seed * 0.6;
        float start_y = 1.2;
        float angle = -0.5 - star_seed * 0.3;
        
        vec2 star_pos = vec2(
            start_x + cos(angle) * progress * 1.5,
            start_y + sin(angle) * progress * 1.5
        );
        
        // Estela brillante
        for (float tail = 0.0; tail < 8.0; tail += 1.0) {
            float tail_offset = tail * 0.015;
            vec2 tail_pos = star_pos - vec2(cos(angle), sin(angle)) * tail_offset;
            
            float dist = length(uv - tail_pos);
            float tail_fade = 1.0 - tail / 8.0;
            float glow = smoothstep(0.025, 0.0, dist) * tail_fade * 5.0;
            
            // Más brillante con beats
            stars += glow * (1.5 + u_beat_intensity * 1.0);
        }
    }
    
    return stars;
}

// PATRÓN 40: Globos Subiendo
float pattern_rising_balloons(vec2 uv, float time, float amp) {
    float balloons = 0.0;
    float num_balloons = 15.0;
    
    for (float i = 0.0; i < num_balloons; i += 1.0) {
        float x_base = i / num_balloons;
        float balloon_seed = random(vec2(x_base * 567.890, 345.678));
        
        // Velocidad de subida lenta
        float rise_speed = 0.015 + balloon_seed * 0.01;
        rise_speed *= (1.0 + u_mid * 0.2);
        
        float cycle_time = time * rise_speed + balloon_seed * 100.0;
        float y_progress = fract(cycle_time) * 1.5 - 0.3;
        float y_pos = -0.3 + y_progress;
        
        // Balanceo suave
        float sway = sin(time * 1.5 + balloon_seed * 6.28) * 0.08;
        float x_pos = x_base + sway;
        
        vec2 balloon_pos = vec2(x_pos, y_pos);
        float dist = length(uv - balloon_pos);
        
        // Forma de globo (círculo con reflejo)
        float balloon_size = 0.025 + balloon_seed * 0.015;
        float balloon_shape = smoothstep(balloon_size, balloon_size * 0.7, dist);
        
        // Reflejo brillante
        vec2 highlight_offset = vec2(-0.008, 0.012);
        float highlight_dist = length(uv - balloon_pos - highlight_offset);
        float highlight = smoothstep(0.008, 0.0, highlight_dist) * 1.5;
        
        // Cuerda del globo
        float string_x = abs(uv.x - x_pos);
        float string_y_start = y_pos - balloon_size;
        float string_length = 0.1;
        if (uv.y < string_y_start && uv.y > string_y_start - string_length && string_x < 0.001) {
            balloons += 0.5;
        }
        
        balloons += (1.0 - balloon_shape) * (3.0 + u_treble * 0.5) + highlight;
    }
    
    return balloons;
}

// PATRÓN 41: Luciérnagas
float pattern_fireflies(vec2 uv, float time, float amp) {
    float fireflies = 0.0;
    float num_fireflies = 30.0;
    
    for (float i = 0.0; i < num_fireflies; i += 1.0) {
        float fly_seed = random(vec2(i * 789.012, 456.789));
        
        // Movimiento errático en todas direcciones
        float move_speed = 0.05 + fly_seed * 0.03;
        float cycle = time * move_speed + fly_seed * 100.0;
        
        // Trayectoria serpenteante
        float x_pos = 0.5 + sin(cycle * 2.0 + fly_seed * 6.28) * 0.4;
        x_pos += cos(cycle * 3.5 + fly_seed * 3.14) * 0.15;
        
        float y_pos = 0.5 + cos(cycle * 1.8 + fly_seed * 4.71) * 0.4;
        y_pos += sin(cycle * 2.7 + fly_seed * 1.57) * 0.15;
        
        vec2 fly_pos = vec2(x_pos, y_pos);
        float dist = length(uv - fly_pos);
        
        // Parpadeo
        float blink_cycle = time * (3.0 + fly_seed * 2.0) + fly_seed * 10.0;
        float blink = pow(sin(blink_cycle) * 0.5 + 0.5, 3.0);
        blink *= (0.7 + u_beat_intensity * 0.3);
        
        // Resplandor suave
        float glow = smoothstep(0.025, 0.0, dist) * 4.0;
        float halo = smoothstep(0.05, 0.0, dist) * 1.0;
        
        fireflies += (glow + halo) * blink;
    }
    
    return fireflies;
}

// PATRÓN 42: Partículas Mágicas
float pattern_magic_particles(vec2 uv, float time, float amp) {
    float magic = 0.0;
    float num_particles = 40.0;
    
    for (float i = 0.0; i < num_particles; i += 1.0) {
        float particle_seed = random(vec2(i * 890.123, 567.890));
        
        // Velocidad de subida con variación
        float rise_speed = 0.03 + particle_seed * 0.02;
        rise_speed *= (1.0 + u_treble * 0.4);
        
        float cycle_time = time * rise_speed + particle_seed * 100.0;
        float y_progress = fract(cycle_time);
        
        // Espiral ascendente
        float spiral_radius = 0.15 + sin(y_progress * 6.28 * 2.0) * 0.1;
        float spiral_angle = y_progress * 12.56 + particle_seed * 6.28;
        
        float center_x = 0.3 + particle_seed * 0.4;
        float x_pos = center_x + cos(spiral_angle) * spiral_radius * (1.0 - y_progress * 0.3);
        float y_pos = -0.2 + y_progress * 1.4;
        
        vec2 particle_pos = vec2(x_pos, y_pos);
        float dist = length(uv - particle_pos);
        
        // Brillo pulsante
        float pulse = sin(time * 5.0 + particle_seed * 6.28) * 0.3 + 0.7;
        pulse *= (1.0 + u_beat_intensity * 0.5);
        
        // Partícula brillante con estela
        float core = smoothstep(0.01, 0.0, dist) * 5.0;
        float glow = smoothstep(0.03, 0.0, dist) * 2.5;
        float halo = smoothstep(0.05, 0.0, dist) * 1.0;
        
        // Se desvanece al llegar arriba
        float fade = 1.0 - pow(y_progress, 2.0);
        
        magic += (core + glow + halo) * pulse * fade;
    }
    
    return magic;
}

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;
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
    else if (u_pattern_index == 40) intensity = pattern_rising_balloons(uv, u_time, u_amplitude);
    else if (u_pattern_index == 41) intensity = pattern_fireflies(uv, u_time, u_amplitude);
    else if (u_pattern_index == 42) intensity = pattern_magic_particles(uv, u_time, u_amplitude);

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
