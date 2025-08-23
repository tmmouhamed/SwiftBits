import SwiftUI

struct BeamsDemo: View {
    @State private var beamWidth: Float = 2.0
    @State private var beamHeight: Float = 15.0
    @State private var beamNumber: Float = 12.0
    @State private var speed: Float = 2.0
    @State private var noiseIntensity: Float = 1.75
    @State private var scale: Float = 0.2
    @State private var rotation: Float = 0.0
    @State private var selectedColorPreset = 0
    
    let colorPresets: [(name: String, color: Color)] = [
        ("White", .white),
        ("Cyan", Color(red: 0.0, green: 0.8, blue: 1.0)),
        ("Purple", Color(red: 0.8, green: 0.3, blue: 1.0)),
        ("Gold", Color(red: 1.0, green: 0.8, blue: 0.3)),
        ("Green", Color(red: 0.3, green: 1.0, blue: 0.5))
    ]
    
    var body: some View {
        FullScreenDemo(
            title: "Light Beams",
            effect: BeamsEffect(
                beamWidth: beamWidth,
                beamHeight: beamHeight,
                beamNumber: beamNumber,
                lightColor: colorPresets[selectedColorPreset].color,
                speed: speed,
                noiseIntensity: noiseIntensity,
                scale: scale,
                rotation: rotation
            )
        ) {
            Group {
                ControlPicker(
                    label: "Light Color",
                    selection: $selectedColorPreset,
                    options: colorPresets.enumerated().map { index, preset in
                        (label: preset.name, value: index)
                    }
                )
                
                ControlSlider(
                    label: "Beam Count",
                    value: $beamNumber,
                    in: 4...20,
                    step: 1,
                    color: .blue,
                    format: "%.0f"
                )
                
                ControlSlider(
                    label: "Beam Width",
                    value: $beamWidth,
                    in: 0.5...5.0,
                    color: .green,
                    format: "%.1f"
                )
                
                ControlSlider(
                    label: "Beam Height",
                    value: $beamHeight,
                    in: 5...25,
                    color: .orange,
                    format: "%.1f"
                )
                
                ControlSlider(
                    label: "Wave Speed",
                    value: $speed,
                    in: 0.5...5.0,
                    color: .purple,
                    format: "%.1f"
                )
                
                ControlSlider(
                    label: "Noise Intensity",
                    value: $noiseIntensity,
                    in: 0.5...3.0,
                    color: .red,
                    format: "%.2f"
                )
                
                ControlSlider(
                    label: "Noise Scale",
                    value: $scale,
                    in: 0.1...1.0,
                    color: .cyan,
                    format: "%.2f"
                )
                
                ControlSlider(
                    label: "Rotation",
                    value: $rotation,
                    in: -45...45,
                    color: .yellow,
                    format: "%.0f°"
                )
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Light Beams Info")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text("Adjust parameters to see the beams react in real-time")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.5))
                        .italic()
                }
            }
        }
    }
}