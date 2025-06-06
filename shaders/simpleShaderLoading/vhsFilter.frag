// shader designed by Milo:3 Silli Denote (shader was made a long while ago so no info is present)

#define PI 3.141592653

extern float time = 0.0;

extern bool band = true;
extern float banding = 40.0;

extern bool filmGrain = true;
extern float filmGrainEffect = 0.3;

extern bool blurHorizontally = true;
extern int horizontalBlur = 5;
extern float chromaticAberration = 2.0;

vec4 tex2D(Image texture, vec2 pos)
{
    vec4 color = Texel(texture, pos);
    if (0.5f < abs(pos.x - 0.5f))
    {
        color = vec4(0.1f);
    }
    return color;
}

float rand(vec2 _v)
{
    return fract(sin(dot(_v, vec2(20.45, 43.37))) * 62118.88);
}

float iHash(vec2 _v, vec2 _r)
{
    vec2 recip_r = 1.0 / _r;

    float hash1 = rand(floor(_v * _r + vec2(0.0, 0.0)) * recip_r);
    float hash2 = rand(floor(_v * _r + vec2(1.0, 0.0)) * recip_r);
    float hash3 = rand(floor(_v * _r + vec2(0.0, 1.0)) * recip_r);
    float hash4 = rand(floor(_v * _r + vec2(1.0, 1.0)) * recip_r);

    vec2 ip = vec2(smoothstep(vec2(0.0, 0.0), vec2(1.0, 1.0), fract(_v * _r)));
    return (hash1 * (1.0 - ip.x) + hash2 * ip.x) * (1.0 - ip.y) + (hash3 * (1.0 - ip.x) + hash4 * ip.x) * ip.y;
}

float noise(vec2 position)
{
    float sum = 0.0;

    for(int i = 1; i < 9; i++)
    {
        sum += iHash(position + vec2(i), vec2(2.0 * pow(2.0, i))) / pow(2.0, i);
    }

    return sum;
}

vec4 effect(vec4 colour, Image img, vec2 texture_coords, vec2 pixel_coords)
{
    float grainFactor = 0.0;

    if (filmGrain)
    {
        grainFactor = rand(texture_coords + time); 
    }

    vec2 uvn = pixel_coords / love_ScreenSize.xy;
    vec4 color = vec4(0.0);

    // tape wave
    uvn.x += (noise(vec2(uvn.y, time)) - 0.5)* 0.005 + (noise(vec2(uvn.y * 100.0, time * 10.0)) - 0.5) * 0.01;

    // tape crease
    float tapeCreasePhase = clamp((sin(uvn.y * 8.0 - time * PI * 1.2) - 0.92) * noise(vec2(time)), 0.0, 0.01) * 10.0;
    float tapeCreaseNoise = max(noise(vec2(uvn.y * 100.0, time * 10.0)) - 0.5, 0.0);
    uvn.x = uvn.x - tapeCreaseNoise * tapeCreasePhase;

    float snPhase = smoothstep(0.03, 0.0, uvn.y);
    
    color = tex2D(img, uvn);
    color *= 1.0 - tapeCreasePhase;
    color = mix(color, color, snPhase);

    // horizontal blur
    if (blurHorizontally)
    {
        for(int x = -horizontalBlur; x < horizontalBlur; x++)
        {
            color += vec4(
                tex2D(img, uvn + vec2(x, 0.0) / love_ScreenSize.xy).r,
                tex2D(img, uvn + vec2(x - chromaticAberration, 0.0) / love_ScreenSize.xy).g,
                tex2D(img, uvn + vec2(x - chromaticAberration * 2.0, 0.0) / love_ScreenSize.xy).b,
                0.0
            );
        }

        color /= horizontalBlur * 2.0;
    }

    // ac beat
    color *= 1.0 + clamp(noise(vec2(0.0, texture_coords.y + time * 0.2)) * 0.6 - 0.25, 0.0, 0.1);

    // colour reduction
    if (band)
    {
        color *= banding;
        color = floor(color + 0.5) / banding;
    }

    color = mix(color, vec4(0.0), grainFactor * filmGrainEffect);

    return vec4(color.rgb * 1.25, 1.0);
}