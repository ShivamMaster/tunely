import SwiftUI

func tunelyHash(_ value: String) -> UInt64 {
    var hash: UInt64 = 1_469_598_103_934_665_603
    for byte in value.utf8 {
        hash ^= UInt64(byte)
        hash = hash &* 1_099_511_628_211
    }
    return hash
}

struct ArtSpec {
    let colors: [Color]
    let deep: Color
    let bright: Color
    let shape: Int

    init(seed: String) {
        let hash = tunelyHash(seed)
        let palette = Theme.artPalettes[Int(hash % UInt64(Theme.artPalettes.count))]
        colors = [Color(hex: palette.0), Color(hex: palette.1), Color(hex: palette.2)]
        deep = Color(hex: palette.2)
        bright = Color(hex: palette.0)
        shape = Int((hash / 31) % 6)
    }
}

struct ArtworkView: View {
    let seed: String
    var title: String?
    var cornerRadius: CGFloat = 12
    var showsMonogram: Bool = true

    var body: some View {
        GeometryReader { geo in
            let spec = ArtSpec(seed: seed)
            ZStack(alignment: .bottomTrailing) {
                LinearGradient(
                    colors: [spec.colors[0], spec.colors[1], spec.colors[2]],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                Canvas { context, size in
                    ArtRenderer.draw(spec: spec, context: &context, size: size)
                }
                if showsMonogram {
                    Text(monogram)
                        .font(.system(size: max(10, geo.size.width * 0.26), weight: .black, design: .rounded))
                        .foregroundStyle(.white.opacity(0.92))
                        .shadow(color: .black.opacity(0.28), radius: 6, x: 0, y: 2)
                        .padding(geo.size.width * 0.09)
                        .lineLimit(1)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 0.5)
        }
        .accessibilityLabel(title ?? "Cover artwork")
    }

    private var monogram: String {
        let source = title ?? seed
        let words = source.split(separator: " ")
        var letters = words.prefix(2).compactMap { $0.first }
        if let number = words.first(where: { $0.allSatisfy { $0.isNumber } }), let digit = number.first {
            letters.append(digit)
        }
        if letters.isEmpty { return "T" }
        return String(letters).uppercased()
    }
}

enum ArtRenderer {
    static func draw(spec: ArtSpec, context: inout GraphicsContext, size: CGSize) {
        let width = size.width
        let height = size.height
        guard width > 1, height > 1 else { return }
        let ink = Color.white

        switch spec.shape {
        case 0:
            let big = CGRect(x: width * 0.52, y: -height * 0.12, width: width * 0.78, height: width * 0.78)
            context.fill(Path(ellipseIn: big), with: .color(ink.opacity(0.13)))
            context.stroke(Path(ellipseIn: big), with: .color(ink.opacity(0.38)), lineWidth: max(1, width * 0.012))
            let low = CGRect(x: -width * 0.22, y: height * 0.52, width: width * 0.82, height: width * 0.82)
            context.fill(Path(ellipseIn: low), with: .color(spec.deep.opacity(0.55)))
            context.fill(Path(ellipseIn: dotRect(width, height, 0.16)), with: .color(ink.opacity(0.8)))

        case 1:
            var arcPath = Path()
            for i in 0..<5 {
                let inset = CGFloat(i) * width * 0.1
                let radius = width * 0.72 - inset
                guard radius > 0 else { continue }
                arcPath.addArc(
                    center: CGPoint(x: width * 0.05, y: height * 0.98),
                    radius: radius,
                    startAngle: .degrees(-88),
                    endAngle: .degrees(-2),
                    clockwise: false
                )
            }
            context.stroke(arcPath, with: .color(ink.opacity(0.3)), lineWidth: max(1, width * 0.018))
            context.fill(Path(ellipseIn: dotRect(width, height, 0.24)), with: .color(spec.bright.opacity(0.9)))

        case 2:
            for i in 0..<5 {
                var stripe = Path()
                stripe.move(to: CGPoint(x: -height * 0.25 + CGFloat(i) * width * 0.26, y: height))
                stripe.addLine(to: CGPoint(x: width * 0.4 + CGFloat(i) * width * 0.26, y: 0))
                context.stroke(stripe, with: .color(ink.opacity(0.14)), lineWidth: width * 0.055)
            }
            context.fill(Path(ellipseIn: dotRect(width, height, 0.2)), with: .color(ink.opacity(0.85)))

        case 3:
            let blob = CGRect(x: -width * 0.1, y: height * 0.18, width: width * 0.7, height: width * 0.7)
            context.fill(Path(ellipseIn: blob), with: .color(spec.deep.opacity(0.6)))
            let blobTwo = CGRect(x: width * 0.42, y: height * 0.5, width: width * 0.62, height: width * 0.62)
            context.fill(Path(ellipseIn: blobTwo), with: .color(ink.opacity(0.12)))
            for row in 0..<3 {
                for column in 0..<3 {
                    let x = width * 0.66 + CGFloat(column) * width * 0.09
                    let y = height * 0.14 + CGFloat(row) * width * 0.09
                    context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: width * 0.028, height: width * 0.028)), with: .color(ink.opacity(0.7)))
                }
            }

        case 4:
            for i in 0..<4 {
                let inset = CGFloat(i) * width * 0.09
                let ring = CGRect(x: width * 0.28 + inset, y: height * 0.28 + inset,
                                  width: width * 0.5 - inset * 2, height: width * 0.5 - inset * 2)
                if ring.width > 2 {
                    context.stroke(Path(ellipseIn: ring), with: .color(ink.opacity(0.4)), lineWidth: max(1, width * 0.01))
                }
            }
            context.fill(Path(ellipseIn: CGRect(x: width * 0.38, y: height * 0.38, width: width * 0.24, height: width * 0.24)), with: .color(spec.bright))
            var line = Path()
            line.move(to: CGPoint(x: width * 0.08, y: height * 0.82))
            line.addLine(to: CGPoint(x: width * 0.92, y: height * 0.82))
            context.stroke(line, with: .color(ink.opacity(0.28)), lineWidth: max(1, width * 0.008))

        default:
            var wave = Path()
            wave.move(to: CGPoint(x: 0, y: height * 0.72))
            wave.addCurve(
                to: CGPoint(x: width, y: height * 0.58),
                control1: CGPoint(x: width * 0.3, y: height * 0.4),
                control2: CGPoint(x: width * 0.66, y: height * 0.9)
            )
            wave.addLine(to: CGPoint(x: width, y: height))
            wave.addLine(to: CGPoint(x: 0, y: height))
            wave.closeSubpath()
            context.fill(wave, with: .color(spec.deep.opacity(0.65)))
            var second = Path()
            second.move(to: CGPoint(x: 0, y: height * 0.86))
            second.addCurve(
                to: CGPoint(x: width, y: height * 0.74),
                control1: CGPoint(x: width * 0.34, y: height * 0.62),
                control2: CGPoint(x: width * 0.7, y: height * 1.02)
            )
            second.addLine(to: CGPoint(x: width, y: height))
            second.addLine(to: CGPoint(x: 0, y: height))
            second.closeSubpath()
            context.fill(second, with: .color(ink.opacity(0.16)))
            context.fill(Path(ellipseIn: dotRect(width, height, 0.16)), with: .color(spec.bright.opacity(0.9)))
        }
    }

    private static func dotRect(_ width: CGFloat, _ height: CGFloat, _ fraction: CGFloat) -> CGRect {
        let size = width * fraction
        return CGRect(x: width * 0.09, y: height * 0.09, width: size, height: size)
    }
}

struct AvatarView: View {
    let name: String
    var size: CGFloat = 32

    var body: some View {
        let spec = ArtSpec(seed: name)
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [spec.colors[0], spec.colors[1]],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Text(initials)
                .font(.system(size: size * 0.36, weight: .heavy))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay {
            Circle().strokeBorder(Color.white.opacity(0.16), lineWidth: 0.5)
        }
        .accessibilityLabel(name)
    }

    private var initials: String {
        let words = name.split(separator: " ").prefix(2)
        let letters = words.compactMap { $0.first }
        return String(letters).uppercased()
    }
}
