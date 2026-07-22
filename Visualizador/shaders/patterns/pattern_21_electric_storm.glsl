float pattern_electric_storm(vec2 uv, float time, float amp) {
    vec2 p = uv * 6.0;
    float storm = 0.0;
    for (int i = 0; i < 3; i++) {
        float fi = float(i);
        float wave1 = sin(p.x * (2.0 + fi) + sin(p.y * (3.0 + fi) + time * (2.0 + fi * 0.5) + u_bass * 6.0) * 2.0);
        float wave2 = cos(p.y * (2.5 + fi) + cos(p.x * (2.0 + fi) - time * (1.5 + fi * 0.3) + u_mid * 5.0) * 2.0);
        storm += (wave1 + wave2) / (fi + 2.0);
    }
    float bolts = sin(p.x * 80.0 + time * 15.0) * sin(p.y * 80.0 - time * 15.0);
    bolts = pow(max(bolts, 0.0), 10.0) * u_beat_intensity * 3.0;
    float energy = sin(length(p) * 5.0 - time * 3.0 + u_treble * 8.0) * 0.3;
    return (storm * 0.3 + 0.5) + bolts + energy;
}