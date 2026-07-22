// PATRÓN 51: Red de Laberintos Eléctricos (Cyber Labyrinth IFS)
float pattern_cyber_labyrinth_ifs(vec2 uv, float time, float amp) {
    vec2 p = uv - 0.5;
    p.x *= u_resolution.x / u_resolution.y;
    
    // Zoom general rítmico
    p *= 1.4 - u_bass * 0.12;
    
    float accum = 0.0;
    
    // Bucle IFS rectangular con giros ortogonales (90 grados) para aspecto electrónico
    for (int i = 0; i < 5; i++) {
        // Desplazamiento simétrico reactivo al bajo (abre y cierra las pistas del laberinto)
        p = abs(p) - vec2(0.28 + u_bass * 0.06, 0.28 + u_bass * 0.06);
        
        // Inversión en círculo pequeña para forzar líneas rectas fractales
        float d2 = dot(p, p) + 0.002 + u_treble * 0.003;
        p = p / d2;
        
        // Rotación ortogonal de 90 grados (1.5707963) con un desfase mínimo de tiempo
        p = rotate2d(1.5707963 + sin(time * 0.15) * 0.02) * p;
        
        // Acumular líneas rectas y finas (pistas de cobre del circuito)
        accum += exp(-abs(p.x) * 2.2) + exp(-abs(p.y) * 2.2);
    }
    
    accum /= 10.0;
    
    // Ondas eléctricas que recorren las pistas (reactivas a los agudos/hi-hats)
    float electricity = sin(p.x * 20.0 - time * 6.0) * cos(p.y * 20.0 + time * 4.0) * u_treble;
    float final_intensity = accum * 0.7 + max(electricity, 0.0) * 0.45;
    
    // Brillo en los golpes
    final_intensity *= (0.65 + u_beat_intensity * 0.7);
    
    // Resplandor del núcleo cibernético
    float center_glow = 0.15 / (length(uv - 0.5) + 0.2);
    
    float result = final_intensity + center_glow * 0.25;
    return clamp(result, 0.0, 1.0);
}
