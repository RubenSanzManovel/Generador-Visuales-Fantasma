float pattern_infinity_mirror(vec2 uv, float time, float amp) {
    vec2 p = uv - 0.5;
    p.x *= u_resolution.x / u_resolution.y;
    for (int i = 0; i < 4; i++) {
        p = abs(p) / dot(p, p) - vec2(0.8, 0.6);
        p = rotate2d(time * 0.3 + float(i) * 0.5 + u_bass * 1.5) * p;
    }
    float mirror = sin(length(p) * 5.0 + time * 2.0 + u_mid * 4.0);
    return mirror * 0.5 + 0.5 + u_beat_intensity * 0.2;
}