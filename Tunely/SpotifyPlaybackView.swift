import SwiftUI
import UIKit

struct SpotifyPlaybackView: View {
    @EnvironmentObject private var player: PlaybackController
    @EnvironmentObject private var spotify: SpotifyPlaybackService
    @Environment(\.dismiss) private var dismiss

    @State private var copied = false

    private var dashboardURL: URL {
        URL(string: "https://developer.spotify.com/dashboard") ?? URL(string: "https://developer.spotify.com")!
    }

    private var appStoreURL: URL {
        URL(string: "https://apps.apple.com/app/spotify-music-and-podcasts/id324684580")
            ?? URL(string: "https://apps.apple.com")!
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    intro
                    if spotify.hasPlaylistAccess {
                        SpotifyPlaylistSection()
                    }
                    content
                    if spotify.isConnected || spotify.hasPlaylistAccess {
                        disconnectButton
                    }
                    disclosure
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 30)
            }
            .scrollIndicators(.hidden)
            .background(Theme.bg)
            .navigationTitle("Spotify")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.bg, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(Theme.text)
                }
            }
        }
        .presentationBackground(Theme.bg)
        .onAppear {
            spotify.refreshAvailability()
        }
        .onChange(of: spotify.isPaused) { _, paused in
            if spotify.isConnected && !paused && player.isPlaying {
                player.pause()
            }
        }
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Theme.accent, Color(hex: 0x7C5CFF)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                    Image(systemName: "waveform")
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Spotify playback")
                        .font(Typo.bold(19))
                        .foregroundStyle(Theme.text)
                    Text("Licensed remote playback")
                        .font(Typo.regular(12))
                        .foregroundStyle(Theme.secondary)
                }
            }
            Text("Browse the playlists Spotify shares with Tunely, then open one in Spotify to listen. Remote playback controls use the official Spotify iOS SDK; Tunely never streams, downloads or caches Spotify content.")
                .font(Typo.regular(13))
                .foregroundStyle(Theme.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch spotify.status {
        case .disabled:
            infoCard(
                symbol: "flag.slash",
                title: "Feature flag is off",
                message: "Enable SpotifyPlaybackEnabled in Info.plist or launch Tunely with --enable-spotify."
            )
        case .notConfigured:
            setupCard
        case .appMissing:
            appMissingCard
        case .ready:
            readyCard
        case .authorizing:
            progressCard(title: "Authorize in Spotify", message: "Complete the permission prompt in the Spotify app.")
        case .connecting:
            progressCard(title: "Connecting…", message: "Linking Tunely to the Spotify player.")
        case .failed(let message):
            failedCard(message)
        case .connected:
            SpotifyRemotePlayerView()
        }
    }

    private var setupCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Finish Spotify setup", systemImage: "key.horizontal")
                .font(Typo.semibold(16))
                .foregroundStyle(Theme.text)

            Text("Add your Spotify client ID to enable this path. Playlist browsing works with a free Spotify account; remote playback controls require Premium.")
                .font(Typo.regular(13))
                .foregroundStyle(Theme.secondary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 4) {
                Text("CLIENT ID")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1)
                    .foregroundStyle(Theme.tertiary)
                Text(SpotifyFeature.clientID.isEmpty ? "Not set" : SpotifyFeature.clientID)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(Theme.text.opacity(0.85))
                    .lineLimit(1)
            }

            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text("REDIRECT URI")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1)
                        .foregroundStyle(Theme.tertiary)
                    Spacer()
                    Button(copied ? "Copied" : "Copy") {
                        UIPasteboard.general.string = spotify.redirectURIString
                        copied = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                            copied = false
                        }
                    }
                    .font(Typo.semibold(12))
                    .foregroundStyle(Theme.accent)
                }
                Text(spotify.redirectURIString)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(Theme.text.opacity(0.85))
                    .lineLimit(2)
            }

            Text("Set SpotifyClientID in Info.plist or pass --spotify-client-id <id>. Register the redirect URI in the Spotify Developer Dashboard, then relaunch. Never add the client secret to an iOS app.")
                .font(Typo.regular(12))
                .foregroundStyle(Theme.tertiary)
                .fixedSize(horizontal: false, vertical: true)

            Link("Open Spotify Developer Dashboard", destination: dashboardURL)
                .font(Typo.semibold(13))
                .foregroundStyle(Theme.accent)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .sensoryFeedback(.success, trigger: copied)
    }

    private var appMissingCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            infoCard(
                symbol: "iphone.slash",
                title: "Spotify app required",
                message: "The Spotify iOS SDK controls the Spotify app on this device. Install Spotify and tap Retry."
            )
            Button {
                spotify.refreshAvailability()
            } label: {
                Text("Retry")
                    .font(Typo.semibold(14))
                    .foregroundStyle(Theme.bgDeep)
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
                    .background(Theme.text)
                    .clipShape(Capsule())
            }
            .buttonStyle(PressableButtonStyle())

            Link("Open Spotify in the App Store", destination: appStoreURL)
                .font(Typo.semibold(13))
                .foregroundStyle(Theme.accent)
        }
    }

    private var readyCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Connect your Spotify account", systemImage: "link")
                .font(Typo.semibold(16))
                .foregroundStyle(Theme.text)
            Text("Tunely will request permission to read your playlists and control playback. Playlists open in Spotify; remote playback controls require Premium. Your session is not stored between launches.")
                .font(Typo.regular(13))
                .foregroundStyle(Theme.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Button {
                spotify.connect()
            } label: {
                HStack(spacing: 7) {
                    Image(systemName: "waveform")
                        .font(.system(size: 13, weight: .bold))
                    Text("Connect Spotify")
                        .font(Typo.semibold(15))
                }
                .foregroundStyle(Theme.bgDeep)
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background(Theme.accent)
                .clipShape(Capsule())
            }
            .buttonStyle(PressableButtonStyle())
            .sensoryFeedback(.impact(weight: .medium), trigger: spotify.status)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func progressCard(title: String, message: String) -> some View {
        VStack(spacing: 12) {
            ProgressView()
                .controlSize(.large)
                .tint(Theme.accent)
            Text(title)
                .font(Typo.semibold(16))
                .foregroundStyle(Theme.text)
            Text(message)
                .font(Typo.regular(13))
                .foregroundStyle(Theme.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func failedCard(_ message: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            infoCard(
                symbol: "exclamationmark.triangle",
                title: spotify.hasPlaylistAccess ? "Playback controls unavailable" : "Spotify couldn't connect",
                message: spotify.hasPlaylistAccess
                    ? "Your playlists are available above, but remote playback needs Spotify Premium. \(message)"
                    : message
            )
            Button {
                spotify.connect()
            } label: {
                Text("Try Again")
                    .font(Typo.semibold(14))
                    .foregroundStyle(Theme.bgDeep)
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
                    .background(Theme.accent)
                    .clipShape(Capsule())
            }
            .buttonStyle(PressableButtonStyle())
        }
    }

    private func infoCard(symbol: String, title: String, message: String) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Label(title, systemImage: symbol)
                .font(Typo.semibold(16))
                .foregroundStyle(Theme.text)
            Text(message)
                .font(Typo.regular(13))
                .foregroundStyle(Theme.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var disconnectButton: some View {
        Button {
            spotify.disconnect()
        } label: {
            Text("Disconnect Spotify")
                .font(Typo.semibold(13))
                .foregroundStyle(Theme.secondary)
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(Theme.surface)
                .clipShape(Capsule())
        }
        .buttonStyle(PressableButtonStyle())
    }

    private var disclosure: some View {
        Text("Licensing: Tunely does not stream, download or cache Spotify audio. Playlist browsing uses the Spotify Web API; playback opens in the Spotify app under your Spotify account. Tunely does not block or skip Spotify ads.")
            .font(Typo.regular(11))
            .foregroundStyle(Theme.tertiary)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.top, 4)
    }
}
