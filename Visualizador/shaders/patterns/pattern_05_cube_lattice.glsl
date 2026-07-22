float pattern_cube_lattice(vec2 uv, float time, float amp) {
    vec2 p = uv * 8.0;
    p = rotate2d(time * 0.5 + u_bass * 2.5) * (p - 4.0) + 4.0;
    vec2 grid = fract(p) - 0.5;
    grid = rotate2d(time * 0.8 + u_mid * 2.0) * grid;
    vec2 iso;
    iso.x = (grid.x - grid.y) * 0.866;
    iso.y = (grid.x + grid.y) * 0.5;
    float size = 0.25 + u_beat_intensity * 0.15;
    float cube = smoothstep(size, size - 0.02, max(abs(iso.x), abs(iso.y)));
    float glow = pow(1.0 - max(abs(iso.x), abs(iso.y)) / 0.5, 3.0) * u_treble * 0.5;
    return cube + glow;
}