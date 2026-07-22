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
