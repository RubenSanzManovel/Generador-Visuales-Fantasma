// PATRÓN 36: Pelo Cayendo (Falling Hair) - FLUJO SUAVE & SEDOSO CON TEXTURA
float pattern_falling_hair(vec2 uv, float time, float amp) {
    float hair = 0.0;
    
    // Configuración de columnas (50 columnas horizontales)
    float num_cols = 50.0;
    float col_idx = floor(uv.x * num_cols);
    
    // Fuerza de viento global muy suave y lenta (restaurada al original)
    float wind = sin(time * 0.4) * 0.015 * (1.0 + u_smooth_amplitude * 0.5);
    
    // Iterar sobre la columna actual y sus dos vecinas para cubrir la distorsión horizontal
    for (float offset = -1.0; offset <= 1.0; offset += 1.0) {
        float c = col_idx + offset;
        
        // Semilla única para la columna
        float seed = random(vec2(c * 12.9898, 78.233));
        
        // Velocidad de caída fluida y suave reactiva a la amplitud general suavizada (restaurada al original)
        float base_speed = 0.06 + seed * 0.08;
        float fall_speed = base_speed * (1.0 + u_smooth_amplitude * 1.0);
        
        // Tiempo de ciclo y progreso vertical
        float cycle_time = time * fall_speed + seed * 100.0;
        float y_progress = fract(cycle_time) * 1.8 - 0.4;
        
        // Longitud del mechón
        float strand_length = 0.35 + seed * 0.45;
        
        // Alturas de inicio y fin del mechón
        float y_top = 1.2 - y_progress;
        float y_bottom = y_top - strand_length;
        
        // Solo procesar si el mechón está en el rango vertical visible (con un margen)
        if (uv.y < y_top + 0.05 && uv.y > y_bottom - 0.05) {
            float t = (y_top - uv.y) / strand_length;
            t = clamp(t, 0.0, 1.0);
            
            // X central de esta columna
            float x_center = (c + 0.5) / num_cols;
            
            // Ondulación principal fluida y lenta (restaurada al original)
            float wave_freq = 3.5 + seed * 4.5;
            float wave_amp = (0.01 + seed * 0.015) * (1.0 + u_smooth_amplitude * 0.6);
            float wave = sin(uv.y * wave_freq - time * 0.8 + seed * 6.28) * 
                         cos(uv.y * wave_freq * 0.3 + time * 0.5) * wave_amp;
            
            // Aplicar viento y juntar ondas
            float x_offset = wave + wind * t;
            
            // Dibujar 3 fibras individuales por columna para simular un mechón sedoso
            for (float fiber = -1.0; fiber <= 1.0; fiber += 1.0) {
                // Desfase horizontal y de fase para cada fibra del mechón
                float fiber_offset_x = fiber * (0.0025 + seed * 0.0025) * (1.0 - t * 0.4);
                float fiber_phase = fiber * 1.2 + seed * 3.14;
                
                // Ondulación interna muy sutil y suave de la fibra
                float fiber_wave = sin(uv.y * 10.0 + time * 1.2 + fiber_phase) * 0.0006 * (1.0 + u_smooth_amplitude * 0.4);
                
                float expected_x = x_center + x_offset + fiber_offset_x + fiber_wave;
                float dist_x = abs(uv.x - expected_x);
                
                // Grosor de la fibra muy fino (restaurado al original)
                float thickness = (0.0005 + (1.0 - t) * 0.0008) * (1.0 + u_smooth_amplitude * 0.3);
                
                // Intensidad y suavizado de la fibra
                float fiber_intensity = smoothstep(thickness, 0.0, dist_x);
                
                // Difuminado suave en los extremos del mechón
                float edge_fade = smoothstep(0.0, 0.15, t) * smoothstep(1.0, 0.85, t);
                
                // Brillo de cada fibra, pulsando suavemente al ritmo general de la música (restaurado al original)
                float brightness = (fiber == 0.0) ? 2.2 : 1.2; // Fibra central más brillante
                float fiber_glow = fiber_intensity * edge_fade * brightness * (1.0 + u_smooth_amplitude * 1.2);
                
                // --- NUEVO EFECTO: IMPULSO ELÉCTRICO RECTILÍNEO POR BEATS ---
                // Un pulso de luz de alta intensidad recorre el hilo hacia abajo al compás de cada golpe (beat_intensity)
                float pulse_pos = fract(time * 2.2 - seed * 3.0);
                float energy_pulse = smoothstep(0.12, 0.0, abs(t - pulse_pos)) * u_beat_intensity * 1.2;
                
                fiber_glow += fiber_intensity * edge_fade * energy_pulse * 1.8;
                
                hair += fiber_glow;
            }
            
            // Brillo resplandeciente suave en la punta del mechón (restaurado al original)
            float tip_expected_x = x_center + (sin(y_bottom * wave_freq - time * 0.8 + seed * 6.28) * 
                                  cos(y_bottom * wave_freq * 0.3 + time * 0.5) * wave_amp) + wind;
            vec2 tip_pos = vec2(tip_expected_x, y_bottom);
            float tip_dist = distance(uv, tip_pos);
            float tip_glow = smoothstep(0.02, 0.0, tip_dist) * (0.15 + u_smooth_amplitude * 1.5) * (seed * 0.5 + 0.5);
            hair += tip_glow;
        }
    }
    
    // --- FONDO DE CASCADA VOLUMÉTRICA DE LUZ ---
    // Haces de luz suaves que caen lentamente en segundo plano
    float light_rays = sin(uv.x * 6.0 + wind * 3.0 + time * 0.1) * 
                       cos(uv.x * 3.0 - time * 0.05) * 0.5 + 0.5;
    
    float ray_flow = sin(uv.y * 2.5 + time * 0.5 + light_rays * 1.5);
    float ray_intensity = light_rays * (ray_flow * 0.5 + 0.5) * (0.03 + u_smooth_amplitude * 0.05);
    
    // Destello de neblina reactiva suave
    float dist_center = length(uv - 0.5);
    float pulse = (0.03 + u_smooth_amplitude * 0.06) * (1.0 - dist_center * 0.6);
    
    // Textura fluida y orgánica de fondo (Domain Warping sutil)
    vec2 p = uv * 3.5;
    p.x += sin(time * 0.15 + p.y) * 0.25;
    p.y += cos(time * 0.1 + p.x) * 0.25 - time * 0.08; // Caída lenta de la textura
    p += u_smooth_amplitude * 0.25; // Reacción de posición a la música
    
    float tex = sin(p.x + sin(p.y)) * cos(p.y + cos(p.x)) * 0.5 + 0.5;
    float tex_react = tex * (0.012 + u_smooth_amplitude * 0.025); // Muy sutil
    
    float background = ray_intensity + pulse + tex_react;
    
    // Mezclar el cabello luminoso con el fondo atmosférico
    float final_value = mix(background, hair, clamp(hair, 0.0, 1.0));
    
    return final_value;
}