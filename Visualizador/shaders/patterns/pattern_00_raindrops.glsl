float pattern_raindrops(vec2 uv, float time) {
    // 30.0, 20.0: Frecuencia del fondo | 0.5: Velocidad de animación | 0.03: Intensidad fondo
    float bg = sin(uv.x * 30.0 + time * 0.5) * cos(uv.y * 20.0 - time * 0.5) * 0.03;
    float wave = 0.0;
    for (int i = 0; i < 10; i++) {
        float t = time - u_drops_time[i];
        if (t > 0.0 && t < 4.0) { // 4.0: Duración de cada onda
            float d = distance(uv, u_drops_pos[i]);
            // 40.0: Frecuencia de ondas | 6.0: Velocidad expansión | 100.0: Atenuación distancia
            wave += sin(d * 40.0 - t * 6.0) * pow(1.0 - t / 6.0, 2.0) / (1.0 + d * d * 100.0);
        }
    }
    return bg + wave;
}