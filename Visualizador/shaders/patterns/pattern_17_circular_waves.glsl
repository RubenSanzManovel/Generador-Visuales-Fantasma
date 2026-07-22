float pattern_circular_waves(vec2 uv, float time, float amp) {
    vec2 p = uv - 0.5;
    p.x *= u_resolution.x / u_resolution.y;
    float r = length(p);
    float a = atan(p.y, p.x);
    // 30.0: Frecuencia ondas circulares | 5.0: Velocidad | 15.0: Reacción bass
    float waves = sin(r * 30.0 - time * 5.0 + u_bass * 15.0) * 0.5 + 0.5;
    // 8.0: Brazos espiral | 10.0: Densidad radial | 3.0: Velocidad | 7.0: Reacción mid
    float spiral = sin(a * 8.0 + r * 10.0 - time * 3.0 + u_mid * 7.0) * 0.5 + 0.5;
    // 5.0: Frecuencia pulsos | 2.0: Velocidad pulsos
    float pulse = pow(sin(r * 5.0 - time * 2.0) * 0.5 + 0.5, 2.0) * u_beat_intensity;
    return waves * spiral + pulse;
}