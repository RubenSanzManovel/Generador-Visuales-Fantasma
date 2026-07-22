// PATRÓN 49: Caleidoscopio de Cristales Cósmicos (Cosmic Crystal IFS)
float pattern_cosmic_crystal_ifs(vec2 uv, float time, float amp) {
    vec2 p = uv - 0.5;
    p.x *= u_resolution.x / u_resolution.y;
    
    // Rotación global reactiva
    p = rotate2d(time * 0.06 + u_bass * 0.15) * p;
    p *= 1.2 - u_bass * 0.1;
    
    float accum = 0.0;
    float sectors = 5.0; // Simetría pentagonal
    float sector_angle = 6.2831853 / sectors;
    
    // Bucle IFS para plegado de espejos fractales
    for (int i = 0; i < 5; i++) {
        // 1. Caleidoscopio angular
        float a = atan(p.y, p.x);
        float r = length(p);
        a = mod(a, sector_angle) - sector_angle * 0.5;
        p = vec2(cos(a), sin(a)) * r;
        
        // 2. Desplazamiento reactivo al bombo
        p.x -= 0.32 + u_bass * 0.08;
        p = abs(p);
        
        // 3. Inversión esférica
        float d2 = dot(p, p) + 0.003;
        p = p / d2;
        
        // 4. Rotación del espejo interno
        p = rotate2d(0.6 + float(i) * 0.3 + time * 0.15) * p;
        
        // Acumular trazos de coordenadas finas (cristalinas)
        accum += exp(-abs(p.x) * 1.8) + exp(-abs(p.y) * 1.8);
    }
    
    accum /= 9.0;
    
    // Ondas secundarias de agudos que destellan en los cristales
    float crystal_shine = sin(length(p) * 3.0 - time * 4.0 + u_treble * 5.0) * 0.5 + 0.5;
    float final_intensity = accum * 0.7 + pow(crystal_shine, 4.0) * u_treble * 0.55;
    
    // Halo central
    float center_glow = 0.20 / (length(uv - 0.5) + 0.3);
    
    float result = final_intensity * (0.65 + u_beat_intensity * 0.5) + center_glow * 0.25;
    return clamp(result, 0.0, 1.0);
}
