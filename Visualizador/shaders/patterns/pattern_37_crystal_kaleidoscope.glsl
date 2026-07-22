// PATRÓN 40: Caleidoscopio de Cristales Fractales
float pattern_crystal_kaleidoscope(vec2 uv, float time, float amp) {
    vec2 p = uv - 0.5;
    p.x *= u_resolution.x / u_resolution.y;
    
    // Zoom reactivo al bajo
    p *= 1.0 - u_bass * 0.15;
    
    for (int i = 0; i < 5; i++) {
        // Doblez simétrico absoluto
        p = abs(p);
        
        // Inversión circular con offset dinámico reactivo a la música
        float d2 = dot(p, p) + 0.001; // Evitar división por cero
        p = p / d2 - vec2(0.55 + u_bass * 0.1, 0.75 + u_mid * 0.1);
        
        // Rotación con velocidad diferenciada por iteración y aceleración por agudos
        float angle = time * 0.25 + float(i) * 0.6 + u_treble * 1.2;
        p = rotate2d(angle) * p;
    }
    
    // Generar bordes afilados cristalinos (estilo rejilla de cristal brillante)
    float crystal_x = abs(sin(p.x * 4.0 + time));
    float crystal_y = abs(cos(p.y * 4.0 - time));
    float val = smoothstep(0.12, 0.0, crystal_x * crystal_y);
    
    // Añadir glow de fondo
    float glow = exp(-length(p) * 0.18) * 0.4;
    
    return val * (0.8 + u_beat_intensity * 0.6) + glow;
}
