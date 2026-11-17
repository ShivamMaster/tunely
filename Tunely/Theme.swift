import SwiftUI

enum Theme {
    static let bg = Color(hex: 0x121212)
    static let bgDeep = Color(hex: 0x0A0A0A)
    static let surface = Color(hex: 0x1A1A1A)
    static let surfaceRaised = Color(hex: 0x232323)
    static let chrome = Color(hex: 0x0E0E0E)
    static let accent = Color(hex: 0xFF5A36)
    static let accentDeep = Color(hex: 0xD93F1E)
    static let gold = Color(hex: 0xFFC145)
    static let text = Color(hex: 0xF7F7F7)
    static let secondary = Color(hex: 0xA8A8A8)
    static let tertiary = Color(hex: 0x6E6E6E)
    static let hairline = Color.white.opacity(0.08)

    /// Original cover palettes, each a start / end / shadow triple.
    static let artPalettes: [(UInt32, UInt32, UInt32)] = [
        (0xFF6B4A, 0x8E2DE2, 0x1A0B2E),
        (0x00C2A8, 0x1B4B8F, 0x081B2E),
        (0xFFC145, 0xD94F2B, 0x2B0F08),
        (0xC8B6FF, 0x5B4BFF, 0x120C3A),
        (0xFF8FB1, 0xFF5A36, 0x2C0B17),
        (0x67E8F9, 0x2563EB, 0x0A1024),
        (0xD9F99D, 0x2F7D4F, 0x08170F),
        (0xFF3CAC, 0x7A1FA2, 0x22061C),
        (0xFFB38B, 0x8D4A2F, 0x1F0F0A),
        (0x9AD0FF, 0x3B5B7A, 0x0B1620),
        (0xFDE68A, 0x8A7A1F, 0x1C1A06),
        (0xBFF7EA, 0x0E7490, 0x041A1F),
        (0xFFB4C8, 0x4C1D95, 0x140A26),
        (0xFFA94D, 0x9B1B30, 0x25060B),
        (0x8FF7C6, 0x0F766E, 0x04120F),
        (0xF5E6C8, 0xB08968, 0x1A140E)
    ]
}

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: opacity)
    }
}

enum Typo {
    static func heavy(_ size: CGFloat) -> Font {
        .system(size: size, weight: .heavy)
    }

    static func bold(_ size: CGFloat) -> Font {
        .system(size: size, weight: .bold)
    }

    static func semibold(_ size: CGFloat) -> Font {
        .system(size: size, weight: .semibold)
    }

    static func medium(_ size: CGFloat) -> Font {
        .system(size: size, weight: .medium)
    }

    static func regular(_ size: CGFloat) -> Font {
        .system(size: size, weight: .regular)
    }
}
