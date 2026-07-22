float pattern_liquid_metal(vec2 uv, float time, float amp) {
    vec2 p = (uv - 0.5) * 3.0;
    p.x *= u_resolution.x / u_resolution.y;
    float liquid = 0.0;
    
    // Generamos dos semillas pseudoaleatorias usando el tiempo del último beat.
    // Esto hace que la estructura cambie aleatoriamente en cada golpe de ritmo,
    // variando la simetría y el tamaño de los círculos para evitar repeticiones.
    float beat_rand = fract(sin(u_last_beat_time * 43.13) * 927.43);
    float beat_rand2 = fract(sin(u_last_beat_time * 91.71) * 314.15);
    
    for (int i = 0; i < 4; i++) {
        float fi = float(i);
        
        // Introducemos una ligera asimetría angular aleatoria en cada beat para deformar las órbitas
        float angle = (time * 0.45 + u_mid * 0.4) + fi * 1.57079 + (fi * (beat_rand - 0.5) * 0.18);
        
        // Modulamos aleatoriamente el radio base con el beat para que el tamaño cambie dinámicamente
        float base_radius = 0.65 + beat_rand2 * 0.25;
        float radius = base_radius + u_bass * 0.40;
        vec2 offset = vec2(cos(angle), sin(angle)) * radius;
        
        // Plegado de espacio fractal (fractal space folding)
        p = abs(p) / dot(p, p) - offset;
        
        // Rotación interna reactiva para dar dinamismo a las órbitas
        p = rotate2d(time * 0.22 + fi * 0.8 + u_mid * 0.6) * p;
        
        liquid += length(p) * (0.3 + u_beat_intensity * 0.2);
    }
    
    // Hacemos el efecto mucho más limpio (sharper) aplicando una potencia alta
    // a la oscilación, reduciendo el degradado ancho (blur/haz) a líneas finas y nítidas
    float rings = sin(liquid * 1.8 + time * 2.0 + u_treble * 3.0) * 0.5 + 0.5;
    return pow(rings, 5.0);
}