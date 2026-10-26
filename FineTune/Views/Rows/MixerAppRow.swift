// FineTune/Views/Rows/MixerAppRow.swift
import SwiftUI

/// Sound-menu style app row: icon, name over a plain slider, and a ⋯ button that
/// opens the app's output, boost and equalizer options inline.
/// Shared by AppRow (active apps) and InactiveAppRow (pinned inactive apps).
struct MixerAppRow<EQContent: View>: View {
    let icon: NSImage
    let name: String
    let volume: Float  // Linear gain 0-1 (boost applied separately)
    let isMuted: Bool
    var isInactive: Bool = false
    let devices: [AudioDevice]
    let deviceIconOverrides: [String: String]
    let selectedDeviceUID: String
    let selectedDeviceUIDs: Set<String>
    let isFollowingDefault: Bool
    let defaultDeviceUID: String?
    let deviceSelectionMode: DeviceSelectionMode
    let boost: BoostLevel
    let isEQEnabled: Bool
    let isExpanded: Bool
    let isFocused: Bool
    let onVolumeChange: (Float) -> Void
    let onMuteChange: (Bool) -> Void
    let onBoostChange: (BoostLevel) -> Void
    let onDeviceSelected: (String) -> Void
    let onDevicesSelected: (Set<String>) -> Void
    let onDeviceModeChange: (DeviceSelectionMode) -> Void
    let onSelectFollowDefault: () -> Void
    let onToggleExpanded: () -> Void
    @ViewBuilder let eqPanel: () -> EQContent

    @State private var isHovered = false
    @State private var isShowingEQ = false
    @State private var dragOverrideValue: Double?

    private var sliderValue: Double {
        dragOverrideValue ?? VolumeMapping.gainToSlider(volume)
    }

    private var sliderBinding: Binding<Double> {
        Binding(
            get: { sliderValue },
            set: { newValue in
                dragOverrideValue = newValue
                onVolumeChange(VolumeMapping.sliderToGain(newValue))
                if isMuted { onMuteChange(false) }
            }
        )
    }

    /// Muted, or dragged all the way down (the x² mapping can leave tiny non-zero values).
    private var showsMuted: Bool { isMuted || Int(round(sliderValue * 100)) == 0 }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                iconButton

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 5) {
                        Text(name)
                            .font(.system(size: 12.5))
                            .lineLimit(1)
                            .help(name)
                        if showsMuted {
                            Image(systemName: "speaker.slash.fill")
                                .font(.system(size: 9))
                                .foregroundStyle(.secondary)
                        }
                        if boost != .x1 {
                            Text(boost.label)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(.secondary)
                        }
                    }

                    SoundSlider(
                        value: sliderBinding,
                        isDimmed: showsMuted,
                        trackHeight: 4,
                        knobSize: CGSize(width: 18, height: 12),
                        onEditingChanged: { editing in
                            if !editing { dragOverrideValue = nil }
                        }
                    )
                    .scrollWheelStep(sliderBinding, in: 0.0...1.0)
                }
                .opacity(isInactive ? 0.6 : 1)

                moreButton
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)

            if isExpanded {
                optionsPanel
                    .transition(.opacity.combined(with: .scale(scale: 0.98, anchor: .top)))
            }
        }
        .background {
            RoundedRectangle(cornerRadius: 9)
                .fill(isHovered || isExpanded || isFocused ? DesignTokens.Colors.hoverSurface : .clear)
                .allowsHitTesting(false)
        }
        .onHover { isHovered = $0 }
        .animation(DesignTokens.Animation.hover, value: isHovered)
        .onChange(of: isExpanded) { _, expanded in
            if !expanded { isShowingEQ = false }
        }
    }

    // MARK: - Header pieces

    /// Clicking the icon mutes, the way the speaker glyph does in the Sound menu.
    private var iconButton: some View {
        Button {
            if showsMuted {
                if Int(round(sliderValue * 100)) == 0 { onVolumeChange(1.0) }
                onMuteChange(false)
            } else {
                onMuteChange(true)
            }
        } label: {
            Image(nsImage: icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 28, height: 28)
                .opacity(showsMuted || isInactive ? 0.45 : 1)
                .saturation(showsMuted ? 0 : 1)
        }
        .buttonStyle(.plain)
        .help(showsMuted ? "Unmute \(name)" : "Mute \(name)")
        .accessibilityLabel(showsMuted ? "Unmute \(name)" : "Mute \(name)")
    }

    private var moreButton: some View {
        Button(action: onToggleExpanded) {
            Image(systemName: "ellipsis")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(isExpanded ? Color.primary : Color.secondary)
                .frame(width: 22, height: 22)
                .background(Circle().fill(Color.primary.opacity(isExpanded ? 0.16 : 0.1)))
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .opacity(isHovered || isExpanded || isFocused ? 1 : 0)
        .help("\(name) options")
        .accessibilityLabel("\(name) options")
    }

    // MARK: - Options

    private var optionsPanel: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                optionRow("Output") {
                    DevicePicker(
                        devices: devices,
                        deviceIconOverrides: deviceIconOverrides,
                        selectedDeviceUID: selectedDeviceUID,
                        selectedDeviceUIDs: selectedDeviceUIDs,
                        isFollowingDefault: isFollowingDefault,
                        defaultDeviceUID: defaultDeviceUID,
                        mode: deviceSelectionMode,
                        onModeChange: onDeviceModeChange,
                        onDeviceSelected: onDeviceSelected,
                        onDevicesSelected: onDevicesSelected,
                        onSelectFollowDefault: onSelectFollowDefault,
                        showModeToggle: true,
                        triggerWidth: 170,
                        triggerStyle: .full
                    )
                }
                .zIndex(1)  // keep the picker's dropdown above the rows below

                Divider().opacity(0.5)

                optionRow("Boost") {
                    Picker("Boost", selection: Binding(get: { boost }, set: onBoostChange)) {
                        ForEach(BoostLevel.allCases, id: \.self) { level in
                            Text(level.label).tag(level)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .controlSize(.small)
                    .fixedSize()
                }

                Divider().opacity(0.5)

                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        isShowingEQ.toggle()
                    }
                } label: {
                    optionRow("Equalizer") {
                        HStack(spacing: 4) {
                            Text(isEQEnabled ? "On" : "Off")
                                .foregroundStyle(.secondary)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundStyle(.secondary)
                                .rotationEffect(.degrees(isShowingEQ ? 90 : 0))
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.primary.opacity(0.06)))

            if isShowingEQ {
                eqPanel()
                    .transition(.opacity.combined(with: .scale(scale: 0.98, anchor: .top)))
            }
        }
        .padding(.horizontal, 6)
        .padding(.bottom, 6)
    }

    private func optionRow<Trailing: View>(_ title: String, @ViewBuilder trailing: () -> Trailing) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 12))
            Spacer(minLength: 8)
            trailing()
                .font(.system(size: 12))
        }
        .padding(.horizontal, 10)
        .frame(minHeight: 30)
    }
}
