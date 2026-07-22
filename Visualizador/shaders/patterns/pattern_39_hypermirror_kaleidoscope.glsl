// PATRÓN 42: Caleidoscopio de Hyper-Mirror Cósmico
float pattern_hypermirror_kaleidoscope(vec2 uv, float time, float amp) {
    vec2 p = uv - 0.5;
    p.x *= u_resolution.x / u_resolution.y;
    
    for (int i = 0; i < 5; i++) {
        // Rotación previa al espejo para desfasar la simetría
        p = rotate2d(time * 0.1 + float(i) * 1.2) * p;
        
        // Inversión fractal con desfase grande y reactivo a graves
        float d2 = dot(p, p) + 0.001;
        p = abs(p) / d2 - vec2(0.95 + u_bass * 0.15, 0.35 + u_treble * 0.15);
    }
    
    // Patrón de interferencia hiper-reflejado radial y angular
    float r = length(p);
    float a = atan(p.y, p.x);
    
    // Ondas superpuestas que generan un caleidoscopio orgánico y fluido
    float wave1 = sin(r * 8.0 + time * 2.5 + u_mid * 3.0);
    float wave2 = cos(a * 8.0 - time * 1.5 + u_bass * 2.0);
    float pattern = wave1 * wave2;
    
    // Hacerlo brillar intensamente en los picos de ritmo
    float intensity = smoothstep(-0.2, 0.6, pattern) * (0.6 + u_beat_intensity * 0.6);
    
    // Brillo difuso central por difracción
    float glow = 0.25 / (r + 0.4);
    
    return clamp(intensity + glow * 0.4, 0.0, 1.0);
}
