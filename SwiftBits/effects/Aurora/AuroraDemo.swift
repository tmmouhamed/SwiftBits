import SwiftUI

struct AuroraDemo: View {
    @State private var amplitude: Float = 1.0
    @State private var blend: Float = 0.5
    @State private var colorStops: [Color] = [
        Color(red: 0.32, green: 0.15, blue: 1.0),
        Color(red: 0.49, green: 1.0, blue: 0.40),
        Color(red: 0.32, green: 0.15, blue: 1.0),
    ]
    
    var body: some View {
        FullScreenDemo(
            title: "Aurora Effect",
            effect: AuroraEffect(
                colorStops: colorStops,
                amplitude: amplitude,
                blend: blend
            )
        ) {
            Group {
                ControlSlider(
                    label: "Amplitude",
                    value: $amplitude,
                    in: 0.2...2.0,
                    color: .green,
                    format: "%.2f"
                )
                
                ControlSlider(
                    label: "Blend",
                    value: $blend,
                    in: 0.0...1.0,
                    color: .purple,
                    format: "%.2f"
                )
            }
        }
    }
}