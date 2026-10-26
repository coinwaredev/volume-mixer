// FineTune/Views/Components/DeviceBadge.swift
import SwiftUI
import AppKit

/// Circular badge that replaces the leading radio button on a device row, drawn
/// like the macOS Sound menu: the selected device sits on a white disc with an
/// accent-colored glyph; the others on a soft translucent disc.
///
/// The badge owns no behavior. The parent row container handles tap-to-set-default
/// via a row-level `TapGesture` so the click target spans the whole row, mirroring
/// the macOS Sound submenu pattern.
struct DeviceBadge: View {
    /// The device's icon image, if available. Falls back to `fallbackSymbol`.
    let icon: NSImage?
    /// Whether this row is the current default device.
    let isSelected: Bool
    /// SF Symbol name used when `icon` is nil. Defaults to a speaker glyph for
    /// output devices; input device rows pass `"mic"` so the fallback matches
    /// the row's domain.
    var fallbackSymbol: String = "speaker.wave.2.fill"

    private static let badgeSize: CGFloat = 26
    private static let glyphSize: CGFloat = 15

    var body: some View {
        ZStack {
            // Sound-menu style: white disc when selected, soft disc otherwise.
            Circle()
                .fill(isSelected ? Color.white : Color.primary.opacity(0.14))

            // Glyph — device icon when present, fallback SF Symbol otherwise.
            Group {
                if let icon {
                    Image(nsImage: icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else {
                    Image(systemName: fallbackSymbol)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
            }
            .frame(width: Self.glyphSize, height: Self.glyphSize)
            .foregroundStyle(isSelected ? Color.accentColor : Color.primary)
        }
        .frame(width: Self.badgeSize, height: Self.badgeSize)
        .accessibilityHidden(true)
    }
}

// MARK: - Previews

#Preview("DeviceBadge States") {
    HStack(spacing: 16) {
        VStack(spacing: 6) {
            DeviceBadge(icon: nil, isSelected: true)
            Text("Selected")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        VStack(spacing: 6) {
            DeviceBadge(icon: nil, isSelected: false)
            Text("Unselected")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
    .padding()
    .frame(width: 200)
}
