float pattern_hypnotic_spiral(vec2 uv, float time, float amp) {
    vec2 p = uv - 0.5;
    p.x *= u_resolution.x / u_resolution.y;
    float r = length(p);
    float a = atan(p.y, p.x);
    // 5.0: Brazos espiral | 20.0: Densidad radial | 4.0: Velocidad rotación | 12.0: Reacción bass
    float spiral = sin(a * 5.0 + r * 20.0 - time * 4.0 - u_bass * 12.0);
    // 30.0: Frecuencia anillos | 3.0: Velocidad anillos | 8.0: Reacción mid
    float rings = sin(r * 30.0 - time * 3.0 + u_mid * 8.0);
    // 10.0: Frecuencia pulsos radiales | 0.5: Intensidad pulsos
    float pulse = 1.0 + u_beat_intensity * sin(r * 10.0) * 0.5;
    return (spiral * rings) * pulse * 0.5 + 0.5;
}