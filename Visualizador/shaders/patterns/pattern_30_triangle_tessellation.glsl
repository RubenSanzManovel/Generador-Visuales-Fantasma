float pattern_triangle_tessellation(vec2 uv, float time, float amp) {
    vec2 p = uv * 15.0;
    p = rotate2d(time * 0.2 + u_bass * 1.0) * (p - 7.5) + 7.5;
    p.y += mod(floor(p.x), 2.0) * 0.5;
    vec2 f = fract(p) - 0.5;
    float angle = time * 3.0 + length(floor(p)) * 0.5 + u_mid * 4.0;
    f = rotate2d(angle) * f;
    float tri = max(abs(f.x) * 1.732 + f.y, -f.y);
    float size = 0.35 + sin(length(floor(p)) * 0.8 + time * 2.0 + u_treble * 5.0) * 0.15;
    float shape = smoothstep(size, size - 0.05, tri);
    float glow = u_beat_intensity * exp(-tri * 4.0);
    float edge = smoothstep(0.02, 0.0, abs(tri - size)) * 0.5;
    return shape + glow + edge;
}