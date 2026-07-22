float pattern_cosmic_zoom(vec2 uv, float time, float amp) {
    vec2 p = 2.0 * uv - 1.0; 
    p.x *= u_resolution.x / u_resolution.y;
    float r = length(p); 
    float a = atan(p.y, p.x);
    
    // Rotación reactiva: la velocidad de giro responde a los graves y al beat
    float rotation = time * 2.0 + u_bass * 1.2 + u_beat_intensity * 0.6;
    
    // Segmentación radial con saltos rítmicos: los puntos se desplazan al ritmo del bajo
    float glitch_factor = floor(r * 20.0 + amp * 50.0 + u_bass * 15.0 + u_beat_intensity * 8.0) / 20.0;
    float arms = 4.0; 
    
    float spiral = sin(a * arms + glitch_factor * 5.0 - rotation);
    
    // Zoom logarítmico reactivo: el radio se contrae con los golpes de bajo para dar sensación de pulso
    float zoom = log(r * (1.0 - u_bass * 0.16 - u_beat_intensity * 0.08));
    
    spiral *= cos(zoom * 5.0 - time); 
    
    return spiral;
}