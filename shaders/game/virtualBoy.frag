vec4 effect(vec4 color, Image image, vec2 uvs, vec2 screen_coords) {
    vec4 pixel = Texel(image, uvs);

    // Boost the red channel
    pixel.r += 0.3;

    // Suppress green and blue completely to make the image purely red-and-black
    pixel.g = 0.0;
    pixel.b = 0.0;

    // Set high contrast: make pixels either red or black
    if (pixel.r > 0.5) {
        pixel.r = 0.8; // Strong red for bright areas
    } else {
        pixel.r = 0.1; // Black for dark areas
    }

    // Return the modified color with full alpha
    return vec4(pixel.r, pixel.g, pixel.b, pixel.a) * color;
}
