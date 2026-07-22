float pattern_oscillating_bars(vec2 uv, float time, float amp) {
    // 1. Inicializar coordenadas deformadas
    vec2 deformed_uv = uv;
    
    // 2. Distorsiones de espacio localizadas (vórtices / pellizcos tridimensionales) en los puntos de golpeo (u_drops_pos)
    for (int i = 0; i < 6; i++) {
        float t = time - u_drops_time[i];
        if (t > 0.0 && t < 1.4) {
            vec2 drop_pos = u_drops_pos[i];
            vec2 delta = deformed_uv - drop_pos;
            float r = length(delta);
            
            // Decaimiento temporal suave
            float progress = t / 1.4;
            float decay = pow(1.0 - progress, 2.5);
            
            // Fuerza de distorsión reactiva
            float strength = (0.28 + u_beat_intensity * 0.22) * decay;
            
            // Área de influencia localizada
            float influence = exp(-r * 12.0);
            
            // Giro tipo vórtice (twist)
            float twist = strength * influence * 6.5;
            vec2 rotated = rotate2d(twist) * delta;
            
            // Pellizco gravitatorio hacia el centro del golpe (pinch)
            vec2 pinch = normalize(delta + vec2(1e-5)) * strength * influence * 0.06;
            
            deformed_uv = drop_pos + rotated - pinch;
        }
    }
    
    // 3. Distorsión ondulatoria global reactiva al bass
    float dist_center = length(deformed_uv - 0.5);
    if (dist_center > 0.001) {
        float wave = sin(dist_center * 7.5 - time * 3.5) * (0.01 + u_bass * 0.038);
        deformed_uv += normalize(deformed_uv - 0.5) * wave;
    }
    
    // 4. Desplazamiento reactivo de las líneas (lasers)
    float bass_shake = smoothstep(0.25, 0.8, u_bass);
    float offset1 = sin(time * 0.35 + u_bass * 1.5) * (0.08 + bass_shake * 0.18);
    float offset2 = cos(time * 0.4 + u_mid * 1.2) * (0.08 + bass_shake * 0.18);
    
    // 5. Moduladores de guiones sci-fi (efecto de flujo de datos viajando por la red)
    float h_dashes = smoothstep(-0.25, 0.25, sin(deformed_uv.x * 20.0 - time * 7.0)) * 0.35 + 0.65;
    float v_dashes = smoothstep(-0.25, 0.25, cos(deformed_uv.y * 18.0 + time * 6.0)) * 0.35 + 0.65;
    
    // 6. Parámetro de ancho de brillo reactivo a frecuencias medias y agudas (glow de neón)
    float glow_width = 0.065 + u_mid * 0.10 + u_treble * 0.07;
    float glow_mult = 0.22 + u_beat_intensity * 0.28;
    
    // --- LÍNEAS HORIZONTALES ---
    float d_horiz = abs(sin((deformed_uv.y + offset1) * 12.0 + time * 0.6 + u_treble * 2.0) - 0.5);
    float horiz_core = smoothstep(0.022, 0.0, d_horiz);
    float horiz_glow = smoothstep(glow_width, 0.0, d_horiz) * glow_mult;
    float horiz_laser = (horiz_core + horiz_glow) * h_dashes;
    
    // --- LÍNEAS VERTICALES ---
    float d_vert = abs(sin((deformed_uv.x + offset2) * 10.0 - time * 0.5 + u_bass * 2.0) - 0.5);
    float vert_core = smoothstep(0.022, 0.0, d_vert);
    float vert_glow = smoothstep(glow_width, 0.0, d_vert) * glow_mult;
    float vert_laser = (vert_core + vert_glow) * v_dashes;
    
    // --- LÍNEAS DIAGONALES ---
    vec2 diag = rotate2d(0.785398) * (deformed_uv - 0.5);
    float d_diag = abs(sin((diag.y - offset1) * 8.0 + time * 0.5 + u_mid * 1.5) - 0.5);
    float diag_core = smoothstep(0.022, 0.0, d_diag);
    float diag_glow = smoothstep(glow_width * 1.2, 0.0, d_diag) * glow_mult;
    float diag_laser = (diag_core + diag_glow) * 0.6;
    
    // Suma de lasers
    float bars = horiz_laser + vert_laser + diag_laser;
    
    // 7. Destellos neón adicionales en las intersecciones de la rejilla principal
    float intersections = horiz_laser * vert_laser;
    bars += intersections * (0.5 + u_beat_intensity * 0.8);
    
    // 8. Pulso de brillo y viñeteado reactivo a la música
    float pulse = (1.0 + sin(dist_center * 5.0 - time * 1.5) * 0.18) * (1.0 + u_beat_intensity * 0.45);
    
    return min(bars * pulse, 2.0);
}