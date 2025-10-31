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

float pattern_star_hyperspace(vec2 uv, float time, float amp) {
    vec2 p = uv - 0.5;
    p.x *= u_resolution.x / u_resolution.y;

    // 1. La velocidad de viaje ahora depende casi por completo de la música.
    // El 'time' solo añade un movimiento de fondo muy lento.
    float speed = time * 0.05 + amp * 5.0; // 0.05: Vel. base (MUY LENTA). 5.0: Reacción al ritmo.

    // 2. Distorsionamos las coordenadas para el efecto de "zoom".
    // La velocidad controla qué tan "lejos" hemos viajado.
    vec2 distorted_uv = p / (1.0 - fract(speed * 0.1)); // 0.1: Intensidad del zoom.

    float r = length(distorted_uv);
    float a = atan(distorted_uv.y, distorted_uv.x);

    // 3. Creamos las estrellas usando las coordenadas distorsionadas.
    float stars = random(vec2(floor(a * 40.0), floor(r * 20.0))); // 40.0 y 20.0: Densidad de estrellas.
    stars = pow(stars, 50.0); // 50.0: Tamaño (más alto = más pequeñas).
    
    // 4. El estiramiento de las estrellas (las estelas) sigue dependiendo del volumen.
    // Esto crea el efecto de "acelerón" cuando la música sube.
    float stretch = 1.0 - smoothstep(0.0, 0.5, r * (1.0 - amp * 0.9)); // 0.9: Intensidad de las estelas.
    
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

float pattern_warp_tunnel(vec2 uv, float time, float amp) {
    vec2 p = uv - 0.5;
    p.x *= u_resolution.x / u_resolution.y;
    float r = length(p);
    float a = atan(p.y, p.x);
    float glitch_factor = floor(r * 20.0 + amp * 40.0) / 20.0;
    float depth = glitch_factor * 5.0 + time * 1.5 + u_mid * 2.0;
    float tunnel = sin(a * 8.0 + depth) * cos(glitch_factor * 20.0 - time * 2.0 + u_bass * 4.0);
    float rings = sin(glitch_factor * 30.0 - time * 3.0 + u_treble * 5.0) * 0.5 + 0.5;
    return (tunnel * 0.5 + 0.5) * rings;
}

float pattern_pixelated_dreams(vec2 uv, float time, float amp) {
    float pixelSize = 25.0 + sin(time * 0.5 + u_bass * 2.0) * 10.0;
    vec2 pixelated = floor(uv * pixelSize) / pixelSize;
    float pattern1 = sin(pixelated.x * 40.0 + time * 1.0 + u_mid * 4.0);
    float pattern2 = cos(pixelated.y * 40.0 - time * 0.8 + u_treble * 3.0);
    float checker = mod(floor(pixelated.x * pixelSize) + floor(pixelated.y * pixelSize), 2.0);
    float noise = random(pixelated + floor(time * 2.0)) * u_beat_intensity * 0.4;
    float grid = smoothstep(0.02, 0.0, fract(uv.x * pixelSize)) + smoothstep(0.02, 0.0, fract(uv.y * pixelSize));
    return (pattern1 * pattern2) * 0.5 + 0.5 + noise + checker * 0.1 + grid * 0.15;
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
