import SwiftUI
import MetalKit
import Combine

struct PlasmaEffect: View {
    @State private var time: Float = 0
    @State private var mousePosition = CGPoint.zero
    @State private var directionValue: Float = 1.0
    
    // Plasma parameters
    let color: Color
    let speed: Float
    let direction: String
    let scale: Float
    let opacity: Float
    let mouseInteractive: Bool
    
    let timer = Timer.publish(every: 1/60.0, on: .main, in: .common).autoconnect()
    
    init(
        color: Color = .white,
        speed: Float = 1.0,
        direction: String = "forward",
        scale: Float = 1.0,
        opacity: Float = 1.0,
        mouseInteractive: Bool = true
    ) {
        self.color = color
        self.speed = speed
        self.direction = direction
        self.scale = scale
        self.opacity = opacity
        self.mouseInteractive = mouseInteractive
    }
    
    var body: some View {
        PlasmaMetalView(
            time: time,
            mousePosition: mousePosition,
            directionValue: directionValue,
            color: color,
            speed: speed,
            scale: scale,
            opacity: opacity,
            mouseInteractive: mouseInteractive
        )
        .onReceive(timer) { _ in
            time += 0.016
            
            // Handle direction changes
            switch direction {
            case "reverse":
                directionValue = -1.0
            case "pingpong":
                directionValue = sin(time * 0.5)
            default: // "forward"
                directionValue = 1.0
            }
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    if mouseInteractive {
                        mousePosition = value.location
                    }
                }
        )
    }
}

struct PlasmaMetalView: UIViewRepresentable {
    let time: Float
    let mousePosition: CGPoint
    let directionValue: Float
    let color: Color
    let speed: Float
    let scale: Float
    let opacity: Float
    let mouseInteractive: Bool
    
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
        return mtkView
    }
    
    func updateUIView(_ uiView: MTKView, context: Context) {
        let coordinator = context.coordinator
        coordinator.time = time
        coordinator.mousePosition = mousePosition
        coordinator.directionValue = directionValue
        coordinator.color = color
        coordinator.speed = speed
        coordinator.scale = scale
        coordinator.opacity = opacity
        coordinator.mouseInteractive = mouseInteractive
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, MTKViewDelegate {
        var time: Float = 0
        var mousePosition = CGPoint.zero
        var directionValue: Float = 1.0
        var color = Color.white
        var speed: Float = 1.0
        var scale: Float = 1.0
        var opacity: Float = 1.0
        var mouseInteractive = true
        
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
            
            guard let vertexFunction = library.makeFunction(name: "plasmaVertex") else {
                print("Failed to find plasmaVertex function")
                return
            }
            
            guard let fragmentFunction = library.makeFunction(name: "plasmaFragment") else {
                print("Failed to find plasmaFragment function")
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
            
            // Clear to transparent
            descriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
            
            // Convert SwiftUI Color to RGB
            let uiColor = UIColor(color)
            var red: CGFloat = 0
            var green: CGFloat = 0
            var blue: CGFloat = 0
            var alpha: CGFloat = 0
            uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
            
            // Determine if using custom color (not white)
            let useCustomColor: Float = (red != 1.0 || green != 1.0 || blue != 1.0) ? 1.0 : 0.0
            
            // Set up uniforms
            var uniforms1 = SIMD4<Float>(
                time,
                Float(view.drawableSize.width),
                Float(view.drawableSize.height),
                speed * 0.4
            )
            
            var uniforms2 = SIMD4<Float>(
                directionValue,
                scale,
                opacity,
                useCustomColor
            )
            
            var customColorData = SIMD4<Float>(
                Float(red),
                Float(green),
                Float(blue),
                mouseInteractive ? 1.0 : 0.0
            )
            
            var mouseData = SIMD4<Float>(
                Float(mousePosition.x * view.contentScaleFactor),
                Float(mousePosition.y * view.contentScaleFactor),
                0.0,
                0.0
            )
            
            encoder.setRenderPipelineState(pipelineState)
            encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            encoder.setFragmentBytes(&uniforms1, length: MemoryLayout<SIMD4<Float>>.size, index: 0)
            encoder.setFragmentBytes(&uniforms2, length: MemoryLayout<SIMD4<Float>>.size, index: 1)
            encoder.setFragmentBytes(&customColorData, length: MemoryLayout<SIMD4<Float>>.size, index: 2)
            encoder.setFragmentBytes(&mouseData, length: MemoryLayout<SIMD4<Float>>.size, index: 3)
            
            // Draw fullscreen triangle
            encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
            
            encoder.endEncoding()
            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
    }
}