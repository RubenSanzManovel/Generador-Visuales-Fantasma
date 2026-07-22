float pattern_geometric_dance(vec2 uv, float time, float amp) {
    vec2 p = uv * 6.0;
    p = rotate2d(time * 0.5 + u_bass * 2.0) * (p - 3.0) + 3.0;
    vec2 grid = fract(p) - 0.5;
    float shape = max(abs(grid.x), abs(grid.y));
    float morph = sin(time * 3.0 + length(p) + u_mid * 5.0) * 0.5 + 0.5;
    float size = 0.3 + morph * 0.2 + u_treble * 0.15;
    return smoothstep(size, size - 0.05, shape);
}