/*
Purpose: Demo view for the Metal-based `SilkEffect`, exposing sliders/toggles to adjust speed, scale, color, noise intensity, and rotation.
Inputs:  SwiftUI state from user controls; depends on `SilkEffect`.
Outputs: Visual demonstration only; no external side effects.
*/
import SwiftUI

public struct SilkDemo: View {
  @State private var speed: Float = 5
  @State private var scale: Float = 1
  @State private var hue: Float = 270  // for color selection convenience
  @State private var saturation: Float = 0.15
  @State private var brightness: Float = 0.55
  @State private var noiseIntensity: Float = 1.5
  @State private var rotation: Float = 0

  public init() {}

  private var currentColor: Color {
    Color(hue: Double(hue) / 360.0, saturation: Double(saturation), brightness: Double(brightness))
  }

  public var body: some View {
    FullScreenDemo(
        title: "Silk Effect",
        effect: SilkEffect(
            speed: speed,
            scale: scale,
            color: currentColor,
            noiseIntensity: noiseIntensity,
            rotation: rotation
        )
    ) {
        Group {
            ControlSlider(
                label: "Speed",
                value: $speed,
                in: 0...10,
                color: .blue,
                format: "%.1f"
            )
            
            ControlSlider(
                label: "Scale",
                value: $scale,
                in: 0.5...3,
                color: .green,
                format: "%.1f"
            )
            
            ControlSlider(
                label: "Noise Intensity",
                value: $noiseIntensity,
                in: 0...3,
                color: .orange,
                format: "%.1f"
            )
            
            ControlSlider(
                label: "Rotation",
                value: $rotation,
                in: -3.14...3.14,
                color: .purple,
                format: "%.2f"
            )
            
            ControlSlider(
                label: "Hue",
                value: $hue,
                in: 0...360,
                color: .red,
                format: "%.0f°"
            )
            
            ControlSlider(
                label: "Saturation",
                value: $saturation,
                in: 0...1,
                color: .pink,
                format: "%.2f"
            )
            
            ControlSlider(
                label: "Brightness",
                value: $brightness,
                in: 0...1,
                color: .yellow,
                format: "%.2f"
            )
        }
    }
  }
}

struct SilkDemo_Previews: PreviewProvider {
  static var previews: some View {
    SilkDemo().preferredColorScheme(.dark)
  }
}
