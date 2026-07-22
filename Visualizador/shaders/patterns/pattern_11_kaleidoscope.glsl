float pattern_kaleidoscope(vec2 uv, float time, float amp) {
    vec2 p = uv - 0.5;
    p = rotate2d(time * 0.3 + u_bass * 1.5) * p;
    p = abs(p);
    p = rotate2d(0.785398) * p;
    p = abs(p);
    float c = length(p - 0.2);
    float b = max(abs(p.x), abs(p.y));
    return sin(c * 20.0 + b * 10.0 - time * 4.0 + u_mid * 5.0);
}