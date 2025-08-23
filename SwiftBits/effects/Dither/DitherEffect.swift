import SwiftUI
import MetalKit
import Combine

struct DitherEffect: View {
    @State private var time: Float = 0
    @State private var mousePosition = CGPoint.zero
    @State private var isMouseInteracting = false
    
    // Wave parameters
    let waveSpeed: Float
    let waveFrequency: Float
    let waveAmplitude: Float
    let waveColor: SIMD3<Float>
    
    // Dither parameters
    let colorNum: Float
    let pixelSize: Float
    let enableMouseInteraction: Bool
    let mouseRadius: Float
    
    let timer = Timer.publish(every: 1/60.0, on: .main, in: .common).autoconnect()
    
    init(
        waveSpeed: Float = 0.05,
        waveFrequency: Float = 3.0,
        waveAmplitude: Float = 0.3,
        waveColor: SIMD3<Float> = SIMD3<Float>(0.5, 0.5, 0.5),
        colorNum: Float = 4.0,
        pixelSize: Float = 2.0,
        enableMouseInteraction: Bool = true,
        mouseRadius: Float = 0.3
    ) {
        self.waveSpeed = waveSpeed
        self.waveFrequency = waveFrequency
        self.waveAmplitude = waveAmplitude
        self.waveColor = waveColor
        self.colorNum = colorNum
        self.pixelSize = pixelSize
        self.enableMouseInteraction = enableMouseInteraction
        self.mouseRadius = mouseRadius
    }
    
    var body: some View {
        DitherMetalView(
            time: time,
            mousePosition: mousePosition,
            waveSpeed: waveSpeed,
            waveFrequency: waveFrequency,
            waveAmplitude: waveAmplitude,
            waveColor: waveColor,
            colorNum: colorNum,
            pixelSize: pixelSize,
            enableMouseInteraction: enableMouseInteraction,
            mouseRadius: mouseRadius
        )
        .onReceive(timer) { _ in
            time += 0.016
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    if enableMouseInteraction {
                        mousePosition = value.location
                        isMouseInteracting = true
                    }
                }
                .onEnded { _ in
                    isMouseInteracting = false
                }
        )
    }
}

struct DitherMetalView: UIViewRepresentable {
    let time: Float
    let mousePosition: CGPoint
    let waveSpeed: Float
    let waveFrequency: Float
    let waveAmplitude: Float
    let waveColor: SIMD3<Float>
    let colorNum: Float
    let pixelSize: Float
    let enableMouseInteraction: Bool
    let mouseRadius: Float
    
    func makeUIView(context: Context) -> MTKView {
        let mtkView = MTKView()
        mtkView.device = MTLCreateSystemDefaultDevice()
        mtkView.delegate = context.coordinator
        mtkView.preferredFramesPerSecond = 60
        mtkView.enableSetNeedsDisplay = false  // Changed to false for continuous rendering
        mtkView.framebufferOnly = false
        mtkView.drawableSize = mtkView.frame.size
        mtkView.isPaused = false
        mtkView.backgroundColor = .clear
        return mtkView
    }
    
    func updateUIView(_ uiView: MTKView, context: Context) {
        context.coordinator.time = time
        context.coordinator.mousePosition = mousePosition
        context.coordinator.waveSpeed = waveSpeed
        context.coordinator.waveFrequency = waveFrequency
        context.coordinator.waveAmplitude = waveAmplitude
        context.coordinator.waveColor = waveColor
        context.coordinator.colorNum = colorNum
        context.coordinator.pixelSize = pixelSize
        context.coordinator.enableMouseInteraction = enableMouseInteraction
        context.coordinator.mouseRadius = mouseRadius
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, MTKViewDelegate {
        var time: Float = 0
        var mousePosition = CGPoint.zero
        var waveSpeed: Float = 0.05
        var waveFrequency: Float = 3.0
        var waveAmplitude: Float = 0.3
        var waveColor = SIMD3<Float>(0.5, 0.5, 0.5)
        var colorNum: Float = 4.0
        var pixelSize: Float = 2.0
        var enableMouseInteraction = true
        var mouseRadius: Float = 0.3
        
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
            
            // Create vertex data for fullscreen quad
            let vertices: [Float] = [
                -1.0, -1.0, 0.0, 1.0,  // bottom left
                 1.0, -1.0, 0.0, 1.0,  // bottom right
                -1.0,  1.0, 0.0, 1.0,  // top left
                 1.0,  1.0, 0.0, 1.0,  // top right
            ]
            
            vertexBuffer = device.makeBuffer(bytes: vertices,
                                            length: vertices.count * MemoryLayout<Float>.stride,
                                            options: [])
            
            let library = try! device.makeDefaultLibrary(bundle: .main)
            let vertexFunction = library.makeFunction(name: "ditherVertex")
            let fragmentFunction = library.makeFunction(name: "ditherFragment")
            
            let pipelineDescriptor = MTLRenderPipelineDescriptor()
            pipelineDescriptor.vertexFunction = vertexFunction
            pipelineDescriptor.fragmentFunction = fragmentFunction
            pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
            
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
            
            // Clear to black
            descriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
            
            // Set up uniforms
            var uniforms = SIMD4<Float>(
                time,
                Float(view.drawableSize.width),
                Float(view.drawableSize.height),
                waveSpeed
            )
            
            var waveParams = SIMD4<Float>(
                waveFrequency,
                waveAmplitude,
                colorNum,
                pixelSize
            )
            
            var waveColorData = SIMD4<Float>(
                waveColor.x,
                waveColor.y,
                waveColor.z,
                enableMouseInteraction ? 1.0 : 0.0
            )
            
            var mouseData = SIMD4<Float>(
                Float(mousePosition.x) * Float(view.contentScaleFactor),
                Float(mousePosition.y) * Float(view.contentScaleFactor),
                mouseRadius,
                0.0
            )
            
            encoder.setRenderPipelineState(pipelineState)
            encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            encoder.setFragmentBytes(&uniforms, length: MemoryLayout<SIMD4<Float>>.size, index: 0)
            encoder.setFragmentBytes(&waveParams, length: MemoryLayout<SIMD4<Float>>.size, index: 1)
            encoder.setFragmentBytes(&waveColorData, length: MemoryLayout<SIMD4<Float>>.size, index: 2)
            encoder.setFragmentBytes(&mouseData, length: MemoryLayout<SIMD4<Float>>.size, index: 3)
            
            // Draw fullscreen quad
            encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
            
            encoder.endEncoding()
            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
    }
}