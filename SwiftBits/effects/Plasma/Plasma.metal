#include <metal_stdlib>
using namespace metal;

// Check if float is finite (not NaN or Inf)
static inline bool plasma_finite(float x) {
    return !isnan(x) && !isinf(x);
}

// Sanitize color values
static inline float3 plasma_sanitize(float3 c) {
    return float3(
        plasma_finite(c.r) ? c.r : 0.0,
        plasma_finite(c.g) ? c.g : 0.0,
        plasma_finite(c.b) ? c.b : 0.0
    );
}

// Main plasma effect function
static inline float4 plasma_mainImage(float2 fragCoord, float2 resolution, float time, 
                                      float speed, float direction, float scale,
                                      float2 mouse, bool mouseInteractive) {
    float2 center = resolution * 0.5;
    float2 C = (fragCoord - center) / scale + center;
    
    // Mouse interaction
    if (mouseInteractive) {
        float2 mouseOffset = (mouse - center) * 0.0002;
        C += mouseOffset * length(C - center);
    }
    
    float i = 0.0;
    float d, z = 0.0;
    float T = time * speed * direction;
    float3 O = float3(0.0);
    float3 p, S;
    float4 o = float4(0.0);
    
    // Main plasma loop
    for (int iter = 0; iter < 60; iter++) {
        i += 1.0;
        
        // Calculate ray direction
        p = z * normalize(float3(C - 0.5 * resolution, resolution.y));
        p.z -= 4.0;
        S = p;
        d = p.y - T;
        
        // Apply wave distortion
        p.x += 0.4 * (1.0 + p.y) * sin(d + p.x * 0.1) * cos(0.34 * d + p.x * 0.05);
        
        // Rotation matrix
        float cosY = cos(p.y - T);
        float sinY = sin(p.y - T);
        float2x2 rotMat = float2x2(cosY, -sinY, sinY, cosY);
        float2 Q = rotMat * p.xz;
        
        // Calculate distance
        z += d = abs(sqrt(length(Q * Q)) - 0.25 * (5.0 + S.y)) / 3.0 + 8e-4;
        
        // Accumulate color
        o = 1.0 + sin(S.y + p.z * 0.5 + S.z - length(S - p) + float4(2, 1, 0, 8));
        O += o.w / d * o.xyz;
    }
    
    // Apply tanh for smooth falloff
    float3 color = tanh(O / 1e4);
    return float4(color, 1.0);
}

// Vertex shader
vertex float4 plasmaVertex(uint vid [[vertex_id]],
                           constant float4* vertices [[buffer(0)]]) {
    return vertices[vid];
}

// Fragment shader
fragment float4 plasmaFragment(float4 position [[position]],
                               constant float4& uniforms1 [[buffer(0)]],  // time, resolution.x, resolution.y, speed
                               constant float4& uniforms2 [[buffer(1)]],  // direction, scale, opacity, useCustomColor
                               constant float4& customColor [[buffer(2)]], // r, g, b, mouseInteractive
                               constant float4& mouseData [[buffer(3)]]) { // mouseX, mouseY, unused, unused
    
    float time = uniforms1.x;
    float2 resolution = float2(uniforms1.y, uniforms1.z);
    float speed = uniforms1.w;
    
    float direction = uniforms2.x;
    float scale = uniforms2.y;
    float opacity = uniforms2.z;
    float useCustomColor = uniforms2.w;
    
    float3 customColorRGB = customColor.xyz;
    bool mouseInteractive = customColor.w > 0.5;
    
    float2 mouse = mouseData.xy;
    
    // Calculate plasma effect
    float4 o = plasma_mainImage(position.xy, resolution, time, speed, direction, scale, mouse, mouseInteractive);
    float3 rgb = plasma_sanitize(o.rgb);
    
    // Apply custom color if enabled
    float3 finalColor;
    if (useCustomColor > 0.5) {
        float intensity = (rgb.r + rgb.g + rgb.b) / 3.0;
        finalColor = intensity * customColorRGB;
    } else {
        finalColor = rgb;
    }
    
    // Calculate alpha based on intensity
    float alpha = length(rgb) * opacity;
    
    return float4(finalColor, alpha);
}