// PATRÓN 25: Aurora Boreal Fluyente - SIMPLEX NOISE EN GPU
float pattern_aurora_flow(vec2 uv, float time, float amp) {
    vec2 p = uv;
    
    // Curvar lateralmente según la altura Y, los bajos y el tiempo para dar un fluir sinuoso reactivo
    p.x += sin(p.y * 2.5 + time * 1.5) * (0.05 + u_bass * 0.25);
    
    float flow = 0.0;
    
    // Crear 4 capas de auroras ondulantes usando Simplex Noise 3D
    for (int i = 0; i < 4; i++) {
        float fi = float(i);
        
        // Coordenadas de ruido con deformación ondulante reactiva
        vec3 noise_coord = vec3(p.x * (1.2 + fi * 0.4) - time * (0.15 + fi * 0.08), 
                                p.y * (0.8 + fi * 0.2) + sin(p.x * 2.0 + time * 0.5) * 0.1, 
                                time * 0.12 + u_bass * 0.08);
                                
        // Generar la onda de la aurora usando el ruido Simplex 3D
        float noise_val = snoise(noise_coord + vec3(fi * 20.0));
        
        // Desplazar las coordenadas Y para simular distorsión fluida reactiva
        p.y += noise_val * 0.07 * (0.5 + u_mid * 0.8);
        
        // Calcular la intensidad de esta capa de aurora (perfil de campana vertical suave)
        float vertical_profile = exp(-pow(p.y - (0.35 + fi * 0.12), 2.0) / (0.015 + u_bass * 0.01));
        
        // Sumar la intensidad escalada
        flow += (noise_val * 0.5 + 0.5) * vertical_profile * (0.4 + u_amplitude * 1.4);
    }
    
    // Shimmering de agudos (estrellas/brillos superpuestos en la aurora)
    float shimmer = snoise(vec3(p * 45.0, time * 3.5)) * u_treble * 0.12;
    
    float result = flow * 0.28 + shimmer;
    return clamp(result, 0.0, 1.0);
}