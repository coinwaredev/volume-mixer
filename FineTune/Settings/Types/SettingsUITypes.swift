// FineTune/Settings/Types/SettingsUITypes.swift
import Foundation
import AppKit

// MARK: - App-Wide Settings Enums

enum MenuBarIconStyle: String, Codable, CaseIterable, Identifiable {
    case speaker = "Speaker"
    case device = "Device"
    case waveform = "Waveform"
    case equalizer = "Equalizer"

    var id: String { rawValue }

    /// SF Symbol name
    var iconName: String {
        switch self {
        case .speaker: return "speaker.wave.2.fill"
        case .device: return "headphones"
        case .waveform: return "waveform"
        case .equalizer: return "slider.vertical.3"
        }
    }

    /// Saved styles that no longer exist (the old "Default" app-logo icon) fall back to Speaker.
    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = MenuBarIconStyle(rawValue: raw) ?? .speaker
    }
}

// MARK: - HUD Style

/// Style of the on-screen HUD shown when media keys drive FineTune's volume.
/// `.tahoe` renders a small top-right pill; `.classic` renders a center-bottom panel
/// with 16 segment tiles matching Apple's pre-Tahoe HUD aesthetic.
enum HUDStyle: String, Codable, CaseIterable, Identifiable {
    case tahoe
    case classic

    var id: String { rawValue }
}

// MARK: - Appearance Preference

/// User preference for app appearance. `.system` follows macOS appearance live;
/// `.light` and `.dark` lock the override regardless of system setting.
enum AppearancePreference: String, Codable, CaseIterable, Identifiable, CustomStringConvertible {
    case system
    case light
    case dark

    var id: String { rawValue }

    var description: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
}

extension AppearancePreference {
    /// AppKit appearance override. `nil` means "inherit from window or app".
    /// Apply via `nsView.window?.appearance = value` for any `NSWindow`/`NSPanel`
    /// the app hosts (popup, popover, HUD).
    /// `.aqua` available since macOS 10.9; `.darkAqua` since 10.14.
    var nsAppearance: NSAppearance? {
        switch self {
        case .system: return nil
        case .light: return NSAppearance(named: .aqua)
        case .dark: return NSAppearance(named: .darkAqua)
        }
    }
}

// MARK: - Popup Dimensions

struct PopupDimensions: Equatable {
    let width: CGFloat
    let contentPadding: CGFloat
    /// Ceiling on the scrollable body. Sized to stay within a 13" MacBook Air's
    /// usable height after the menu bar, since FluidMenuBarExtra does not clamp
    /// the popup against `screen.visibleFrame` vertically.
    let maxContentHeight: CGFloat
}

extension PopupDimensions {
    static let standard = PopupDimensions(width: 330, contentPadding: 10, maxContentHeight: 600)
}

// MARK: - Volume Hotkey Step Size

enum VolumeHotkeyStep: String, Codable, CaseIterable, Identifiable, CustomStringConvertible {
    case coarse
    case normal
    case fine
    case extraFine

    var id: String { rawValue }

    var sliderDelta: Double {
        switch self {
        case .coarse:    return 1.0 / 8.0
        case .normal:    return 1.0 / 16.0
        case .fine:      return 1.0 / 32.0
        case .extraFine: return 1.0 / 64.0
        }
    }

    var description: String {
        switch self {
        case .coarse:    return "Coarse (12.5%)"
        case .normal:    return "Normal (6.25%)"
        case .fine:      return "Fine (3.13%)"
        case .extraFine: return "Extra-Fine (1.56%)"
        }
    }
}
