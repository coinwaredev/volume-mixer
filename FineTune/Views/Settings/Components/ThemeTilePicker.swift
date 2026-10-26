// FineTune/Views/Settings/Components/ThemeTilePicker.swift
import SwiftUI

@MainActor
struct ThemeTilePicker: View {
    @Binding var selection: AppearancePreference

    var body: some View {
        HStack(spacing: 12) {
            ForEach(AppearancePreference.allCases) { preference in
                ThemeTile(
                    preference: preference,
                    isSelected: selection == preference,
                    onTap: { selection = preference }
                )
            }
        }
    }
}

// MARK: - Tile

private struct ThemeTile: View {
    let preference: AppearancePreference
    let isSelected: Bool
    let onTap: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 6) {
            ThemePreviewMockup(preference: preference)
                .frame(width: 72, height: 46)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .strokeBorder(
                            isSelected ? Color.accentColor : Color(nsColor: .separatorColor),
                            lineWidth: isSelected ? 2 : 0.5
                        )
                }

            Text(preference.description)
                .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? .primary : .secondary)
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.15), value: isSelected)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        .accessibilityLabel(Text(preference.description))
    }
}

// MARK: - Mockup

private struct ThemePreviewMockup: View {
    let preference: AppearancePreference

    var body: some View {
        switch preference {
        case .system:
            HStack(spacing: 0) {
                MockWindow(scheme: .light)
                MockWindow(scheme: .dark)
            }
        case .light:
            MockWindow(scheme: .light)
        case .dark:
            MockWindow(scheme: .dark)
        }
    }
}

private struct MockWindow: View {
    enum Scheme { case light, dark }

    let scheme: Scheme

    private var bg: Color { scheme == .light ? Color(white: 0.93) : Color(white: 0.11) }
    private var titlebar: Color { scheme == .light ? Color(white: 0.97) : Color(white: 0.18) }
    private var stripe: Color { scheme == .light ? Color(white: 0.72) : Color(white: 0.36) }

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .leading) {
                titlebar
                HStack(spacing: 2) {
                    Circle().fill(Color(red: 1.00, green: 0.37, blue: 0.36)).frame(width: 3, height: 3)
                    Circle().fill(Color(red: 1.00, green: 0.79, blue: 0.27)).frame(width: 3, height: 3)
                    Circle().fill(Color(red: 0.24, green: 0.80, blue: 0.34)).frame(width: 3, height: 3)
                }
                .padding(.leading, 4)
            }
            .frame(height: 9)

            VStack(alignment: .leading, spacing: 2.5) {
                Capsule().fill(stripe).frame(width: 18, height: 2)
                Capsule().fill(stripe).frame(width: 26, height: 2)
                Capsule().fill(stripe.opacity(0.7)).frame(width: 14, height: 2)
            }
            .padding(.top, 5)
            .padding(.leading, 4)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(bg)
        }
    }
}
