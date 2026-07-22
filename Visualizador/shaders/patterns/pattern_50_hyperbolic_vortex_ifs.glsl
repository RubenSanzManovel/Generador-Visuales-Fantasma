// PATRÓN 50: Vórtice Hiperbólico Fractal (Hyperbolic Vortex IFS)
float pattern_hyperbolic_vortex_ifs(vec2 uv, float time, float amp) {
    vec2 p = uv - 0.5;
    p.x *= u_resolution.x / u_resolution.y;
    
    // Giro espiral inicial reactivo al bombo
    p = rotate2d(time * 0.15 - u_bass * 0.2) * p;
    p *= 1.3 - u_smooth_amplitude * 0.15;
    
    float accum = 0.0;
    
    // Bucle KIFS con torsión helicoidal de 6 iteraciones
    for (int i = 0; i < 6; i++) {
        // Rotación progresiva desfasada por el índice del bucle
        p = rotate2d(0.8 + float(i) * 0.5 - time * 0.1) * p;
        
        // Pliegue especular de cuadrantes
        p = abs(p);
        
        // Inversión en círculo con gran radio (crea formas curvadas y nubosas)
        float d2 = dot(p, p) + 0.04 + u_bass * 0.06;
        p = p / d2 - vec2(0.55 + u_bass * 0.1);
        
        // Torsión progresiva
        p = rotate2d(time * 0.18 + float(i) * 0.2) * p;
        
        // Acumular campos de ondas sinusoidales entrelazadas
        accum += sin(p.x * 1.5) * cos(p.y * 1.5) * 0.5 + 0.5;
    }
    
    accum /= 6.0;
    
    // Efecto de brillo de plasma volumétrico
    float final_intensity = pow(accum, 2.5) * (0.8 + u_beat_intensity * 0.7);
    
    // Neblina profunda
    float glow = 0.22 / (length(uv - 0.5) + 0.25);
    
    float result = final_intensity * 0.75 + glow * 0.25;
    return clamp(result, 0.0, 1.0);
}
