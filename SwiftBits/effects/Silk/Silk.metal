/*
Purpose: Metal shader for the Silk procedural pattern. Ported from a Three.js GLSL fragment/vertex shader; includes UV rotation, animated sine patterns, simple noise, and solid alpha.
Inputs:  Uniforms buffer (time, resolution, color, speed, scale, rotation, noiseIntensity); vertex stage builds fullscreen quad and UVs.
Outputs: Opaque RGBA color; no blending required.
*/
#include <metal_stdlib>
using namespace metal;

struct UniformsSilk {
    float time;
    float2 resolution;
    float3 color;
    float speed;
    float scale;
    float rotation;
    float noiseIntensity;
};

struct VertexOutSilk {
    float4 position [[position]];
    float2 uv;
};

vertex VertexOutSilk silkVertex(uint vertexID [[vertex_id]]) {
    VertexOutSilk out;
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

// A very lightweight hash-based noise approximation in 2D
static inline float noise2(float2 texCoord) {
    const float e = 2.71828182845904523536f;
    float G = e;
    float2 r = (G * sin(G * texCoord));
    return fract(r.x * r.y * (1.0 + texCoord.x));
}

static inline float2 rotateUvs(float2 uv, float angle) {
    float c = cos(angle);
    float s = sin(angle);
    float2x2 rot = float2x2(float2(c, -s), float2(s, c));
    return rot * uv;
}

fragment float4 silkFragment(
    VertexOutSilk in [[stage_in]],
    constant UniformsSilk &u [[buffer(0)]]
) {
    // Build UV in [0,1]
    float2 uv = in.uv * u.scale;
    uv = rotateUvs(uv, u.rotation);
    float2 tex = uv * u.scale;
    float tOffset = u.speed * u.time;

    tex.y += 0.03 * sin(8.0 * tex.x - tOffset);

    float pattern = 0.6 +
                    0.4 * sin(5.0 * (tex.x + tex.y +
                                     cos(3.0 * tex.x + 5.0 * tex.y) +
                                     0.02 * tOffset) +
                             sin(20.0 * (tex.x + tex.y - 0.1 * tOffset)));

    float rnd = noise2(float2((in.uv.x) * u.resolution.x,
                              (in.uv.y) * u.resolution.y));

    float3 base = u.color;
    float3 rgb = base * pattern - (rnd / 15.0) * u.noiseIntensity;
    rgb = clamp(rgb, 0.0, 1.0);
    return float4(rgb, 1.0);
}


