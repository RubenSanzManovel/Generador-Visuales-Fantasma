float pattern_mixed_glitch(vec2 uv, float time, float amp) {
    float beat_push = smoothstep(0.15, 0.9, u_bass);
    float tilt = (beat_push + u_beat_intensity * 0.35) * 0.45;
    vec2 d = uv - 0.5;
    d = rotate2d(tilt) * d;
    d += 0.5;
    float g = fract(floor(d.y * 18.0 + time * 2.5) / 18.0);
    d.x += (g - 0.5) * (0.18 + beat_push * 0.25);
    d.y += sin(time * 0.6 + u_mid * 2.0) * 0.01;

    float r = sin(d.x * 24.0 + time * 1.6 + beat_push * 2.0) * 0.5 + 0.5;
    float gr = sin(d.x * 25.0 + time * 1.7 + beat_push * 2.2) * 0.5 + 0.5;
    float flicker = sin(uv.y * 220.0 + time * 14.0 + u_treble * 8.0) * 0.08;
    float scan = smoothstep(0.9, 0.95, fract(uv.y * 6.0 + time * 0.4));

    return r * gr + flicker + scan * 0.15 + u_treble * 0.35;
}