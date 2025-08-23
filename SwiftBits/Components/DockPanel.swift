import SwiftUI

struct DockPanel<Content: View>: View {
    @State private var isExpanded = false
    @State private var dragOffset: CGFloat = 0
    @State private var currentHeight: CGFloat = 60
    @Binding var title: String
    @Environment(\.presentationMode) var presentationMode
    let content: Content
    
    private let minHeight: CGFloat = 60
    private let maxHeight: CGFloat = 400
    private let handleHeight: CGFloat = 30
    
    init(title: Binding<String>, @ViewBuilder content: () -> Content) {
        self._title = title
        self.content = content()
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                Spacer()
                
                // Dock Panel with Light Theme
                VStack(spacing: 0) {
                    // Handle Bar
                    HStack {
                        Spacer()
                        
                        RoundedRectangle(cornerRadius: 2.5)
                            .fill(Color.gray.opacity(0.4))
                            .frame(width: 40, height: 5)
                            .padding(.vertical, 12.5)
                        
                        Spacer()
                    }
                    .frame(height: handleHeight)
                    .background(
                        LinearGradient(
                            colors: [Color.white.opacity(0.95), Color.white.opacity(0.98)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                dragOffset = value.translation.height
                                let newHeight = currentHeight - dragOffset
                                
                                if newHeight >= minHeight && newHeight <= maxHeight {
                                    withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.8)) {
                                        currentHeight = newHeight
                                        isExpanded = newHeight > minHeight + 20
                                    }
                                }
                            }
                            .onEnded { _ in
                                dragOffset = 0
                                
                                // Snap to expanded or collapsed
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    if currentHeight < 150 {
                                        currentHeight = minHeight
                                        isExpanded = false
                                    } else {
                                        currentHeight = maxHeight
                                        isExpanded = true
                                    }
                                }
                            }
                    )
                    
                    // Title Bar with Back Button
                    HStack(spacing: 12) {
                        // Back Button
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("Back")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundColor(.gray)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                Capsule()
                                    .fill(Color.gray.opacity(0.1))
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Title
                        Text(title)
                            .font(.headline)
                            .foregroundColor(.black)
                        
                        Spacer()
                        
                        // Expand/Collapse Button
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                isExpanded.toggle()
                                currentHeight = isExpanded ? maxHeight : minHeight
                            }
                        }) {
                            Image(systemName: isExpanded ? "chevron.down.circle.fill" : "chevron.up.circle.fill")
                                .foregroundColor(.gray)
                                .font(.title2)
                        }
                    }
                    .padding(.horizontal, 15)
                    .frame(height: 30)
                    .background(Color.white.opacity(0.98))
                    
                    // Content Area
                    if isExpanded {
                        ScrollView {
                            VStack(spacing: 15) {
                                content
                            }
                            .padding()
                        }
                        .frame(maxHeight: currentHeight - minHeight)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .top)),
                            removal: .opacity
                        ))
                    }
                }
                .frame(height: currentHeight)
                .background(
                    ZStack {
                        // Light theme background
                        Color.white.opacity(0.98)
                        
                        // Subtle blur effect
                        Rectangle()
                            .fill(.regularMaterial)
                            .opacity(0.3)
                    }
                )
                .clipShape(
                    RoundedRectangle(cornerRadius: isExpanded ? 20 : 15)
                        .offset(y: isExpanded ? 0 : 10)
                )
                .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: -5)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: -2)
                .padding(.horizontal, isExpanded ? 10 : 20)
                .offset(y: dragOffset)
            }
        }
    }
}

// Convenience wrapper for full screen demos
struct FullScreenDemo<Effect: View, Controls: View>: View {
    let title: String
    let effect: Effect
    let controls: () -> Controls
    
    @State private var dockTitle: String
    
    init(title: String, effect: Effect, @ViewBuilder controls: @escaping () -> Controls) {
        self.title = title
        self.effect = effect
        self.controls = controls
        self._dockTitle = State(initialValue: title)
    }
    
    var body: some View {
        ZStack {
            // Background
            Color.black
                .ignoresSafeArea()
            
            // Main Effect (Full Screen)
            effect
                .ignoresSafeArea()
            
            // Dock Panel
            DockPanel(title: $dockTitle) {
                controls()
            }
            .ignoresSafeArea(edges: .horizontal)
        }
        .navigationBarHidden(true)
        .statusBar(hidden: true)
    }
}

// Control Components for uniform styling
struct ControlSlider: View {
    let label: String
    @Binding var value: Float
    let range: ClosedRange<Float>
    let step: Float?
    let color: Color
    let format: String
    
    init(
        label: String,
        value: Binding<Float>,
        in range: ClosedRange<Float>,
        step: Float? = nil,
        color: Color = .blue,
        format: String = "%.1f"
    ) {
        self.label = label
        self._value = value
        self.range = range
        self.step = step
        self.color = color
        self.format = format
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.black.opacity(0.7))
                Spacer()
                Text(String(format: format, value))
                    .font(.caption.monospacedDigit())
                    .foregroundColor(.black.opacity(0.9))
                
                if let step = step {
                    Slider(value: $value, in: range, step: step)
                        .accentColor(color)
                } else {
                    Slider(value: $value, in: range)
                        .accentColor(color)
                }
            }
        }
    }
}

struct ControlToggle: View {
    let label: String
    @Binding var isOn: Bool
    let description: String?
    
    init(label: String, isOn: Binding<Bool>, description: String? = nil) {
        self.label = label
        self._isOn = isOn
        self.description = description
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Toggle(label, isOn: $isOn)
                .font(.caption)
                .foregroundColor(.black.opacity(0.9))
            
            if let description = description {
                Text(description)
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .italic()
            }
        }
    }
}

struct ControlPicker<T: Hashable>: View {
    let label: String
    @Binding var selection: T
    let options: [(label: String, value: T)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.caption)
                .foregroundColor(.black.opacity(0.7))
            
            Picker(label, selection: $selection) {
                ForEach(options, id: \.value) { option in
                    Text(option.label).tag(option.value)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
    }
}

struct ControlColorPicker<T: Hashable>: View {
    let label: String
    @Binding var selection: T
    let presets: [(name: String, value: T, colors: [Color])]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.caption)
                .foregroundColor(.black.opacity(0.7))
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(presets, id: \.value) { preset in
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selection = preset.value
                            }
                        }) {
                            VStack(spacing: 4) {
                                // Color preview
                                HStack(spacing: 2) {
                                    ForEach(0..<min(preset.colors.count, 4), id: \.self) { index in
                                        Circle()
                                            .fill(preset.colors[index])
                                            .frame(width: 12, height: 12)
                                    }
                                    if preset.colors.count > 4 {
                                        Text("+\(preset.colors.count - 4)")
                                            .font(.caption2)
                                            .foregroundColor(.gray)
                                    }
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(selection == preset.value ? 
                                              Color.gray.opacity(0.2) : 
                                              Color.gray.opacity(0.05))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(selection == preset.value ? 
                                                       Color.blue : Color.clear, 
                                                       lineWidth: 2)
                                        )
                                )
                                
                                Text(preset.name)
                                    .font(.caption2)
                                    .foregroundColor(.black.opacity(0.7))
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
    }
}
