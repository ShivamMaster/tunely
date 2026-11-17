import Foundation

/// Tunely's licensed Spotify path is opt-in. It stays invisible and inert unless
/// the feature flag is enabled and a Spotify client ID is configured.
enum SpotifyFeature {
    static var isEnabled: Bool {
        if launchArguments.contains("--enable-spotify") {
            return true
        }
        return boolValue(for: "SpotifyPlaybackEnabled")
    }

    static var clientID: String {
        let override = launchValue(for: "--spotify-client-id")
        let raw = override ?? stringValue(for: "SpotifyClientID") ?? ""
        return raw.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static var redirectURI: URL {
        let override = launchValue(for: "--spotify-redirect-uri")
        let raw = override ?? stringValue(for: "SpotifyRedirectURI") ?? "tunely-spotify://callback"
        return URL(string: raw) ?? URL(string: "tunely-spotify://callback")!
    }

    static var isConfigured: Bool {
        guard isEnabled else { return false }
        let trimmed = clientID
        guard !trimmed.isEmpty else { return false }
        guard trimmed.count >= 16 else { return false }
        let allowed = CharacterSet(charactersIn: "0123456789abcdefABCDEF")
        return trimmed.unicodeScalars.allSatisfy { allowed.contains($0) }
    }

    private static var launchArguments: [String] {
        ProcessInfo.processInfo.arguments
    }

    private static func stringValue(for key: String) -> String? {
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func boolValue(for key: String) -> Bool {
        if let value = Bundle.main.object(forInfoDictionaryKey: key) as? Bool {
            return value
        }
        if let value = Bundle.main.object(forInfoDictionaryKey: key) as? String {
            return ["yes", "true", "1"].contains(value.lowercased())
        }
        return false
    }

    private static func launchValue(for flag: String) -> String? {
        let arguments = launchArguments
        guard let index = arguments.firstIndex(of: flag) else { return nil }
        guard arguments.indices.contains(index + 1) else { return nil }
        let value = arguments[index + 1].trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}
