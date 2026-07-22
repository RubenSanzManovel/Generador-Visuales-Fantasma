// PATRÓN 15: Hiperimpulso Estelar (Giro "en Seco" con Beat y Avance Hacia Adelante)
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