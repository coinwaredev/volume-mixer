// FineTune/Views/Components/SoundSlider.swift
import SwiftUI

/// Volume slider styled after the macOS Sound menu: thin capsule track, a light
/// fill and a white pill knob that is always visible. Value is a 0–1 fraction.
struct SoundSlider: View {
    @Binding var value: Double
    var isDimmed: Bool = false
    var trackHeight: CGFloat = 5
    var knobSize = CGSize(width: 20, height: 14)
    var onEditingChanged: (Bool) -> Void = { _ in }

    @State private var isDragging = false

    var body: some View {
        GeometryReader { geo in
            let travel = max(geo.size.width - knobSize.width, 1)
            let x = travel * min(max(value, 0), 1)

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.primary.opacity(0.16))
                    .frame(height: trackHeight)

                Capsule()
                    .fill(Color.primary.opacity(isDimmed ? 0.3 : 0.8))
                    .frame(width: x + knobSize.width / 2, height: trackHeight)

                Capsule()
                    .fill(.white)
                    .overlay(Capsule().strokeBorder(.black.opacity(0.1), lineWidth: 0.5))
                    .shadow(color: .black.opacity(0.3), radius: 1.5, y: 0.5)
                    .frame(width: knobSize.width, height: knobSize.height)
                    .scaleEffect(isDragging ? 1.08 : 1)
                    .offset(x: x)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { drag in
                        if !isDragging {
                            isDragging = true
                            onEditingChanged(true)
                        }
                        value = min(max((drag.location.x - knobSize.width / 2) / travel, 0), 1)
                    }
                    .onEnded { _ in
                        isDragging = false
                        onEditingChanged(false)
                    }
            )
            .animation(DesignTokens.Animation.quick, value: isDragging)
        }
        .frame(height: knobSize.height + 2)
        .accessibilityElement()
        .accessibilityLabel("Volume")
        .accessibilityValue("\(Int(round(value * 100))) percent")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: value = min(value + 0.05, 1)
            case .decrement: value = max(value - 0.05, 0)
            @unknown default: break
            }
        }
    }
}

#Preview("Sound Slider") {
    struct Wrapper: View {
        @State private var value = 0.4
        var body: some View {
            SoundSlider(value: $value)
                .frame(width: 260)
                .padding(40)
        }
    }
    return Wrapper()
}
