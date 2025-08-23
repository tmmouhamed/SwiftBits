#include <metal_stdlib>
using namespace metal;

// Random function
static inline float prism_rand(float2 co) {
    return fract(sin(dot(co, float2(12.9898, 78.233))) * 43758.5453123);
}

// Tanh for float4
static inline float4 prism_tanh4(float4 x) {
    float4 e2x = exp(2.0 * x);
    return (e2x - 1.0) / (e2x + 1.0);
}

// SDF for anisotropic octahedron (inverted)
static inline float prism_sdOctaAnisoInv(float3 p, float invBaseHalf, float invHeight, float minAxis) {
    float3 q = float3(abs(p.x) * invBaseHalf, abs(p.y) * invHeight, abs(p.z) * invBaseHalf);
    float m = q.x + q.y + q.z - 1.0;
    return m * minAxis * 0.5773502691896258;
}

// SDF for upward pyramid (inverted)
static inline float prism_sdPyramidUpInv(float3 p, float invBaseHalf, float invHeight, float minAxis) {
    float oct = prism_sdOctaAnisoInv(p, invBaseHalf, invHeight, minAxis);
    float halfSpace = -p.y;
    return max(oct, halfSpace);
}

// HSV to RGB hue rotation matrix
static inline float3x3 prism_hueRotation(float a) {
    float c = cos(a);
    float s = sin(a);
    
    float3x3 W = float3x3(
        0.299, 0.587, 0.114,
        0.299, 0.587, 0.114,
        0.299, 0.587, 0.114
    );
    
    float3x3 U = float3x3(
         0.701, -0.587, -0.114,
        -0.299,  0.413, -0.114,
        -0.300, -0.588,  0.886
    );
    
    float3x3 V = float3x3(
         0.168, -0.331,  0.500,
         0.328,  0.035, -0.500,
        -0.497,  0.296,  0.201
    );
    
    return W + U * c + V * s;
}

// Vertex shader
vertex float4 prismVertex(uint vid [[vertex_id]],
                         constant float4* vertices [[buffer(0)]]) {
    return vertices[vid];
}

// Fragment shader
fragment float4 prismFragment(float4 position [[position]],
                              constant float4& uniforms1 [[buffer(0)]],   // time, resolution.x, resolution.y, height
                              constant float4& uniforms2 [[buffer(1)]],   // baseHalf, glow, noise, saturation
                              constant float4& uniforms3 [[buffer(2)]],   // scale, hueShift, colorFreq, bloom
                              constant float4& uniforms4 [[buffer(3)]],   // centerShift, invBaseHalf, invHeight, minAxis
                              constant float4& uniforms5 [[buffer(4)]],   // pxScale, timeScale, offsetX, offsetY
                              constant float3x3& rotMatrix [[buffer(5)]],
                              constant int& useBaseWobble [[buffer(6)]]) {
    
    float time = uniforms1.x;
    float2 resolution = float2(uniforms1.y, uniforms1.z);
    float height = uniforms1.w;
    
    float baseHalf = uniforms2.x;
    float glow = uniforms2.y;
    float noise = uniforms2.z;
    float saturation = uniforms2.w;
    
    float scale = uniforms3.x;
    float hueShift = uniforms3.y;
    float colorFreq = uniforms3.z;
    float bloom = uniforms3.w;
    
    float centerShift = uniforms4.x;
    float invBaseHalf = uniforms4.y;
    float invHeight = uniforms4.z;
    float minAxis = uniforms4.w;
    
    float pxScale = uniforms5.x;
    float timeScale = uniforms5.y;
    float2 offset = float2(uniforms5.z, uniforms5.w);
    
    // Calculate ray starting position
    float2 f = (position.xy - 0.5 * resolution - offset) * pxScale;
    
    float z = 5.0;
    float d = 0.0;
    float3 p;
    float4 o = float4(0.0);
    
    // Base wobble animation
    float2x2 wob = float2x2(1.0, 0.0, 0.0, 1.0);
    if (useBaseWobble == 1) {
        float t = time * timeScale;
        float c0 = cos(t + 0.0);
        float c1 = cos(t + 33.0);
        float c2 = cos(t + 11.0);
        wob = float2x2(c0, c1, c2, c0);
    }
    
    // Raymarch through the prism
    const int STEPS = 100;
    for (int i = 0; i < STEPS; i++) {
        p = float3(f, z);
        
        // Apply wobble
        float2 xz = wob * p.xz;
        p.x = xz.x;
        p.z = xz.y;
        
        // Apply rotation
        p = rotMatrix * p;
        
        // Shift for centering
        float3 q = p;
        q.y += centerShift;
        
        // Calculate distance to prism
        d = 0.1 + 0.2 * abs(prism_sdPyramidUpInv(q, invBaseHalf, invHeight, minAxis));
        z -= d;
        
        // Accumulate color based on position and distance
        o += (sin((p.y + z) * colorFreq + float4(0.0, 1.0, 2.0, 3.0)) + 1.0) / d;
    }
    
    // Apply bloom and glow
    o = prism_tanh4(o * o * (glow * bloom) / 1e5);
    
    float3 col = o.rgb;
    
    // Add noise
    float n = prism_rand(position.xy + float2(time));
    col += (n - 0.5) * noise;
    col = clamp(col, 0.0, 1.0);
    
    // Apply saturation
    float L = dot(col, float3(0.2126, 0.7152, 0.0722));
    col = clamp(mix(float3(L), col, saturation), 0.0, 1.0);
    
    // Apply hue shift
    if (abs(hueShift) > 0.0001) {
        col = clamp(prism_hueRotation(hueShift) * col, 0.0, 1.0);
    }
    
    return float4(col, o.a);
}