import SwiftUI

struct PlaylistView: View {
    @EnvironmentObject private var player: PlaybackController

    private let fixedCollection: Collection?
    private let isLiked: Bool

    @State private var titleShown = false
    @State private var headerOpacity: Double = 1

    init(collection: Collection) {
        fixedCollection = collection
        isLiked = false
    }

    init(liked: Bool) {
        fixedCollection = nil
        isLiked = liked
    }

    private var collection: Collection {
        if isLiked {
            return Fixtures.likedCollection(player.likedIDs)
        }
        return fixedCollection ?? Fixtures.collections[0]
    }

    private var tracks: [Track] { collection.tracks }
    private var spec: ArtSpec { ArtSpec(seed: collection.artworkSeed) }

    private var isThisSource: Bool {
        player.sourceID == collection.id
    }

    private var showsPause: Bool {
        isThisSource && player.isPlaying
    }

    var body: some View {
        ZStack(alignment: .top) {
            Theme.bg.ignoresSafeArea()

            LinearGradient(
                colors: [spec.colors[1].opacity(0.9), Theme.bg],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 540)
            .opacity(headerOpacity)
            .ignoresSafeArea(edges: .top)
            .allowsHitTesting(false)

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    actionRow
                    trackList
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 34)
            }
            .scrollIndicators(.hidden)
            .onScrollGeometryChange(for: CGFloat.self) { geometry in
                geometry.contentOffset.y + geometry.contentInsets.top
            } action: { _, offset in
                headerOpacity = max(0, min(1, 1 - offset / 340))
                let collapsed = offset > 300
                if collapsed != titleShown {
                    withAnimation(.snappy(duration: 0.22)) {
                        titleShown = collapsed
                    }
                }
            }
        }
        .overlay(alignment: .topTrailing) {
            if titleShown {
                playButton(size: 52)
                    .padding(.top, 6)
                    .padding(.trailing, 18)
                    .transition(.scale(scale: 0.6).combined(with: .opacity))
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                if titleShown {
                    Text(collection.title)
                        .font(Typo.semibold(16))
                        .foregroundStyle(Theme.text)
                        .lineLimit(1)
                        .transition(.opacity)
                }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 18) {
            ArtworkView(
                seed: collection.artworkSeed,
                title: collection.title,
                cornerRadius: 12
            )
            .frame(width: 226, height: 226)
            .shadow(color: .black.opacity(0.45), radius: 18, y: 10)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 10)

            VStack(alignment: .leading, spacing: 8) {
                Text(collection.kind.label.uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.4)
                    .foregroundStyle(Theme.text.opacity(0.75))

                Text(collection.title)
                    .font(Typo.heavy(32))
                    .foregroundStyle(Theme.text)
                    .fixedSize(horizontal: false, vertical: true)

                Text(collection.blurb)
                    .font(Typo.regular(13))
                    .foregroundStyle(Theme.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 7) {
                    AvatarView(name: collection.owner, size: 22)
                    Text(collection.owner)
                        .font(Typo.semibold(13))
                        .foregroundStyle(Theme.text)
                    Text("·")
                        .foregroundStyle(Theme.secondary)
                    Text(metaText)
                        .font(Typo.regular(12))
                        .foregroundStyle(Theme.secondary)
                }
                .padding(.top, 2)
            }
        }
    }

    private var metaText: String {
        if isLiked {
            return "\(tracks.count) songs · \(collection.durationLabel)"
        }
        return collection.metaLine
    }

    private var actionRow: some View {
        HStack(spacing: 2) {
            if !isLiked {
                HeartButton(isOn: player.isSaved(collection)) {
                    player.toggleSave(collection)
                }
            }

            Button {
                player.toggleDownload(collection)
            } label: {
                Image(systemName: player.isDownloaded(collection) ? "checkmark.circle.fill" : "arrow.down.circle")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(player.isDownloaded(collection) ? Theme.accent : Theme.secondary)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .sensoryFeedback(.success, trigger: player.isDownloaded(collection))
            .accessibilityLabel(player.isDownloaded(collection) ? "Remove download" : "Download")

            Menu {
                Button {
                    player.enqueue(contentsOf: tracks)
                } label: {
                    Label("Add All to Queue", systemImage: "text.badge.plus")
                }
                Button {
                    player.toggleDownload(collection)
                } label: {
                    Label(
                        player.isDownloaded(collection) ? "Remove Download" : "Download",
                        systemImage: "arrow.down.circle"
                    )
                }
                ShareLink(item: "\(collection.title) on Tunely") {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(Theme.secondary)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("More options")

            Button {
                player.toggleShuffle()
            } label: {
                Image(systemName: "shuffle")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(player.shuffle ? Theme.accent : Theme.secondary)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .sensoryFeedback(.selection, trigger: player.shuffle)
            .accessibilityLabel("Shuffle")

            Spacer(minLength: 0)

            playButton(size: 56)
        }
    }

    private func playButton(size: CGFloat) -> some View {
        Button {
            if isThisSource {
                player.togglePlayPause()
            } else {
                player.playCollection(collection)
            }
        } label: {
            ZStack {
                Circle()
                    .fill(Theme.accent)
                    .frame(width: size, height: size)
                    .shadow(color: Theme.accent.opacity(0.35), radius: 10, y: 5)
                Image(systemName: showsPause ? "pause.fill" : "play.fill")
                    .font(.system(size: size * 0.36, weight: .bold))
                    .foregroundStyle(Color(hex: 0x1B0904))
                    .offset(x: showsPause ? 0 : 2)
            }
            .contentShape(Circle())
        }
        .buttonStyle(PressableButtonStyle())
        .sensoryFeedback(.impact(weight: .medium), trigger: showsPause)
        .accessibilityLabel(showsPause ? "Pause" : "Play \(collection.title)")
    }

    // MARK: - Tracks

    private var trackList: some View {
        VStack(alignment: .leading, spacing: 6) {
            if tracks.isEmpty {
                EmptyStateView(
                    symbol: "heart",
                    title: "Nothing liked yet",
                    message: "Tap the heart on any track and it will show up here."
                )
            } else {
                HStack {
                    Text(collection.countLabel)
                        .font(Typo.medium(12))
                        .foregroundStyle(Theme.secondary)
                    Spacer()
                    Text(collection.durationLabel)
                        .font(Typo.medium(12))
                        .foregroundStyle(Theme.secondary)
                }
                .padding(.bottom, 4)

                ForEach(Array(tracks.enumerated()), id: \.element.id) { offset, track in
                    TrackRowView(track: track, position: offset + 1, isCurrent: player.current?.id == track.id) {
                        player.play(
                            track,
                            in: tracks,
                            sourceID: collection.id,
                            sourceName: collection.title
                        )
                    }
                }
            }
        }
    }
}
