import SwiftUI

struct ParticlesDemo: View {
    @State private var particleCount: Float = 200
    @State private var particleSpread: Float = 10
    @State private var speed: Float = 0.1
    @State private var moveParticlesOnHover = false
    @State private var particleHoverFactor: Float = 1.0
    @State private var alphaParticles = false
    @State private var particleBaseSize: Float = 100
    @State private var sizeRandomness: Float = 1.0
    @State private var cameraDistance: Float = 20
    @State private var disableRotation = false
    @State private var selectedColorPreset = "rainbow"
    
    let colorPresets: [String: [Color]] = [
        "rainbow": [.red, .orange, .yellow, .green, .blue, .purple],
        "ocean": [.blue, .cyan, .mint, .teal],
        "sunset": [.red, .orange, .pink, .purple],
        "monochrome": [.white],
        "galaxy": [.purple, .pink, .indigo, .cyan],
        "forest": [.green, .mint, .brown]
    ]
    
    var body: some View {
        FullScreenDemo(
            title: "Particles Effect",
            effect: ParticlesEffect(
                particleCount: Int(particleCount),
                particleSpread: particleSpread,
                speed: speed,
                particleColors: colorPresets[selectedColorPreset] ?? [.white],
                moveParticlesOnHover: moveParticlesOnHover,
                particleHoverFactor: particleHoverFactor,
                alphaParticles: alphaParticles,
                particleBaseSize: particleBaseSize,
                sizeRandomness: sizeRandomness,
                cameraDistance: cameraDistance,
                disableRotation: disableRotation
            )
        ) {
            Group {
                ControlPicker(
                    label: "Color Preset",
                    selection: $selectedColorPreset,
                    options: Array(colorPresets.keys.sorted()).map { key in
                        (label: key.capitalized, value: key)
                    }
                )
                
                ControlSlider(
                    label: "Particle Count",
                    value: $particleCount,
                    in: 50...500,
                    step: 10,
                    color: .blue,
                    format: "%.0f"
                )
                
                ControlSlider(
                    label: "Spread",
                    value: $particleSpread,
                    in: 5...20,
                    color: .green,
                    format: "%.1f"
                )
                
                ControlSlider(
                    label: "Animation Speed",
                    value: $speed,
                    in: 0.01...0.5,
                    color: .orange,
                    format: "%.2f"
                )
                
                ControlSlider(
                    label: "Particle Size",
                    value: $particleBaseSize,
                    in: 50...200,
                    color: .purple,
                    format: "%.0f"
                )
                
                ControlSlider(
                    label: "Size Variation",
                    value: $sizeRandomness,
                    in: 0...2,
                    color: .pink,
                    format: "%.1f"
                )
                
                ControlSlider(
                    label: "Camera Distance",
                    value: $cameraDistance,
                    in: 10...40,
                    color: .cyan,
                    format: "%.1f"
                )
                
                if moveParticlesOnHover {
                    ControlSlider(
                        label: "Hover Strength",
                        value: $particleHoverFactor,
                        in: 0.5...3,
                        color: .yellow,
                        format: "%.1f"
                    )
                }
                
                ControlToggle(
                    label: "Alpha Blending",
                    isOn: $alphaParticles,
                    description: "Enable transparency blending"
                )
                
                ControlToggle(
                    label: "Mouse Interaction",
                    isOn: $moveParticlesOnHover,
                    description: moveParticlesOnHover ? "Drag on the effect to interact" : nil
                )
                
                ControlToggle(
                    label: "Disable Rotation",
                    isOn: $disableRotation,
                    description: "Stop automatic rotation"
                )
            }
        }
    }
}