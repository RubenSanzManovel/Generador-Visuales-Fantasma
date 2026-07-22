// PATRÓN 32: Sueños Pixelados (Versión LENTA Y MENOS EPILÉPTICA)
float pattern_pixelated_dreams(vec2 uv, float time, float amp) {
    float bass_pulse = smoothstep(0.15, 0.8, u_bass);
    float slow_time = time * 0.015;

    // 1. Tamaño de píxel reactivo y lento
    float pixelSize = 28.0 + sin(slow_time + u_bass * 1.5) * (6.0 + bass_pulse * 6.0);
    vec2 pixelated = floor(uv * pixelSize) / pixelSize;

    // 2. Patrones base (muy lentos)
    float pattern1 = sin(pixelated.x * 35.0 + slow_time * 0.6 + u_mid * 2.0);
    float pattern2 = cos(pixelated.y * 35.0 - slow_time * 0.5 + u_treble * 1.8);

    // 3. Combinación más suave
    float combined_pattern = pow(abs(pattern1 * pattern2), 4.0);

    // 4. Ruido que cambia con los bajos (pulsos)
    float noise_time = floor(time * (0.5 + bass_pulse * 3.0));
    float noise = random(pixelated + noise_time) * (0.2 + bass_pulse * 0.8);

    // 5. Rejilla de píxeles sutil
    float grid = (smoothstep(0.02, 0.0, fract(uv.x * pixelSize)) + smoothstep(0.02, 0.0, fract(uv.y * pixelSize))) * 0.04;

    // 6. Combinación final
    return (combined_pattern * 0.8 + noise * 0.6) * (0.9 + amp * 1.1) + grid;
}