float pattern_dancing_triangles(vec2 uv, float time, float amp) {
    vec2 p = uv * 10.0;
    
    // Rotación global con un balanceo suave y rítmico coordinado por los graves (u_bass)
    float global_rot = time * 0.2 + u_bass * 0.28;
    p = rotate2d(global_rot) * (p - 5.0) + 5.0;
    
    vec2 grid = fract(p) - 0.5;
    
    // Rotación individual reactiva al beat (giro rápido y enérgico de 1.4 rad que luego decae, en vez de los 6.0 rad originales)
    float local_rot = time * 1.2 + length(floor(p)) * 0.3 + u_beat_intensity * 1.4;
    grid = rotate2d(local_rot) * grid;
    
    // Dibujo del triángulo equilátero
    float tri = max(abs(grid.x) * 1.7320508 + grid.y, -grid.y);
    
    // El tamaño de los triángulos "salta" hacia afuera con el beat y oscila suavemente
    float size = 0.28 + sin(length(floor(p)) * 0.5 + time * 2.0) * 0.06 + u_beat_intensity * 0.10;
    
    // Borde suavizado pero bien definido
    float shape = smoothstep(size, size - 0.03, tri);
    
    // Destello de brillo interno sutil e integrado
    float pulse = pow(max(1.0 - tri / 0.4, 0.0), 3.0) * (0.05 + u_treble * 0.20);
    
    return shape + pulse;
}