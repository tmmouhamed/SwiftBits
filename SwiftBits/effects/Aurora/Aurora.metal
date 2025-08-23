/*
Purpose: Metal shader for aurora-like flowing glow using animated noise and a 3-stop color ramp.
Inputs:  Uniforms (time, amplitude, resolution, blend, colorStops[3]); fullscreen quad from vertex stage.
Outputs: Premultiplied-alpha RGBA color representing the aurora band; suitable for ONE / ONE_MINUS_SRC_ALPHA blending.
*/
#include <metal_stdlib>
using namespace metal;

struct UniformsAurora {
    float time;
    float amplitude;
    float2 resolution;
    float blend;
    // Match Swift struct: float3 + pad to 16-byte alignment
    float3 colorStop0; float pad0;
    float3 colorStop1; float pad1;
    float3 colorStop2; float pad2;
};

struct VertexOutAurora {
    float4 position [[position]];
    float2 uv;
};

vertex VertexOutAurora auroraVertex(uint vertexID [[vertex_id]]) {
    VertexOutAurora out;
    float2 positions[4] = {
        float2(-1.0, -1.0),
        float2( 1.0, -1.0),
        float2(-1.0,  1.0),
        float2( 1.0,  1.0)
    };
    float2 position = positions[vertexID];
    out.position = float4(position, 0.0, 1.0);
    out.uv = (position + 1.0) * 0.5;
    return out;
}

// Simple hash-based value noise for performance; adequate for soft aurora motion
inline float noise2(float2 p) {
    return fract(sin(dot(p, float2(12.9898,78.233))) * 43758.5453);
}

// Hash function returning [0,1)
static inline float hash21(float2 p) {
    return fract(sin(dot(p, float2(127.1, 311.7))) * 43758.5453123);
}

// 2D value noise with smooth interpolation
static inline float valueNoise2D(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);
    float a = hash21(i + float2(0.0, 0.0));
    float b = hash21(i + float2(1.0, 0.0));
    float c = hash21(i + float2(0.0, 1.0));
    float d = hash21(i + float2(1.0, 1.0));
    float2 u2 = f * f * (3.0 - 2.0 * f);
    return mix(mix(a, b, u2.x), mix(c, d, u2.x), u2.y);
}

// Fractional Brownian Motion over valueNoise2D
static inline float fbm2D(float2 p) {
    float v = 0.0;
    float a = 0.6;
    float2 shift = float2(100.0, 100.0);
    for (int i = 0; i < 4; i++) {
        v += a * valueNoise2D(p);
        p = p * 1.9 + shift;
        a *= 0.5;
    }
    return v;
}

fragment float4 auroraFragment(
    VertexOutAurora in [[stage_in]],
    constant UniformsAurora &u [[buffer(0)]]
) {
    float2 uv = float2(in.uv.x, 1.0 - in.uv.y);

    // ----- Smooth value noise with fBM and light domain warp -----

    float t = u.time;
    float2 p = float2(uv.x * 2.0, uv.y * 1.2);
    // Domain warp to create flowing, smooth ribbons
    float2 warp = float2(
        fbm2D(float2(p.x * 0.7 + t * 0.05, t * 0.08)),
        fbm2D(float2(p.x * 0.9 - t * 0.04, t * 0.06))
    );
    p += (warp - 0.5) * 0.2;

    // ----- Aurora cross-section as gaussian band around a base curve -----
    float baseY = 0.35
                + 0.04 * sin(uv.x * 2.5 + t * 0.15)
                + 0.06 * (fbm2D(float2(uv.x * 1.1 + t * 0.05, t * 0.07)) - 0.5);
    float sigma = mix(0.08, 0.22, clamp(u.blend, 0.0, 1.0));
    float dy = uv.y - baseY;

    // Multi-tap along Y to emulate soft blur
    const int taps = 5;
    const float w[taps] = {0.12, 0.20, 0.36, 0.20, 0.12};
    const float offs[taps] = {-2.0, -1.0, 0.0, 1.0, 2.0};
    float band = 0.0;
    for (int i = 0; i < taps; i++) {
        float yy = dy + offs[i] * sigma * 0.35;
        float g = exp(-0.5 * (yy * yy) / (sigma * sigma));
        band += w[i] * g;
    }

    // Subtle fBM modulation for natural variation
    float modulate = 0.85 + 0.15 * fbm2D(float2(uv.x * 3.0 + t * 0.2, uv.y * 2.0));
    float intensity = band * modulate * (0.8 + 0.4 * clamp(u.amplitude, 0.0, 2.0));
    intensity = clamp(intensity, 0.0, 1.0);

    // ----- 3-stop color ramp across X -----
    float f = clamp(uv.x, 0.0, 1.0);
    float3 c0 = u.colorStop0;
    float3 c1 = u.colorStop1;
    float3 c2 = u.colorStop2;
    float3 rampColor = (f < 0.5) ? mix(c0, c1, f / 0.5) : mix(c1, c2, (f - 0.5) / 0.5);

    float a = intensity;
    float3 rgb = rampColor * intensity;
    return float4(rgb, a);
}


