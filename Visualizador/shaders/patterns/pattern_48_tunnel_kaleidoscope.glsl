float pattern_tunnel_kaleidoscope(vec2 uv, float time, float amp) {
    vec2 p = uv - 0.5;
    p.x *= u_resolution.x / u_resolution.y;
    
    // 1. Rotación general del portal reactiva al bombo
    float rot_twist = time * 0.05 + u_bass * 0.35 + u_beat_intensity * 0.15;
    vec2 rotated_p = rotate2d(rot_twist) * p;
    
    // 2. Simetría de cuadrante octogonal (8 pliegues rectangulares)
    vec2 q = abs(rotated_p);
    if (q.y > q.x) {
        q = q.yx;
    }
    
    // 3. Distancia al borde del cuadrado contenedor
    float r_square = max(q.x, q.y);
    
    // 4. Mapeo logarítmico para zoom infinito cuadrado con rebote elástico por bombo
    float log_r = log(max(r_square, 0.001)) * 0.6366197;
    float zoom = log_r - time * 0.55 - u_bass * 0.8 - u_beat_intensity * 0.4;
    
    // 5. Baldosas cuadradas concéntricas
    float tile_x = abs(mod(zoom, 1.0) - 0.5);
    float tile_y = q.y / (q.x + 0.0001) * 0.5; // Normalización angular del cuadrante
    
    // 6. Dibujar bordes cuadrados reactivos con grosor dinámico
    float line_thick = 0.035 + u_bass * 0.065 + u_beat_intensity * 0.03;
    float border = smoothstep(line_thick, 0.0, abs(tile_x - 0.42));
    
    // Pistas de circuito
    float wire1 = smoothstep(line_thick * 0.7, 0.0, abs(tile_x - tile_y * 0.6));
    float wire2 = smoothstep(line_thick * 0.6, 0.0, abs(tile_x + tile_y - 0.35));
    
    // Nodos en las esquinas que brillan intensamente
    float node = smoothstep(0.05, 0.0, length(vec2(tile_x - 0.25, tile_y - 0.25))) * u_beat_intensity * 0.8;
    
    float shape = border * 0.9 + wire1 * 0.4 + wire2 * 0.35 + node;
    
    // Brillo de neón reactivo
    float glow = (0.005 + u_bass * 0.007) / (0.007 + abs(tile_x - 0.42));
    
    float depth_fade = smoothstep(0.015, 0.4, r_square);
    float final_color = (shape + glow * 0.2) * depth_fade * (0.7 + u_bass * 0.5 + u_beat_intensity * 0.3);
    
    return clamp(final_color, 0.0, 1.0);
}
