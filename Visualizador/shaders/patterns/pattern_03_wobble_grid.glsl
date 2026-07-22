float pattern_wobble_grid(vec2 uv, float time, float amp) {
    vec2 d = uv;
    
    // Ondulación de líneas verticales (desplazamiento en X) reactiva a graves (u_bass) y beats
    float wave_amp_x = 0.003 + clamp(u_bass * 0.18 + u_beat_intensity * 0.02, 0.0, 0.09);
    float wave_freq_x = 8.0;
    d.x += sin(uv.y * wave_freq_x + time * 1.2) * wave_amp_x;
    
    // Ondulación de líneas horizontales (desplazamiento en Y) altamente sensible a los agudos / hi-hats (u_treble)
    // Multiplicamos por 1.8 para compensar que el valor relativo de agudos del FFT suele ser muy pequeño
    float wave_amp_y = 0.003 + clamp(u_treble * 1.8, 0.0, 0.09);
    float wave_freq_y = 12.0; 
    d.y += cos(uv.x * wave_freq_y - time * 1.2) * wave_amp_y; 
    
    // Zoom/breathing muy suave en la densidad para que los bloques no cambien drásticamente de tamaño
    float grid_density = 20.0 - u_bass * 1.5;
    
    // Exponente del bisel sutilmente reactivo (mantiene las líneas nítidas)
    float exponent = 12.0 - u_bass * 4.0;
    exponent = max(exponent, 4.0);
    
    // Dibujo del diseño de bloques con bisel
    float lx = pow(abs(sin(d.x * 3.14159265 * grid_density)), exponent);
    float ly = pow(abs(sin(d.y * 3.14159265 * grid_density)), exponent);
    
    float cell_val = 1.0 - max(lx, ly);
    
    // Brillo dinámico: los bloques pulsan con el bajo y el ritmo general
    float result = cell_val * (0.8 + u_bass * 0.25 + u_beat_intensity * 0.15);
    
    return clamp(result, 0.0, 1.0);
}