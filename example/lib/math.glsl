#pragma language glsl3

// A library of math functions.

float round(in float p)
{
    return floor(p + 0.5);
}

vec2 round(in vec2 p)
{
    return floor(p + 0.5);
}

vec3 round(in vec3 p)
{
    return floor(p + 0.5);
}

float smoothstep01(in float x)
{
    return smoothstep(0.0, 1.0, x);
}

float pingpong01(float x)
{
    // Introduce a typo and you'll get an error pointing to this file.
    //~ retur 1.0;
    return 1.0 - abs(1.0 - mod(x, 2));
}

