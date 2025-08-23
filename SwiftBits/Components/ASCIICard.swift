import SwiftUI
import Combine

struct ASCIICard: View {
    let title: String
    let description: String
    let icon: String
    let index: Int
    @State private var isHovered = false
    @State private var showAnimation = false
    
    // ASCII patterns for decoration
    let topBorder = "┌─────────────────────┐"
    let bottomBorder = "└─────────────────────┘"
    let sideBorder = "│"
    
    // Random ASCII decorations
    let decorations = ["◆", "◇", "○", "●", "▪", "▫", "▴", "▾", "◂", "▸"]
    
    var body: some View {
        VStack(spacing: 0) {
            // Top border with index
            HStack(spacing: 0) {
                Text("[")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.gray)
                Text(String(format: "%02d", index))
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.blue)
                Text("]")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.gray)
                
                Text(" ─────────────── ")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.gray.opacity(0.5))
                
                // Status indicator
                Circle()
                    .fill(isHovered ? Color.green : Color.orange)
                    .frame(width: 6, height: 6)
                    .overlay(
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
            }
            .padding(.horizontal, 12)
            .padding(.top, 12)
            
            // Main content area
            VStack(spacing: 8) {
                // Icon with ASCII frame
                ZStack {
                    // ASCII frame animation
                    if showAnimation {
                        ForEach(0..<4, id: \.self) { i in
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.blue.opacity(0.3 - Double(i) * 0.075), lineWidth: 1)
                                .frame(width: 40 + CGFloat(i * 8), height: 40 + CGFloat(i * 8))
                                .scaleEffect(isHovered ? 1.1 : 1.0)
                                .animation(
                                    .easeInOut(duration: 1.5)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(i) * 0.1),
                                    value: showAnimation
                                )
                        }
                    }
                    
                    // Icon
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .thin, design: .default))
                        .foregroundColor(.blue)
                        .frame(width: 40, height: 40)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
                                )
                        )
                }
                .frame(height: 60)
                
                // Title with ASCII style
                HStack(spacing: 4) {
                    Text(">")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.blue.opacity(0.7))
                    Text(title.uppercased())
                        .font(.system(.caption, design: .monospaced))
                        .fontWeight(.medium)
                        .foregroundColor(.black)
                    Text("_")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.blue)
                        .opacity(isHovered ? 1 : 0)
                        .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: isHovered)
                }
                
                // Description with typewriter effect
                Text(description)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.horizontal, 8)
                
                // Status bar
                HStack(spacing: 4) {
                    ForEach(0..<3, id: \.self) { i in
                        Rectangle()
                            .fill(isHovered ? Color.green : Color.gray)
                            .frame(width: 20, height: 2)
                            .opacity(isHovered ? 1.0 : 0.3)
                            .animation(.easeInOut(duration: 0.3).delay(Double(i) * 0.1), value: isHovered)
                    }
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            
            // Bottom border with decorations
            HStack(spacing: 2) {
                Text("└")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.gray.opacity(0.5))
                
                ForEach(0..<15, id: \.self) { _ in
                    Text("─")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.gray.opacity(0.5))
                }
                
                Text("┘")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.gray.opacity(0.5))
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .background(
            ZStack {
                // Base background
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white)
                
                // Grid pattern overlay
                GeometryReader { geometry in
                    Path { path in
                        let spacing: CGFloat = 10
                        let width = geometry.size.width
                        let height = geometry.size.height
                        
                        // Vertical lines
                        for x in stride(from: 0, through: width, by: spacing) {
                            path.move(to: CGPoint(x: x, y: 0))
                            path.addLine(to: CGPoint(x: x, y: height))
                        }
                        
                        // Horizontal lines
                        for y in stride(from: 0, through: height, by: spacing) {
                            path.move(to: CGPoint(x: 0, y: y))
                            path.addLine(to: CGPoint(x: width, y: y))
                        }
                    }
                    .stroke(Color.gray.opacity(0.03), lineWidth: 0.5)
                }
                
                // Hover glow effect
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.blue.opacity(isHovered ? 0.3 : 0),
                                Color.green.opacity(isHovered ? 0.2 : 0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
        )
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .shadow(
            color: isHovered ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1),
            radius: isHovered ? 8 : 4,
            x: 0,
            y: isHovered ? 4 : 2
        )
        .drawingGroup()
        .disabled(true)
        
    }
}

struct ASCIIHeader: View {
    @State private var currentTime = Date()
    @State private var loadingDots = ""
    
    let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
    let dotTimer = Timer.publish(every: 0.3, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 8) {
            // ASCII Art Logo
            VStack(spacing: 2) {
                Text("╔═══════════════════════════════════════╗")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.gray)
                
                HStack(spacing: 0) {
                    Text("║ ")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.gray)
                    Text("SWIFTBITS")
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(.blue)
                    Text(" // ")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.gray)
                    Text("VISUAL.ENGINE")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.gray)
                    Text(" ║")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.gray)
                }
                
                Text("╚═══════════════════════════════════════╝")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.gray)
            }
            
            // System Status
            HStack(spacing: 16) {
                // Version
                HStack(spacing: 4) {
                    Text("VER:")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.gray)
                    Text("2.0.1")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.green)
                }
                
                Text("•")
                    .foregroundColor(.gray.opacity(0.5))
                
                // Status
                HStack(spacing: 4) {
                    Text("STATUS:")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.gray)
                    Text("READY")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.green)
                    Text(loadingDots)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.green)
                }
                
                Text("•")
                    .foregroundColor(.gray.opacity(0.5))
                
                // Time
                HStack(spacing: 4) {
                    Text("TIME:")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.gray)
                    Text(currentTime, formatter: timeFormatter)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.blue)
                }
            }
            
            // Command line
            HStack(spacing: 4) {
                Text("$")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.blue)
                Text("SELECT * FROM effects WHERE type='visual'")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.gray)
                Text("_")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.blue)
                    .opacity(0.7)
                    .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: true)
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .onReceive(timer) { _ in
            currentTime = Date()
        }
        .onReceive(dotTimer) { _ in
            if loadingDots.count >= 3 {
                loadingDots = ""
            } else {
                loadingDots += "."
            }
        }
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }
}
