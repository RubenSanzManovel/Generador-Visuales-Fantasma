float pattern_hex_nest(vec2 uv, float time, float amp) {
    vec2 p = (uv * 2.0 - 1.0) * 5.0;
    p.x *= u_resolution.x / u_resolution.y;
    p = rotate2d(time * 0.6 + u_bass * 2.0) * p;
    vec2 q = abs(p);
    return sin(max(q.x, dot(q, normalize(vec2(1.0, 1.73)))) * 5.0 - time * 4.0 + u_mid * 7.0);
}