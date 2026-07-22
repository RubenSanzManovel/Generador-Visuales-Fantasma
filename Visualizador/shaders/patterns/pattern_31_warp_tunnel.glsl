// PATRÓN 31: Túnel de Distorsión
float pattern_warp_tunnel(vec2 uv, float time, float amp) {
    vec2 p = uv - 0.5;
    p.x *= u_resolution.x / u_resolution.y;
    float r = length(p);
    float a = atan(p.y, p.x);

    // Factor digital segmentado en anillos concéntricos que pulsan con la amplitud general
    float glitch_factor = floor(r * (18.0 - u_bass * 6.0) + amp * 10.0) / 18.0;
    
    // El túnel fluye y avanza hacia adelante
    float depth = glitch_factor * 12.0 - time * 1.5 - u_mid * 2.0; 
    
    // Torsión espiral continua que se intensifica dinámicamente con los golpes de bajos
    float twist = sin(r * 5.0 - time * 1.0) * (0.8 + u_bass * 1.6);
    
    // Haces espirales del túnel
    float tunnel = sin(a * 6.0 + depth + twist);
    
    // Anillos concéntricos digitales que viajan a lo largo del túnel reactivos a agudos
    float rings = sin(glitch_factor * 24.0 - time * 2.0 - u_treble * 3.0) * 0.5 + 0.5;
    
    // Glow neón central en el punto ciego del túnel que late con el beat
    float center_glow = exp(-r * 7.5) * (0.15 + u_beat_intensity * 0.55);
    
    // Mezcla final de rejilla de túnel modulada por el bajo + destello central
    float intensity = (tunnel * 0.5 + 0.5) * rings * (0.7 + u_bass * 0.6) + center_glow;
    
    return clamp(intensity, 0.0, 1.0);
}