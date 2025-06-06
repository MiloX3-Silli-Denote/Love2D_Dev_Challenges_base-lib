vec4 effect(vec4 color, Image image, vec2 uvs, vec2 screen_coords) {
    vec4 pixel = Texel(image, uvs);

    // Invert the color channels
    pixel.r = 1.0 - pixel.r;
    pixel.g = 1.0 - pixel.g;
    pixel.b = 1.0 - pixel.b;

    // Return the modified color with full alpha
    return vec4(pixel.rgb, pixel.a) * color;
}
