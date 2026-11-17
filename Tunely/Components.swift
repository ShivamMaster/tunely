import SwiftUI

struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .opacity(configuration.isPressed ? 0.88 : 1)
            .animation(.spring(response: 0.22, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct ChipView: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Typo.semibold(13))
                .foregroundStyle(isSelected ? Theme.bgDeep : Theme.text)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isSelected ? Theme.text : Theme.surfaceRaised)
                .clipShape(Capsule())
        }
        .buttonStyle(PressableButtonStyle())
        .sensoryFeedback(.selection, trigger: isSelected)
    }
}

struct SectionTitle: View {
    let title: String

    var body: some View {
        Text(title)
            .font(Typo.bold(21))
            .foregroundStyle(Theme.text)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct IconButton: View {
    let systemName: String
    var size: CGFloat = 18
    var color: Color = Theme.text.opacity(0.88)
    var label: String = ""
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: size, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityLabel(label.isEmpty ? systemName : label)
    }
}

struct HeartButton: View {
    var isOn: Bool
    var size: CGFloat = 24
    let action: () -> Void
    @State private var pop = false

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.45)) { pop = true }
            action()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.7)) { pop = false }
            }
        } label: {
            Image(systemName: isOn ? "heart.fill" : "heart")
                .font(.system(size: size, weight: .semibold))
                .foregroundStyle(isOn ? Theme.accent : Theme.text.opacity(0.85))
                .scaleEffect(pop ? 1.28 : 1)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.impact(weight: .light), trigger: isOn)
        .accessibilityLabel(isOn ? "Remove from Liked Songs" : "Add to Liked Songs")
    }
}

struct EqualizerBars: View {
    var isPlaying: Bool
    var color: Color = Theme.accent

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.12, paused: !isPlaying)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            HStack(alignment: .bottom, spacing: 2) {
                ForEach(0..<4, id: \.self) { index in
                    Capsule()
                        .fill(color)
                        .frame(width: 2.5, height: barHeight(index: index, time: time))
                }
            }
            .frame(width: 17, height: 15, alignment: .bottom)
        }
        .accessibilityHidden(true)
    }

    private func barHeight(index: Int, time: TimeInterval) -> CGFloat {
        guard isPlaying else {
            return index % 2 == 0 ? 5 : 9
        }
        let wave = abs(sin(time * 4.1 + Double(index) * 1.15))
        return 4 + CGFloat(wave) * 10
    }
}

struct ScrubBar: View {
    var progress: Double
    var accent: Color = .white
    let onScrub: (Double?) -> Void
    @State private var isDragging = false

    var body: some View {
        GeometryReader { geo in
            let width = max(geo.size.width, 1)
            let clamped = min(max(progress, 0), 1)
            let barHeight: CGFloat = isDragging ? 6 : 4
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.22))
                    .frame(height: barHeight)
                Capsule()
                    .fill(accent)
                    .frame(width: max(0, width * clamped), height: barHeight)
                Circle()
                    .fill(accent)
                    .frame(width: isDragging ? 16 : 12)
                    .offset(x: width * clamped - (isDragging ? 8 : 6))
                    .opacity(isDragging ? 1 : 0)
            }
            .frame(maxHeight: .infinity, alignment: .center)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        isDragging = true
                        onScrub(min(max(value.location.x / width, 0), 1))
                    }
                    .onEnded { _ in
                        isDragging = false
                        onScrub(nil)
                    }
            )
        }
        .frame(height: 28)
        .animation(.snappy(duration: 0.15), value: isDragging)
    }
}

struct EmptyStateView: View {
    let symbol: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 34, weight: .medium))
                .foregroundStyle(Theme.accent)
            Text(title)
                .font(Typo.bold(19))
                .foregroundStyle(Theme.text)
            Text(message)
                .font(Typo.regular(14))
                .foregroundStyle(Theme.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 44)
        .padding(.horizontal, 28)
    }
}

struct ExplicitBadge: View {
    var body: some View {
        Text("E")
            .font(.system(size: 9, weight: .heavy))
            .foregroundStyle(Theme.bg)
            .frame(width: 15, height: 15)
            .background(Color.white.opacity(0.72))
            .clipShape(RoundedRectangle(cornerRadius: 2, style: .continuous))
            .accessibilityLabel("Explicit")
    }
}
