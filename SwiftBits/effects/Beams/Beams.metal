#include <metal_stdlib>
using namespace metal;

// 3D Perlin noise
static inline float4 beams_permute(float4 x) {
    return fmod(((x * 34.0) + 1.0) * x, 289.0);
}

static inline float4 beams_taylorInvSqrt(float4 r) {
    return 1.79284291400159 - 0.85373472095314 * r;
}

static inline float3 beams_fade(float3 t) {
    return t * t * t * (t * (t * 6.0 - 15.0) + 10.0);
}

static inline float beams_cnoise(float3 P) {
    float3 Pi0 = floor(P);
    float3 Pi1 = Pi0 + float3(1.0);
    Pi0 = fmod(Pi0, 289.0);
    Pi1 = fmod(Pi1, 289.0);
    float3 Pf0 = fract(P);
    float3 Pf1 = Pf0 - float3(1.0);
    
    float4 ix = float4(Pi0.x, Pi1.x, Pi0.x, Pi1.x);
    float4 iy = float4(Pi0.yy, Pi1.yy);
    float4 iz0 = Pi0.zzzz;
    float4 iz1 = Pi1.zzzz;
    
    float4 ixy = beams_permute(beams_permute(ix) + iy);
    float4 ixy0 = beams_permute(ixy + iz0);
    float4 ixy1 = beams_permute(ixy + iz1);
    
    float4 gx0 = ixy0 / 7.0;
    float4 gy0 = fract(floor(gx0) / 7.0) - 0.5;
    gx0 = fract(gx0);
    float4 gz0 = float4(0.5) - abs(gx0) - abs(gy0);
    float4 sz0 = step(gz0, float4(0.0));
    gx0 -= sz0 * (step(0.0, gx0) - 0.5);
    gy0 -= sz0 * (step(0.0, gy0) - 0.5);
    
    float4 gx1 = ixy1 / 7.0;
    float4 gy1 = fract(floor(gx1) / 7.0) - 0.5;
    gx1 = fract(gx1);
    float4 gz1 = float4(0.5) - abs(gx1) - abs(gy1);
    float4 sz1 = step(gz1, float4(0.0));
    gx1 -= sz1 * (step(0.0, gx1) - 0.5);
    gy1 -= sz1 * (step(0.0, gy1) - 0.5);
    
    float3 g000 = float3(gx0.x, gy0.x, gz0.x);
    float3 g100 = float3(gx0.y, gy0.y, gz0.y);
    float3 g010 = float3(gx0.z, gy0.z, gz0.z);
    float3 g110 = float3(gx0.w, gy0.w, gz0.w);
    float3 g001 = float3(gx1.x, gy1.x, gz1.x);
    float3 g101 = float3(gx1.y, gy1.y, gz1.y);
    float3 g011 = float3(gx1.z, gy1.z, gz1.z);
    float3 g111 = float3(gx1.w, gy1.w, gz1.w);
    
    float4 norm0 = beams_taylorInvSqrt(float4(dot(g000, g000), dot(g010, g010), dot(g100, g100), dot(g110, g110)));
    g000 *= norm0.x;
    g010 *= norm0.y;
    g100 *= norm0.z;
    g110 *= norm0.w;
    
    float4 norm1 = beams_taylorInvSqrt(float4(dot(g001, g001), dot(g011, g011), dot(g101, g101), dot(g111, g111)));
    g001 *= norm1.x;
    g011 *= norm1.y;
    g101 *= norm1.z;
    g111 *= norm1.w;
    
    float n000 = dot(g000, Pf0);
    float n100 = dot(g100, float3(Pf1.x, Pf0.yz));
    float n010 = dot(g010, float3(Pf0.x, Pf1.y, Pf0.z));
    float n110 = dot(g110, float3(Pf1.xy, Pf0.z));
    float n001 = dot(g001, float3(Pf0.xy, Pf1.z));
    float n101 = dot(g101, float3(Pf1.x, Pf0.y, Pf1.z));
    float n011 = dot(g011, float3(Pf0.x, Pf1.yz));
    float n111 = dot(g111, Pf1);
    
    float3 fade_xyz = beams_fade(Pf0);
    float4 n_z = mix(float4(n000, n100, n010, n110), float4(n001, n101, n011, n111), fade_xyz.z);
    float2 n_yz = mix(n_z.xy, n_z.zw, fade_xyz.y);
    float n_xyz = mix(n_yz.x, n_yz.y, fade_xyz.x);
    
    return 2.2 * n_xyz;
}

// Simple 2D noise for fragment shader
static inline float beams_noise(float2 st) {
    float2 i = floor(st);
    float2 f = fract(st);
    
    float a = fract(sin(dot(i, float2(12.9898, 78.233))) * 43758.5453123);
    float b = fract(sin(dot(i + float2(1.0, 0.0), float2(12.9898, 78.233))) * 43758.5453123);
    float c = fract(sin(dot(i + float2(0.0, 1.0), float2(12.9898, 78.233))) * 43758.5453123);
    float d = fract(sin(dot(i + float2(1.0, 1.0), float2(12.9898, 78.233))) * 43758.5453123);
    
    float2 u = f * f * (3.0 - 2.0 * f);
    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

struct VertexOut {
    float4 position [[position]];
    float3 worldPos;
    float3 normal;
    float2 uv;
    float beamIndex;
};

// Vertex shader
vertex VertexOut beamsVertex(uint vid [[vertex_id]],
                             constant float4* vertices [[buffer(0)]],
                             constant float4& uniforms [[buffer(1)]],    // time, beamWidth, beamHeight, beamNumber
                             constant float4& params [[buffer(2)]]) {     // speed, noiseIntensity, scale, rotation
    VertexOut out;
    
    float time = uniforms.x;
    float beamWidth = uniforms.y;
    float beamHeight = uniforms.z;
    float beamNumber = uniforms.w;
    float speed = params.x;
    float noiseIntensity = params.y;
    float scale = params.z;
    float rotation = params.w;
    
    // Create beam geometry
    int beamIndex = vid / 4;  // Each beam has 4 vertices
    int localVid = vid % 4;
    
    float totalWidth = beamNumber * beamWidth;
    float xOffset = -totalWidth * 0.5 + float(beamIndex) * beamWidth;
    
    // Create quad vertices
    float x = xOffset + ((localVid % 2) ? beamWidth : 0.0);
    float y = ((localVid < 2) ? -beamHeight : beamHeight) * 0.5;
    float z = 0.0;
    
    // Apply rotation
    float cosR = cos(rotation);
    float sinR = sin(rotation);
    float2 rotatedXY = float2(x * cosR - y * sinR, x * sinR + y * cosR);
    x = rotatedXY.x;
    y = rotatedXY.y;
    
    // Apply noise displacement
    float3 noisePos = float3(x * 0.0, y - (float(localVid < 2) ? 0.0 : 1.0), z + time * speed * 3.0) * scale;
    float displacement = beams_cnoise(noisePos) * noiseIntensity;
    z += displacement;
    
    // Calculate normal
    float3 pos1 = float3(x + 0.01, y, z);
    float3 noisePos1 = float3(pos1.x * 0.0, pos1.y - (float(localVid < 2) ? 0.0 : 1.0), pos1.z + time * speed * 3.0) * scale;
    pos1.z += beams_cnoise(noisePos1) * noiseIntensity;
    
    float3 pos2 = float3(x, y - 0.01, z);
    float3 noisePos2 = float3(pos2.x * 0.0, pos2.y - (float(localVid < 2) ? 0.0 : 1.0) - 0.01, pos2.z + time * speed * 3.0) * scale;
    pos2.z += beams_cnoise(noisePos2) * noiseIntensity;
    
    float3 tangentX = normalize(pos1 - float3(x, y, z));
    float3 tangentY = normalize(pos2 - float3(x, y, z));
    float3 normal = normalize(cross(tangentY, tangentX));
    
    // Perspective projection
    float4 viewPos = float4(x, y, z, 1.0);
    float fov = 30.0 * 3.14159 / 180.0;
    float aspect = 1.0;
    float near = 0.1;
    float far = 100.0;
    float fovScale = 1.0 / tan(fov * 0.5);
    
    // Camera at (0, 0, 20)
    viewPos.z -= 20.0;
    
    out.position = float4(
        viewPos.x * fovScale / -viewPos.z,
        viewPos.y * fovScale * aspect / -viewPos.z,
        (viewPos.z + near) / (near - far),
        1.0
    );
    
    out.worldPos = float3(x, y, z);
    out.normal = normal;
    out.uv = float2(float(localVid % 2), float(localVid < 2) ? 0.0 : 1.0);
    out.beamIndex = float(beamIndex);
    
    return out;
}

// Fragment shader
fragment float4 beamsFragment(VertexOut in [[stage_in]],
                             constant float4& uniforms [[buffer(0)]],
                             constant float4& params [[buffer(1)]],
                             constant float4& lightColor [[buffer(2)]]) {
    float time = uniforms.x;
    float noiseIntensity = params.y;
    
    // Base color (dark metallic)
    float3 baseColor = float3(0.02, 0.02, 0.02);
    
    // Calculate lighting
    float3 lightDir = normalize(float3(0.0, 0.3, 1.0));
    float3 normal = normalize(in.normal);
    
    // Diffuse lighting
    float diffuse = max(dot(normal, lightDir), 0.0);
    
    // Specular lighting
    float3 viewDir = normalize(float3(0.0, 0.0, 1.0));
    float3 reflectDir = reflect(-lightDir, normal);
    float specular = pow(max(dot(viewDir, reflectDir), 0.0), 32.0);
    
    // Combine lighting
    float3 color = baseColor;
    color += diffuse * lightColor.xyz * 0.8;
    color += specular * lightColor.xyz * 0.5;
    
    // Add edge glow based on normal
    float edgeFactor = 1.0 - abs(dot(normal, viewDir));
    color += lightColor.xyz * pow(edgeFactor, 2.0) * 0.3;
    
    // Add noise grain
    float randomNoise = beams_noise(in.position.xy + time);
    color -= randomNoise / 15.0 * noiseIntensity;
    
    // Add subtle beam variation
    float beamVariation = sin(in.beamIndex * 2.3 + time) * 0.1 + 0.9;
    color *= beamVariation;
    
    // Fade edges
    float edgeFade = smoothstep(0.0, 0.1, in.uv.x) * smoothstep(1.0, 0.9, in.uv.x);
    edgeFade *= smoothstep(0.0, 0.05, in.uv.y) * smoothstep(1.0, 0.95, in.uv.y);
    color *= edgeFade;
    
    return float4(color, 1.0);
}