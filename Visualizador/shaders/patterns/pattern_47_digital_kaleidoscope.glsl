float pattern_digital_kaleidoscope(vec2 uv, float time, float amp) {
    vec2 p = uv - 0.5;
    p.x *= u_resolution.x / u_resolution.y;
    
    float r = length(p);
    float a = atan(p.y, p.x);
    
    // 1. Simetría triangular y rotación reactiva al bombo
    float tri_sectors = 3.0;
    float tri_angle = 6.2831853 / tri_sectors;
    float rot_twist = -time * 0.08 - u_bass * 0.4 - u_beat_intensity * 0.2;
    float a_tri = mod(a + rot_twist, tri_angle) - tri_angle * 0.5;
    
    // 2. Distancia al plano del triángulo
    float r_tri = r * cos(a_tri);
    
    // 3. Zoom infinito con rebote elástico pesado al ritmo del bombo
    float log_r = log(max(r_tri, 0.001)) * 0.55;
    float zoom = log_r - time * 0.65 - u_bass * 0.85 - u_beat_intensity * 0.45;
    
    // 4. Baldosas concéntricas triangulares
    float tile_x = abs(mod(zoom, 1.0) - 0.5);
    float tile_y = abs(a_tri * 0.9549);
    
    // 5. Dibujar bordes triangulares concéntricos reactivos con grosor dinámico
    float line_thick = 0.04 + u_bass * 0.065 + u_beat_intensity * 0.03;
    float border = smoothstep(line_thick, 0.0, abs(tile_x - 0.44));
    
    // Haces de luz desde las esquinas que vibran fuertemente con el bajo
    float ray = smoothstep(0.02 + u_bass * 0.015, 0.0, abs(tile_y)) * smoothstep(0.12, 0.9, r) * (0.1 + u_bass * 0.9 + u_beat_intensity * 0.4);
    
    float lines = smoothstep(line_thick * 0.6, 0.0, abs(tile_x - tile_y * 0.5));
    
    float shape = border * 0.9 + ray * 0.65 + lines * 0.4;
    
    // Brillo de neón reactivo
    float glow = (0.006 + u_bass * 0.007) / (0.008 + abs(tile_x - 0.44));
    
    float depth_fade = smoothstep(0.015, 0.35, r);
    float final_color = (shape + glow * 0.22) * depth_fade * (0.7 + u_bass * 0.5 + u_beat_intensity * 0.3);
    
    return clamp(final_color, 0.0, 1.0);
}
