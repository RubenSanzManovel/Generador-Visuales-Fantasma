float pattern_mandala_kaleidoscope(vec2 uv, float time, float amp) {
    vec2 p = uv - 0.5;
    p.x *= u_resolution.x / u_resolution.y;
    
    float r = length(p);
    float a = atan(p.y, p.x);
    float safe_r = max(r, 0.001);
    
    // 1. Zoom logarítmico con empuje de retroceso elástico en los bombos (u_bass y u_beat_intensity)
    float log_r = log(safe_r) * 0.6366197;
    float zoom = log_r - time * 0.5 - u_bass * 0.7 - u_beat_intensity * 0.35;
    
    // 2. Giro y torsión angular reactiva a los graves del bombo
    float sectors = 8.0;
    float sector_angle = 6.2831853 / sectors;
    float rot_twist = time * 0.12 + u_bass * 0.4 + u_beat_intensity * 0.2;
    float folded_a = abs(mod(a + rot_twist, sector_angle) - sector_angle * 0.5);
    
    // 3. Crear el patrón de mosaico
    vec2 st = vec2(zoom, folded_a * 1.273239);
    
    // Reflejar para suavidad infinita
    vec2 tile = abs(mod(st, 1.0) - 0.5);
    
    // 4. Grosor de línea dinámico que se ensancha con el impacto del bombo
    float line_thick = 0.035 + u_bass * 0.065 + u_beat_intensity * 0.03;
    float line1 = smoothstep(line_thick, 0.0, abs(tile.x - tile.y));
    float line2 = smoothstep(line_thick * 0.75, 0.0, abs(tile.x + tile.y - 0.3));
    
    float shape = line1 * 0.8 + line2 * 0.5;
    
    // Resplandor volumétrico que estalla con el bajo
    float glow = (0.006 + u_bass * 0.008) / (0.008 + abs(tile.x - tile.y));
    
    // Profundidad central
    float depth_fade = smoothstep(0.01, 0.4, r);
    
    float final_color = (shape + glow * 0.2) * depth_fade * (0.7 + u_bass * 0.5 + u_beat_intensity * 0.3);
    
    return clamp(final_color, 0.0, 1.0);
}
