// PATRÓN 43: Túnel de Log-Espiral Infinito Premium "Vórtice Dimensional"
float pattern_log_tunnel(vec2 uv, float time, float amp) {
    vec2 p = uv - 0.5;
    p.x *= u_resolution.x / u_resolution.y;
    
    // Rotación global impulsada por el tiempo reactivo
    float rot_angle = u_reactive_time * 0.15 + u_bass * 0.1;
    p = rotate2d(rot_angle) * p;
    
    float r = length(p);
    float a = atan(p.y, p.x);
    
    // Evitar log(0) indeterminado
    float r_safe = max(r, 0.0001);
    
    // Distorsión reactiva de coordenadas (Domain Warping)
    // El túnel se deforma y ondulea orgánicamente al ritmo de graves y medios
    float distort = sin(a * 5.0 + u_reactive_time * 2.0) * (0.05 + u_bass * 0.12) +
                    cos(a * 3.0 - u_reactive_time * 1.5) * (0.03 + u_mid * 0.08);
    
    // Coordenadas Log-Polares base con velocidad de avance acumulada (u_reactive_time)
    // Se añade un desplazamiento directo de bajos (u_bass * 0.35) para dar un efecto de rebote/pulsación elástica
    float log_r = log(r_safe) - u_reactive_time * 2.2 - u_bass * 0.35 + distort;
    
    // Torsión espiral reactiva según la profundidad
    float twist = sin(log_r * 0.45 + u_reactive_time * 0.8) * (0.4 + u_bass * 0.8);
    float angle1 = a + twist;
    float angle2 = a - twist * 0.7; // Contragiro para crear patrones de interferencia
    
    // 1. Rejillas de Neón Cruzadas (Espiral Doble)
    // Usamos dos espirales desfasadas para crear una cuadrícula romboidal infinita
    // Añadimos ondulación reactiva en las líneas (vibración como cuerdas de guitarra)
    float wave_ripple = sin(log_r * 8.0 - u_reactive_time * 5.0) * (0.05 + u_bass * 0.25);
    float grid1 = sin(log_r * 3.0 + angle1 * 4.0 + wave_ripple);
    float grid2 = sin(log_r * 2.0 - angle2 * 5.0 - wave_ripple);
    
    float lines1 = smoothstep(0.12 + u_treble * 0.08, 0.0, abs(grid1));
    float lines2 = smoothstep(0.12 + u_mid * 0.06, 0.0, abs(grid2));
    float lattice = max(lines1, lines2) * (0.45 + u_bass * 0.55);
    
    // 2. Anillos Pulsantes Volumétricos (Glow)
    // Anillos concéntricos de neón que explotan hacia el espectador
    float ring_val = sin(log_r * 4.0 - u_reactive_time * 4.0);
    float ring_glow = exp(-abs(ring_val) * (7.0 - u_bass * 4.0)); // Se ensancha y brilla con bajos
    float rings = ring_glow * (0.3 + u_beat_intensity * 0.7);
    
    // 3. Estrellas / Sparks voladoras (Polvo Cósmico en el túnel)
    // Partículas veloces generadas de forma procedural en el espacio log-polar
    vec2 star_uv = vec2(log_r * 3.5, (a + u_reactive_time * 0.2) * 8.0 / 3.14159);
    vec2 star_id = floor(star_uv);
    vec2 star_fract = fract(star_uv) - 0.5;
    
    // Hash pseudo-aleatorio para cada celda
    float h = fract(sin(dot(star_id, vec2(127.1, 311.7))) * 43758.5453123);
    
    // Dibujar estrellas en un 25% de las celdas
    float star_active = step(0.75, h);
    float star_pulse = sin(u_reactive_time * 4.0 + h * 6.283) * 0.4 + 0.6;
    float star_dist = length(star_fract);
    // El brillo/tamaño de las estrellas responde a los agudos (hi-hats)
    float star_glow = smoothstep(0.08 + u_treble * 0.15, 0.0, star_dist) * star_pulse * star_active;
    
    // 4. Portal central brillante (Vórtice / Agujero de gusano)
    // Un núcleo brillante de luz en el fondo del túnel
    float portal = exp(-r * 6.0) * (0.8 + u_beat_intensity * 1.8);
    
    // 5. Cintas helicoidales de barrido lateral (Ribbons)
    float ribbon = sin(a * 3.0 + log_r * 1.5 + u_reactive_time * 3.0) * 0.5 + 0.5;
    ribbon = pow(ribbon, 6.0) * (0.3 + u_mid * 0.7);
    
    // Niebla / Oscurecimiento atmosférico hacia el centro para dar profundidad
    float depth_fade = smoothstep(0.02, 0.75, r);
    
    // Mezcla de componentes
    float composition = lattice * 0.65 + rings * 0.5 + star_glow * 0.85 + portal * 0.9 + ribbon * 0.4;
    
    // Salida final escalada por el beat general de la música
    return clamp(composition * depth_fade * (1.0 + u_beat_intensity * 0.35), 0.0, 1.0);
}
