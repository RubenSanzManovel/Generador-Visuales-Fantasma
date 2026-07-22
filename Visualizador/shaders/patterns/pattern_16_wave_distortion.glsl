float pattern_wave_distortion(vec2 uv, float time, float amp) {
    vec2 d = uv;
    // Amplitud de distorsión dinámica en X modulada un poco más por los graves (u_bass) y el beat
    float amp_x = (0.07 + u_bass * 0.14 + u_beat_intensity * 0.04) * amp;
    float amp_y = (0.07 + u_mid * 0.07) * amp;
    
    d.x += sin(uv.y * 8.0 + time * 3.0 + u_bass * 8.0) * amp_x;
    d.y += cos(uv.x * 6.0 + time * 2.0 + u_mid * 6.0) * amp_y;
    
    float pattern1 = sin(d.x * 20.0 + time) * cos(d.y * 20.0 - time);
    float pattern2 = sin((d.x + d.y) * 15.0 - time * 2.0 + u_treble * 5.0);
    return (pattern1 + pattern2) * 0.5 + 0.5;
}