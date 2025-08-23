import SwiftUI

struct DitherDemo: View {
    @State private var waveSpeed: Float = 0.05
    @State private var waveFrequency: Float = 3.0
    @State private var waveAmplitude: Float = 0.3
    @State private var colorNum: Float = 4.0
    @State private var pixelSize: Float = 2.0
    @State private var enableMouseInteraction = true
    @State private var selectedColorPreset = 0
    
    let colorPresets: [(name: String, color: SIMD3<Float>)] = [
        ("Monochrome", SIMD3<Float>(0.5, 0.5, 0.5)),
        ("Ocean", SIMD3<Float>(0.2, 0.5, 0.8)),
        ("Sunset", SIMD3<Float>(0.9, 0.4, 0.3)),
        ("Forest", SIMD3<Float>(0.3, 0.7, 0.4)),
        ("Purple", SIMD3<Float>(0.6, 0.3, 0.8))
    ]
    
    var body: some View {
        FullScreenDemo(
            title: "Dithered Waves",
            effect: DitherEffect(
                waveSpeed: waveSpeed,
                waveFrequency: waveFrequency,
                waveAmplitude: waveAmplitude,
                waveColor: colorPresets[selectedColorPreset].color,
                colorNum: colorNum,
                pixelSize: pixelSize,
                enableMouseInteraction: enableMouseInteraction,
                mouseRadius: 0.3
            )
        ) {
            Group {
                ControlPicker(
                    label: "Color Preset",
                    selection: $selectedColorPreset,
                    options: colorPresets.enumerated().map { index, preset in
                        (label: preset.name, value: index)
                    }
                )
                
                ControlSlider(
                    label: "Wave Speed",
                    value: $waveSpeed,
                    in: 0.01...0.2,
                    color: .blue,
                    format: "%.2f"
                )
                
                ControlSlider(
                    label: "Wave Frequency",
                    value: $waveFrequency,
                    in: 1...10,
                    color: .green,
                    format: "%.1f"
                )
                
                ControlSlider(
                    label: "Wave Amplitude",
                    value: $waveAmplitude,
                    in: 0.1...0.8,
                    color: .orange,
                    format: "%.2f"
                )
                
                ControlSlider(
                    label: "Color Levels",
                    value: $colorNum,
                    in: 2...16,
                    step: 1,
                    color: .purple,
                    format: "%.0f"
                )
                
                ControlSlider(
                    label: "Pixel Size",
                    value: $pixelSize,
                    in: 1...8,
                    step: 1,
                    color: .red,
                    format: "%.0f"
                )
                
                ControlToggle(
                    label: "Mouse Interaction",
                    isOn: $enableMouseInteraction,
                    description: enableMouseInteraction ? "Drag on the effect to interact" : nil
                )
            }
        }
    }
}