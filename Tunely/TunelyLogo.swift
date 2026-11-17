import SwiftUI

struct TunelyMark: View {
    var size: CGFloat = 30

    var body: some View {
        Canvas { context, canvasSize in
            let width = canvasSize.width
            let height = canvasSize.height
            let rect = CGRect(origin: .zero, size: canvasSize)
            let background = Path(
                roundedRect: rect,
                cornerRadius: width * 0.3,
                style: .continuous
            )
            let shading = GraphicsContext.Shading.linearGradient(
                Gradient(colors: [Theme.accent, Color(hex: 0xFFA34D)]),
                startPoint: .zero,
                endPoint: CGPoint(x: width, y: height)
            )
            context.fill(background, with: shading)

            let barWidth = width * 0.115
            let gap = width * 0.082
            let heights: [CGFloat] = [0.26, 0.5, 0.36]
            let total = barWidth * 3 + gap * 2
            var x = (width - total) / 2
            for (index, fraction) in heights.enumerated() {
                let barHeight = height * fraction
                let barRect = CGRect(x: x, y: (height - barHeight) / 2, width: barWidth, height: barHeight)
                let bar = Path(roundedRect: barRect, cornerRadius: barWidth / 2, style: .continuous)
                context.fill(bar, with: .color(.white.opacity(index == 1 ? 1 : 0.88)))
                x += barWidth + gap
            }

            let dotSize = width * 0.11
            let dot = CGRect(x: width * 0.74, y: height * 0.15, width: dotSize, height: dotSize)
            context.fill(Path(ellipseIn: dot), with: .color(.white.opacity(0.9)))
        }
        .frame(width: size, height: size)
        .shadow(color: Theme.accent.opacity(0.35), radius: size * 0.16, x: 0, y: size * 0.08)
        .accessibilityLabel("Tunely logo")
    }
}

struct TunelyWordmark: View {
    var size: CGFloat = 30

    var body: some View {
        HStack(spacing: 9) {
            TunelyMark(size: size)
            Text("Tunely")
                .font(.system(size: size * 0.7, weight: .heavy, design: .rounded))
                .tracking(-0.6)
                .foregroundStyle(Theme.text)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Tunely")
    }
}
