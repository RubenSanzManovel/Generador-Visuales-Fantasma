// PATRÓN 48: Flujo de Plasma Líquido
float pattern_liquid_plasma(vec2 uv, float time, float amp) {
    vec2 p = uv - 0.5;
    p.x *= u_resolution.x / u_resolution.y;
    
    // Domain warping multi-frecuencia para dinámica de fluidos viscosos
    float time_scale = time * 0.6;
    
    vec2 q = vec2(
        sin(p.x * 3.0 + time_scale * 0.8) + cos(p.y * 2.0 + time_scale * 0.5),
        sin(p.y * 3.0 - time_scale * 0.7) + cos(p.x * 2.0 + time_scale * 0.9)
    ) * (0.6 + u_bass * 0.4); // Amplitud del fluido deformada por graves
    
    vec2 r = vec2(
        sin(p.x + q.x * 2.5 + time_scale * 1.2),
        cos(p.y + q.y * 2.5 - time_scale * 1.0)
    );
    
    // Calcular el plasma líquido combinando la deformación
    float val = sin(length(p + r) * 5.0 - time_scale * 2.0 + u_mid * 3.0);
    val = val * 0.5 + 0.5;
    
    // Reforzar las crestas del fluido para darle aspecto brillante 3D
    float ridges = pow(val, 4.0) * 1.5;
    float soft = val * 0.4;
    
    float final_plasma = ridges + soft;
    
    // Pulso con beats de la batería
    final_plasma *= (0.8 + u_beat_intensity * 0.5);
    
    return clamp(final_plasma, 0.0, 1.0);
}
