vec4 effect(vec4 color, Image image, vec2 uvs, vec2 screen_coords) {
    vec4 pixel = Texel(image, uvs);

    // Calculate the average of the texture's RGB values
    float colorAverage = (pixel.r + pixel.g + pixel.b) / 3.0;

    // Return the grayscale color with the same alpha as the pixel
    return vec4(colorAverage, colorAverage, colorAverage, pixel.a);
}
