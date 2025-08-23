/*
Purpose: Metal shader for the "Orb" effect, ported from GLSL. Implements hue rotation, simplex-like noise, hover-based UV distortion, and rotation.
Inputs:  Uniforms buffer (time, resolution, hue, hover, rot, hoverIntensity); vertex stage provides fullscreen quad with UVs.
Outputs: Premultiplied-alpha RGBA suitable for ONE / ONE_MINUS_SRC_ALPHA blending.
*/
#include <metal_stdlib>
using namespace metal;

struct UniformsOrb {
    float time;
    float2 resolution;
    float hue;
    float hover;
    float rot;
    float hoverIntensity;
    float pad0; // align to 16 bytes
};

struct VertexOutOrb {
    float4 position [[position]];
    float2 uv;
};

vertex VertexOutOrb orbVertex(uint vertexID [[vertex_id]]) {
    VertexOutOrb out;
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

// --- Color space helpers (YIQ) ---
static inline float3 rgb2yiq(float3 c) {
    float y = dot(c, float3(0.299, 0.587, 0.114));
    float i = dot(c, float3(0.596, -0.274, -0.322));
    float q = dot(c, float3(0.211, -0.523, 0.312));
    return float3(y, i, q);
}

static inline float3 yiq2rgb(float3 c) {
    float r = c.x + 0.956 * c.y + 0.621 * c.z;
    float g = c.x - 0.272 * c.y - 0.647 * c.z;
    float b = c.x - 1.106 * c.y + 1.703 * c.z;
    return float3(r, g, b);
}

static inline float3 adjustHue(float3 color, float hueDeg) {
    float hueRad = hueDeg * 3.14159265f / 180.0f;
    float3 yiq = rgb2yiq(color);
    float cosA = cos(hueRad);
    float sinA = sin(hueRad);
    float i = yiq.y * cosA - yiq.z * sinA;
    float q = yiq.y * sinA + yiq.z * cosA;
    yiq.y = i;
    yiq.z = q;
    return yiq2rgb(yiq);
}

// --- Noise helpers (hash and 3D simplex-like noise) ---
static inline float3 hash33(float3 p3) {
    p3 = fract(p3 * float3(0.1031, 0.11369, 0.13787));
    p3 += dot(p3, p3.yxz + 19.19);
    float3 r = -1.0 + 2.0 * fract(float3(
        p3.x + p3.y,
        p3.x + p3.z,
        p3.y + p3.z
    ) * p3.zyx);
    return r;
}

static inline float snoise3(float3 p) {
    const float K1 = 0.333333333f;
    const float K2 = 0.166666667f;
    float3 i = floor(p + (p.x + p.y + p.z) * K1);
    float3 d0 = p - (i - (i.x + i.y + i.z) * K2);
    float3 e = step(float3(0.0), d0 - d0.yzx);
    float3 i1 = e * (1.0 - e.zxy);
    float3 i2 = 1.0 - e.zxy * (1.0 - e);
    float3 d1 = d0 - (i1 - K2);
    float3 d2 = d0 - (i2 - K1);
    float3 d3 = d0 - 0.5;
    float4 h = max(0.6 - float4(
        dot(d0, d0),
        dot(d1, d1),
        dot(d2, d2),
        dot(d3, d3)
    ), 0.0);
    float4 n = h * h * h * h * float4(
        dot(d0, hash33(i)),
        dot(d1, hash33(i + i1)),
        dot(d2, hash33(i + i2)),
        dot(d3, hash33(i + 1.0))
    );
    return dot(float4(31.316), n);
}

static inline float4 extractAlpha(float3 colorIn) {
    float a = max(max(colorIn.r, colorIn.g), colorIn.b);
    float3 rgb = (a > 1e-5) ? (colorIn / (a + 1e-5)) : colorIn;
    return float4(rgb, a);
}

// Constants from GLSL
constant float3 baseColor1 = float3(0.611765, 0.262745, 0.996078);
constant float3 baseColor2 = float3(0.298039, 0.760784, 0.913725);
constant float3 baseColor3 = float3(0.062745, 0.078431, 0.600000);
constant float innerRadius = 0.6;
constant float noiseScale = 0.65;

static inline float light1(float intensity, float attenuation, float dist) {
    return intensity / (1.0 + dist * attenuation);
}
static inline float light2(float intensity, float attenuation, float dist) {
    return intensity / (1.0 + dist * dist * attenuation);
}

static inline float4 drawOrb(float2 uv, constant UniformsOrb &u) {
    float3 color1 = adjustHue(baseColor1, u.hue);
    float3 color2 = adjustHue(baseColor2, u.hue);
    float3 color3 = adjustHue(baseColor3, u.hue);

    float ang = atan2(uv.y, uv.x);
    float len = length(uv);
    float invLen = (len > 0.0) ? (1.0 / len) : 0.0;

    float n0 = snoise3(float3(uv * noiseScale, u.time * 0.5)) * 0.5 + 0.5;
    float r0 = mix(mix(innerRadius, 1.0, 0.4), mix(innerRadius, 1.0, 0.6), n0);
    float d0 = distance(uv, (r0 * invLen) * uv);
    float v0 = light1(1.0, 10.0, d0);
    v0 *= smoothstep(r0 * 1.05, r0, len);
    float cl = cos(ang + u.time * 2.0) * 0.5 + 0.5;

    float a = u.time * -1.0;
    float2 pos = float2(cos(a), sin(a)) * r0;
    float d = distance(uv, pos);
    float v1 = light2(1.5, 5.0, d);
    v1 *= light1(1.0, 50.0, d0);

    float v2 = smoothstep(1.0, mix(innerRadius, 1.0, n0 * 0.5), len);
    float v3 = smoothstep(innerRadius, mix(innerRadius, 1.0, 0.5), len);

    float3 col = mix(color1, color2, cl);
    col = mix(color3, col, v0);
    col = (col + v1) * v2 * v3;
    col = clamp(col, 0.0, 1.0);

    return extractAlpha(col);
}

fragment float4 orbFragment(
    VertexOutOrb in [[stage_in]],
    constant UniformsOrb &u [[buffer(0)]]
) {
    float2 fragCoord = float2(in.uv.x * u.resolution.x,
                              in.uv.y * u.resolution.y);
    float2 center = u.resolution * 0.5;
    float size = min(u.resolution.x, u.resolution.y);
    float2 uv = (fragCoord - center) / size * 2.0;

    // Rotation
    float angle = u.rot;
    float s = sin(angle);
    float c = cos(angle);
    uv = float2(c * uv.x - s * uv.y, s * uv.x + c * uv.y);

    // Hover distort
    uv.x += u.hover * u.hoverIntensity * 0.1 * sin(uv.y * 10.0 + u.time);
    uv.y += u.hover * u.hoverIntensity * 0.1 * sin(uv.x * 10.0 + u.time);

    float4 col = drawOrb(uv, u);
    // Premultiply
    return float4(col.rgb * col.a, col.a);
}


