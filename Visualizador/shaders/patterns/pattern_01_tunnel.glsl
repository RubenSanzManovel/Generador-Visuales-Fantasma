// PATRÓN 01: Túnel Psicodélico "Viaje de Ácido" 3D - ULTRA REACTIVO
float pattern_tunnel(vec2 uv, float time) {
    // Escalar coordenadas a [-1, 1] y corregir aspect ratio
    vec2 p = uv * 2.0 - 1.0;
    p.x *= u_resolution.x / u_resolution.y;
    
    // Cámara ultra-rápida con balanceo helicoidal reactivo al bajo
    vec3 ro = vec3(sin(time * 1.5) * 0.12, cos(time * 1.2) * 0.12, time * 2.2 + u_bass * 0.6);
    
    // Campo de visión más ancho para mayor inmersión tridimensional (trippy FOV)
    vec3 rd = normalize(vec3(p, 0.75));
    
    float t = 0.05;
    float max_dist = 18.0;
    float intensity = 0.0;
    
    // Raymarching sobre un túnel infinito con torsión
    for (int i = 0; i < 40; i++) {
        vec3 pos = ro + rd * t;
        
        // Torsión en espiral del espacio Z
        float twist = pos.z * 0.38 + time * 0.8;
        vec2 twisted_xy = rotate2d(twist) * pos.xy;
        
        float angle = atan(twisted_xy.y, twisted_xy.x);
        
        // El radio del túnel se ondula lateral y longitudinalmente de forma agresiva
        float r_wall = 1.32 + sin(pos.z * 1.4 - time * 3.5 + angle * 3.0) * (0.12 + u_bass * 0.28);
        float dist = r_wall - length(pos.xy);
        
        // Acumular anillos de luz volumétricos neón que flotan hacia la cámara
        float ring_val = sin(pos.z * 2.2 - time * 6.0) * 0.5 + 0.5;
        float ring = pow(ring_val, 16.0); // Anillos muy definidos
        intensity += ring * 0.065 * exp(-t * 0.08) * (1.0 + u_bass * 2.0);
        
        if (dist < 0.01) {
            // Impacto en la pared: Calcular textura de interferencia óptica psicodélica
            float pattern1 = sin(angle * 6.0 + pos.z * 2.5 - time * 5.0);
            float pattern2 = cos(angle * 4.0 - pos.z * 3.5 + time * 4.0);
            float waves = sin(pattern1 * 3.5 + pattern2 * 3.5 + time * 2.0) * 0.5 + 0.5;
            
            // Líneas de corriente helicoidales
            float strip = fract(angle * 4.0 / 3.14159 + pos.z * 0.4 - time * 1.8);
            float lines = smoothstep(0.14, 0.0, abs(strip - 0.5));
            
            float trippy_texture = mix(waves, lines, 0.5);
            
            // Sumar brillo de la pared con atenuación por profundidad
            intensity += trippy_texture * 0.88 * exp(-t * 0.12) * (0.8 + u_bass * 0.6);
            break;
        }
        
        // Avanzar el rayo
        t += max(dist * 0.45, 0.02);
        if (t > max_dist) break;
    }
    
    // Sparkles de alta frecuencia (agudos) que destellan en el túnel
    float sparkle_pattern = sin(atan(p.y, p.x) * 16.0 + time * 12.0) * cos(length(p) * 20.0 - time * 8.0) * 0.5 + 0.5;
    float sparkles = pow(sparkle_pattern, 12.0) * u_treble * 0.28 * exp(-length(p) * 1.5);
    
    // Destellos generales por golpes de agudos
    float flashes = sin(time * 15.0) * u_treble * 0.12;
    
    float result = intensity + sparkles + flashes;
    return clamp(result, 0.0, 1.0);
}