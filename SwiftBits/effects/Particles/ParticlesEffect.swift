import SwiftUI
import MetalKit
import Combine
import simd

struct ParticlesEffect: View {
    @State private var time: Float = 0
    @State private var mousePosition = CGPoint.zero
    @State private var rotationX: Float = 0
    @State private var rotationY: Float = 0
    @State private var rotationZ: Float = 0
    
    // Particle parameters
    let particleCount: Int
    let particleSpread: Float
    let speed: Float
    let particleColors: [Color]
    let moveParticlesOnHover: Bool
    let particleHoverFactor: Float
    let alphaParticles: Bool
    let particleBaseSize: Float
    let sizeRandomness: Float
    let cameraDistance: Float
    let disableRotation: Bool
    
    let timer = Timer.publish(every: 1/60.0, on: .main, in: .common).autoconnect()
    
    init(
        particleCount: Int = 200,
        particleSpread: Float = 10,
        speed: Float = 0.1,
        particleColors: [Color] = [.white],
        moveParticlesOnHover: Bool = false,
        particleHoverFactor: Float = 1.0,
        alphaParticles: Bool = false,
        particleBaseSize: Float = 100,
        sizeRandomness: Float = 1.0,
        cameraDistance: Float = 20,
        disableRotation: Bool = false
    ) {
        self.particleCount = particleCount
        self.particleSpread = particleSpread
        self.speed = speed
        self.particleColors = particleColors.isEmpty ? [.white] : particleColors
        self.moveParticlesOnHover = moveParticlesOnHover
        self.particleHoverFactor = particleHoverFactor
        self.alphaParticles = alphaParticles
        self.particleBaseSize = particleBaseSize
        self.sizeRandomness = sizeRandomness
        self.cameraDistance = cameraDistance
        self.disableRotation = disableRotation
    }
    
    var body: some View {
        ParticlesMetalView(
            time: time,
            mousePosition: mousePosition,
            rotationX: rotationX,
            rotationY: rotationY,
            rotationZ: rotationZ,
            particleCount: particleCount,
            particleSpread: particleSpread,
            particleColors: particleColors,
            moveParticlesOnHover: moveParticlesOnHover,
            particleHoverFactor: particleHoverFactor,
            alphaParticles: alphaParticles,
            particleBaseSize: particleBaseSize,
            sizeRandomness: sizeRandomness,
            cameraDistance: cameraDistance
        )
        .onReceive(timer) { _ in
            time += 0.016 * speed
            
            if !disableRotation {
                rotationX = sin(time * 0.2) * 0.1
                rotationY = cos(time * 0.5) * 0.15
                rotationZ += 0.01 * speed
            }
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    if moveParticlesOnHover {
                        let size = UIScreen.main.bounds
                        let x = (value.location.x / size.width) * 2 - 1
                        let y = -((value.location.y / size.height) * 2 - 1)
                        mousePosition = CGPoint(x: x, y: y)
                    }
                }
        )
    }
}

struct ParticlesMetalView: UIViewRepresentable {
    let time: Float
    let mousePosition: CGPoint
    let rotationX: Float
    let rotationY: Float
    let rotationZ: Float
    let particleCount: Int
    let particleSpread: Float
    let particleColors: [Color]
    let moveParticlesOnHover: Bool
    let particleHoverFactor: Float
    let alphaParticles: Bool
    let particleBaseSize: Float
    let sizeRandomness: Float
    let cameraDistance: Float
    
    func makeUIView(context: Context) -> MTKView {
        let mtkView = MTKView()
        mtkView.device = MTLCreateSystemDefaultDevice()
        mtkView.delegate = context.coordinator
        mtkView.preferredFramesPerSecond = 60
        mtkView.enableSetNeedsDisplay = false
        mtkView.framebufferOnly = false
        mtkView.drawableSize = mtkView.frame.size
        mtkView.isPaused = false
        mtkView.backgroundColor = .clear
        mtkView.isOpaque = false
        mtkView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        // Setup particles after device is set
        context.coordinator.setupParticles(count: particleCount, colors: particleColors)
        return mtkView
    }
    
    func updateUIView(_ uiView: MTKView, context: Context) {
        let coordinator = context.coordinator
        coordinator.time = time
        coordinator.mousePosition = mousePosition
        coordinator.rotationX = rotationX
        coordinator.rotationY = rotationY
        coordinator.rotationZ = rotationZ
        coordinator.particleSpread = particleSpread
        coordinator.moveParticlesOnHover = moveParticlesOnHover
        coordinator.particleHoverFactor = particleHoverFactor
        coordinator.alphaParticles = alphaParticles
        coordinator.particleBaseSize = particleBaseSize
        coordinator.sizeRandomness = sizeRandomness
        coordinator.cameraDistance = cameraDistance
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, MTKViewDelegate {
        var time: Float = 0
        var mousePosition = CGPoint.zero
        var rotationX: Float = 0
        var rotationY: Float = 0
        var rotationZ: Float = 0
        var particleSpread: Float = 10
        var moveParticlesOnHover = false
        var particleHoverFactor: Float = 1.0
        var alphaParticles = false
        var particleBaseSize: Float = 100
        var sizeRandomness: Float = 1.0
        var cameraDistance: Float = 20
        
        var device: MTLDevice!
        var commandQueue: MTLCommandQueue!
        var pipelineState: MTLRenderPipelineState!
        var particleBuffer: MTLBuffer!
        var particleCount: Int = 0
        
        struct Particle {
            var position: SIMD3<Float>
            var random: SIMD4<Float>
            var color: SIMD3<Float>
        }
        
        override init() {
            super.init()
            setupMetal()
        }
        
        func setupMetal() {
            device = MTLCreateSystemDefaultDevice()
            commandQueue = device.makeCommandQueue()
            
            guard let library = device.makeDefaultLibrary() else {
                print("Failed to create Metal library")
                return
            }
            
            guard let vertexFunction = library.makeFunction(name: "particlesVertex") else {
                print("Failed to find particlesVertex function")
                return
            }
            
            guard let fragmentFunction = library.makeFunction(name: "particlesFragment") else {
                print("Failed to find particlesFragment function")
                return
            }
            
            let pipelineDescriptor = MTLRenderPipelineDescriptor()
            pipelineDescriptor.vertexFunction = vertexFunction
            pipelineDescriptor.fragmentFunction = fragmentFunction
            pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
            
            // Enable blending for transparency
            pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
            pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
            pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
            
            pipelineState = try! device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        }
        
        func setupParticles(count: Int, colors: [Color]) {
            guard device != nil else { return }
            
            particleCount = count
            var particles: [Particle] = []
            particles.reserveCapacity(count)
            
            for _ in 0..<count {
                // Generate random position on unit sphere
                var x: Float, y: Float, z: Float, len: Float
                repeat {
                    x = Float.random(in: -1...1)
                    y = Float.random(in: -1...1)
                    z = Float.random(in: -1...1)
                    len = x * x + y * y + z * z
                } while len > 1 || len == 0
                
                let r = pow(Float.random(in: 0...1), 1.0/3.0)
                let position = SIMD3<Float>(x * r, y * r, z * r)
                
                // Random values for animation
                let random = SIMD4<Float>(
                    Float.random(in: 0...1),
                    Float.random(in: 0...1),
                    Float.random(in: 0...1),
                    Float.random(in: 0...1)
                )
                
                // Random color from palette
                let color = colors.isEmpty ? Color.white : colors[Int.random(in: 0..<colors.count)]
                let uiColor = UIColor(color)
                var red: CGFloat = 0
                var green: CGFloat = 0
                var blue: CGFloat = 0
                var alpha: CGFloat = 0
                uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
                
                let particleColor = SIMD3<Float>(Float(red), Float(green), Float(blue))
                
                particles.append(Particle(position: position, random: random, color: particleColor))
            }
            
            if !particles.isEmpty {
                particleBuffer = device.makeBuffer(bytes: particles,
                                                  length: particles.count * MemoryLayout<Particle>.stride,
                                                  options: .storageModeShared)
            }
        }
        
        func createProjectionMatrix(fov: Float, aspect: Float, near: Float, far: Float) -> float4x4 {
            let y = 1 / tan(fov * 0.5)
            let x = y / aspect
            let z = far / (far - near)
            let w = -near * z
            
            return float4x4(
                SIMD4<Float>(x, 0, 0, 0),
                SIMD4<Float>(0, y, 0, 0),
                SIMD4<Float>(0, 0, z, 1),
                SIMD4<Float>(0, 0, w, 0)
            )
        }
        
        func createViewMatrix(position: SIMD3<Float>, target: SIMD3<Float>, up: SIMD3<Float>) -> float4x4 {
            let z = normalize(position - target)
            let x = normalize(cross(up, z))
            let y = cross(z, x)
            
            return float4x4(
                SIMD4<Float>(x.x, y.x, z.x, 0),
                SIMD4<Float>(x.y, y.y, z.y, 0),
                SIMD4<Float>(x.z, y.z, z.z, 0),
                SIMD4<Float>(-dot(x, position), -dot(y, position), -dot(z, position), 1)
            )
        }
        
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
            // Handle size change if needed
        }
        
        func draw(in view: MTKView) {
            guard let drawable = view.currentDrawable,
                  let descriptor = view.currentRenderPassDescriptor,
                  let commandBuffer = commandQueue.makeCommandBuffer(),
                  let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor),
                  particleBuffer != nil,
                  view.drawableSize.width > 0,
                  view.drawableSize.height > 0 else {
                return
            }
            
            // Clear to transparent
            descriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
            
            // Set up matrices
            let aspect = Float(view.drawableSize.width / view.drawableSize.height)
            let projectionMatrix = createProjectionMatrix(fov: 15.0 * Float.pi / 180.0,
                                                         aspect: aspect,
                                                         near: 0.1,
                                                         far: 100.0)
            
            let viewMatrix = createViewMatrix(position: SIMD3<Float>(0, 0, cameraDistance),
                                             target: SIMD3<Float>(0, 0, 0),
                                             up: SIMD3<Float>(0, 1, 0))
            
            let modelMatrix = float4x4(
                SIMD4<Float>(1, 0, 0, 0),
                SIMD4<Float>(0, 1, 0, 0),
                SIMD4<Float>(0, 0, 1, 0),
                SIMD4<Float>(0, 0, 0, 1)
            )
            
            // Calculate mouse position in 3D space
            let mousePos = moveParticlesOnHover ?
                SIMD3<Float>(-Float(mousePosition.x), -Float(mousePosition.y), 0) :
                SIMD3<Float>(0, 0, 0)
            
            // Create uniforms structure with proper memory layout
            struct ParticleUniforms {
                var modelMatrix: float4x4
                var viewMatrix: float4x4
                var projectionMatrix: float4x4
                var time: Float
                var spread: Float
                var baseSize: Float
                var sizeRandomness: Float
                var alphaParticles: Float
                var mousePosition: SIMD3<Float>
                var hoverFactor: Float
                var rotation: SIMD3<Float>
            }
            
            var uniforms = ParticleUniforms(
                modelMatrix: modelMatrix,
                viewMatrix: viewMatrix,
                projectionMatrix: projectionMatrix,
                time: time,
                spread: particleSpread,
                baseSize: particleBaseSize,
                sizeRandomness: sizeRandomness,
                alphaParticles: alphaParticles ? 1.0 : 0.0,
                mousePosition: mousePos,
                hoverFactor: particleHoverFactor,
                rotation: SIMD3<Float>(rotationX, rotationY, rotationZ)
            )
            
            encoder.setRenderPipelineState(pipelineState)
            encoder.setVertexBuffer(particleBuffer, offset: 0, index: 0)
            encoder.setVertexBytes(&uniforms, length: MemoryLayout<ParticleUniforms>.stride, index: 1)
            encoder.setFragmentBytes(&uniforms, length: MemoryLayout<ParticleUniforms>.stride, index: 0)
            
            // Draw particles as points
            encoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: particleCount)
            
            encoder.endEncoding()
            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
    }
}