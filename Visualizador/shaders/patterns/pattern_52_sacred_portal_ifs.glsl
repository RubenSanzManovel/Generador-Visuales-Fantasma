// PATRÓN 52: Portal de Mandalas Sagrados (Sacred Geometry Portal IFS)
float pattern_sacred_portal_ifs(vec2 uv, float time, float amp) {
    vec2 p = uv - 0.5;
    p.x *= u_resolution.x / u_resolution.y;
    
    // Rotación suave del portal completo
    p = rotate2d(-time * 0.08) * p;
    p *= 1.1 - u_bass * 0.15;
    
    float accum = 0.0;
    
    // Simetría radial de 12 caras para aspecto de rosetón/mandala denso
    float sectors = 12.0;
    float sector_angle = 6.2831853 / sectors;
    
    // Bucle IFS para plegado hiperbólico de gran detalle
    for (int i = 0; i < 5; i++) {
        // 1. Simetría caleidoscópica densa
        float a = atan(p.y, p.x);
        float r = length(p);
        a = mod(a + time * 0.03, sector_angle) - sector_angle * 0.5;
        p = vec2(cos(a), sin(a)) * r;
        
        // 2. Desplazamiento reactivo radial al bombo
        p.x -= 0.38 + u_bass * 0.12;
        p.y = abs(p.y);
        
        // 3. Inversión esférica
        float d2 = dot(p, p) + 0.008;
        p = p / d2;
        
        // 4. Rotación del espejo interno
        p = rotate2d(0.85 + float(i) * 0.35 + time * 0.1) * p;
        
        // Acumular trazos radiales del mandala
        accum += smoothstep(0.06 + u_treble * 0.04, 0.0, abs(p.y)) * 0.85;
    }
    
    accum /= 5.0;
    
    // Ondas concéntricas que fluyen por las nervaduras del mandala
    float ripples = sin(length(p) * 2.0 - time * 3.0 + u_mid * 3.5);
    ripples = smoothstep(0.12, 0.0, abs(ripples));
    
    float final_intensity = accum * 0.65 + ripples * 0.45;
    
    // Añadir brillo en los beats
    final_intensity *= (0.7 + u_beat_intensity * 0.7);
    
    // Resplandor del portal
    float center_glow = 0.22 / (length(uv - 0.5) + 0.28);
    
    float result = final_intensity * 0.8 + center_glow * 0.35;
    return clamp(result, 0.0, 1.0);
}
