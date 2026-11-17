import SwiftUI

struct MiniPlayerView: View {
    @EnvironmentObject private var player: PlaybackController
    let onOpen: () -> Void
    @State private var isPressed = false

    var body: some View {
        if let track = player.current {
            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    ArtworkView(seed: track.artworkSeed, title: track.album, cornerRadius: 5, showsMonogram: false)
                        .frame(width: 40, height: 40)
                        .shadow(color: .black.opacity(0.35), radius: 3, y: 1)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(track.title)
                            .font(Typo.semibold(13))
                            .foregroundStyle(Theme.text)
                            .lineLimit(1)
                        HStack(spacing: 5) {
                            if track.explicit {
                                ExplicitBadge()
                            }
                            Text(track.artist.name)
                                .font(Typo.regular(11))
                                .foregroundStyle(Theme.secondary)
                                .lineLimit(1)
                        }
                    }

                    Spacer(minLength: 4)

                    Image(systemName: player.outputDevice.symbol)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.secondary)
                        .padding(.trailing, 2)

                    Button {
                        player.togglePlayPause()
                    } label: {
                        Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(Theme.text)
                            .frame(width: 38, height: 38)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(player.isPlaying ? "Pause" : "Play")
                }
                .padding(.leading, 8)
                .padding(.trailing, 4)
                .padding(.vertical, 6)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.white.opacity(0.13))
                        Rectangle()
                            .fill(Theme.accent)
                            .frame(width: geo.size.width * player.progress)
                    }
                }
                .frame(height: 2)
                .clipShape(RoundedRectangle(cornerRadius: 1, style: .continuous))
                .padding(.horizontal, 8)
                .padding(.bottom, 6)
            }
            .background(Theme.surfaceRaised)
            .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.06), lineWidth: 0.5)
            }
            .scaleEffect(isPressed ? 0.985 : 1)
            .contentShape(Rectangle())
            .onTapGesture {
                onOpen()
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPressed = true }
                    .onEnded { _ in isPressed = false }
            )
            .animation(.spring(response: 0.22, dampingFraction: 0.8), value: isPressed)
            .accessibilityElement(children: .contain)
            .accessibilityAddTraits(.isButton)
            .accessibilityLabel("Now playing \(track.title) by \(track.artist.name). Open player")
            .accessibilityIdentifier("mini-player")
        }
    }
}
