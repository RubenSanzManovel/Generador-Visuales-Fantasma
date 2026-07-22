float pattern_morphing_tiles(vec2 uv, float time, float amp) {
    // 1. Dinámica de rejilla que respira y rota con el ritmo
    float density = 8.0 - u_bass * 1.5;
    vec2 p = uv - 0.5;
    p.x *= u_resolution.x / u_resolution.y;
    
    // Rotación suave del plano que acelera con el beat
    float grid_angle = time * 0.08 + u_bass * 0.5 + u_beat_intensity * 0.25;
    p = rotate2d(grid_angle) * p;
    
    vec2 grid_pos = p * density;
    vec2 tile_id = floor(grid_pos);
    vec2 grid = fract(grid_pos) - 0.5;
    
    // 2. Rotación interna individual de cada baldosa reactiva
    float tile_random = random(tile_id);
    float tile_angle = sin(time * 0.8 + tile_random * 6.28) * 0.25 + u_mid * 0.8;
    grid = rotate2d(tile_angle) * grid;
    
    // 3. Distancias para las formas (Cuadrado, Círculo, Diamante)
    float d_square = max(abs(grid.x), abs(grid.y));
    float d_circle = length(grid);
    float d_diamond = abs(grid.x) + abs(grid.y);
    
    // 4. Ciclo de metamorfosis (Morphing) reactivo al ritmo
    // Transiciona suavemente: Cuadrado -> Círculo -> Diamante -> Cuadrado
    float morph_time = time * 0.5 + u_bass * 0.6;
    float morph_phase = mod(morph_time, 3.0);
    float dist = 0.0;
    
    if (morph_phase < 1.0) {
        dist = mix(d_square, d_circle, smoothstep(0.0, 1.0, fract(morph_phase)));
    } else if (morph_phase < 2.0) {
        dist = mix(d_circle, d_diamond, smoothstep(0.0, 1.0, fract(morph_phase)));
    } else {
        dist = mix(d_diamond, d_square, smoothstep(0.0, 1.0, fract(morph_phase)));
    }
    
    // 5. Sombreado 3D falso (Phong/Biselado)
    // Calculamos la normal en base a la distancia al centro de la baldosa
    vec2 grad = normalize(grid + vec2(1e-5)) * dist;
    vec3 normal = normalize(vec3(-grad * 2.2, 0.45)); // 0.45 controla el relieve
    
    // Iluminación
    vec3 light_dir = normalize(vec3(0.5, 0.5, 0.8)); // Dirección de la luz
    float diffuse = max(dot(normal, light_dir), 0.0);
    
    vec3 view_dir = vec3(0.0, 0.0, 1.0);
    vec3 reflect_dir = reflect(-light_dir, normal);
    float specular = pow(max(dot(reflect_dir, view_dir), 0.0), 12.0) * 0.5;
    float fresnel = pow(1.0 - max(dot(normal, view_dir), 0.0), 3.0) * 0.35;
    
    // Máscara de baldosa con bisel limpio en los bordes
    float tile_mask = smoothstep(0.46, 0.38, dist);
    
    // 6. Onda de luz propagándose desde el centro
    float dist_center = length(uv - 0.5);
    float wave = sin(dist_center * 10.0 - time * 3.5 + u_bass * 4.0) * 0.4 + 0.6;
    
    // Reactividad general y mezcla
    float brightness = (diffuse * 0.75 + specular + fresnel) * wave * (0.6 + u_beat_intensity * 0.5);
    
    // Asegurar bordes oscuros limpios y limitar el brillo máximo
    float intensity = tile_mask * brightness;
    
    return min(intensity, 0.88);
}