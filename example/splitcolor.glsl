#pragma language glsl3
// Try changing the values in the colours below while the game is running.


#include "example/lib/math.glsl"


uniform float iTime;


// Learn more here: http://blogs.love2d.org/content/beginners-guide-shaders
vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
{
    vec4 left = vec4(1.0, 0.0, 0.0, color.a);
    vec4 right = vec4(0.0, 0.0, 1.0, color.a);
    vec4 overlay = vec4(0.0, 0.5, 0.0, color.a);
    float cycle_duration = 10.0;
    float progress = screen_coords.x / love_ScreenSize.x;
    return mix(left, right, smoothstep01(progress))
        + overlay * pingpong(iTime / cycle_duration);
}
