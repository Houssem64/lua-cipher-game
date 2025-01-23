uniform vec2 iResolution;
uniform float iTime;
uniform sampler2D iChannel0;
uniform sampler2D iChannel1;

vec2 mod_emu(vec2 x, float y) {
    return x - y * floor(x / y);
}

float hash2(vec2 p) {
    vec3 p33 = fract(vec3(p.xyx) * 0.2831);
    p33 += dot(p33, p33.yzx + 19.19);
    return fract((p33.x + p33.y) * p33.z);
}

float f_rem(vec2 iR) {
    float slices = floor(iR.y / 320.0);
    if (slices < 1.0) return 4.0;
    if (slices == 1.0) return 6.0;
    if (slices == 2.0) return 8.0;
    if (slices >= 3.0) return 10.0;
    if (slices >= 4.0) return 12.0;
    return 0.0;
}

vec4 mainImage(vec2 fragCoord) {
    // Normalize coordinates
    vec2 U = fragCoord / iResolution.xy;
    
    // Amplitude calculation
    float amp = 0.5 - texelFetch(iChannel1, ivec2(20, 0), 0).x + 
                0.5 * texelFetch(iChannel1, ivec2(400, 0), 0).x;
    
    // Normalized coordinates with inversion
    vec2 V = 1.0 - (2.0 * fragCoord / iResolution.xy);
    
    // Offset calculation
    vec2 off = vec2(
        smoothstep(0.0, (amp * f_rem(iResolution.xy)) * 0.5, 
        cos(iTime + (fragCoord.y / iResolution.y) * 5.0)), 
        0.0
    ) - vec2(0.5, 0.0);
    
    // Texture sampling with offset
    float r = texture2D(iChannel0, (0.03 * off) + U).x;
    float g = texture2D(iChannel0, (0.04 * off) + U).x;
    float b = texture2D(iChannel0, (0.05 * off) + U).x;
    
    // Base color
    vec4 C = vec4(0.0, 0.1, 0.2, 1.0);
    
    // Add hash noise
    C += 0.06 * hash2(iTime + V * vec2(1462.439, 297.185));
    
    // Add color channels
    C += vec4(r, g, b, 1.0);
    
    // Radial falloff
    C *= 1.25 * (1.0 - smoothstep(0.1, 1.8, length(V * V)));
    
    // Modulo operation
    fragCoord = mod_emu(fragCoord, f_rem(iResolution.xy));
    
    // Additional darkening
    C *= 0.4 + sign(smoothstep(0.99, 1.0, fragCoord.y));
    
    // Additional red highlight
    float sbf7 = 1.0 - length(V * vec2(0.5, 0.35));
    C += 0.14 * vec4(pow(sbf7, 3.0), 0.0, 0.0, 1.0);
    
    return C;
}

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
    return mainImage(screen_coords);
}