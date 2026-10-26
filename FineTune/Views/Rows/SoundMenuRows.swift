// FineTune/Views/Rows/SoundMenuRows.swift
import SwiftUI

// Rows for the popup's device section, laid out like the macOS Sound menu.

/// Main volume for the default output device: speaker glyph, slider, loud glyph.
/// Clicking the small speaker toggles mute, like the Sound menu.
struct MasterVolumeRow: View {
    let volume: Float
    let isMuted: Bool
    let volumeBackend: VolumeControlTier
    let onVolumeChange: (Float) -> Void
    let onMuteToggle: () -> Void

    @State private var sliderValue: Double
    @State private var isEditing = false
    /// Suppresses write-back while syncing from a device change (USB DAC quantization loop).
    @State private var isUpdatingFromDevice = false

    init(volume: Float, isMuted: Bool, volumeBackend: VolumeControlTier,
         onVolumeChange: @escaping (Float) -> Void, onMuteToggle: @escaping () -> Void) {
        self.volume = volume
        self.isMuted = isMuted
        self.volumeBackend = volumeBackend
        self.onVolumeChange = onVolumeChange
        self.onMuteToggle = onMuteToggle
        self._sliderValue = State(initialValue: DeviceRow.volumeToSlider(volume, backend: volumeBackend))
    }

    private var showsMuted: Bool { isMuted || Int(round(sliderValue * 100)) == 0 }

    var body: some View {
        HStack(spacing: 9) {
            Button(action: onMuteToggle) {
                Image(systemName: showsMuted ? "speaker.slash.fill" : "speaker.fill")
                    .font(.system(size: 12))
                    .frame(width: 16)
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.plain)
            .help(isMuted ? "Unmute" : "Mute")
            .accessibilityLabel(isMuted ? "Unmute" : "Mute")

            SoundSlider(value: $sliderValue, isDimmed: showsMuted) { editing in
                isEditing = editing
            }
            .scrollWheelStep($sliderValue, in: 0.0...1.0)

            Image(systemName: "speaker.wave.3.fill")
                .font(.system(size: 12))
                .accessibilityHidden(true)
        }
        .onChange(of: sliderValue) { _, newValue in
            if isUpdatingFromDevice {
                isUpdatingFromDevice = false
                return
            }
            onVolumeChange(DeviceRow.sliderToVolume(newValue, backend: volumeBackend))
            if isMuted && newValue > 0 { onMuteToggle() }
        }
        .onChange(of: volume) { _, newValue in
            guard !isEditing else { return }
            let newSlider = DeviceRow.volumeToSlider(newValue, backend: volumeBackend)
            guard newSlider != sliderValue else { return }
            isUpdatingFromDevice = true
            sliderValue = newSlider
        }
    }
}

/// A device in the Output or Input list: badge + name, click to make it the default.
struct SoundMenuDeviceRow<Trailing: View>: View {
    let icon: NSImage?
    var symbol: String? = nil
    let name: String
    let isSelected: Bool
    var fallbackSymbol: String = "speaker.wave.2.fill"
    var isFocused: Bool = false
    let onSelect: () -> Void
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        HStack(spacing: 10) {
            DeviceBadge(icon: icon, isSelected: isSelected, fallbackSymbol: fallbackSymbol, symbol: symbol)
            Text(name)
                .font(.system(size: 13))
                .lineLimit(1)
                .help(name)
            Spacer(minLength: 4)
            trailing()
        }
        .contentShape(Rectangle())
        .onTapGesture { if !isSelected { onSelect() } }
        .modifier(SoundMenuRowBackground(isFocused: isFocused))
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

extension SoundMenuDeviceRow where Trailing == EmptyView {
    init(icon: NSImage?, symbol: String? = nil, name: String, isSelected: Bool,
         fallbackSymbol: String = "speaker.wave.2.fill", isFocused: Bool = false, onSelect: @escaping () -> Void) {
        self.init(icon: icon, symbol: symbol, name: name, isSelected: isSelected, fallbackSymbol: fallbackSymbol,
                  isFocused: isFocused, onSelect: onSelect, trailing: { EmptyView() })
    }
}

/// "Input  <current mic>  ›" section header that expands the input devices inline,
/// styled like the "Output" header above it.
struct SoundMenuDisclosureRow: View {
    let title: String
    let value: String
    let isExpanded: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 6) {
                Text(title)
                    .sectionHeaderStyle()
                Spacer(minLength: 4)
                Text(value)
                    .font(.system(size: 11.5))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Image(systemName: "chevron.right")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
            }
            .frame(minHeight: 18)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .modifier(SoundMenuRowBackground(isFocused: false))
        .accessibilityLabel("\(title), \(value)")
        .accessibilityHint(isExpanded ? "Hide input devices" : "Show input devices")
    }
}

/// Menu-row hover highlight with the Sound menu's tighter row spacing.
struct SoundMenuRowBackground: ViewModifier {
    let isFocused: Bool
    @State private var isHovered = false

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: 7)
                    .fill(isHovered || isFocused ? DesignTokens.Colors.hoverSurface : Color.clear)
                    .allowsHitTesting(false)
            )
            .onHover { isHovered = $0 }
            .animation(DesignTokens.Animation.hover, value: isHovered)
    }
}

/// Footer row like "Wi-Fi Settings…": plain text, highlighted on hover.
struct SoundMenuFooterRow: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13))
                .frame(maxWidth: .infinity, minHeight: 22, alignment: .leading)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .modifier(SoundMenuRowBackground(isFocused: false))
    }
}
