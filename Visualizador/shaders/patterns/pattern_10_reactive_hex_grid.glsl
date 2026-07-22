float pattern_reactive_hex_grid(vec2 uv, float time, float amp) {
    vec2 p = uv - 0.5;
    p.x *= u_resolution.x / u_resolution.y;
    
    // Escala del suelo de la discoteca (baldosas cuadradas retro)
    float grid_scale = 10.0;
    vec2 grid_pos = p * grid_scale;
    vec2 tile_id = floor(grid_pos);
    vec2 q = fract(grid_pos) - 0.5;
    
    // 1. Efecto de relieve y bombilla interna para cada baldosa de cristal
    float dist_edge = max(abs(q.x), abs(q.y));
    
    // Bisel de la baldosa (líneas divisorias negras y limpias en los bordes)
    float bevel = smoothstep(0.48, 0.40, dist_edge);
    
    // Destello de la bombilla central debajo del cristal (más amplio y brillante)
    float bulb = exp(-dot(q, q) * 12.0) * 0.6;
    float tile_surface = (0.7 + bulb * 0.5) * bevel;
    
    // 2. Alternancia de tablero de ajedrez retro (Checkered Pattern)
    float checker = mod(tile_id.x + tile_id.y, 2.0);
    
    // Parpadeo alternante rápido que acelera con los bajos (Bass)
    float blink_speed = 3.5 + u_bass * 4.0;
    float blink = sin(time * blink_speed + checker * 3.14159) * 0.25 + 0.75; // No cae tanto en la fase oscura
    
    // 3. Parpadeo sutil individual y asíncrono para dar realismo a los paneles
    float tile_random = random(tile_id);
    float tile_flicker = sin(time * 2.0 + tile_random * 6.2831) * 0.15 + 0.85;
    
    // 4. Onda reactiva del Beat con valle de sombra tridimensional (contraste extremo de luz y sombra)
    float pulse = time - u_drops_time[0];
    float wave_dist = length(p) - pulse * 1.3;
    float wave_envelope = smoothstep(0.45, 0.0, abs(wave_dist));
    // Onda senoidal que pasa de positivo (brillo) a negativo (sombra) para un contraste hiper-marcado
    float beat_ripple = sin(wave_dist * 18.0) * wave_envelope * u_beat_intensity * 0.85;
    
    // 5. Brillo base del suelo combinando el volumen de la música (brillo mínimo elevado de 0.20 a 0.45)
    float ambient_glow = 0.45 + u_amplitude * 0.60 + u_bass * 0.30;
    
    // 6. Mezcla de brillo total (la onda resta brillo en su fase negativa creando sombra física)
    float brightness = ambient_glow * blink * tile_flicker + beat_ripple;
    
    // Permitimos que baje hasta casi cero (0.02) en la fase de sombra de la onda para marcar la transición
    brightness = clamp(brightness, 0.02, 1.4);
    
    // Combinamos la iluminación con la textura de la baldosa y aplicamos multiplicador de ganancia de salida
    return clamp(tile_surface * brightness * 1.3, 0.0, 1.0);
}