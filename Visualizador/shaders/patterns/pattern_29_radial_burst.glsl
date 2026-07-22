// PATRÓN 29: Súper Explosión Radial Reactiva a FFT - ANÁLISIS DE FRECUENCIA RADIAL PREMIUM
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
    // Anillo Interior (Reactivo al Bajo y FFT)
    // Subimos la ganancia base de graves a 3.5 para darles un protagonismo masivo en la horizontal,
    // y mantenemos el boost de medios/agudos en 8.0 para que sigan teniendo crestas gigantes.
    float freq_index = angle_norm * 0.5;
    float fft_boosted = fft_val * (3.5 + smoothstep(0.02, 0.5, freq_index) * 8.0);
    float inner_radius = 0.25 + fft_boosted * 0.32;
    float inner_circle_dist = abs(r - inner_radius);
    float inner_glow = 0.004 / (inner_circle_dist + 0.006) * (0.8 + u_bass * 0.6);
    
    // Anillo Exterior (Reactivo a Medios y Agudos)
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