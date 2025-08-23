/*
Purpose: SwiftUI UIViewRepresentable for an "Orb" glow effect using Metal, ported from a WebGL/GLSL implementation; supports hue shift, hover-driven distortion, and rotation-on-hover.
Inputs:  Public properties `hue` (degrees), `hoverIntensity` [0..1], `rotateOnHover` (Bool), `forceHoverState` (Bool). Requires `MetalKit` and shader functions `orbVertex`/`orbFragment` in `Orb.metal`.
Outputs: Transparent layer rendering the orb with premultiplied alpha; no side effects beyond rendering. Exposes only visual output.
*/
import MetalKit
import SwiftUI
import simd

public struct OrbEffect: UIViewRepresentable {
  public var hue: Float
  public var hoverIntensity: Float
  public var rotateOnHover: Bool
  public var forceHoverState: Bool

  public init(
    hue: Float = 0,
    hoverIntensity: Float = 0.2,
    rotateOnHover: Bool = true,
    forceHoverState: Bool = false
  ) {
    self.hue = hue
    self.hoverIntensity = hoverIntensity
    self.rotateOnHover = rotateOnHover
    self.forceHoverState = forceHoverState
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
    // MARK: - Uniforms
    struct UniformsOrb {
      var time: Float
      var resolution: simd_float2
      var hue: Float
      var hover: Float
      var rot: Float
      var hoverIntensity: Float
      var pad0: Float  // align to 16-byte stride (total 32 bytes)
    }

    // MARK: - Metal
    private weak var view: MTKView?
    private var device: MTLDevice?
    private var commandQueue: MTLCommandQueue?
    private var pipelineState: MTLRenderPipelineState?
    private var buffer: MTLBuffer?

    // MARK: - State
    private var startTime: CFTimeInterval = CACurrentMediaTime()
    private var lastTime: CFTimeInterval = 0
    private var targetHover: Float = 0
    private var uniforms = UniformsOrb(
      time: 0,
      resolution: .zero,
      hue: 0,
      hover: 0,
      rot: 0,
      hoverIntensity: 0.2,
      pad0: 0
    )
    private var config: OrbEffect?
    private let rotationSpeed: Float = 0.3

    // MARK: - Setup
    func configure(for view: MTKView) {
      self.view = view
      guard let device = view.device else { return }
      self.device = device
      commandQueue = device.makeCommandQueue()

      let descriptor = MTLRenderPipelineDescriptor()
      let library = device.makeDefaultLibrary()
      descriptor.vertexFunction = library?.makeFunction(name: "orbVertex")
      descriptor.fragmentFunction = library?.makeFunction(name: "orbFragment")
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
        length: MemoryLayout<UniformsOrb>.stride, options: .storageModeShared)

      // Gestures to simulate hover
      let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
      pan.maximumNumberOfTouches = 1
      view.addGestureRecognizer(pan)
      let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
      view.addGestureRecognizer(tap)

      view.delegate = self
    }

    func update(with config: OrbEffect) {
      self.config = config
      uniforms.hue = config.hue
      uniforms.hoverIntensity = config.hoverIntensity
      // hover / rot updated in draw loop
    }

    // MARK: - Gestures
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
      guard let view = view else { return }
      let location = gesture.location(in: view)
      updateHoverTarget(with: location)
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
      guard let view = view else { return }
      let location = gesture.location(in: view)
      updateHoverTarget(with: location)
      if gesture.state == .ended || gesture.state == .cancelled || gesture.state == .failed {
        targetHover = 0
      }
    }

    private func updateHoverTarget(with location: CGPoint) {
      guard let view = view else { return }
      let width = view.bounds.width
      let height = view.bounds.height
      let size = min(width, height)
      let centerX = width * 0.5
      let centerY = height * 0.5
      let uvX = Float(((location.x - centerX) / size) * 2.0)
      let uvY = Float(((location.y - centerY) / size) * 2.0)
      let r = sqrt(uvX * uvX + uvY * uvY)
      targetHover = (r < 0.8) ? 1.0 : 0.0
    }

    // MARK: - MTKViewDelegate
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

      // Time
      let now = CACurrentMediaTime()
      if lastTime == 0 { lastTime = now }
      let dt = Float(now - lastTime)
      lastTime = now
      uniforms.time = Float(now - startTime)

      // Resolution
      let size = view.drawableSize
      uniforms.resolution = simd_float2(Float(size.width), Float(size.height))

      // Hover smoothing and rotation
      let forceHover = config?.forceHoverState ?? false
      let effectiveTarget = forceHover ? 1.0 : targetHover
      uniforms.hover += (effectiveTarget - uniforms.hover) * 0.1
      if (config?.rotateOnHover ?? true) && uniforms.hover > 0.5 {
        uniforms.rot += dt * rotationSpeed
      }

      // Hue / intensity are refreshed by update(with:)

      // Write uniforms
      memcpy(buffer.contents(), &uniforms, MemoryLayout<UniformsOrb>.stride)

      // Encode
      let commandBuffer = commandQueue.makeCommandBuffer()
      let encoder = commandBuffer?.makeRenderCommandEncoder(descriptor: descriptor)
      encoder?.setRenderPipelineState(pipelineState)
      encoder?.setFragmentBuffer(buffer, offset: 0, index: 0)
      encoder?.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
      encoder?.endEncoding()

      commandBuffer?.present(drawable)
      commandBuffer?.commit()
    }
  }
}
