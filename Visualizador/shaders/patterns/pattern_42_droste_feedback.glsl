// PATRÓN 45: Droste Feedback Recursivo Premium (100% Sin Costuras y Reactivo)
float pattern_droste_feedback(vec2 uv, float time, float amp) {
    vec2 p = uv - 0.5;
    p.x *= u_resolution.x / u_resolution.y;
    
    // Rotación global impulsada por el tiempo reactivo (lento en silencio, rápido en beats)
    p = rotate2d(u_reactive_time * 0.06) * p;
    
    // Convertir a coordenadas polares
    float r = length(p);
    float a = atan(p.y, p.x);
    
    // Evitar log(0) indeterminado
    float r_safe = max(r, 0.0001);
    float log_r = log(r_safe);
    
    // Constantes matemáticas para garantizar una Droste sin costuras (seam-free)
    // El número de brazos/espirales (arms) DEBE ser un entero
    float arms = 6.0; 
    
    // Modulación del rebote del zoom/escala por los bajos de la música
    float scale = 1.15 + u_bass * 0.45;
    
    // Torsión angular instantánea en los beats (efecto de sacudida/giro)
    float twist = u_bass * 0.25;
    
    // Mapeo Droste Periódico usando u_reactive_time para la velocidad de avance
    // (Avanza lento en silencio, se dispara a velocidad luz con los bombos)
    float u = log_r * scale + (a + twist) * (arms / 6.2831853) - u_reactive_time * 0.8;
    float v = (a + twist) * (arms / 6.2831853) - log_r * scale + u_reactive_time * 0.15;
    
    // Generar la repetición periódica de la rejilla
    vec2 cell = vec2(fract(u), fract(v));
    cell = abs(cell - 0.5) * 2.0;
    
    // Geometría interna (baldosas espirales redondeadas con relieve de neón)
    float val = sin(cell.x * 3.141592) * cos(cell.y * 3.141592);
    
    // Ancho de línea neón reactivo a los agudos (hi-hats)
    float lines = smoothstep(0.08 + u_treble * 0.12, 0.0, abs(val) - 0.015);
    
    // Iluminación interna de cada celda (efecto bombilla interna que pulsa con el volumen)
    float cell_glow = pow(max(0.0, val), 2.0) * u_amplitude * 0.7;
    
    // Brillo reactivo y glow volumétrico del núcleo central (explota con los bajos)
    float core_intensity = 3.2 - u_bass * 1.5;
    float glow = exp(-r * core_intensity) * (0.45 + u_bass * 1.85);
    float pulse = (0.75 + u_beat_intensity * 0.45);
    
    // Composición final
    float composition = lines * pulse + cell_glow + glow * 0.4;
    
    return clamp(composition, 0.0, 1.0);
}
