void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution;
    uv = (uv - 0.5) / u_zoom + 0.5;
    float intensity = 0.0;

    if (u_pattern_index == 0)       intensity = pattern_raindrops(uv, u_time);
    else if (u_pattern_index == 1)  intensity = pattern_tunnel(uv, u_time);
    else if (u_pattern_index == 2)  intensity = pattern_cosmic_zoom(uv, u_time, u_amplitude);
    else if (u_pattern_index == 3)  intensity = pattern_wobble_grid(uv, u_time, u_amplitude);
    else if (u_pattern_index == 4)  intensity = pattern_glitchy_orb(uv, u_time, u_amplitude);
    else if (u_pattern_index == 5)  intensity = pattern_cube_lattice(uv, u_time, u_amplitude);
    else if (u_pattern_index == 6)  intensity = pattern_woven_fabric(uv, u_time, u_amplitude);
    else if (u_pattern_index == 7)  intensity = pattern_spinning_rose(uv, u_time, u_amplitude);
    else if (u_pattern_index == 8)  intensity = pattern_flower_garden(uv, u_time, u_amplitude);
    else if (u_pattern_index == 9)  intensity = pattern_hex_nest(uv, u_time, u_amplitude);
    else if (u_pattern_index == 10) intensity = pattern_reactive_hex_grid(uv, u_time, u_amplitude);
    else if (u_pattern_index == 11) intensity = pattern_kaleidoscope(uv, u_time, u_amplitude);
    else if (u_pattern_index == 12) intensity = pattern_mixed_glitch(uv, u_time, u_amplitude);
    else if (u_pattern_index == 13) intensity = pattern_dancing_triangles(uv, u_time, u_amplitude);
    else if (u_pattern_index == 14) intensity = pattern_explosion_field(uv, u_time);
    else if (u_pattern_index == 15) intensity = pattern_star_hyperspace(uv, u_time, u_amplitude);
    else if (u_pattern_index == 16) intensity = pattern_wave_distortion(uv, u_time, u_amplitude);
    else if (u_pattern_index == 17) intensity = pattern_circular_waves(uv, u_time, u_amplitude);
    else if (u_pattern_index == 18) intensity = pattern_plasma_flow(uv, u_time, u_amplitude);
    else if (u_pattern_index == 19) intensity = pattern_morphing_tiles(uv, u_time, u_amplitude);
    else if (u_pattern_index == 20) intensity = pattern_liquid_metal(uv, u_time, u_amplitude);
    else if (u_pattern_index == 21) intensity = pattern_electric_storm(uv, u_time, u_amplitude);
    else if (u_pattern_index == 22) intensity = pattern_hypnotic_spiral(uv, u_time, u_amplitude);
    else if (u_pattern_index == 23) intensity = pattern_matrix_rain(uv, u_time, u_amplitude);
    else if (u_pattern_index == 24) intensity = pattern_geometric_dance(uv, u_time, u_amplitude);
    else if (u_pattern_index == 25) intensity = pattern_aurora_flow(uv, u_time, u_amplitude);
    else if (u_pattern_index == 26) intensity = pattern_fractal_noise(uv, u_time, u_amplitude);
    else if (u_pattern_index == 27) intensity = pattern_voronoi_cells(uv, u_time, u_amplitude);
    else if (u_pattern_index == 28) intensity = pattern_oscillating_bars(uv, u_time, u_amplitude);
    else if (u_pattern_index == 29) intensity = pattern_radial_burst(uv, u_time, u_amplitude);
    else if (u_pattern_index == 30) intensity = pattern_triangle_tessellation(uv, u_time, u_amplitude);
    else if (u_pattern_index == 31) intensity = pattern_warp_tunnel(uv, u_time, u_amplitude);
    else if (u_pattern_index == 32) intensity = pattern_pixelated_dreams(uv, u_time, u_amplitude);
    else if (u_pattern_index == 33) intensity = pattern_concentric_squares(uv, u_time, u_amplitude);
    else if (u_pattern_index == 34) intensity = pattern_infinity_mirror(uv, u_time, u_amplitude);
    else if (u_pattern_index == 35) intensity = pattern_equalizer(uv, u_time, u_amplitude);
    else if (u_pattern_index == 36) intensity = pattern_falling_hair(uv, u_time, u_amplitude);
    else if (u_pattern_index == 37) intensity = pattern_rising_smoke(uv, u_time, u_amplitude);
    else if (u_pattern_index == 38) intensity = pattern_confetti(uv, u_time, u_amplitude);
    else if (u_pattern_index == 39) intensity = pattern_shooting_stars(uv, u_time, u_amplitude);
    else if (u_pattern_index == 40) intensity = pattern_fireflies(uv, u_time, u_amplitude);
    else if (u_pattern_index == 41) intensity = pattern_magic_particles(uv, u_time, u_amplitude);

    vec3 bg = vec3(0.0, 0.0, 0.05);
    vec3 color = u_base_color * intensity * 1.5;
    
    color.r += u_treble * 0.3;
    color.g += u_mid * 0.3;
    color.b += u_bass * 0.3;
    
    vec3 final = bg + color;
    
    if (u_bloom_intensity > 0.0) {
        vec3 bright = max(final - 0.7, 0.0) * 2.0;
        final += bright * length(bright) * u_bloom_intensity;
    }
    
    if (u_vignette_intensity > 0.0) {
        float dist = length(uv - 0.5);
        float vig = smoothstep(0.8, 0.3, dist);
        vig = mix(1.0, vig, u_vignette_intensity);
        final *= vig;
    }
    
    final = clamp((final - 0.5) * u_contrast + 0.5, 0.0, 1.0);
    
    float lum = dot(final, vec3(0.299, 0.587, 0.114));
    final = mix(vec3(lum), final, u_saturation);
    
    final = clamp(final, 0.0, 1.0);
    
    gl_FragColor = vec4(final, 1.0);
}
