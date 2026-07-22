float pattern_woven_fabric(vec2 uv, float time, float amp) {
    // Coordinación de deformación de tela ondulante al viento (grandes olas impulsadas por graves)
    vec2 p = uv;
    
    // Deformación de tela suave 2D (ondas que se cruzan)
    float wave_x = sin(uv.y * 4.0 + time * 1.2) * cos(uv.x * 2.0 + time * 0.6);
    float wave_y = cos(uv.x * 4.0 + time * 1.0) * sin(uv.y * 2.0 + time * 0.8);
    
    // Mayor amplitud de onda con el bajo para dar dinamismo de viento fuerte
    float fabric_wave_scale = 0.05 + u_bass * 0.12 + u_beat_intensity * 0.06;
    p.x += wave_x * fabric_wave_scale;
    p.y += wave_y * fabric_wave_scale;
    
    // Zoom/breathing (latido) dinámico de la tela al ritmo de los graves
    p = (p - 0.5) * (1.0 - u_bass * 0.08) + 0.5;
    
    // Frecuencia del tejido (densidad de hilos de la tela)
    float thread_density = 45.0;
    
    // Vibración eléctrica microscópica en los hilos guiada por los agudos (hi-hats)
    float micro_ripple = sin(p.x * 90.0 + time * 8.0) * 0.003 * u_treble;
    vec2 tp = p + vec2(micro_ripple);
    
    // Definir los hilos horizontales y verticales
    float horiz_thread = sin(tp.y * thread_density + sin(tp.x * 12.0 + time * 2.0) * 0.8) * 0.5 + 0.5;
    float vert_thread = sin(tp.x * thread_density + cos(tp.y * 12.0 - time * 1.5) * 0.8) * 0.5 + 0.5;
    
    // Interlazar hilos (patrón de tablero alternado para simular cruce real de tejido)
    float cross_mask = sin(tp.x * thread_density * 0.5) * cos(tp.y * thread_density * 0.5);
    float weave = mix(horiz_thread, vert_thread, cross_mask * 0.5 + 0.5);
    
    // Sombreado 3D de hilos (efecto de relieve satinado en los cruces)
    float satin_shimmer = pow(weave, 3.0) * 1.4;
    
    // Reflejo especular de brillo neón reactivo a los agudos/hi-hats
    float spec = pow(weave, 12.0) * (0.2 + u_treble * 1.8);
    
    // Sombras generales de los pliegues de la tela (luces y sombras volumétricas del viento)
    float folds = sin(p.x * 6.0 - time * 0.8) * cos(p.y * 4.0 + time * 0.5) * 0.25 + 0.75;
    
    // Mezclar el patrón del tejido, el sombreado satinado y los pliegues
    float result = (satin_shimmer * folds + spec) * (0.8 + u_bass * 0.3 + u_beat_intensity * 0.2);
    
    return clamp(result, 0.0, 1.0);
}