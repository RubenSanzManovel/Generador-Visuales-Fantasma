// PATRÓN 44: Interferencia Moiré Premium "Lava Lamp de Neón"
float pattern_moire_interference(vec2 uv, float time, float amp) {
    vec2 p = uv - 0.5;
    p.x *= u_resolution.x / u_resolution.y;
    
    // 1. Escala reactiva global (efecto Zoom de Bombo)
    // El visual entero respira y hace zoom con el bajo
    float zoom_factor = 1.0 - u_bass * 0.25;
    vec2 p_zoomed = p * zoom_factor;
    
    // 2. Centros Orbitales con Rebote Violento (Beat Snap)
    // Los centros se repelen fuertemente en cada golpe de ritmo,
    // lo que hace que las franjas de interferencia se muevan rápidamente
    float separation = 0.05 + u_beat_intensity * 0.35 + u_bass * 0.15;
    vec2 center_a = vec2(sin(time * 0.8), cos(time * 0.5)) * separation;
    vec2 center_b = vec2(cos(time * 0.7), sin(time * 0.9)) * -separation;
    
    // 3. Deformación Líquida Reactiva (Domain Warping Dinámico)
    // En silencio es muy sutil, en los beats se ondula con gran fuerza
    float warp_intensity = 0.06 + u_bass * 0.25 + u_beat_intensity * 0.15;
    vec2 warp = vec2(
        sin(p_zoomed.y * 3.0 + time * 1.5) * 0.2,
        cos(p_zoomed.x * 3.0 - time * 1.2) * 0.2
    ) * warp_intensity;
    
    vec2 p_a = p_zoomed + warp - center_a;
    vec2 p_b = p_zoomed + warp - center_b;
    
    float dist_a = length(p_a);
    float dist_b = length(p_b);
    
    // 4. Modulación de Frecuencia por Beats (Compresión Radial)
    // En los beats las ondas se multiplican y aprietan, en silencio se dilatan
    float freq_a = 5.0 + u_bass * 8.0;
    float freq_b = 4.5 + u_mid * 6.0;
    
    // 5. Ondas base continuas
    float wave_a = sin(dist_a * freq_a - time * 2.5);
    float wave_b = sin(dist_b * freq_b + time * 2.0);
    
    // 6. Interferencia por ADICIÓN (crea bandas continuas gigantes)
    float sum_wave = (wave_a + wave_b) * 0.5;
    float moire_bands = abs(sum_wave);
    
    // Brillo de neón de las bandas modulado por los bajos
    float glow = smoothstep(0.08, 0.82, moire_bands) * (0.3 + u_bass * 0.7);
    
    // Envolvente Moiré de frecuencia ultra-baja (blobs de interferencia)
    float phase_diff = (dist_a * freq_a - time * 2.5) - (dist_b * freq_b + time * 2.0);
    float moire_envelope = cos(phase_diff) * 0.5 + 0.5;
    
    // Nubes volumétricas que se encienden con el ritmo general de la música
    float volumetric = pow(moire_envelope, 2.5) * (0.4 + u_amplitude * 1.2);
    
    // 7. Núcleos de luz explosivos en los centros (flashes con los beats)
    // El radio del núcleo se expande y su brillo estalla con los bajos
    float core_a = exp(-dist_a * (14.0 - u_bass * 7.0)) * (0.2 + u_bass * 1.8);
    float core_b = exp(-dist_b * (14.0 - u_bass * 7.0)) * (0.2 + u_bass * 1.8);
    
    float final_val = (glow * 0.65 + volumetric * 0.85) * (1.0 + u_beat_intensity * 0.4) + core_a + core_b;
    
    // Atenuación suave hacia los bordes de la pantalla
    float edge_fade = smoothstep(0.95, 0.2, length(p));
    
    return clamp(final_val * edge_fade, 0.0, 1.0);
}
