float pattern_explosion_field(vec2 uv, float time) {
    float ex = 0.0;
    for (int i = 0; i < 10; i++) {
        float t = time - u_drops_time[i];
        if (t > 0.0 && t < 1.5) {
            float d = distance(uv, u_drops_pos[i]);
            float rad = t * 0.9;
            ex += smoothstep(rad, rad - 0.1, d) * pow(1.0 - t / 1.5, 2.0);
        }
    }
    
    // Fondo muy tenue pero visible a través de los filtros de contraste del visualizador
    // Rango de brillo de 5.5% a 9.5% según el volumen (suficiente para no ser tapado por el contraste)
    float waves = sin(uv.x * 2.0 + time * 0.15) * cos(uv.y * 2.0 - time * 0.1) * 0.5 + 0.5;
    float background = waves * (0.055 + u_amplitude * 0.04);
    
    return ex + background;
}