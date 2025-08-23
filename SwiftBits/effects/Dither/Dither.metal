#include <metal_stdlib>
using namespace metal;

// Perlin noise implementation
static inline float4 dither_mod289(float4 x) {
    return x - floor(x * (1.0/289.0)) * 289.0;
}

static inline float4 dither_permute(float4 x) {
    return dither_mod289(((x * 34.0) + 1.0) * x);
}

static inline float4 dither_taylorInvSqrt(float4 r) {
    return 1.79284291400159 - 0.85373472095314 * r;
}

static inline float2 dither_fade(float2 t) {
    return t * t * t * (t * (t * 6.0 - 15.0) + 10.0);
}

static inline float dither_cnoise(float2 P) {
    float4 Pi = floor(P.xyxy) + float4(0.0, 0.0, 1.0, 1.0);
    float4 Pf = fract(P.xyxy) - float4(0.0, 0.0, 1.0, 1.0);
    Pi = dither_mod289(Pi);
    
    float4 ix = Pi.xzxz;
    float4 iy = Pi.yyww;
    float4 fx = Pf.xzxz;
    float4 fy = Pf.yyww;
    
    float4 i = dither_permute(dither_permute(ix) + iy);
    
    float4 gx = fract(i * (1.0/41.0)) * 2.0 - 1.0;
    float4 gy = abs(gx) - 0.5;
    float4 tx = floor(gx + 0.5);
    gx = gx - tx;
    
    float2 g00 = float2(gx.x, gy.x);
    float2 g10 = float2(gx.y, gy.y);
    float2 g01 = float2(gx.z, gy.z);
    float2 g11 = float2(gx.w, gy.w);
    
    float4 norm = dither_taylorInvSqrt(float4(dot(g00, g00), dot(g01, g01), dot(g10, g10), dot(g11, g11)));
    g00 *= norm.x;
    g01 *= norm.y;
    g10 *= norm.z;
    g11 *= norm.w;
    
    float n00 = dot(g00, float2(fx.x, fy.x));
    float n10 = dot(g10, float2(fx.y, fy.y));
    float n01 = dot(g01, float2(fx.z, fy.z));
    float n11 = dot(g11, float2(fx.w, fy.w));
    
    float2 fade_xy = dither_fade(Pf.xy);
    float2 n_x = mix(float2(n00, n01), float2(n10, n11), fade_xy.x);
    return 2.3 * mix(n_x.x, n_x.y, fade_xy.y);
}

// Fractal Brownian Motion
static inline float dither_fbm(float2 p, float waveFrequency, float waveAmplitude) {
    float value = 0.0;
    float amp = 1.0;
    float freq = waveFrequency;
    
    const int OCTAVES = 4;
    for (int i = 0; i < OCTAVES; i++) {
        value += amp * abs(dither_cnoise(p * freq));
        freq *= 2.0;
        amp *= waveAmplitude;
    }
    return value;
}

// Pattern generation
static inline float dither_pattern(float2 p, float time, float waveSpeed, float waveFrequency, float waveAmplitude) {
    float2 p2 = p - time * waveSpeed;
    return dither_fbm(p + dither_fbm(p2, waveFrequency, waveAmplitude), waveFrequency, waveAmplitude);
}

// Bayer matrix for dithering
constant float bayerMatrix8x8[64] = {
    0.0/64.0, 48.0/64.0, 12.0/64.0, 60.0/64.0,  3.0/64.0, 51.0/64.0, 15.0/64.0, 63.0/64.0,
    32.0/64.0,16.0/64.0, 44.0/64.0, 28.0/64.0, 35.0/64.0,19.0/64.0, 47.0/64.0, 31.0/64.0,
    8.0/64.0, 56.0/64.0,  4.0/64.0, 52.0/64.0, 11.0/64.0,59.0/64.0,  7.0/64.0, 55.0/64.0,
    40.0/64.0,24.0/64.0, 36.0/64.0, 20.0/64.0, 43.0/64.0,27.0/64.0, 39.0/64.0, 23.0/64.0,
    2.0/64.0, 50.0/64.0, 14.0/64.0, 62.0/64.0,  1.0/64.0,49.0/64.0, 13.0/64.0, 61.0/64.0,
    34.0/64.0,18.0/64.0, 46.0/64.0, 30.0/64.0, 33.0/64.0,17.0/64.0, 45.0/64.0, 29.0/64.0,
    10.0/64.0,58.0/64.0,  6.0/64.0, 54.0/64.0,  9.0/64.0,57.0/64.0,  5.0/64.0, 53.0/64.0,
    42.0/64.0,26.0/64.0, 38.0/64.0, 22.0/64.0, 41.0/64.0,25.0/64.0, 37.0/64.0, 21.0/64.0
};

// Dither function
static inline float3 dither_apply(float2 uv, float3 color, float2 resolution, float pixelSize, float colorNum) {
    float2 scaledCoord = floor(uv * resolution / pixelSize);
    int x = int(fmod(scaledCoord.x, 8.0));
    int y = int(fmod(scaledCoord.y, 8.0));
    
    float threshold = bayerMatrix8x8[y * 8 + x] - 0.25;
    float step = 1.0 / (colorNum - 1.0);
    color += threshold * step;
    
    float bias = 0.2;
    color = clamp(color - bias, 0.0, 1.0);
    
    return floor(color * (colorNum - 1.0) + 0.5) / (colorNum - 1.0);
}

// Vertex shader
vertex float4 ditherVertex(uint vid [[vertex_id]],
                          constant float4* vertices [[buffer(0)]]) {
    return vertices[vid];
}

// Fragment shader
fragment float4 ditherFragment(float4 position [[position]],
                              constant float4& uniforms [[buffer(0)]],     // time, resolution.x, resolution.y, waveSpeed
                              constant float4& waveParams [[buffer(1)]],   // waveFrequency, waveAmplitude, colorNum, pixelSize
                              constant float4& waveColor [[buffer(2)]],    // r, g, b, mouseEnabled
                              constant float4& mouseData [[buffer(3)]]) {   // mouseX, mouseY, mouseRadius, unused
    float2 resolution = float2(uniforms.y, uniforms.z);
    float2 uv = position.xy / resolution - 0.5;
    uv.x *= resolution.x / resolution.y;
    
    // Generate wave pattern
    float f = dither_pattern(uv, uniforms.x, uniforms.w, waveParams.x, waveParams.y);
    
    // Mouse interaction
    if (waveColor.w > 0.5) {
        float2 mouseNDC = (mouseData.xy / resolution - 0.5) * float2(1.0, -1.0);
        mouseNDC.x *= resolution.x / resolution.y;
        float dist = length(uv - mouseNDC);
        float effect = 1.0 - smoothstep(0.0, mouseData.z, dist);
        f -= 0.5 * effect;
    }
    
    // Apply wave color
    float3 col = mix(float3(0.0), waveColor.xyz, f);
    
    // Apply dithering
    float2 pixelUV = position.xy / resolution;
    col = dither_apply(pixelUV, col, resolution, waveParams.w, waveParams.z);
    
    return float4(col, 1.0);
}