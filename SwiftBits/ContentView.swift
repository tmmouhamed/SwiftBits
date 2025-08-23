//
//  ContentView.swift
//  SwiftBits
//
//  Created by 赵翔宇 on 2025/8/22.
//

import SwiftUI

struct ContentView: View {
    enum Effect: String, CaseIterable, Identifiable {
        case aurora = "Aurora"
        case orb = "Orb"

        case silk = "Silk"
        
        case dither = "Dither"
        case beams = "Beams"
        case galaxy = "Galaxy"
        case prism = "Prism"
        case plasma = "Plasma"
        case particles = "Particles"
        
        var id: String { rawValue }
        
        var title: String {
            switch self {
            case .aurora: return "Aurora"
            case .orb: return "Orb"

            case .silk: return "Silk"
            
            case .dither: return "Dither"
            case .beams: return "Beams"
            case .galaxy: return "Galaxy"
            case .prism: return "Prism"
            case .plasma: return "Plasma"
            case .particles: return "Particles"
            }
        }
        
        var description: String {
            switch self {
            case .aurora: return "Northern lights simulation"
            case .orb: return "3D sphere rendering"

            case .silk: return "Silk fabric physics"
            case .dither: return "Wave dithering effect"
            case .beams: return "Light beam dynamics"
            case .galaxy: return "Particle galaxy system"
            case .prism: return "Prism light dispersion"
            case .plasma: return "Plasma wave generation"
            case .particles: return "3D particle engine"
            }
        }
        
        var icon: String {
            switch self {
            case .aurora: return "sparkles"
            case .orb: return "circle.hexagongrid"
            case .silk: return "waveform.path"
            case .dither: return "square.grid.4x3.fill"
            case .beams: return "light.beacon.max.fill"
            case .galaxy: return "star.circle.fill"
            case .prism: return "pyramid.fill"
            case .plasma: return "waveform"
            case .particles: return "sparkle"
            }
        }
    }
    
    @State private var searchText = ""
    @State private var showSystemInfo = false
    
    var filteredEffects: [Effect] {
        if searchText.isEmpty {
            return Effect.allCases
        } else {
            return Effect.allCases.filter {
                $0.title.lowercased().contains(searchText.lowercased()) ||
                    $0.description.lowercased().contains(searchText.lowercased())
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background with grid pattern
                GeometryReader { geometry in
                    // Base color
                    Color(red: 0.98, green: 0.98, blue: 0.97)
                        .ignoresSafeArea()
                    
                    // Grid overlay
                    Path { path in
                        let spacing: CGFloat = 20
                        let width = geometry.size.width
                        let height = geometry.size.height
                        
                        for x in stride(from: 0, through: width, by: spacing) {
                            path.move(to: CGPoint(x: x, y: 0))
                            path.addLine(to: CGPoint(x: x, y: height))
                        }
                        
                        for y in stride(from: 0, through: height, by: spacing) {
                            path.move(to: CGPoint(x: 0, y: y))
                            path.addLine(to: CGPoint(x: width, y: y))
                        }
                    }
                    .stroke(Color.gray.opacity(0.05), lineWidth: 0.5)
                    .ignoresSafeArea()
                }
                
                ScrollView {
                    LazyVStack(spacing: 24) {
                        // ASCII Header
//                        ASCIIHeader()
                        
                        // Search Bar
                        HStack(spacing: 8) {
                            Text(">")
                                .font(.system(size: 14, design: .monospaced))
                                .foregroundColor(.blue)
                            
                            TextField("由赵纯想从Reactbits迁移并开源", text: $searchText)
                                .font(.system(size: 12, design: .monospaced))
                                .textFieldStyle(PlainTextFieldStyle())
                            
                            if !searchText.isEmpty {
                                Button(action: { searchText = "" }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                        )
                        .padding(.horizontal, 20)
                        
                        // Results count
                        if !searchText.isEmpty {
                            HStack {
                                Text("// Found")
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(.gray)
                                Text("\(filteredEffects.count)")
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(.blue)
                                Text("results")
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(.gray)
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // Effects Grid
                        LazyVGrid(
                            columns: [
                                GridItem(.adaptive(minimum: 160, maximum: 200), spacing: 16)
                            ],
                            spacing: 16
                        ) {
                            ForEach(Array(filteredEffects.enumerated()), id: \.element.id) { index, effect in
                                NavigationLink(destination: destinationView(for: effect)) {
                                    ASCIICard(
                                        title: effect.title,
                                        description: effect.description,
                                        icon: effect.icon,
                                        index: index + 1
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Footer
                        VStack(spacing: 8) {
                            Divider()
                                .padding(.horizontal, 40)
                            
                            HStack(spacing: 16) {
                                Text("EOF")
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(.gray)
                                
                                Text("•")
                                    .foregroundColor(.gray.opacity(0.3))
                                
                                Text("\(Effect.allCases.count) MODULES LOADED")
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(.gray)
                                
                                Text("•")
                                    .foregroundColor(.gray.opacity(0.3))
                                
                                Text("METAL RENDERER")
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(.gray)
                            }
                            
                            Text("─────────────────────────────────")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.gray.opacity(0.3))
                            
                            // Copyright with ASCII art
                            HStack(spacing: 4) {
                                Text("[")
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(.gray)
                                Text("©")
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(.blue)
                                Text("2025")
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(.gray)
                                Text("]")
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(.gray)
                                Text("SWIFTBITS.VISUAL")
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.vertical, 32)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    @ViewBuilder
    private func destinationView(for effect: Effect) -> some View {
        switch effect {
        case .aurora:
            AuroraDemo()
        case .orb:
            OrbDemo()
        case .silk:
            SilkDemo()

        case .dither:
            DitherDemo()
        case .beams:
            BeamsDemo()
        case .galaxy:
            GalaxyDemo()
        case .prism:
            PrismDemo()
        case .plasma:
            PlasmaDemo()
        case .particles:
            ParticlesDemo()
        }
    }
}

#Preview {
    ContentView()
}
