// FineTune/Views/DesignSystem/LiquidGlassPopup.swift
// Custom build: the menu bar popup uses macOS's native Liquid Glass instead of the older popover material.
import AppKit
import SwiftUI

extension View {
    /// Native Liquid Glass panel on macOS 26+, the original popover glass before that.
    @ViewBuilder
    func liquidGlassPopup() -> some View {
        if #available(macOS 26.0, *) {
            self.background(LiquidGlassWindowInstaller().frame(width: 0, height: 0))
        } else {
            self.darkGlassBackground()
        }
    }

    /// Background for a floating panel (AutoEQ): none on macOS 26+, where `PopoverHost(glass: true)`
    /// puts the panel in Liquid Glass, and the menu material before that.
    @ViewBuilder
    func floatingPanelBackground() -> some View {
        if #available(macOS 26.0, *) {
            self
        } else {
            self
                .background(
                    VisualEffectBackground(material: .menu, blendingMode: .behindWindow)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(DesignTokens.Colors.glassBorder, lineWidth: 0.5)
                }
        }
    }
}

/// Swaps FluidMenuBarExtra's NSVisualEffectView content view for an NSGlassEffectView,
/// moving the SwiftUI hosting view inside the glass.
@available(macOS 26.0, *)
private struct LiquidGlassWindowInstaller: NSViewRepresentable {
    static let cornerRadius: CGFloat = 18

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async { [weak view] in
            if let window = view?.window { Self.install(in: window) }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        if let window = nsView.window { Self.install(in: window) }
    }

    static func install(in window: NSWindow) {
        guard String(describing: type(of: window)).contains("FluidMenuBarExtra"),
              let effect = window.contentView as? NSVisualEffectView,
              let hosting = effect.subviews.first
        else { return }

        let glass = NSGlassEffectView()
        glass.cornerRadius = cornerRadius
        hosting.removeFromSuperview()
        glass.contentView = hosting
        hosting.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hosting.topAnchor.constraint(equalTo: glass.topAnchor),
            hosting.bottomAnchor.constraint(equalTo: glass.bottomAnchor),
            hosting.leadingAnchor.constraint(equalTo: glass.leadingAnchor),
            hosting.trailingAnchor.constraint(equalTo: glass.trailingAnchor),
        ])

        window.backgroundColor = .clear
        window.isOpaque = false
        window.contentView = glass
        window.invalidateShadow()
    }
}
