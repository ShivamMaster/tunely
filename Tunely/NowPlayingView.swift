import SwiftUI

struct NowPlayingView: View {
    @EnvironmentObject private var player: PlaybackController
    @Environment(\.dismiss) private var dismiss

    @State private var scrubFraction: Double?
    @State private var showDevices = false
    @State private var showQueue = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                background
                if let track = player.current {
                    ScrollView {
                        VStack(spacing: 0) {
                            topBar(track: track)
                            artwork(track: track, width: min(geo.size.width - 72, 318))
                            titleRow(track: track)
                            #if DEBUG
                            if showsRemoteTestControls {
                                remoteTestControls
                            }
                            #endif
                            if let error = player.errorText {
                                errorBanner(error)
                            }
                            SeekSectionView(player: player, scrubFraction: $scrubFraction)
                            TransportControlsView(player: player)
                            NowPlayingBottomBar(
                                player: player,
                                showDevices: $showDevices,
                                showQueue: $showQueue,
                                shareText: shareText(track)
                            )
                            LyricsCard(track: track)
                                .padding(.top, 26)
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 40)
                    }
                    .scrollIndicators(.hidden)
                } else {
                    EmptyStateView(
                        symbol: "music.note",
                        title: "Nothing playing",
                        message: "Pick a track from Home, Search or Your Library."
                    )
                }
            }
        }
        .presentationBackground(Theme.bg)
        .sheet(isPresented: $showDevices) {
            DevicesSheet()
                .presentationDetents([.height(340)])
                .presentationDragIndicator(.visible)
                .presentationBackground(Theme.surface)
        }
        .sheet(isPresented: $showQueue) {
            QueueView()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationBackground(Theme.bg)
        }
    }

    private var background: some View {
        Group {
            if let track = player.current {
                let spec = ArtSpec(seed: track.artworkSeed)
                LinearGradient(
                    colors: [spec.colors[1], spec.colors[2].opacity(0.96), Theme.bg],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .overlay(Color.black.opacity(0.16))
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.45), value: track.id)
            } else {
                Theme.bg.ignoresSafeArea()
            }
        }
    }

    private func topBar(track: Track) -> some View {
        HStack(spacing: 8) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Theme.text)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close player")

            Spacer(minLength: 0)

            VStack(spacing: 3) {
                Text("PLAYING FROM PLAYLIST")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1.1)
                    .foregroundStyle(Theme.text.opacity(0.65))
                Text(player.sourceName.isEmpty ? "Tunely" : player.sourceName)
                    .font(Typo.semibold(13))
                    .foregroundStyle(Theme.text)
                    .lineLimit(1)
            }
            .multilineTextAlignment(.center)

            Spacer(minLength: 0)

            Menu {
                Button {
                    player.toggleLike(track)
                } label: {
                    Label(
                        player.isLiked(track) ? "Remove from Liked Songs" : "Add to Liked Songs",
                        systemImage: player.isLiked(track) ? "heart.fill" : "heart"
                    )
                }
                Button {
                    player.enqueue(track)
                } label: {
                    Label("Add to Queue", systemImage: "text.badge.plus")
                }
                ShareLink(item: shareText(track)) {
                    Label("Share Song", systemImage: "square.and.arrow.up")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Theme.text)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("More options")
        }
        .padding(.top, 4)
    }

    private func artwork(track: Track, width: CGFloat) -> some View {
        ArtworkView(seed: track.artworkSeed, title: track.album, cornerRadius: 12)
            .frame(width: width, height: width)
            .shadow(color: .black.opacity(0.45), radius: 24, x: 0, y: 14)
            .overlay {
                if player.isBuffering {
                    ProgressView()
                        .controlSize(.large)
                        .tint(.white)
                }
            }
            .scaleEffect(player.isPlaying ? 1 : 0.92)
            .animation(.spring(response: 0.34, dampingFraction: 0.78), value: player.isPlaying)
            .padding(.top, 22)
            .accessibilityLabel("Artwork for \(track.album)")
    }

    private func titleRow(track: Track) -> some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(track.title)
                    .font(Typo.heavy(24))
                    .foregroundStyle(Theme.text)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("now-playing-title")
                HStack(spacing: 6) {
                    if track.explicit {
                        ExplicitBadge()
                    }
                    Text(track.artist.name)
                        .font(Typo.regular(15))
                        .foregroundStyle(Theme.text.opacity(0.7))
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 0)
            HeartButton(isOn: player.isLiked(track), size: 26) {
                player.toggleLike(track)
            }
        }
        .padding(.top, 30)
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 14, weight: .semibold))
            Text(message)
                .font(Typo.regular(12))
                .lineLimit(2)
            Spacer(minLength: 0)
            Button("Retry") {
                player.retry()
            }
            .font(Typo.semibold(12))
            .foregroundStyle(Theme.accent)
        }
        .foregroundStyle(Theme.text.opacity(0.9))
        .padding(12)
        .background(Color.black.opacity(0.25))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .padding(.top, 14)
    }

    private func shareText(_ track: Track) -> String {
        "Listening to \(track.title) by \(track.artist.name) on Tunely."
    }

    #if DEBUG
    private var showsRemoteTestControls: Bool {
        ProcessInfo.processInfo.arguments.contains("--uitest-remote-bridge")
    }

    private var remoteTestControls: some View {
        HStack(spacing: 12) {
            Button("Remote previous") {
                player.engine.simulateRemoteCommand("previous")
            }
            .accessibilityIdentifier("test-remote-previous")

            Button("Remote next") {
                player.engine.simulateRemoteCommand("next")
            }
            .accessibilityIdentifier("test-remote-next")
        }
        .font(Typo.semibold(12))
        .foregroundStyle(Theme.text)
        .padding(.top, 12)
    }
    #endif
}
