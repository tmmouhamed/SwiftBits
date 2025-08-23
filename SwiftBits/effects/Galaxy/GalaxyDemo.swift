import SwiftUI

struct GalaxyDemo: View {
    @State private var starSpeed: Float = 0.5
    @State private var density: Float = 1.0
    @State private var hueShift: Float = 140.0
    @State private var speed: Float = 1.0
    @State private var glowIntensity: Float = 0.3
    @State private var saturation: Float = 0.8
    @State private var twinkleIntensity: Float = 0.3
    @State private var rotationSpeed: Float = 0.1
    @State private var repulsionStrength: Float = 2.0
    @State private var autoCenterRepulsion: Float = 0.0
    @State private var mouseRepulsion = true
    @State private var transparent = true
    @State private var selectedPreset = 0
    
    let presets: [(name: String, hue: Float, saturation: Float, glow: Float)] = [
        ("Nebula", 140.0, 0.8, 0.3),
        ("Aurora", 180.0, 1.0, 0.5),
        ("Cosmic", 280.0, 0.6, 0.4),
        ("Solar", 60.0, 0.9, 0.6),
        ("Deep Space", 220.0, 0.4, 0.2)
    ]
    
    var body: some View {
        FullScreenDemo(
            title: "Galaxy Effect",
            effect: ZStack {
                if !transparent {
                    Color.black.ignoresSafeArea()
                }
                
                GalaxyEffect(
                    starSpeed: starSpeed,
                    density: density,
                    hueShift: presets[selectedPreset].hue,
                    speed: speed,
                    glowIntensity: presets[selectedPreset].glow,
                    saturation: presets[selectedPreset].saturation,
                    mouseRepulsion: mouseRepulsion,
                    repulsionStrength: repulsionStrength,
                    twinkleIntensity: twinkleIntensity,
                    rotationSpeed: rotationSpeed,
                    autoCenterRepulsion: autoCenterRepulsion,
                    transparent: transparent
                )
            }
        ) {
            Group {
                ControlPicker(
                    label: "Preset",
                    selection: $selectedPreset,
                    options: presets.enumerated().map { index, preset in
                        (label: preset.name, value: index)
                    }
                )
                
                ControlSlider(
                    label: "Star Speed",
                    value: $starSpeed,
                    in: 0.1...2.0,
                    color: .blue,
                    format: "%.2f"
                )
                
                ControlSlider(
                    label: "Star Density",
                    value: $density,
                    in: 0.5...3.0,
                    color: .green,
                    format: "%.1f"
                )
                
                ControlSlider(
                    label: "Animation Speed",
                    value: $speed,
                    in: 0.1...3.0,
                    color: .orange,
                    format: "%.1f"
                )
                
                ControlSlider(
                    label: "Twinkle Intensity",
                    value: $twinkleIntensity,
                    in: 0.0...1.0,
                    color: .purple,
                    format: "%.2f"
                )
                
                ControlSlider(
                    label: "Rotation Speed",
                    value: $rotationSpeed,
                    in: 0.0...0.5,
                    color: .red,
                    format: "%.2f"
                )
                
                if mouseRepulsion {
                    ControlSlider(
                        label: "Repulsion Strength",
                        value: $repulsionStrength,
                        in: 0.5...5.0,
                        color: .cyan,
                        format: "%.1f"
                    )
                }
                
                ControlSlider(
                    label: "Center Repulsion",
                    value: $autoCenterRepulsion,
                    in: 0.0...3.0,
                    color: .yellow,
                    format: "%.1f"
                )
                
                ControlToggle(
                    label: "Mouse Repulsion",
                    isOn: $mouseRepulsion,
                    description: "Enable mouse interaction with stars"
                )
                
                ControlToggle(
                    label: "Transparent Background",
                    isOn: $transparent,
                    description: "Drag on the galaxy to interact with stars"
                )
            }
        }
    }
}