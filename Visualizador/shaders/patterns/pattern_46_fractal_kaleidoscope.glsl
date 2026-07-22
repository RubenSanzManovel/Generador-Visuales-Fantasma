float pattern_fractal_kaleidoscope(vec2 uv, float time, float amp) {
    vec2 p = uv - 0.5;
    p.x *= u_resolution.x / u_resolution.y;
    
    float r = length(p);
    float a = atan(p.y, p.x);
    float safe_r = max(r, 0.001);
    
    // 1. Zoom espiral con gran empuje de retroceso elástico modulado por el bombo
    float log_r = log(safe_r) * 0.6366197;
    float zoom = log_r - time * 0.45 + a * 0.1591549 - u_bass * 0.85 - u_beat_intensity * 0.4;
    
    // 2. Torsión angular y rotación reactiva al bombo
    float sectors = 10.0;
    float sector_angle = 6.2831853 / sectors;
    float twist = log(safe_r) * 0.5 + time * 0.2 + u_bass * 0.65 + u_beat_intensity * 0.25;
    float folded_a = abs(mod(a + twist, sector_angle) - sector_angle * 0.5);
    
    // 3. Coordenadas de la baldosa espiral
    vec2 st = vec2(zoom, folded_a * 1.591549);
    vec2 tile = abs(mod(st, 1.0) - 0.5);
    
    // 4. Brazos de espiral reactivos con grosor dinámico
    float line_thick = 0.03 + u_bass * 0.05 + u_beat_intensity * 0.02;
    float arm1 = smoothstep(line_thick, 0.0, abs(tile.x - tile.y * 1.1));
    float arm2 = smoothstep(line_thick * 0.8, 0.0, abs(tile.x + tile.y - 0.35));
    
    float shape = arm1 * 0.85 + arm2 * 0.45;
    
    // Brillo espiral líquido que se inflama con los graves
    float glow = (0.007 + u_bass * 0.009) / (0.009 + abs(tile.x - tile.y * 1.1));
    
    float depth_fade = smoothstep(0.015, 0.4, r);
    float final_color = (shape + glow * 0.22) * depth_fade * (0.7 + u_bass * 0.5 + u_beat_intensity * 0.3);
    
    return clamp(final_color, 0.0, 1.0);
}
