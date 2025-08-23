/*
Purpose: SwiftUI UIViewRepresentable for a "Silk" animated procedural background, ported from a WebGL/Three shader to Metal; supports color, speed, scale, rotation, noise intensity.
Inputs:  Public properties `speed`, `scale`, `color`, `noiseIntensity`, `rotation`. Requires `MetalKit` and shader functions `silkVertex`/`silkFragment` in `Silk.metal`.
Outputs: Opaque (alpha=1) fragment rendering; no side effects beyond rendering.
*/
import MetalKit
import SwiftUI
import simd

public struct SilkEffect: UIViewRepresentable {
  public var speed: Float
  public var scale: Float
  public var color: Color
  public var noiseIntensity: Float
  public var rotation: Float

  public init(
    speed: Float = 5,
    scale: Float = 1,
    color: Color = Color(red: 0.482, green: 0.455, blue: 0.506),
    noiseIntensity: Float = 1.5,
    rotation: Float = 0
  ) {
    self.speed = speed
    self.scale = scale
    self.color = color
    self.noiseIntensity = noiseIntensity
    self.rotation = rotation
  }

  public func makeUIView(context: Context) -> MTKView {
    let view = MTKView(frame: .zero, device: MTLCreateSystemDefaultDevice())
    view.isPaused = false
    view.enableSetNeedsDisplay = false
    view.preferredFramesPerSecond = 60
    view.isOpaque = true
    view.clearColor = MTLClearColorMake(0, 0, 0, 1)
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
    struct UniformsSilk {
      var time: Float
      var resolution: simd_float2
      var color: simd_float3
      var speed: Float
      var scale: Float
      var rotation: Float
      var noiseIntensity: Float
    }

    private weak var view: MTKView?
    private var device: MTLDevice?
    private var commandQueue: MTLCommandQueue?
    private var pipelineState: MTLRenderPipelineState?
    private var buffer: MTLBuffer?

    private var startTime: CFTimeInterval = CACurrentMediaTime()
    private var uniforms = UniformsSilk(
      time: 0,
      resolution: .zero,
      color: simd_float3(0.482, 0.455, 0.506),
      speed: 5,
      scale: 1,
      rotation: 0,
      noiseIntensity: 1.5
    )

    func configure(for view: MTKView) {
      self.view = view
      guard let device = view.device else { return }
      self.device = device
      commandQueue = device.makeCommandQueue()

      let descriptor = MTLRenderPipelineDescriptor()
      let library = device.makeDefaultLibrary()
      descriptor.vertexFunction = library?.makeFunction(name: "silkVertex")
      descriptor.fragmentFunction = library?.makeFunction(name: "silkFragment")
      descriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat
      // This effect outputs opaque pixels; blending is not required.
      descriptor.colorAttachments[0]?.isBlendingEnabled = false

      pipelineState = try? device.makeRenderPipelineState(descriptor: descriptor)
      buffer = device.makeBuffer(
        length: MemoryLayout<UniformsSilk>.stride, options: .storageModeShared)

      view.delegate = self
    }

    func update(with config: SilkEffect) {
      uniforms.speed = config.speed
      uniforms.scale = config.scale
      uniforms.rotation = config.rotation
      uniforms.noiseIntensity = config.noiseIntensity
      uniforms.color = Self.colorToFloat3(config.color)
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

      // Time & resolution
      uniforms.time = Float(CACurrentMediaTime() - startTime)
      let size = view.drawableSize
      uniforms.resolution = simd_float2(Float(size.width), Float(size.height))

      memcpy(buffer.contents(), &uniforms, MemoryLayout<UniformsSilk>.stride)

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
