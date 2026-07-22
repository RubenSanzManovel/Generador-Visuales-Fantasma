#version 120

uniform sampler2D u_scene_tex;
uniform sampler2D u_bloom_tex;
uniform vec2 u_resolution;

uniform float u_bloom_intensity;
uniform float u_vignette_intensity;
uniform float u_contrast;
uniform float u_saturation;
uniform int u_color_grading;

uniform float u_amplitude;
uniform float u_treble;
uniform float u_midi_phaser;
uniform float u_time;

// Función para rotar tono (hue) de un color RGB
vec3 rotate_hue(vec3 rgb, float angle) {
    vec3 k = vec3(0.57735, 0.57735, 0.57735);
    float cosAngle = cos(angle);
    return rgb * cosAngle + cross(k, rgb) * sin(angle) + k * dot(k, rgb) * (1.0 - cosAngle);
}

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;
    
    // 1. Phaser Wobble (Ondulación líquida/metálica en pantalla completa)
    if (u_midi_phaser > 0.01) {
        float wave_factor = u_midi_phaser * 0.015;
        uv.x += sin(uv.y * 30.0 + u_time * 9.0) * wave_factor;
        uv.y += cos(uv.x * 30.0 - u_time * 9.0) * wave_factor;
    }
    
    vec2 to_center = uv - 0.5;
    float dist_from_center = length(to_center);
    
    // Aberración cromática normal reactiva al audio
    vec2 normal_shift = normalize(to_center) * dist_from_center * dist_from_center * (u_amplitude * 0.025 + u_treble * 0.018);
    
    // 2. Phaser RGB split (Oscilación horizontal completa sin atenuar por distancia al centro)
    vec2 phaser_shift = vec2(0.0);
    if (u_midi_phaser > 0.01) {
        phaser_shift.x = sin(u_time * 4.5) * u_midi_phaser * 0.045;
    }
    
    vec2 final_shift = normal_shift + phaser_shift;
    
    // Muestreo con separación de canales (Aberración Cromática)
    vec3 color;
    color.r = texture2D(u_scene_tex, uv - final_shift).r;
    color.g = texture2D(u_scene_tex, uv).g;
    color.b = texture2D(u_scene_tex, uv + final_shift).b;
    
    // Mezclar con el Bloom de forma aditiva suavizada
    vec3 bloom = texture2D(u_bloom_tex, uv).rgb;
    color += bloom * u_bloom_intensity * 1.5;
    
    // Luminancia base
    float lum = dot(color, vec3(0.299, 0.587, 0.114));
    
    // --- FILTROS DE GRADACIÓN DE COLOR (LUTs matemáticas) ---
    if (u_color_grading == 1) {
        // 1. Teal & Orange (Cinematográfico de alto contraste)
        float shadow = 1.0 - smoothstep(0.0, 0.6, lum);
        float highlight = smoothstep(0.35, 0.95, lum);
        vec3 teal = vec3(0.08, 0.62, 0.72);
        vec3 orange = vec3(0.98, 0.52, 0.15);
        color = mix(color, teal * lum * 1.6, shadow * 0.38);
        color = mix(color, orange * lum * 1.6, highlight * 0.38);
    } 
    else if (u_color_grading == 2) {
        // 2. Cyberpunk (Magenta & Cyan neón)
        vec3 cyan = vec3(0.0, 0.85, 0.98);
        vec3 magenta = vec3(0.92, 0.05, 0.68);
        vec3 cyberpunk_tint = mix(cyan, magenta, uv.y + sin(uv.x * 2.0) * 0.1);
        color = mix(color, color * cyberpunk_tint * 2.2, 0.35);
        // Boost en altas luces
        color += smoothstep(0.7, 1.0, color) * magenta * 0.4;
    }
    else if (u_color_grading == 3) {
        // 3. Vintage Warm (Desaturado, cálido, sombras levantadas)
        vec3 warm_tint = vec3(0.98, 0.88, 0.72);
        color = mix(color * warm_tint, color, 0.3);
        color.rgb += vec3(0.035, 0.02, 0.0); // Sombras lavadas/cálidas
        color = clamp(color, 0.0, 1.0);
    }
    else if (u_color_grading == 4) {
        // 4. Monocromático de Alto Contraste (Blanco y Negro dramático)
        color = vec3(lum);
        color = clamp((color - 0.5) * 1.35 + 0.5, 0.0, 1.0);
    }
    
    // Aplicar contraste general
    color = clamp((color - 0.5) * u_contrast + 0.5, 0.0, 1.0);
    
    // Aplicar saturación general (recálculo de lum)
    float new_lum = dot(color, vec3(0.299, 0.587, 0.114));
    color = mix(vec3(new_lum), color, u_saturation);
    
    // Aplicar Viñeta
    if (u_vignette_intensity > 0.0) {
        float vig = smoothstep(0.85, 0.28, dist_from_center);
        vig = mix(1.0, vig, u_vignette_intensity);
        color *= vig;
    }
    
    // 3. Phaser Psychedelic Hue Sweep (Barrido arcoíris infinito)
    if (u_midi_phaser > 0.01) {
        float hue_angle = u_time * 3.5 * u_midi_phaser;
        color = rotate_hue(color, hue_angle);
    }
    
    gl_FragColor = vec4(clamp(color, 0.0, 1.0), 1.0);
}
