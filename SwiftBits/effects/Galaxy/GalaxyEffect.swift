import SwiftUI
import MetalKit
import Combine

struct GalaxyEffect: View {
    @State private var time: Float = 0
    @State private var mousePosition = CGPoint(x: 0.5, y: 0.5)
    @State private var mouseActive: Float = 0
    
    // Galaxy parameters
    let focal: SIMD2<Float>
    let rotation: SIMD2<Float>
    let starSpeed: Float
    let density: Float
    let hueShift: Float
    let speed: Float
    let glowIntensity: Float
    let saturation: Float
    let mouseRepulsion: Bool
    let repulsionStrength: Float
    let twinkleIntensity: Float
    let rotationSpeed: Float
    let autoCenterRepulsion: Float
    let transparent: Bool
    
    let timer = Timer.publish(every: 1/60.0, on: .main, in: .common).autoconnect()
    
    init(
        focal: SIMD2<Float> = SIMD2<Float>(0.5, 0.5),
        rotation: SIMD2<Float> = SIMD2<Float>(1.0, 0.0),
        starSpeed: Float = 0.5,
        density: Float = 1.0,
        hueShift: Float = 140.0,
        speed: Float = 1.0,
        glowIntensity: Float = 0.3,
        saturation: Float = 0.8,
        mouseRepulsion: Bool = true,
        repulsionStrength: Float = 2.0,
        twinkleIntensity: Float = 0.3,
        rotationSpeed: Float = 0.1,
        autoCenterRepulsion: Float = 0.0,
        transparent: Bool = true
    ) {
        self.focal = focal
        self.rotation = rotation
        self.starSpeed = starSpeed
        self.density = density
        self.hueShift = hueShift
        self.speed = speed
        self.glowIntensity = glowIntensity
        self.saturation = saturation
        self.mouseRepulsion = mouseRepulsion
        self.repulsionStrength = repulsionStrength
        self.twinkleIntensity = twinkleIntensity
        self.rotationSpeed = rotationSpeed
        self.autoCenterRepulsion = autoCenterRepulsion
        self.transparent = transparent
    }
    
    var body: some View {
        GalaxyMetalView(
            time: time,
            mousePosition: mousePosition,
            mouseActive: mouseActive,
            focal: focal,
            rotation: rotation,
            starSpeed: starSpeed,
            density: density,
            hueShift: hueShift,
            speed: speed,
            glowIntensity: glowIntensity,
            saturation: saturation,
            mouseRepulsion: mouseRepulsion,
            repulsionStrength: repulsionStrength,
            twinkleIntensity: twinkleIntensity,
            rotationSpeed: rotationSpeed,
            autoCenterRepulsion: autoCenterRepulsion,
            transparent: transparent
        )
        .onReceive(timer) { _ in
            time += 0.016
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    mousePosition = value.location
                    mouseActive = 1.0
                }
                .onEnded { _ in
                    withAnimation(.easeOut(duration: 0.5)) {
                        mouseActive = 0.0
                    }
                }
        )
    }
}

struct GalaxyMetalView: UIViewRepresentable {
    let time: Float
    let mousePosition: CGPoint
    let mouseActive: Float
    let focal: SIMD2<Float>
    let rotation: SIMD2<Float>
    let starSpeed: Float
    let density: Float
    let hueShift: Float
    let speed: Float
    let glowIntensity: Float
    let saturation: Float
    let mouseRepulsion: Bool
    let repulsionStrength: Float
    let twinkleIntensity: Float
    let rotationSpeed: Float
    let autoCenterRepulsion: Float
    let transparent: Bool
    
    func makeUIView(context: Context) -> MTKView {
        let mtkView = MTKView()
        mtkView.device = MTLCreateSystemDefaultDevice()
        mtkView.delegate = context.coordinator
        mtkView.preferredFramesPerSecond = 60
        mtkView.enableSetNeedsDisplay = false
        mtkView.framebufferOnly = false
        mtkView.drawableSize = mtkView.frame.size
        mtkView.isPaused = false
        mtkView.backgroundColor = transparent ? .clear : .black
        mtkView.isOpaque = !transparent
        return mtkView
    }
    
    func updateUIView(_ uiView: MTKView, context: Context) {
        let coordinator = context.coordinator
        coordinator.time = time
        coordinator.mousePosition = mousePosition
        coordinator.mouseActive = mouseActive
        coordinator.focal = focal
        coordinator.rotation = rotation
        coordinator.starSpeed = starSpeed
        coordinator.density = density
        coordinator.hueShift = hueShift
        coordinator.speed = speed
        coordinator.glowIntensity = glowIntensity
        coordinator.saturation = saturation
        coordinator.mouseRepulsion = mouseRepulsion
        coordinator.repulsionStrength = repulsionStrength
        coordinator.twinkleIntensity = twinkleIntensity
        coordinator.rotationSpeed = rotationSpeed
        coordinator.autoCenterRepulsion = autoCenterRepulsion
        coordinator.transparent = transparent
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, MTKViewDelegate {
        var time: Float = 0
        var mousePosition = CGPoint(x: 0.5, y: 0.5)
        var mouseActive: Float = 0
        var focal = SIMD2<Float>(0.5, 0.5)
        var rotation = SIMD2<Float>(1.0, 0.0)
        var starSpeed: Float = 0.5
        var density: Float = 1.0
        var hueShift: Float = 140.0
        var speed: Float = 1.0
        var glowIntensity: Float = 0.3
        var saturation: Float = 0.8
        var mouseRepulsion = true
        var repulsionStrength: Float = 2.0
        var twinkleIntensity: Float = 0.3
        var rotationSpeed: Float = 0.1
        var autoCenterRepulsion: Float = 0.0
        var transparent = true
        
        var device: MTLDevice!
        var commandQueue: MTLCommandQueue!
        var pipelineState: MTLRenderPipelineState!
        var vertexBuffer: MTLBuffer!
        
        override init() {
            super.init()
            setupMetal()
        }
        
        func setupMetal() {
            device = MTLCreateSystemDefaultDevice()
            commandQueue = device.makeCommandQueue()
            
            // Create fullscreen triangle vertices
            let vertices: [Float] = [
                -1.0, -1.0, 0.0, 1.0,
                 3.0, -1.0, 0.0, 1.0,
                -1.0,  3.0, 0.0, 1.0
            ]
            
            vertexBuffer = device.makeBuffer(bytes: vertices,
                                            length: vertices.count * MemoryLayout<Float>.stride,
                                            options: [])
            
            guard let library = device.makeDefaultLibrary() else {
                print("Failed to create Metal library")
                return
            }
            
            guard let vertexFunction = library.makeFunction(name: "galaxyVertex") else {
                print("Failed to find galaxyVertex function")
                return
            }
            
            guard let fragmentFunction = library.makeFunction(name: "galaxyFragment") else {
                print("Failed to find galaxyFragment function")
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
            pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
            pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
            
            pipelineState = try! device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        }
        
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
            // Handle size change if needed
        }
        
        func draw(in view: MTKView) {
            guard let drawable = view.currentDrawable,
                  let descriptor = view.currentRenderPassDescriptor,
                  let commandBuffer = commandQueue.makeCommandBuffer(),
                  let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
                return
            }
            
            // Clear to transparent or black
            if transparent {
                descriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
            } else {
                descriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
            }
            
            // Normalize mouse position
            let normalizedMouseX = Float(mousePosition.x / view.bounds.width)
            let normalizedMouseY = Float(1.0 - mousePosition.y / view.bounds.height)
            
            // Set up uniforms
            var uniforms = SIMD4<Float>(
                time,
                Float(view.drawableSize.width),
                Float(view.drawableSize.height),
                starSpeed
            )
            
            var params1 = SIMD4<Float>(
                density,
                hueShift,
                speed,
                glowIntensity
            )
            
            var params2 = SIMD4<Float>(
                saturation,
                twinkleIntensity,
                rotationSpeed,
                repulsionStrength
            )
            
            var mouseData = SIMD4<Float>(
                normalizedMouseX,
                normalizedMouseY,
                mouseActive,
                autoCenterRepulsion
            )
            
            var focalData = SIMD4<Float>(
                focal.x,
                focal.y,
                rotation.x,
                rotation.y
            )
            
            var flags = SIMD4<Float>(
                mouseRepulsion ? 1.0 : 0.0,
                transparent ? 1.0 : 0.0,
                0.0,
                0.0
            )
            
            encoder.setRenderPipelineState(pipelineState)
            encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            encoder.setFragmentBytes(&uniforms, length: MemoryLayout<SIMD4<Float>>.size, index: 0)
            encoder.setFragmentBytes(&params1, length: MemoryLayout<SIMD4<Float>>.size, index: 1)
            encoder.setFragmentBytes(&params2, length: MemoryLayout<SIMD4<Float>>.size, index: 2)
            encoder.setFragmentBytes(&mouseData, length: MemoryLayout<SIMD4<Float>>.size, index: 3)
            encoder.setFragmentBytes(&focalData, length: MemoryLayout<SIMD4<Float>>.size, index: 4)
            encoder.setFragmentBytes(&flags, length: MemoryLayout<SIMD4<Float>>.size, index: 5)
            
            // Draw fullscreen triangle
            encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
            
            encoder.endEncoding()
            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
    }
}