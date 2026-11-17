import SwiftUI

struct SpotifyPlaylistSection: View {
    @EnvironmentObject private var spotify: SpotifyPlaybackService
    @State private var showAll = false

    private var visiblePlaylists: [SpotifyPlaylist] {
        showAll ? spotify.playlists : Array(spotify.playlists.prefix(8))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            content
            footer
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Your Spotify playlists")
                    .font(Typo.semibold(16))
                    .foregroundStyle(Theme.text)
                if !spotify.playlists.isEmpty {
                    Text("\(spotify.playlists.count) available")
                        .font(Typo.regular(11))
                        .foregroundStyle(Theme.tertiary)
                }
            }

            Spacer(minLength: 0)

            Button {
                spotify.loadPlaylists()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.accent)
                    .frame(width: 36, height: 36)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(spotify.isLoadingPlaylists)
            .accessibilityLabel("Refresh Spotify playlists")
        }
    }

    @ViewBuilder
    private var content: some View {
        if spotify.isLoadingPlaylists && spotify.playlists.isEmpty {
            HStack(spacing: 9) {
                ProgressView()
                    .controlSize(.small)
                    .tint(Theme.accent)
                Text("Loading your playlists…")
                    .font(Typo.regular(13))
                    .foregroundStyle(Theme.secondary)
            }
            .padding(.vertical, 8)
        } else if let error = spotify.playlistError, spotify.playlists.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Label("Couldn't load playlists", systemImage: "exclamationmark.triangle")
                    .font(Typo.semibold(13))
                    .foregroundStyle(Theme.text)
                Text(error)
                    .font(Typo.regular(12))
                    .foregroundStyle(Theme.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Button("Try Again") {
                    spotify.loadPlaylists()
                }
                .font(Typo.semibold(12))
                .foregroundStyle(Theme.accent)
            }
            .padding(.vertical, 4)
        } else if spotify.playlists.isEmpty {
            Text("No playlists returned. Spotify only shares playlists this account can access.")
                .font(Typo.regular(12))
                .foregroundStyle(Theme.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.vertical, 4)
        } else {
            VStack(spacing: 2) {
                ForEach(visiblePlaylists) { playlist in
                    SpotifyPlaylistRow(playlist: playlist)
                }
            }

            if spotify.playlists.count > 8 {
                Button(showAll ? "Show fewer" : "Show all \(spotify.playlists.count)") {
                    withAnimation(.snappy(duration: 0.2)) {
                        showAll.toggle()
                    }
                }
                .font(Typo.semibold(12))
                .foregroundStyle(Theme.accent)
            }
        }
    }

    private var footer: some View {
        Text("Selecting a playlist opens it in Spotify. Free accounts keep Spotify's ads. Spotify may omit algorithmic playlists for new apps.")
            .font(Typo.regular(11))
            .foregroundStyle(Theme.tertiary)
            .fixedSize(horizontal: false, vertical: true)
    }
}

struct SpotifyPlaylistRow: View {
    let playlist: SpotifyPlaylist
    @Environment(\.openURL) private var openURL

    var body: some View {
        Button {
            openURL(playlist.spotifyURL) { accepted in
                if !accepted {
                    openURL(playlist.webURL)
                }
            }
        } label: {
            HStack(spacing: 12) {
                artwork
                VStack(alignment: .leading, spacing: 3) {
                    Text(playlist.name)
                        .font(Typo.medium(14))
                        .foregroundStyle(Theme.text)
                        .lineLimit(1)
                    Text(meta)
                        .font(Typo.regular(11))
                        .foregroundStyle(Theme.secondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.tertiary)
            }
            .padding(.vertical, 5)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open \(playlist.name) in Spotify")
    }

    private var meta: String {
        if playlist.trackCount > 0 {
            return "\(playlist.ownerName) · \(playlist.trackCount) songs"
        }
        return "Playlist · \(playlist.ownerName)"
    }

    private var artwork: some View {
        AsyncImage(url: playlist.imageURL) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
            case .failure, .empty:
                placeholder
            @unknown default:
                placeholder
            }
        }
        .frame(width: 46, height: 46)
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }

    private var placeholder: some View {
        ZStack {
            Theme.surfaceRaised
            Image(systemName: "music.note")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.tertiary)
        }
    }
}
