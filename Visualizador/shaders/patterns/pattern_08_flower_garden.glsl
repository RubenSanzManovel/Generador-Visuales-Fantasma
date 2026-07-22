float pattern_flower_garden(vec2 uv, float time, float amp) {
    vec2 p = fract(uv * 5.0) - 0.5;
    float r = length(p);
    float a = atan(p.y, p.x);
    float pet = 5.0 + floor(u_bass * 10.0);
    float f = sin(a * pet + time) * 0.25 + 0.25;
    return smoothstep(f, f + 0.1, r) + smoothstep(0.1, 0.0, r) * u_mid;
}