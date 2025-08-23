import SwiftUI
import MetalKit
import Combine

struct PrismEffect: View {
    @State private var time: Float = 0
    @State private var mousePosition = CGPoint(x: 0.5, y: 0.5)
    @State private var currentYaw: Float = 0
    @State private var currentPitch: Float = 0
    @State private var currentRoll: Float = 0
    
    // Prism parameters
    let height: Float
    let baseWidth: Float
    let animationType: String
    let glow: Float
    let noise: Float
    let transparent: Bool
    let scale: Float
    let hueShift: Float
    let colorFrequency: Float
    let hoverStrength: Float
    let inertia: Float
    let bloom: Float
    let timeScale: Float
    
    let timer = Timer.publish(every: 1/60.0, on: .main, in: .common).autoconnect()
    
    init(
        height: Float = 3.5,
        baseWidth: Float = 5.5,
        animationType: String = "rotate",
        glow: Float = 1.0,
        noise: Float = 0.5,
        transparent: Bool = true,
        scale: Float = 3.6,
        hueShift: Float = 0.0,
        colorFrequency: Float = 1.0,
        hoverStrength: Float = 2.0,
        inertia: Float = 0.05,
        bloom: Float = 1.0,
        timeScale: Float = 0.5
    ) {
        self.height = max(0.001, height)
        self.baseWidth = max(0.001, baseWidth)
        self.animationType = animationType
        self.glow = max(0.0, glow)
        self.noise = max(0.0, noise)
        self.transparent = transparent
        self.scale = max(0.001, scale)
        self.hueShift = hueShift
        self.colorFrequency = max(0.0, colorFrequency)
        self.hoverStrength = max(0.0, hoverStrength)
        self.inertia = max(0.0, min(1.0, inertia))
        self.bloom = max(0.0, bloom)
        self.timeScale = max(0.0, timeScale)
    }
    
    var body: some View {
        PrismMetalView(
            time: time,
            mousePosition: mousePosition,
            currentYaw: currentYaw,
            currentPitch: currentPitch,
            currentRoll: currentRoll,
            height: height,
            baseWidth: baseWidth,
            animationType: animationType,
            glow: glow,
            noise: noise,
            transparent: transparent,
            scale: scale,
            hueShift: hueShift,
            colorFrequency: colorFrequency,
            hoverStrength: hoverStrength,
            inertia: inertia,
            bloom: bloom,
            timeScale: timeScale
        )
        .onReceive(timer) { _ in
            time += 0.016
            
            // Update rotation based on animation type
            if animationType == "3drotate" {
                let t = time * timeScale
                currentYaw = t * 0.45
                currentPitch = sin(t * 0.45) * 0.6
                currentRoll = sin(t * 0.3) * 0.5
            }
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    if animationType == "hover" {
                        let size = UIScreen.main.bounds
                        let normalizedX = (value.location.x - size.width * 0.5) / (size.width * 0.5)
                        let normalizedY = (value.location.y - size.height * 0.5) / (size.height * 0.5)
                        
                        withAnimation(.easeOut(duration: 0.1)) {
                            currentYaw = -Float(normalizedX) * 0.6 * hoverStrength
                            currentPitch = Float(normalizedY) * 0.6 * hoverStrength
                        }
                    }
                }
                .onEnded { _ in
                    if animationType == "hover" {
                        withAnimation(.easeOut(duration: 0.5)) {
                            currentYaw = 0
                            currentPitch = 0
                            currentRoll = 0
                        }
                    }
                }
        )
    }
}

struct PrismMetalView: UIViewRepresentable {
    let time: Float
    let mousePosition: CGPoint
    let currentYaw: Float
    let currentPitch: Float
    let currentRoll: Float
    let height: Float
    let baseWidth: Float
    let animationType: String
    let glow: Float
    let noise: Float
    let transparent: Bool
    let scale: Float
    let hueShift: Float
    let colorFrequency: Float
    let hoverStrength: Float
    let inertia: Float
    let bloom: Float
    let timeScale: Float
    
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
        coordinator.currentYaw = currentYaw
        coordinator.currentPitch = currentPitch
        coordinator.currentRoll = currentRoll
        coordinator.height = height
        coordinator.baseWidth = baseWidth
        coordinator.animationType = animationType
        coordinator.glow = glow
        coordinator.noise = noise
        coordinator.transparent = transparent
        coordinator.scale = scale
        coordinator.hueShift = hueShift
        coordinator.colorFrequency = colorFrequency
        coordinator.hoverStrength = hoverStrength
        coordinator.inertia = inertia
        coordinator.bloom = bloom
        coordinator.timeScale = timeScale
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, MTKViewDelegate {
        var time: Float = 0
        var mousePosition = CGPoint(x: 0.5, y: 0.5)
        var currentYaw: Float = 0
        var currentPitch: Float = 0
        var currentRoll: Float = 0
        var height: Float = 3.5
        var baseWidth: Float = 5.5
        var animationType = "rotate"
        var glow: Float = 1.0
        var noise: Float = 0.5
        var transparent = true
        var scale: Float = 3.6
        var hueShift: Float = 0.0
        var colorFrequency: Float = 1.0
        var hoverStrength: Float = 2.0
        var inertia: Float = 0.05
        var bloom: Float = 1.0
        var timeScale: Float = 0.5
        
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
            
            guard let vertexFunction = library.makeFunction(name: "prismVertex") else {
                print("Failed to find prismVertex function")
                return
            }
            
            guard let fragmentFunction = library.makeFunction(name: "prismFragment") else {
                print("Failed to find prismFragment function")
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
        
        func createRotationMatrix(yaw: Float, pitch: Float, roll: Float) -> simd_float3x3 {
            let cy = cos(yaw)
            let sy = sin(yaw)
            let cx = cos(pitch)
            let sx = sin(pitch)
            let cz = cos(roll)
            let sz = sin(roll)
            
            let r00 = cy * cz + sy * sx * sz
            let r01 = -cy * sz + sy * sx * cz
            let r02 = sy * cx
            
            let r10 = cx * sz
            let r11 = cx * cz
            let r12 = -sx
            
            let r20 = -sy * cz + cy * sx * sz
            let r21 = sy * sz + cy * sx * cz
            let r22 = cy * cx
            
            return simd_float3x3(
                simd_float3(r00, r10, r20),
                simd_float3(r01, r11, r21),
                simd_float3(r02, r12, r22)
            )
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
            
            // Clear background
            if transparent {
                descriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
            } else {
                descriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
            }
            
            // Calculate derived parameters
            let baseHalf: Float = baseWidth * 0.5
            let centerShift: Float = height * 0.25
            let invBaseHalf: Float = 1.0 / baseHalf
            let invHeight: Float = 1.0 / height
            let minAxis: Float = min(baseHalf, height)
            let pxScale: Float = 1.0 / (Float(view.drawableSize.height) * 0.1 * scale)
            let saturation: Float = transparent ? 1.5 : 1.0
            
            // Set up uniforms
            var uniforms1 = SIMD4<Float>(
                time,
                Float(view.drawableSize.width),
                Float(view.drawableSize.height),
                height
            )
            
            var uniforms2 = SIMD4<Float>(
                baseHalf,
                glow,
                noise,
                saturation
            )
            
            var uniforms3 = SIMD4<Float>(
                scale,
                hueShift,
                colorFrequency,
                bloom
            )
            
            var uniforms4 = SIMD4<Float>(
                centerShift,
                invBaseHalf,
                invHeight,
                minAxis
            )
            
            var uniforms5 = SIMD4<Float>(
                pxScale,
                timeScale,
                0.0,  // offsetX
                0.0   // offsetY
            )
            
            // Create rotation matrix
            var rotMatrix = createRotationMatrix(yaw: currentYaw, pitch: currentPitch, roll: currentRoll)
            
            // Set base wobble flag
            var useBaseWobble: Int32 = (animationType == "rotate") ? 1 : 0
            
            encoder.setRenderPipelineState(pipelineState)
            encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            encoder.setFragmentBytes(&uniforms1, length: MemoryLayout<SIMD4<Float>>.size, index: 0)
            encoder.setFragmentBytes(&uniforms2, length: MemoryLayout<SIMD4<Float>>.size, index: 1)
            encoder.setFragmentBytes(&uniforms3, length: MemoryLayout<SIMD4<Float>>.size, index: 2)
            encoder.setFragmentBytes(&uniforms4, length: MemoryLayout<SIMD4<Float>>.size, index: 3)
            encoder.setFragmentBytes(&uniforms5, length: MemoryLayout<SIMD4<Float>>.size, index: 4)
            encoder.setFragmentBytes(&rotMatrix, length: MemoryLayout<simd_float3x3>.size, index: 5)
            encoder.setFragmentBytes(&useBaseWobble, length: MemoryLayout<Int32>.size, index: 6)
            
            // Draw fullscreen triangle
            encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
            
            encoder.endEncoding()
            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
    }
}