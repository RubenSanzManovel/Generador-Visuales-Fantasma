float pattern_concentric_squares(vec2 uv, float time, float amp) {
    vec2 p = abs(uv - 0.5) * 2.0;
    p.x *= u_resolution.x / u_resolution.y;
    // 0.8: Velocidad rotación | 2.5: Reacción bass a rotación
    p = rotate2d(time * 0.8 + u_bass * 2.5) * p;
    float square = max(abs(p.x), abs(p.y));
    // 30.0: Frecuencia anillos | 4.0: Velocidad expansión | 8.0: Reacción mid
    float rings = sin(square * 30.0 - time * 4.0 + u_mid * 8.0) * 0.5 + 0.5;
    // 3.0: Exponente (mayor = esquinas más marcadas) | 0.3: Intensidad esquinas
    float corners = pow(square, 3.0) * u_beat_intensity;
    return rings + corners * 0.3;
}