// Auxiliar: Calcula el centro del túnel en la coordenada Z para simular una curva de gusano o cola
vec2 get_tunnel_center(float z, float time) {
    // Oscilación pseudo-aleatoria continua en X e Y
    float x = sin(z * 0.22 + time * 1.2) * 0.6 + cos(z * 0.11 - time * 0.6) * 0.35;
    float y = cos(z * 0.18 + time * 1.0) * 0.5 + sin(z * 0.08 - time * 0.5) * 0.35;
    
    // Reactividad de latigazo en los graves (la curva se agita con los bombos)
    x += sin(z * 0.45 + time * 4.0) * 0.12 * u_bass;
    y += cos(z * 0.45 + time * 4.0) * 0.12 * u_bass;
    
    return vec2(x, y);
}

// PATRÓN 54: Túnel de Gusano Sinuoso 3D (Worm Tunnel 3D)
float pattern_worm_tunnel(vec2 uv, float time, float amp) {
    vec2 p = uv * 2.0 - 1.0;
    p.x *= u_resolution.x / u_resolution.y;
    
    // Zoom general de seguridad
    p *= 0.95;
    
    // 1. Configurar la cámara para que viaje a lo largo del centro curvado
    float path_z = time * 2.5;
    vec2 cam_xy = get_tunnel_center(path_z, time);
    vec3 ro = vec3(cam_xy, path_z);
    
    // Punto de mira (look-at) situado más adelante en el túnel
    float look_z = path_z + 2.0;
    vec2 look_xy = get_tunnel_center(look_z, time);
    vec3 target = vec3(look_xy, look_z);
    
    // Vectores del espacio de la cámara
    vec3 forward = normalize(target - ro);
    // Vector derecha perpendicular al vector arriba (con un ligero balanceo por rotación)
    vec3 right = normalize(cross(vec3(sin(time * 0.4) * 0.2, 1.0, 0.0), forward));
    vec3 up = normalize(cross(forward, right));
    
    // Rayo de dirección de cámara con lente FOV
    vec3 rd = normalize(p.x * right + p.y * up + forward * 0.9);
    
    float t = 0.05;
    float max_dist = 18.0;
    float intensity = 0.0;
    
    // 2. Raymarching dentro del túnel curvado
    for (int i = 0; i < 40; i++) {
        vec3 pos = ro + rd * t;
        
        // Obtener la desviación local respecto al centro del túnel en esa Z
        vec2 center = get_tunnel_center(pos.z, time);
        vec2 offset_p = pos.xy - center;
        
        // El radio del túnel se ondula rítmicamente simulando los anillos de un gusano
        float r_wall = 1.35 + sin(pos.z * 1.5 - time * 2.5) * 0.12;
        float dist = r_wall - length(offset_p);
        
        // Acumular anillos de neón flotantes muy brillantes en los graves
        float ring_val = sin(pos.z * 2.0 - time * 5.0) * 0.5 + 0.5;
        float ring = pow(ring_val, 14.0);
        intensity += ring * 0.065 * exp(-t * 0.08) * (1.0 + u_bass * 1.8);
        
        // Si el rayo impacta la pared del túnel
        if (dist < 0.01) {
            float angle = atan(offset_p.y, offset_p.x);
            
            // Textura estriada helicoidal psicodélica
            float stripe = fract(angle * 5.0 / 3.14159265 + pos.z * 0.35 - time * 1.5);
            float lines = smoothstep(0.15, 0.0, abs(stripe - 0.5));
            
            // Brillo de textura difuso
            float texture_glow = lines * (0.8 + u_bass * 0.4);
            intensity += texture_glow * 0.85 * exp(-t * 0.11);
            
            // Brillos especulares especulares de agudos (reflejos metálicos en las costillas del gusano)
            float spec = pow(max(dot(reflect(rd, vec3(normalize(offset_p), 0.0)), -forward), 0.0), 8.0);
            intensity += spec * 0.35 * u_treble * exp(-t * 0.1);
            
            break;
        }
        
        // Avanzar el rayo
        t += max(dist * 0.48, 0.025);
        if (t > max_dist) break;
    }
    
    // Destello de chispas en el fondo por los agudos
    float sparkle_pattern = sin(atan(p.y, p.x) * 12.0 + time * 10.0) * cos(length(p) * 15.0 - time * 6.0) * 0.5 + 0.5;
    float sparkles = pow(sparkle_pattern, 10.0) * u_treble * 0.25 * exp(-length(p) * 1.2);
    
    float result = intensity + sparkles;
    return clamp(result, 0.0, 1.0);
}
