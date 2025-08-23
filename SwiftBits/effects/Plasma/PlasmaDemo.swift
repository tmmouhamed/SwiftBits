import SwiftUI

struct PlasmaDemo: View {
    @State private var color = Color.white
    @State private var speed: Float = 1.0
    @State private var direction = "forward"
    @State private var scale: Float = 1.0
    @State private var opacity: Float = 1.0
    @State private var mouseInteractive = true
    @State private var selectedColorPreset = "white"
    
    let colorPresets = [
        "white": Color.white,
        "blue": Color.blue,
        "purple": Color.purple,
        "green": Color.green,
        "orange": Color.orange,
        "pink": Color.pink
    ]
    
    let directionOptions = ["forward", "reverse", "pingpong"]
    
    var body: some View {
        FullScreenDemo(
            title: "Plasma Effect",
            effect: PlasmaEffect(
                color: color,
                speed: speed,
                direction: direction,
                scale: scale,
                opacity: opacity,
                mouseInteractive: mouseInteractive
            )
        ) {
            Group {
                ControlPicker(
                    label: "Color",
                    selection: $selectedColorPreset,
                    options: Array(colorPresets.keys.sorted()).map { key in
                        (label: key.capitalized, value: key)
                    }
                )
                .onChange(of: selectedColorPreset) { newValue in
                    color = colorPresets[newValue] ?? .white
                }
                
                ControlPicker(
                    label: "Direction",
                    selection: $direction,
                    options: directionOptions.map { option in
                        (label: option.capitalized, value: option)
                    }
                )
                
                ControlSlider(
                    label: "Speed",
                    value: $speed,
                    in: 0.1...3.0,
                    color: .blue,
                    format: "%.1f"
                )
                
                ControlSlider(
                    label: "Scale",
                    value: $scale,
                    in: 0.5...3.0,
                    color: .purple,
                    format: "%.1f"
                )
                
                ControlSlider(
                    label: "Opacity",
                    value: $opacity,
                    in: 0.0...1.0,
                    color: .orange,
                    format: "%.2f"
                )
                
                ControlToggle(
                    label: "Mouse Interactive",
                    isOn: $mouseInteractive,
                    description: mouseInteractive ? "Drag on the effect to interact" : nil
                )
            }
        }
    }
}