// PATRÓN 53: Caleidoscopio de Plasma Líquido (Liquid Plasma Fractal IFS)
float pattern_liquid_plasma_ifs(vec2 uv, float time, float amp) {
    vec2 p = uv - 0.5;
    p.x *= u_resolution.x / u_resolution.y;
    
    // Distorsión fluida ondulatoria inicial (reactiva a graves)
    p.x += sin(p.y * 3.5 + time * 0.8) * 0.05 * u_bass;
    p.y += cos(p.x * 3.0 - time * 0.6) * 0.05 * u_bass;
    
    p *= 1.25 - u_smooth_amplitude * 0.15;
    
    float accum = 0.0;
    
    // Bucle KIFS con distorsiones fluidas
    for (int i = 0; i < 5; i++) {
        // Rotación helicoidal
        p = rotate2d(time * 0.08 + float(i) * 1.1) * p;
        
        // Espejo absoluto plegado
        p = abs(p);
        
        // Inversión circular con suavizado reactivo
        float d2 = dot(p, p) + 0.01 + u_bass * 0.02;
        p = p / d2 - vec2(0.68 + u_mid * 0.08);
    }
    
    // Generar patrón de interferencia tipo plasma fluido usando coordenadas transformadas
    float plasma = sin(p.x * 5.0 + time * 2.0) * cos(p.y * 5.0 - time * 1.5) * 0.5 + 0.5;
    plasma += sin(p.y * 8.0 + time * 3.0) * 0.25 + 0.25;
    
    // Hacer brillar el plasma en los beats
    float final_intensity = pow(plasma, 2.0) * (0.75 + u_beat_intensity * 0.75);
    
    // Glow central
    float center_glow = 0.20 / (length(uv - 0.5) + 0.3);
    
    float result = final_intensity * 0.8 + center_glow * 0.25;
    return clamp(result, 0.0, 1.0);
}
