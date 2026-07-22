float pattern_voronoi_cells(vec2 uv, float time, float amp) {
    vec2 p = uv * 8.0; // 8.0: Densidad de células
    vec2 i = floor(p);
    vec2 f = fract(p);
    float min_dist = 1.0;
    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {
            vec2 neighbor = vec2(float(x), float(y));
            // 2.0: Velocidad movimiento puntos | 3.0: Reacción bass/mid a posición
            vec2 point = 0.5 + 0.5 * sin(time * 2.0 + 6.2831 * random(i + neighbor) + vec2(u_bass * 3.0, u_mid * 3.0));
            float d = length(neighbor + point - f);
            min_dist = min(min_dist, d);
        }
    }
    // 0.5: Intensidad reacción a beats
    return smoothstep(0.0, 1.0, min_dist) * (1.0 + u_beat_intensity * 0.5);
}