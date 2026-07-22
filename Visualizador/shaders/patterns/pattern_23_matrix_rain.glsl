float pattern_matrix_rain(vec2 uv, float time, float amp) {
    vec2 p = uv * vec2(40.0, 50.0); // 40.0, 50.0: Densidad de columnas/filas
    float col = floor(p.x);
    float speed = 1.2 + u_bass * 1.5; // 1.2: Velocidad base | 1.5: Aceleración con bass
    float offset = sin(col * 3.0 + time * 0.5) * 10.0; // 3.0, 0.5: Variación entre columnas | 10.0: Amplitud offset
    float row = p.y + time * speed + offset;
    // 0.25: Espaciado gotas | 0.6, 0.0: Difuminado | 0.7: Reacción amplitud
    float drops = smoothstep(0.6, 0.0, fract(row * 0.25)) * (1.0 + amp * 0.7);
    // 0.6, 0.35, 0.15: Intensidades de trails
    float trail1 = smoothstep(1.0, 0.0, fract(row * 0.25 + 0.25)) * 0.6;
    float trail2 = smoothstep(1.0, 0.0, fract(row * 0.25 + 0.5)) * 0.35;
    float trail3 = smoothstep(1.0, 0.0, fract(row * 0.25 + 0.75)) * 0.15;
    // 0.95: Probabilidad glitch | 2.0: Frecuencia cambios | 2.5: Intensidad
    float glitch = step(0.95, random(vec2(col, floor(time * 2.0)))) * u_beat_intensity * 2.5;
    float flicker = sin(col * 5.0 + time * 20.0) * 0.03; // 5.0, 20.0: Parpadeo | 0.03: Intensidad
    float scan = sin(uv.y * 200.0 + time * 30.0) * 0.04; // 200.0: Frecuencia scan | 30.0: Velocidad | 0.04: Intensidad
    float grid = smoothstep(0.015, 0.0, fract(p.x)) * 0.15; // 0.015: Grosor líneas | 0.15: Brillo grid
    float highlight = smoothstep(0.9, 1.0, drops) * u_treble * 0.5; // 0.5: Intensidad highlights
    return drops + trail1 + trail2 + trail3 + glitch + flicker + scan + grid + highlight;
}