float pattern_fractal_noise(vec2 uv, float time, float amp) {
    vec2 p = uv * 4.0;
    float noise = 0.0;
    float amplitude = 1.0;
    for (int i = 0; i < 5; i++) {
        noise += sin(p.x * amplitude + time + u_bass * 3.0) * cos(p.y * amplitude - time + u_mid * 3.0) / amplitude;
        p = rotate2d(0.5 + u_treble) * p * 2.0;
        amplitude *= 2.0;
    }
    return noise * 0.5 + 0.5;
}