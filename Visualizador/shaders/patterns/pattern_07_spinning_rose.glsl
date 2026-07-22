float pattern_spinning_rose(vec2 uv, float time, float amp) {
    vec2 p = uv - 0.5;
    p.x *= u_resolution.x / u_resolution.y;
    float r = length(p);
    float a = atan(p.y, p.x);
    
    // Morphing de pétalos (Esencia)
    float pet_val = 6.0 + u_mid * 4.0;
    float pet1 = floor(pet_val);
    float pet2 = pet1 + 1.0;
    float weight = fract(pet_val);
    
    float swirl = sin(a * 18.0 + time * 1.1) * 0.08;
    float core = 0.32 + sin(time * 0.6 + u_bass * 2.0) * 0.04;
    
    // --- 1. FLOR PRINCIPAL (SEAMLESS) ---
    float rad1 = core + 0.18 * cos(pet1 * a + time * 0.9) + swirl;
    float rad2 = core + 0.18 * cos(pet2 * a + time * 0.9) + swirl;
    float rad = mix(rad1, rad2, weight);
    
    float bloom = smoothstep(rad, rad - 0.08, r);
    float edge = smoothstep(rad + 0.015, rad - 0.015, r);
    
    // --- 2. FLOR ECO SECUNDARIA (OPCIÓN 5) ---
    // Más grande, rotación en sentido opuesto y más suave detrás de la flor
    float a_echo = a - time * 0.35;
    float rad1_echo = (core + 0.12) + 0.22 * cos(pet1 * a_echo - time * 0.45);
    float rad2_echo = (core + 0.12) + 0.22 * cos(pet2 * a_echo - time * 0.45);
    float rad_echo = mix(rad1_echo, rad2_echo, weight) + swirl * 0.5;
    
    float echo = smoothstep(rad_echo, rad_echo - 0.16, r) * 0.38 * (0.4 + u_treble * 0.6);
    
    // --- 3. VENAS DE ENERGÍA EN PÉTALOS (OPCIÓN 2) ---
    // Resalta el eje central de cada pétalo con destellos reactivos
    float petal_cos1 = cos(pet1 * a + time * 0.9);
    float petal_cos2 = cos(pet2 * a + time * 0.9);
    float petal_dist = mix(petal_cos1, petal_cos2, weight);
    float vein = smoothstep(0.92, 1.0, petal_dist); // Eje central del pétalo
    float radial_gradient = 1.0 - smoothstep(0.0, rad, r);
    float energy_veins = vein * radial_gradient * 0.7 * (1.0 + u_beat_intensity * 1.5);
    
    // --- 4. GRANDES ANILLOS DE FONDO Y SATÉLITES (OPCIÓN 1 MEJORADA) ---
    // Anillos concéntricos de mayor diámetro detrás de la flor que pulsan con graves
    // Su intensidad moderada (0.28) hará que el filtro de color (LUT) los tiña de un tono complementario
    float ring1 = smoothstep(0.018, 0.0, abs(r - (0.42 + u_bass * 0.08)));
    float ring2 = smoothstep(0.015, 0.0, abs(r - (0.54 + u_bass * 0.10)));
    float bg_rings = (ring1 + ring2) * 0.28 * (0.6 + u_bass * 0.4);
    
    // Satélites orbitando en dirección contraria
    float a_sat = a + time * 2.2;
    float dots = sin(a_sat * 6.0) * 0.5 + 0.5;
    dots = pow(dots, 35.0); // Puntos circulares afilados
    float dots_ring = smoothstep(0.015, 0.0, abs(r - (0.26 + u_bass * 0.05)));
    float satellites = dots * dots_ring * 0.6 * (1.0 + u_bass * 1.0);
    
    float background_mandala = max(bg_rings, satellites);
    
    // --- ESTRUCTURA GENERAL DE FONDO ---
    float glow = pow(max(0.0, 1.0 - r / 0.75), 2.2) * (0.25 + u_treble * 0.75);
    
    float bg = sin(a * 6.0 + time * 0.4 + u_mid * 2.0) * cos(r * 12.0 - time * 0.6 + u_bass * 4.0);
    bg = bg * 0.12 + 0.15;
    
    float pulse = 1.0 + u_beat_intensity * 0.35;
    
    // --- ACOPLAMIENTO MULTICAPA ---
    // Colocar la flor principal sobre el fondo (echo, grandes anillos y satélites)
    float background_total = max(background_mandala, echo);
    float main_flower = bloom * 0.75;
    
    float result = mix(background_total, main_flower, bloom);
    
    // Superponer bordes neón y venas de energía sobre la flor
    result = (result + edge * 0.5 + energy_veins) * pulse + glow * 0.4 + bg;
    
    return clamp(result, 0.0, 1.0);
}