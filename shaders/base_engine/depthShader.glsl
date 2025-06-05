uniform float z; // depth of the drawn object [0-1] greater is further away

vec4 effect(vec4 colour, Image texture, vec2 textureCoords, vec2 screenCoords)
{
    vec4 ret = Texel(texture, textureCoords) * colour;

    if (ret.a == 0.0) // if the pixel is invisible than dont save its depth value
    {
        discard;
    }

    gl_FragDepth = z; // keep the depth of the pixel for later comparisons

    return ret;
}