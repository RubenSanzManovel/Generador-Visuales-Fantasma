float pattern_hexagonal_kaleidoscope(vec2 uv, float time, float amp) {
    vec2 p = uv - 0.5;
    p.x *= u_resolution.x / u_resolution.y;
    
    float r = length(p);
    float a = atan(p.y, p.x);
    
    // 1. Ángulo y rotación de cuadrante hexagonal reactivo al bombo
    float hex_sectors = 6.0;
    float hex_angle = 6.2831853 / hex_sectors;
    float rot_twist = time * 0.05 + u_bass * 0.35 + u_beat_intensity * 0.15;
    float a_hex = mod(a + rot_twist, hex_angle) - hex_angle * 0.5;
    float r_hex = r * cos(a_hex);
    
    // 2. Zoom infinito hexagonal con rebote elástico hacia adelante/atrás en cada bombo
    float log_r = log(max(r_hex, 0.001)) * 0.65;
    float zoom = log_r - time * 0.6 - u_bass * 0.8 - u_beat_intensity * 0.4;
    
    // 3. Baldosas concéntricas hexagonales
    float tile_x = abs(mod(zoom, 1.0) - 0.5);
    float tile_y = abs(a_hex * 1.909859);
    
    // 4. Grosor de las líneas reactivo al bombo
    float line_thick = 0.04 + u_bass * 0.07 + u_beat_intensity * 0.03;
    float border = smoothstep(line_thick, 0.0, abs(tile_x - 0.43));
    float diagonal = smoothstep(line_thick * 0.75, 0.0, abs(tile_x - tile_y * 0.6));
    
    // Destellos angulares
    float corner_flash = smoothstep(0.05, 0.0, abs(tile_y)) * smoothstep(0.1, 0.5, r) * u_beat_intensity * 0.8;
    
    float shape = border * 0.85 + diagonal * 0.45 + corner_flash;
    
    // Brillo de neón reactivo
    float glow = (0.005 + u_bass * 0.007) / (0.007 + abs(tile_x - 0.43));
    
    float depth_fade = smoothstep(0.02, 0.35, r);
    float final_color = (shape + glow * 0.25) * depth_fade * (0.7 + u_bass * 0.5 + u_beat_intensity * 0.3);
    
    return clamp(final_color, 0.0, 1.0);
}
