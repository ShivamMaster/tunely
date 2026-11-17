import SwiftUI
import UIKit

struct SpotifyRemotePlayerView: View {
    @EnvironmentObject private var player: PlaybackController
    @EnvironmentObject private var spotify: SpotifyPlaybackService
    @State private var scrubFraction: Double?

    var body: some View {
        VStack(spacing: 14) {
            artwork
            metadata
            seekSection
            controls
            if !spotify.contextTitle.isEmpty {
                Text("Playing from \(spotify.contextTitle)")
                    .font(Typo.regular(11))
                    .foregroundStyle(Theme.secondary)
                    .lineLimit(1)
            }
            Text("Audio is playing in the Spotify app")
                .font(Typo.regular(10))
                .foregroundStyle(Theme.tertiary)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.white.opacity(0.06), lineWidth: 0.5)
        }
    }

    private var artwork: some View {
        Group {
            if let image = spotify.artwork {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    LinearGradient(
                        colors: [Theme.accent.opacity(0.55), Color(hex: 0x3B2A6B)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    Image(systemName: "waveform")
                        .font(.system(size: 38, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.85))
                }
            }
        }
        .frame(width: 170, height: 170)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .shadow(color: .black.opacity(0.35), radius: 10, y: 5)
    }

    private var metadata: some View {
        VStack(spacing: 3) {
            Text(spotify.trackTitle.isEmpty ? "Nothing playing in Spotify" : spotify.trackTitle)
                .font(Typo.semibold(17))
                .foregroundStyle(Theme.text)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            if !spotify.artistName.isEmpty {
                Text(spotify.artistName)
                    .font(Typo.regular(13))
                    .foregroundStyle(Theme.secondary)
                    .lineLimit(1)
            }
            if !spotify.albumName.isEmpty {
                Text(spotify.albumName)
                    .font(Typo.regular(11))
                    .foregroundStyle(Theme.tertiary)
                    .lineLimit(1)
            }
        }
    }

    private var seekSection: some View {
        TimelineView(.periodic(from: Date(), by: 1)) { context in
            let total = spotify.duration
            let liveFraction = total > 0 ? spotify.position(at: context.date) / total : 0
            let shown = min(max(scrubFraction ?? liveFraction, 0), 1)

            VStack(spacing: 2) {
                ScrubBar(progress: shown, accent: Theme.accent) { value in
                    if let value {
                        scrubFraction = value
                    } else {
                        if let value = scrubFraction {
                            spotify.seek(to: value)
                        }
                        scrubFraction = nil
                    }
                }
                HStack {
                    Text(Format.clock(shown * total))
                    Spacer()
                    Text("-" + Format.clock(max(0, total - shown * total)))
                }
                .font(.system(size: 10, weight: .medium).monospacedDigit())
                .foregroundStyle(Theme.tertiary)
            }
        }
    }

    private var controls: some View {
        HStack(spacing: 30) {
            Button {
                player.pause()
                spotify.previous()
            } label: {
                Image(systemName: "backward.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Theme.text)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Previous Spotify track")

            Button {
                player.pause()
                spotify.togglePlayPause()
            } label: {
                ZStack {
                    Circle()
                        .fill(Theme.text)
                        .frame(width: 58, height: 58)
                    Image(systemName: spotify.isPaused ? "play.fill" : "pause.fill")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(Theme.bgDeep)
                        .offset(x: spotify.isPaused ? 2 : 0)
                }
            }
            .buttonStyle(PressableButtonStyle())
            .accessibilityLabel(spotify.isPaused ? "Play on Spotify" : "Pause Spotify")

            Button {
                player.pause()
                spotify.next()
            } label: {
                Image(systemName: "forward.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Theme.text)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Next Spotify track")
        }
        .sensoryFeedback(.selection, trigger: spotify.isPaused)
    }
}

struct SpotifyLibraryCard: View {
    let status: SpotifyPlaybackStatus
    var playlistCount: Int = 0

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Theme.accent, Color(hex: 0x7C5CFF)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 52, height: 52)
                Image(systemName: "waveform")
                    .font(.system(size: 21, weight: .semibold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("Spotify")
                    .font(Typo.semibold(15))
                    .foregroundStyle(Theme.text)
                Text(subtitle)
                    .font(Typo.regular(12))
                    .foregroundStyle(Theme.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            Circle()
                .fill(dotColor)
                .frame(width: 7, height: 7)
            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Theme.tertiary)
        }
        .padding(10)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Spotify playback. \(subtitle)")
    }

    private var subtitle: String {
        if playlistCount > 0 {
            return "\(playlistCount) playlists · opens in Spotify"
        }
        switch status {
        case .connected: return "Connected · audio plays in Spotify"
        case .ready: return "Connect account · playlists + playback"
        case .authorizing: return "Waiting for Spotify…"
        case .connecting: return "Connecting…"
        case .appMissing: return "Spotify app required"
        case .notConfigured: return "Setup required"
        case .failed: return "Playback unavailable · tap to retry"
        case .disabled: return "Feature off"
        }
    }

    private var dotColor: Color {
        switch status {
        case .connected: return Theme.accent
        case .failed: return Color(hex: 0xFFB020)
        default: return Theme.tertiary
        }
    }
}
