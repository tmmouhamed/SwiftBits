import SwiftUI

struct PrismDemo: View {
    @State private var height: Float = 3.5
    @State private var baseWidth: Float = 5.5
    @State private var animationType = "rotate"
    @State private var glow: Float = 1.0
    @State private var noise: Float = 0.5
    @State private var scale: Float = 3.6
    @State private var hueShift: Float = 0.0
    @State private var colorFrequency: Float = 1.0
    @State private var bloom: Float = 1.0
    @State private var timeScale: Float = 0.5
    @State private var transparent = true
    
    let animationTypes = ["rotate", "hover", "3drotate"]
    
    var body: some View {
        FullScreenDemo(
            title: "Prism Effect",
            effect: ZStack {
                if !transparent {
                    Color.black.ignoresSafeArea()
                }
                
                PrismEffect(
                    height: height,
                    baseWidth: baseWidth,
                    animationType: animationType,
                    glow: glow,
                    noise: noise,
                    transparent: transparent,
                    scale: scale,
                    hueShift: hueShift,
                    colorFrequency: colorFrequency,
                    bloom: bloom,
                    timeScale: timeScale
                )
            }
        ) {
            Group {
                ControlPicker(
                    label: "Animation Type",
                    selection: $animationType,
                    options: [
                        (label: "Rotate", value: "rotate"),
                        (label: "Hover", value: "hover"),
                        (label: "3D Rotate", value: "3drotate")
                    ]
                )
                .onChange(of: animationType) { newValue in
                    if newValue == "hover" {
                        // Could add haptic feedback or other interactions here
                    }
                }
                
                ControlSlider(
                    label: "Height",
                    value: $height,
                    in: 1.0...6.0,
                    color: .blue,
                    format: "%.1f"
                )
                
                ControlSlider(
                    label: "Base Width",
                    value: $baseWidth,
                    in: 2.0...10.0,
                    color: .green,
                    format: "%.1f"
                )
                
                ControlSlider(
                    label: "Scale",
                    value: $scale,
                    in: 1.0...8.0,
                    color: .orange,
                    format: "%.1f"
                )
                
                ControlSlider(
                    label: "Glow Intensity",
                    value: $glow,
                    in: 0.0...3.0,
                    color: .purple,
                    format: "%.1f"
                )
                
                ControlSlider(
                    label: "Bloom",
                    value: $bloom,
                    in: 0.0...3.0,
                    color: .pink,
                    format: "%.1f"
                )
                
                ControlSlider(
                    label: "Color Frequency",
                    value: $colorFrequency,
                    in: 0.1...5.0,
                    color: .red,
                    format: "%.1f"
                )
                
                ControlSlider(
                    label: "Hue Shift",
                    value: $hueShift,
                    in: -3.14...3.14,
                    color: .cyan,
                    format: "%.1f"
                )
                
                ControlSlider(
                    label: "Noise",
                    value: $noise,
                    in: 0.0...1.0,
                    color: .gray,
                    format: "%.2f"
                )
                
                ControlSlider(
                    label: "Animation Speed",
                    value: $timeScale,
                    in: 0.0...2.0,
                    color: .yellow,
                    format: "%.1f"
                )
                
                ControlToggle(
                    label: "Transparent Background",
                    isOn: $transparent,
                    description: animationType == "hover" ? "Drag on the effect to interact" : nil
                )
            }
        }
    }
}