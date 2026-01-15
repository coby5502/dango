import SwiftUI
import AppKit

// MARK: - VisualEffectBlur

public struct VisualEffectBlur: NSViewRepresentable {
    public var material: NSVisualEffectView.Material
    public var blendingMode: NSVisualEffectView.BlendingMode
    public var state: NSVisualEffectView.State
    
    public init(
        material: NSVisualEffectView.Material = .sidebar,
        blendingMode: NSVisualEffectView.BlendingMode = .behindWindow,
        state: NSVisualEffectView.State = .active
    ) {
        self.material = material
        self.blendingMode = blendingMode
        self.state = state
    }
    
    public func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = state
        return view
    }
    
    public func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
        nsView.state = state
    }
}

// MARK: - Glassmorphism Modifier

public struct GlassmorphismModifier: ViewModifier {
    public var material: NSVisualEffectView.Material
    
    public init(material: NSVisualEffectView.Material = .sidebar) {
        self.material = material
    }
    
    public func body(content: Content) -> some View {
        ZStack {
            VisualEffectBlur(material: material)
            content
        }
    }
}

public extension View {
    func glassmorphism(material: NSVisualEffectView.Material = .sidebar) -> some View {
        modifier(GlassmorphismModifier(material: material))
    }
}
