import SwiftUI

struct ArtistView: View {
    @EnvironmentObject private var player: PlaybackController
    let artist: Artist

    private var sourceID: String { "artist-\(artist.id)" }
    private var allTracks: [Track] { Fixtures.tracks.filter { $0.artistID == artist.id } }
    private var topTracks: [Track] { Array(allTracks.prefix(5)) }
    private var releases: [Collection] { Fixtures.collections(byArtist: artist.name) }
    private var spec: ArtSpec { ArtSpec(seed: artist.seed) }

    var body: some View {
        ZStack(alignment: .top) {
            Theme.bg.ignoresSafeArea()
            LinearGradient(
                colors: [spec.colors[1].opacity(0.75), Theme.bg],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 420)
            .ignoresSafeArea(edges: .top)
            .allowsHitTesting(false)

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    actions
                    if !topTracks.isEmpty {
                        popular
                    }
                    if !releases.isEmpty {
                        ShelfView(title: "Releases", collections: releases)
                    }
                    about
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .scrollIndicators(.hidden)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
    }

    private var header: some View {
        VStack(spacing: 12) {
            AvatarView(name: artist.name, size: 148)
                .shadow(color: .black.opacity(0.4), radius: 16, y: 8)
            Text("ARTIST")
                .font(.system(size: 10, weight: .bold))
                .tracking(1.4)
                .foregroundStyle(Theme.text.opacity(0.65))
            Text(artist.name)
                .font(Typo.heavy(30))
                .foregroundStyle(Theme.text)
                .multilineTextAlignment(.center)
            Text("\(Format.number(artist.monthlyListeners)) monthly listeners")
                .font(Typo.regular(12))
                .foregroundStyle(Theme.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 10)
    }

    private var actions: some View {
        HStack(spacing: 12) {
            Button {
                playAll()
            } label: {
                HStack(spacing: 7) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 12, weight: .bold))
                        .offset(x: 1)
                    Text("Play")
                        .font(Typo.semibold(14))
                }
                .foregroundStyle(Color(hex: 0x1B0904))
                .padding(.horizontal, 20)
                .frame(height: 38)
                .background(Theme.accent)
                .clipShape(Capsule())
            }
            .buttonStyle(PressableButtonStyle())

            Button {
                shufflePlay()
            } label: {
                HStack(spacing: 7) {
                    Image(systemName: "shuffle")
                        .font(.system(size: 12, weight: .bold))
                    Text("Shuffle")
                        .font(Typo.semibold(14))
                }
                .foregroundStyle(Theme.text)
                .padding(.horizontal, 20)
                .frame(height: 38)
                .background(Color.white.opacity(0.1))
                .clipShape(Capsule())
            }
            .buttonStyle(PressableButtonStyle())

            Spacer(minLength: 0)
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: player.sourceID == sourceID)
    }

    private var popular: some View {
        VStack(alignment: .leading, spacing: 4) {
            SectionTitle(title: "Popular")
            ForEach(Array(topTracks.enumerated()), id: \.element.id) { offset, track in
                TrackRowView(
                    track: track,
                    position: offset + 1,
                    isCurrent: player.current?.id == track.id
                ) {
                    player.play(track, in: allTracks, sourceID: sourceID, sourceName: artist.name)
                }
            }
        }
    }

    private var about: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("About")
                .font(Typo.bold(20))
                .foregroundStyle(Theme.text)
            Text(artist.bio)
                .font(Typo.regular(14))
                .foregroundStyle(Theme.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Text("\(Format.number(artist.monthlyListeners)) monthly listeners")
                .font(Typo.semibold(12))
                .foregroundStyle(Theme.text.opacity(0.7))
                .padding(.top, 2)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func playAll() {
        guard let first = allTracks.first else { return }
        player.shuffle = false
        player.play(first, in: allTracks, sourceID: sourceID, sourceName: artist.name)
    }

    private func shufflePlay() {
        guard let pick = allTracks.randomElement() else { return }
        player.shuffle = true
        player.play(pick, in: allTracks, sourceID: sourceID, sourceName: artist.name)
    }
}
