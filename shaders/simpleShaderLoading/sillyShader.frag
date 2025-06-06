vec4 effect(vec4 color, Image texture, vec2 uv, vec2 screen_coords) {
    vec4 pixel = Texel(texture, uv);

    // Calculate the average brightness of the pixel
    float colorAverage = (pixel.r + pixel.g + pixel.b) / 3.0;

    // Reduce red and green significantly, while boosting blue slightly
    pixel.r = colorAverage * 0.2; // Keep red dimmed
    pixel.g = colorAverage * 0.2; // Keep green dimmed
    pixel.b = colorAverage * 0.6; // Slightly more blue, but not overpowering

    // Ensure values remain within valid range
    pixel = clamp(pixel, 0.0, 1.0);

    return pixel * color; // Apply alpha blending
}
