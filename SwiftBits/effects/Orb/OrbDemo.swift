import SwiftUI

struct OrbDemo: View {
    @State private var hue: Float = 0
    @State private var hoverIntensity: Float = 0.2
    @State private var rotateOnHover: Bool = true
    @State private var forceHoverState: Bool = false
    
    var body: some View {
        FullScreenDemo(
            title: "Orb Effect",
            effect: OrbEffect(
                hue: hue,
                hoverIntensity: hoverIntensity,
                rotateOnHover: rotateOnHover,
                forceHoverState: forceHoverState
            )
        ) {
            Group {
                ControlSlider(
                    label: "Hue",
                    value: $hue,
                    in: -180...180,
                    color: .purple,
                    format: "%.0f°"
                )
                
                ControlSlider(
                    label: "Hover Intensity",
                    value: $hoverIntensity,
                    in: 0...1,
                    color: .orange,
                    format: "%.2f"
                )
                
                ControlToggle(
                    label: "Rotate on Hover",
                    isOn: $rotateOnHover
                )
                
                ControlToggle(
                    label: "Force Hover State",
                    isOn: $forceHoverState,
                    description: "Keep orb in hover state"
                )
            }
        }
    }
}