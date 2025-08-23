#include <metal_stdlib>
using namespace metal;

#define NUM_LAYER 4.0
#define STAR_COLOR_CUTOFF 0.2
#define PERIOD 3.0

// Hash function for random values
static inline float galaxy_hash21(float2 p) {
    p = fract(p * float2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

// Triangle wave function
static inline float galaxy_tri(float x) {
    return abs(fract(x) * 2.0 - 1.0);
}

// Smooth triangle wave
static inline float galaxy_tris(float x) {
    float t = fract(x);
    return 1.0 - smoothstep(0.0, 1.0, abs(2.0 * t - 1.0));
}

// Normalized triangle wave
static inline float galaxy_trisn(float x) {
    float t = fract(x);
    return 2.0 * (1.0 - smoothstep(0.0, 1.0, abs(2.0 * t - 1.0))) - 1.0;
}

// HSV to RGB conversion
static inline float3 galaxy_hsv2rgb(float3 c) {
    float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    float3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

// Star rendering function
static inline float galaxy_star(float2 uv, float flare, float glowIntensity) {
    float d = length(uv);
    float m = (0.05 * glowIntensity) / d;
    
    // Primary rays
    float rays = smoothstep(0.0, 1.0, 1.0 - abs(uv.x * uv.y * 1000.0));
    m += rays * flare * glowIntensity;
    
    // Rotated rays (45 degrees)
    float2x2 mat45 = float2x2(0.7071, -0.7071, 0.7071, 0.7071);
    uv = mat45 * uv;
    rays = smoothstep(0.0, 1.0, 1.0 - abs(uv.x * uv.y * 1000.0));
    m += rays * 0.3 * flare * glowIntensity;
    
    m *= smoothstep(1.0, 0.2, d);
    return m;
}

// Star layer function
static inline float3 galaxy_starLayer(float2 uv, float time, float starSpeed, float speed, 
                                      float hueShift, float saturation, float glowIntensity, 
                                      float twinkleIntensity) {
    float3 col = float3(0.0);
    
    float2 gv = fract(uv) - 0.5;
    float2 id = floor(uv);
    
    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {
            float2 offset = float2(float(x), float(y));
            float2 si = id + offset;
            float seed = galaxy_hash21(si);
            float size = fract(seed * 345.32);
            float glossLocal = galaxy_tri(starSpeed / (PERIOD * seed + 1.0));
            float flareSize = smoothstep(0.9, 1.0, size) * glossLocal;
            
            // Generate star colors
            float red = smoothstep(STAR_COLOR_CUTOFF, 1.0, galaxy_hash21(si + 1.0)) + STAR_COLOR_CUTOFF;
            float blu = smoothstep(STAR_COLOR_CUTOFF, 1.0, galaxy_hash21(si + 3.0)) + STAR_COLOR_CUTOFF;
            float grn = min(red, blu) * seed;
            float3 base = float3(red, grn, blu);
            
            // Apply color transformations
            float hue = atan2(base.g - base.r, base.b - base.r) / (2.0 * 3.14159) + 0.5;
            hue = fract(hue + hueShift / 360.0);
            float sat = length(base - float3(dot(base, float3(0.299, 0.587, 0.114)))) * saturation;
            float val = max(max(base.r, base.g), base.b);
            base = galaxy_hsv2rgb(float3(hue, sat, val));
            
            // Animated position offset
            float2 pad = float2(
                galaxy_tris(seed * 34.0 + time * speed / 10.0),
                galaxy_tris(seed * 38.0 + time * speed / 30.0)
            ) - 0.5;
            
            // Render star
            float star = galaxy_star(gv - offset - pad, flareSize, glowIntensity);
            
            // Apply twinkle effect
            float twinkle = galaxy_trisn(time * speed + seed * 6.2831) * 0.5 + 1.0;
            twinkle = mix(1.0, twinkle, twinkleIntensity);
            star *= twinkle;
            
            col += star * size * base;
        }
    }
    
    return col;
}

// Vertex shader
vertex float4 galaxyVertex(uint vid [[vertex_id]],
                          constant float4* vertices [[buffer(0)]]) {
    return vertices[vid];
}

// Fragment shader
fragment float4 galaxyFragment(float4 position [[position]],
                              constant float4& uniforms [[buffer(0)]],      // time, resolution.x, resolution.y, starSpeed
                              constant float4& params1 [[buffer(1)]],       // density, hueShift, speed, glowIntensity
                              constant float4& params2 [[buffer(2)]],       // saturation, twinkleIntensity, rotationSpeed, repulsionStrength
                              constant float4& mouseData [[buffer(3)]],     // mouseX, mouseY, mouseActive, autoCenterRepulsion
                              constant float4& focal [[buffer(4)]],         // focalX, focalY, rotationX, rotationY
                              constant float4& flags [[buffer(5)]]) {       // mouseRepulsion, transparent, unused, unused
    
    float time = uniforms.x;
    float2 resolution = float2(uniforms.y, uniforms.z);
    float starSpeed = uniforms.w;
    
    float density = params1.x;
    float hueShift = params1.y;
    float speed = params1.z;
    float glowIntensity = params1.w;
    
    float saturation = params2.x;
    float twinkleIntensity = params2.y;
    float rotationSpeed = params2.z;
    float repulsionStrength = params2.w;
    
    float2 mousePos = mouseData.xy;
    float mouseActive = mouseData.z;
    float autoCenterRepulsion = mouseData.w;
    
    float2 focalPoint = focal.xy;
    float2 rotation = focal.zw;
    
    bool mouseRepulsion = flags.x > 0.5;
    bool transparent = flags.y > 0.5;
    
    // Calculate UV coordinates
    float2 focalPx = focalPoint * resolution;
    float2 uv = (position.xy - focalPx) / resolution.y;
    
    // Apply mouse interaction
    float2 mouseNorm = mousePos - 0.5;
    
    if (autoCenterRepulsion > 0.0) {
        float2 centerUV = float2(0.0, 0.0);
        float centerDist = length(uv - centerUV);
        float2 repulsion = normalize(uv - centerUV) * (autoCenterRepulsion / (centerDist + 0.1));
        uv += repulsion * 0.05;
    } else if (mouseRepulsion) {
        float2 mousePosUV = (mousePos * resolution - focalPx) / resolution.y;
        float mouseDist = length(uv - mousePosUV);
        float2 repulsion = normalize(uv - mousePosUV) * (repulsionStrength / (mouseDist + 0.1));
        uv += repulsion * 0.05 * mouseActive;
    } else {
        float2 mouseOffset = mouseNorm * 0.1 * mouseActive;
        uv += mouseOffset;
    }
    
    // Apply auto-rotation
    float autoRotAngle = time * rotationSpeed;
    float2x2 autoRot = float2x2(cos(autoRotAngle), -sin(autoRotAngle), 
                                sin(autoRotAngle), cos(autoRotAngle));
    uv = autoRot * uv;
    
    // Apply manual rotation
    float2x2 manualRot = float2x2(rotation.x, -rotation.y, rotation.y, rotation.x);
    uv = manualRot * uv;
    
    // Render star layers
    float3 col = float3(0.0);
    
    for (float i = 0.0; i < 1.0; i += 1.0 / NUM_LAYER) {
        float depth = fract(i + starSpeed * speed);
        float scale = mix(20.0 * density, 0.5 * density, depth);
        float fade = depth * smoothstep(1.0, 0.9, depth);
        
        col += galaxy_starLayer(uv * scale + i * 453.32, time, starSpeed, speed, 
                               hueShift, saturation, glowIntensity, twinkleIntensity) * fade;
    }
    
    if (transparent) {
        float alpha = length(col);
        alpha = smoothstep(0.0, 0.3, alpha);
        alpha = min(alpha, 1.0);
        return float4(col, alpha);
    } else {
        return float4(col, 1.0);
    }
}