#include <metal_stdlib>
using namespace metal;

struct Particle {
    float3 position;
    float4 random;
    float3 color;
};

struct ParticleUniforms {
    float4x4 modelMatrix;
    float4x4 viewMatrix;
    float4x4 projectionMatrix;
    float time;
    float spread;
    float baseSize;
    float sizeRandomness;
    float alphaParticles;
    float3 mousePosition;
    float hoverFactor;
    float3 rotation;
};

struct VertexOut {
    float4 position [[position]];
    float pointSize [[point_size]];
    float4 random;
    float3 color;
};

// Vertex shader for particles
vertex VertexOut particlesVertex(const device Particle* particles [[buffer(0)]],
                                 constant ParticleUniforms& uniforms [[buffer(1)]],
                                 uint vid [[vertex_id]]) {
    VertexOut out;
    
    Particle particle = particles[vid];
    
    // Apply spread to position
    float3 pos = particle.position * uniforms.spread;
    pos.z *= 10.0;
    
    // Apply rotation matrices
    float cx = cos(uniforms.rotation.x);
    float sx = sin(uniforms.rotation.x);
    float cy = cos(uniforms.rotation.y);
    float sy = sin(uniforms.rotation.y);
    float cz = cos(uniforms.rotation.z);
    float sz = sin(uniforms.rotation.z);
    
    // Rotation around Z
    float3x3 rotZ = float3x3(
        float3(cz, -sz, 0),
        float3(sz, cz, 0),
        float3(0, 0, 1)
    );
    
    // Rotation around Y
    float3x3 rotY = float3x3(
        float3(cy, 0, sy),
        float3(0, 1, 0),
        float3(-sy, 0, cy)
    );
    
    // Rotation around X
    float3x3 rotX = float3x3(
        float3(1, 0, 0),
        float3(0, cx, -sx),
        float3(0, sx, cx)
    );
    
    // Apply rotations
    pos = rotZ * rotY * rotX * pos;
    
    // Add wave motion
    float t = uniforms.time;
    pos.x += sin(t * particle.random.z + 6.28 * particle.random.w) * mix(0.1, 1.5, particle.random.x);
    pos.y += sin(t * particle.random.y + 6.28 * particle.random.x) * mix(0.1, 1.5, particle.random.w);
    pos.z += sin(t * particle.random.w + 6.28 * particle.random.y) * mix(0.1, 1.5, particle.random.z);
    
    // Apply mouse hover offset
    pos += uniforms.mousePosition * uniforms.hoverFactor;
    
    // Transform to view space
    float4 worldPos = uniforms.modelMatrix * float4(pos, 1.0);
    float4 viewPos = uniforms.viewMatrix * worldPos;
    
    // Calculate point size based on distance
    float size = uniforms.baseSize * (1.0 + uniforms.sizeRandomness * (particle.random.x - 0.5));
    out.pointSize = size / length(viewPos.xyz);
    
    // Project to screen space
    out.position = uniforms.projectionMatrix * viewPos;
    out.random = particle.random;
    out.color = particle.color;
    
    return out;
}

// Fragment shader for particles
fragment float4 particlesFragment(VertexOut in [[stage_in]],
                                 constant ParticleUniforms& uniforms [[buffer(0)]],
                                 float2 pointCoord [[point_coord]]) {
    float2 uv = pointCoord;
    float d = length(uv - float2(0.5));
    
    // Calculate color with animation
    float3 color = in.color + 0.2 * sin(float3(uv.y, uv.x, uv.x) + uniforms.time + in.random.y * 6.28);
    
    if (uniforms.alphaParticles < 0.5) {
        // Solid particles
        if (d > 0.5) {
            discard_fragment();
        }
        return float4(color, 1.0);
    } else {
        // Alpha particles with smooth edges
        float circle = smoothstep(0.5, 0.4, d) * 0.8;
        return float4(color, circle);
    }
}