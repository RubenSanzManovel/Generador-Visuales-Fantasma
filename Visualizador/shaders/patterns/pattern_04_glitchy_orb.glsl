// Función de mezcla suave para efecto Metaball (líquido estirable)
float smin(float a, float b, float k) {
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    return mix(b, a, h) - k * h * (1.0 - h);
}

// Función de distancia para el orbe (esfera deformada por ondas + gotas metaball que se separan)
float map_orb(vec3 p, float time) {
    float r_base = 0.56 + u_bass * 0.28 + u_beat_intensity * 0.12;
    float d_sphere = length(p) - r_base;
    
    // Normalización segura para evitar división por cero
    vec3 np = p / (length(p) + 0.0001);
    float wave1 = sin(np.x * 6.0 + time * 2.5) * cos(np.y * 6.0 - time * 1.8) * sin(np.z * 6.0 + time * 2.0);
    float wave2 = cos(np.x * 12.0 - time * 4.0) * sin(np.y * 10.0 + time * 3.5) * cos(np.z * 8.0 - time * 2.5);
    
    // Escala de deformación modulada por graves, medios y beats
    float deform_scale = (0.08 + u_mid * 0.15 + u_bass * 0.12) * (1.0 + u_beat_intensity * 1.5);
    float d_noise = (wave1 * 0.8 + wave2 * 0.4) * deform_scale;
    
    float d_body = d_sphere + d_noise;
    
    // --- GIGANTESCAS GOTAS QUE SE ESTIRAN Y SE SEPARAN LENTAMENTE (METABALLS 3D) ---
    float d_droplets = 1000.0;
    float active_bass = smoothstep(0.2, 0.6, u_bass);
    
    // 6 gotas de gran tamaño para evitar saturar el espacio
    for (int i = 0; i < 6; i++) {
        float fi = float(i);
        // Direcciones 3D distribuidas angularmente que rotan lentamente
        float theta = fi * 1.047 + time * 0.35; // 60 grados (360/6)
        float phi = sin(fi * 2.3 + time * 0.18) * 0.5;
        vec3 dir = vec3(cos(theta)*cos(phi), sin(theta)*cos(phi), sin(phi));
        
        // Ciclo mucho más lento (time * 0.45) para que floten despacio hacia fuera
        float travel = fract(time * 0.45 + fi * 0.16);
        
        // Desplazamiento radial muy amplio (hasta 2.0) para que se alejen hasta los bordes
        vec3 drop_pos = dir * (r_base + 0.05 + travel * 2.0 * (0.3 + active_bass * 0.7));
        
        // Tamaño gigantesco de gota (0.24 base, encogiéndose despacio a 0.55 * travel)
        float drop_size = 0.24 * (1.0 - travel * 0.55) * (0.35 + active_bass * 0.65);
        
        float d_drop = length(p - drop_pos) - drop_size;
        
        // Fusión suave entre gotas
        d_droplets = smin(d_droplets, d_drop, 0.14);
    }
    
    // Fusión metaball del cuerpo con las gotas con puente de estiramiento muy amplio (0.28)
    // Esto crea un estiramiento de chicle/líquido espeso muy visible antes del desprendimiento
    return smin(d_body, d_droplets, 0.28);
}

// Estimación de la normal usando diferencias centrales (compatible con AMD)
vec3 get_orb_normal(vec3 p, float time) {
    vec2 e = vec2(0.005, 0.0);
    return normalize(vec3(
        map_orb(p + e.xyy, time) - map_orb(p - e.xyy, time),
        map_orb(p + e.yxy, time) - map_orb(p - e.yxy, time),
        map_orb(p + e.yyx, time) - map_orb(p - e.yyx, time)
    ));
}

// PATRÓN 04: Esfera Neon 3D Raymarched - NEBULOSA Y ENERGÍA ULTRA-REACTIVA
float pattern_glitchy_orb(vec2 uv, float time, float amp) {
    // Escalar coordenadas a [-1, 1] y corregir aspect ratio
    vec2 p = uv * 2.0 - 1.0;
    p.x *= u_resolution.x / u_resolution.y;
    
    // Cámara posicionada frente a la esfera
    vec3 ro = vec3(0.0, 0.0, -2.4);
    vec3 rd = normalize(vec3(p, 1.25));
    
    float t = 0.0;
    float max_dist = 5.0;
    float glow = 0.0;
    
    // Raymarching loop para esculpir y añadir brillo volumétrico
    for (int i = 0; i < 35; i++) {
        vec3 pos = ro + rd * t;
        float dist = map_orb(pos, time);
        
        if (dist < 0.01) {
            // Impacto: Calcular normal y sombreado 3D de alta gama para evitar un orbe plano (manchurrón)
            vec3 N = get_orb_normal(pos, time);
            vec3 light_dir = normalize(vec3(1.0, 1.2, -1.5));
            vec3 view_dir = normalize(ro - pos);
            
            // Iluminación Diffuse + Specular (Brillo plástico/metálico premium)
            float diff = max(dot(N, light_dir), 0.0);
            vec3 half_dir = normalize(light_dir + view_dir);
            float spec = pow(max(dot(N, half_dir), 0.0), 32.0);
            
            // Efecto Fresnel para bordes traslúcidos brillantes
            float fresnel = pow(1.0 - max(dot(N, view_dir), 0.0), 3.0);
            
            float lighting = 0.22 + diff * 0.65 + spec * 0.85 + fresnel * 0.45;
            
            // Sumar iluminación del orbe
            glow += lighting * 1.85;
            break;
        }
        
        // Halo neón que envuelve al orbe (volumétrico)
        glow += 0.012 / (0.015 + abs(dist));
        t += dist * 0.75;
        if (t > max_dist) break;
    }
    
    // --- FONDO DE TÚNEL DE ANILLOS CONCÉNTRICOS EN EXPANSIÓN ---
    float r = length(p);
    float a = atan(p.y, p.x);
    float safe_r = max(r, 0.015);
    
    // Coordenada logarítmica para perspectiva del túnel (caída de velocidad por distancia)
    // El time * 4.5 hace que se expandan a gran velocidad hacia afuera
    float tunnel_v = log(safe_r) * 5.0 - time * 4.5 - u_smooth_amplitude * 2.5;
    
    // Anillos con ligera deformación ondulada para mayor sensación de vórtice
    float ring_pat = sin(tunnel_v + sin(a * 4.0 + time * 0.5) * 0.35);
    
    // Grosor del anillo más ancho y visible (se expande con los medios de la música)
    float ring_thickness = 0.16 + u_mid * 0.10;
    float rings = smoothstep(ring_thickness, 0.0, abs(ring_pat));
    
    // Desvanecer cerca de la esfera central para legibilidad y efecto de profundidad infinita
    float depth_fade = smoothstep(0.12, 0.85, r);
    
    // Brillo de los anillos concéntricos intensificado por los graves y beats
    float tunnel_glow = rings * depth_fade * (0.06 + u_bass * 0.15 + u_beat_intensity * 0.08);
    
    // Shimmer/brillo de agudos en perspectiva (destellos rápidos con hi-hats en los bordes)
    float shimmer = sin(a * 8.0) * cos(tunnel_v * 3.0) * u_treble * 0.08 * depth_fade;
    
    float result = glow * (0.35 + u_amplitude * 0.8) + tunnel_glow + shimmer;
    return clamp(result, 0.0, 1.0);
}