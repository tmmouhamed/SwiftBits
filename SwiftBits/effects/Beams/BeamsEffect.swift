import SwiftUI
import MetalKit
import Combine

struct BeamsEffect: View {
    @State private var time: Float = 0
    
    // Beam parameters
    let beamWidth: Float
    let beamHeight: Float
    let beamNumber: Float
    let lightColor: Color
    let speed: Float
    let noiseIntensity: Float
    let scale: Float
    let rotation: Float
    
    let timer = Timer.publish(every: 1/60.0, on: .main, in: .common).autoconnect()
    
    init(
        beamWidth: Float = 2.0,
        beamHeight: Float = 15.0,
        beamNumber: Float = 12.0,
        lightColor: Color = .white,
        speed: Float = 2.0,
        noiseIntensity: Float = 1.75,
        scale: Float = 0.2,
        rotation: Float = 0.0
    ) {
        self.beamWidth = beamWidth
        self.beamHeight = beamHeight
        self.beamNumber = beamNumber
        self.lightColor = lightColor
        self.speed = speed
        self.noiseIntensity = noiseIntensity
        self.scale = scale
        self.rotation = rotation
    }
    
    var body: some View {
        BeamsMetalView(
            time: time,
            beamWidth: beamWidth,
            beamHeight: beamHeight,
            beamNumber: beamNumber,
            lightColor: lightColor,
            speed: speed,
            noiseIntensity: noiseIntensity,
            scale: scale,
            rotation: rotation
        )
        .onReceive(timer) { _ in
            time += 0.016
        }
    }
}

struct BeamsMetalView: UIViewRepresentable {
    let time: Float
    let beamWidth: Float
    let beamHeight: Float
    let beamNumber: Float
    let lightColor: Color
    let speed: Float
    let noiseIntensity: Float
    let scale: Float
    let rotation: Float
    
    func makeUIView(context: Context) -> MTKView {
        let mtkView = MTKView()
        mtkView.device = MTLCreateSystemDefaultDevice()
        mtkView.delegate = context.coordinator
        mtkView.preferredFramesPerSecond = 60
        mtkView.enableSetNeedsDisplay = false
        mtkView.framebufferOnly = false
        mtkView.drawableSize = mtkView.frame.size
        mtkView.isPaused = false
        mtkView.backgroundColor = .black
        return mtkView
    }
    
    func updateUIView(_ uiView: MTKView, context: Context) {
        context.coordinator.time = time
        context.coordinator.beamWidth = beamWidth
        context.coordinator.beamHeight = beamHeight
        context.coordinator.beamNumber = beamNumber
        context.coordinator.lightColor = lightColor
        context.coordinator.speed = speed
        context.coordinator.noiseIntensity = noiseIntensity
        context.coordinator.scale = scale
        context.coordinator.rotation = rotation
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, MTKViewDelegate {
        var time: Float = 0
        var beamWidth: Float = 2.0
        var beamHeight: Float = 15.0
        var beamNumber: Float = 12.0
        var lightColor: Color = .white
        var speed: Float = 2.0
        var noiseIntensity: Float = 1.75
        var scale: Float = 0.2
        var rotation: Float = 0.0
        
        var device: MTLDevice!
        var commandQueue: MTLCommandQueue!
        var pipelineState: MTLRenderPipelineState!
        var vertexBuffer: MTLBuffer!
        var indexBuffer: MTLBuffer!
        
        override init() {
            super.init()
            setupMetal()
        }
        
        func setupMetal() {
            device = MTLCreateSystemDefaultDevice()
            commandQueue = device.makeCommandQueue()
            
            // Create vertices for multiple beams
            let maxBeams = 20
            var vertices: [Float] = []
            
            // Create a quad for each potential beam
            for _ in 0..<maxBeams {
                // Bottom left
                vertices.append(contentsOf: [0.0, 0.0, 0.0, 1.0])
                // Bottom right  
                vertices.append(contentsOf: [1.0, 0.0, 0.0, 1.0])
                // Top left
                vertices.append(contentsOf: [0.0, 1.0, 0.0, 1.0])
                // Top right
                vertices.append(contentsOf: [1.0, 1.0, 0.0, 1.0])
            }
            
            vertexBuffer = device.makeBuffer(bytes: vertices,
                                            length: vertices.count * MemoryLayout<Float>.stride,
                                            options: [])
            
            // Create indices for triangle strips
            var indices: [UInt32] = []
            for i in 0..<maxBeams {
                let base = UInt32(i * 4)
                // First triangle
                indices.append(contentsOf: [base, base + 1, base + 2])
                // Second triangle
                indices.append(contentsOf: [base + 2, base + 1, base + 3])
            }
            
            indexBuffer = device.makeBuffer(bytes: indices,
                                           length: indices.count * MemoryLayout<UInt32>.stride,
                                           options: [])
            
            guard let library = device.makeDefaultLibrary() else {
                print("Failed to create Metal library")
                return
            }
            
            guard let vertexFunction = library.makeFunction(name: "beamsVertex") else {
                print("Failed to find beamsVertex function")
                return
            }
            
            guard let fragmentFunction = library.makeFunction(name: "beamsFragment") else {
                print("Failed to find beamsFragment function")
                return
            }
            
            let pipelineDescriptor = MTLRenderPipelineDescriptor()
            pipelineDescriptor.vertexFunction = vertexFunction
            pipelineDescriptor.fragmentFunction = fragmentFunction
            pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
            
            // Don't use depth testing for now
            // pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
            
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
            
            // Convert color to RGB values
            let uiColor = UIColor(lightColor)
            var red: CGFloat = 0
            var green: CGFloat = 0
            var blue: CGFloat = 0
            var alpha: CGFloat = 0
            uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
            
            // Set up uniforms
            var uniforms = SIMD4<Float>(
                time,
                beamWidth,
                beamHeight,
                beamNumber
            )
            
            var params = SIMD4<Float>(
                speed,
                noiseIntensity,
                scale,
                rotation * Float.pi / 180.0  // Convert to radians
            )
            
            var lightColorData = SIMD4<Float>(
                Float(red),
                Float(green),
                Float(blue),
                1.0
            )
            
            encoder.setRenderPipelineState(pipelineState)
            encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            encoder.setVertexBytes(&uniforms, length: MemoryLayout<SIMD4<Float>>.size, index: 1)
            encoder.setVertexBytes(&params, length: MemoryLayout<SIMD4<Float>>.size, index: 2)
            encoder.setFragmentBytes(&uniforms, length: MemoryLayout<SIMD4<Float>>.size, index: 0)
            encoder.setFragmentBytes(&params, length: MemoryLayout<SIMD4<Float>>.size, index: 1)
            encoder.setFragmentBytes(&lightColorData, length: MemoryLayout<SIMD4<Float>>.size, index: 2)
            
            // Draw beams using indexed drawing
            let beamCount = Int(beamNumber)
            encoder.drawIndexedPrimitives(
                type: .triangle,
                indexCount: beamCount * 6,
                indexType: .uint32,
                indexBuffer: indexBuffer!,
                indexBufferOffset: 0
            )
            
            encoder.endEncoding()
            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
    }
}