float pattern_plasma_flow(vec2 uv, float time, float amp) {
    vec2 p = uv * 3.0; // 3.0: Escala general del plasma
    float plasma = 0.0;
    // 4.0, 3.0, 2.0: Frecuencias de capas | 2.0, 1.5, 3.0: Velocidades | 5.0, 4.0, 6.0: Reacciones a frecuencias
    plasma += sin(p.x * 4.0 + time * 2.0 + u_bass * 5.0);
    plasma += sin(p.y * 3.0 - time * 1.5 + u_mid * 4.0);
    plasma += sin((p.x + p.y) * 2.0 + time * 3.0 + u_treble * 6.0);
    // 5.0: Frecuencia capa circular | 2.5: Velocidad | 8.0: Reacción a amplitud
    plasma += cos(length(p - 1.5) * 5.0 - time * 2.5 + amp * 8.0);
    return plasma * 0.25 + 0.5; // 0.25: Contraste
}