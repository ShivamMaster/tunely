import SwiftUI

struct TrackRowView: View {
    @EnvironmentObject private var player: PlaybackController
    let track: Track
    var position: Int?
    var isCurrent: Bool = false
    let onPlay: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            if let position {
                Text("\(position)")
                    .font(.system(size: 12, weight: .medium).monospacedDigit())
                    .foregroundStyle(isCurrent ? Theme.accent : Theme.tertiary)
                    .frame(width: 18, alignment: .center)
            }

            ArtworkView(
                seed: track.artworkSeed,
                title: track.album,
                cornerRadius: 5,
                showsMonogram: false
            )
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    if isCurrent {
                        EqualizerBars(isPlaying: player.isPlaying)
                    }
                    Text(track.title)
                        .font(Typo.medium(15))
                        .foregroundStyle(isCurrent ? Theme.accent : Theme.text)
                        .lineLimit(1)
                    if track.explicit {
                        ExplicitBadge()
                    }
                }
                Text(track.artist.name)
                    .font(Typo.regular(12))
                    .foregroundStyle(Theme.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 4)

            Text(track.durationLabel)
                .font(.system(size: 11, weight: .medium).monospacedDigit())
                .foregroundStyle(Theme.tertiary)

            Menu {
                Button {
                    player.toggleLike(track)
                } label: {
                    Label(
                        player.isLiked(track) ? "Remove from Liked Songs" : "Like",
                        systemImage: player.isLiked(track) ? "heart.fill" : "heart"
                    )
                }

                Button {
                    player.enqueue(track)
                } label: {
                    Label("Add to Queue", systemImage: "text.badge.plus")
                }

                ShareLink(item: "\(track.title) by \(track.artist.name) on Tunely") {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.secondary)
                    .frame(width: 28, height: 40)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("More options for \(track.title)")
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .onTapGesture {
            onPlay()
        }
        .sensoryFeedback(.selection, trigger: isCurrent)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(track.title) by \(track.artist.name)")
    }
}
