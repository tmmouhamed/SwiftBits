import MetalKit
/*
Purpose: SwiftUI UIViewRepresentable for aurora-like flowing glow using Metal shader `Aurora.metal`.
Inputs:  Public properties `colorStops` (3 colors), `amplitude`, `blend`.
Outputs: Transparent additive layer rendering aurora band; no side effects beyond rendering.
*/
import SwiftUI
import simd

public struct AuroraEffect: UIViewRepresentable {
  public var colorStops: [Color] = [
    Color(red: 0.32, green: 0.15, blue: 1.0), Color(red: 0.49, green: 1.0, blue: 0.40),
    Color(red: 0.32, green: 0.15, blue: 1.0),
  ]
  public var amplitude: Float = 1.0
  public var blend: Float = 0.5

  public init(
    colorStops: [Color] = [
      Color(red: 0.32, green: 0.15, blue: 1.0), Color(red: 0.49, green: 1.0, blue: 0.40),
      Color(red: 0.32, green: 0.15, blue: 1.0),
    ], amplitude: Float = 1.0, blend: Float = 0.5
  ) {
    self.colorStops =
      Array(colorStops.prefix(3))
      + Array(repeating: Color.white, count: max(0, 3 - colorStops.count))
    self.amplitude = amplitude
    self.blend = blend
  }

  public func makeUIView(context: Context) -> MTKView {
    let view = MTKView(frame: .zero, device: MTLCreateSystemDefaultDevice())
    view.isPaused = false
    view.enableSetNeedsDisplay = false
    view.preferredFramesPerSecond = 60
    view.isOpaque = false
    view.clearColor = MTLClearColorMake(0, 0, 0, 0)
    view.framebufferOnly = true
    view.colorPixelFormat = .bgra8Unorm

    context.coordinator.configure(for: view)
    context.coordinator.update(with: self)
    return view
  }

  public func updateUIView(_ uiView: MTKView, context: Context) {
    context.coordinator.update(with: self)
  }

  public func makeCoordinator() -> Renderer { Renderer() }

  public final class Renderer: NSObject, MTKViewDelegate {
    struct UniformsAurora {
      var time: Float
      var amplitude: Float
      var resolution: simd_float2
      var blend: Float
      // Match Metal layout: float3[3] with 16-byte stride → add pad floats
      var colorStop0: simd_float3
      var pad0: Float
      var colorStop1: simd_float3
      var pad1: Float
      var colorStop2: simd_float3
      var pad2: Float
    }

    private weak var view: MTKView?
    private var device: MTLDevice?
    private var commandQueue: MTLCommandQueue?
    private var pipelineState: MTLRenderPipelineState?
    private var buffer: MTLBuffer?
    private var start: CFTimeInterval = CACurrentMediaTime()
    private var uniforms = UniformsAurora(
      time: 0,
      amplitude: 1,
      resolution: .zero,
      blend: 0.5,
      colorStop0: simd_float3(1, 1, 1), pad0: 0,
      colorStop1: simd_float3(1, 1, 1), pad1: 0,
      colorStop2: simd_float3(1, 1, 1), pad2: 0
    )

    func configure(for view: MTKView) {
      self.view = view
      guard let device = view.device else { return }
      self.device = device
      commandQueue = device.makeCommandQueue()

      let descriptor = MTLRenderPipelineDescriptor()
      let library = device.makeDefaultLibrary()
      descriptor.vertexFunction = library?.makeFunction(name: "auroraVertex")
      descriptor.fragmentFunction = library?.makeFunction(name: "auroraFragment")
      descriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat
      let att = descriptor.colorAttachments[0]!
      att.isBlendingEnabled = true
      att.rgbBlendOperation = .add
      att.alphaBlendOperation = .add
      att.sourceRGBBlendFactor = .one
      att.sourceAlphaBlendFactor = .one
      att.destinationRGBBlendFactor = .oneMinusSourceAlpha
      att.destinationAlphaBlendFactor = .oneMinusSourceAlpha

      pipelineState = try? device.makeRenderPipelineState(descriptor: descriptor)
      buffer = device.makeBuffer(
        length: MemoryLayout<UniformsAurora>.stride, options: .storageModeShared)
      view.delegate = self
    }

    func update(with config: AuroraEffect) {
      uniforms.amplitude = config.amplitude
      uniforms.blend = config.blend
      let stops = Array(config.colorStops.prefix(3))
      let c0 = stops.indices.contains(0) ? Self.colorToFloat3(stops[0]) : simd_float3(1, 1, 1)
      let c1 = stops.indices.contains(1) ? Self.colorToFloat3(stops[1]) : simd_float3(1, 1, 1)
      let c2 = stops.indices.contains(2) ? Self.colorToFloat3(stops[2]) : simd_float3(1, 1, 1)
      uniforms.colorStop0 = c0
      uniforms.colorStop1 = c1
      uniforms.colorStop2 = c2
    }

    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
      uniforms.resolution = simd_float2(Float(size.width), Float(size.height))
    }

    public func draw(in view: MTKView) {
      guard let drawable = view.currentDrawable,
        let descriptor = view.currentRenderPassDescriptor,
        let pipelineState = pipelineState,
        let commandQueue = commandQueue,
        let buffer = buffer
      else { return }
      uniforms.time = Float(CACurrentMediaTime() - start)
      let size = view.drawableSize
      uniforms.resolution = simd_float2(Float(size.width), Float(size.height))
      memcpy(buffer.contents(), &uniforms, MemoryLayout<UniformsAurora>.stride)

      let commandBuffer = commandQueue.makeCommandBuffer()
      let encoder = commandBuffer?.makeRenderCommandEncoder(descriptor: descriptor)
      encoder?.setRenderPipelineState(pipelineState)
      encoder?.setFragmentBuffer(buffer, offset: 0, index: 0)
      encoder?.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
      encoder?.endEncoding()
      commandBuffer?.present(drawable)
      commandBuffer?.commit()
    }

    private static func colorToFloat3(_ color: Color) -> simd_float3 {
      #if canImport(UIKit)
        let ui = UIColor(color)
        var r: CGFloat = 1
        var g: CGFloat = 1
        var b: CGFloat = 1
        var a: CGFloat = 1
        ui.getRed(&r, green: &g, blue: &b, alpha: &a)
        return simd_float3(Float(r), Float(g), Float(b))
      #else
        return simd_float3(1, 1, 1)
      #endif
    }
  }
}
