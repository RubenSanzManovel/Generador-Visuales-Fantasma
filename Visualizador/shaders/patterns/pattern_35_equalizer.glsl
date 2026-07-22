// PATRÓN 35: Ecualizador de Espectro FFT Real - Muestreo Directo en 1D
float pattern_equalizer(vec2 uv, float time, float amp) {
    float num_bars = 64.0; // Número de barras del ecualizador
    float bar_index = floor(uv.x * num_bars);
    float bar_fract = fract(uv.x * num_bars);
    
    // Posición normalizada de la barra en el rango [0, 1]
    float bar_pos = (bar_index + 0.5) / num_bars;
    
    // Mapear de forma simétrica: graves en el centro y agudos a los extremos
    // Esto hace que el ecualizador luzca mucho más balanceado visualmente
    float spec_coord = abs(bar_pos - 0.5) * 2.0;
    
    // Muestreo con curva exponencial no lineal enfocada en frecuencias activas.
    // Sumamos un offset de 0.0045 para descartar la zona de sub-graves inaudibles (<30Hz) en el centro,
    // garantizando que las barras centrales se muevan dinámicamente en todas las canciones.
    float mapped_coord = 0.0045 + pow(spec_coord, 1.3) * 0.1755;
    float fft_val = texture1D(u_fft_texture, mapped_coord).r;
    
    // Compensación de ganancia por frecuencia independiente con valores moderados
    float frequency_gain = 0.7 + pow(spec_coord, 1.6) * 6.5;
    float height_raw = fft_val * frequency_gain;
    
    // Curva de compresión suave (soft compression) para evitar que las barras toquen un techo plano
    // Esto asegura que el ecualizador siempre conserve su forma de espectro (picos y valles dinámicos)
    float shape_val = height_raw / (1.0 + height_raw);
    
    // Altura máxima controlada
    float target_max = 0.44 + u_beat_intensity * 0.06;
    float height = shape_val * target_max;
    
    // Ondulación estética suave
    height += sin(time * 2.0 + bar_index * 0.4) * 0.005;
    
    // Limitar altura mínima
    height = max(height, 0.005);
    
    // --- CENTRO EN MITAD DE LA PANTALLA CON EFECTO ESPEJO ---
    float center = 0.5;
    float abs_distance = abs(uv.y - center);
    
    // Ancho de barra con espacio entre ellas
    float bar_mask = smoothstep(0.48, 0.42, abs(bar_fract - 0.5));
    
    // Llenado de barra
    float bar_fill = smoothstep(height + 0.015, height - 0.015, abs_distance) * bar_mask;
    
    // --- FONDO TEXTURIZADO SUTIL ---
    // 1. Rejilla digital muy fina que se desplaza lentamente
    vec2 grid_uv = uv + time * 0.015;
    float grid = sin(grid_uv.x * 60.0) * sin(grid_uv.y * 60.0);
    grid = smoothstep(0.98, 1.0, grid) * 0.035;
    
    // 2. Brillo central difuso reactivo al bajo (reacción de solo el 25%)
    float center_glow = exp(-abs(uv.y - 0.5) * 3.5) * 0.035 * (1.0 + u_bass * 0.25);
    
    // 3. Neblina/oleaje de fondo muy lento (reacción de solo el 20%)
    float waves = sin(uv.x * 3.0 + time * 0.1) * cos(uv.y * 2.5 - time * 0.08) * 0.5 + 0.5;
    float nebula = waves * 0.04 * (1.0 + u_amplitude * 0.2);
    
    float background = center_glow + grid + nebula;
    
    // Combinar barra con fondo
    float result = mix(background, bar_fill * (0.8 + height * 0.5), bar_fill);
    
    return clamp(result, 0.0, 1.0);
}