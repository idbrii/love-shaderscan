#pragma language glsl3


// Use includes to organize yoru shader code.
#include "example/lib/math.glsl"
// Circular includes are ignored.
#include "example/splitcolor.glsl"


// Changing this uniform to a constant won't halt the game because it's sent
// with safe_send.
uniform float iTime;
//~ const float iTime = 0;


vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
{
    // Change these colours while the game is running and you'll see the
    // results without restarting the game.
    vec4 left = vec4(1.0, 0.0, 0.0, color.a);
    vec4 right = vec4(0.0, 0.0, 1.0, color.a);
    vec4 overlay = vec4(0.0, 0.5, 0.0, color.a);

    float cycle_duration = 10.0;
    float progress = screen_coords.x / love_ScreenSize.x;
    return mix(left, right, smoothstep01(progress))
        + overlay * pingpong01(iTime / cycle_duration);
}
