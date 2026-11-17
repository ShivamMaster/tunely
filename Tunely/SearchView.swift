import SwiftUI

struct SearchView: View {
    @EnvironmentObject private var player: PlaybackController
    @State private var query = ""
    @FocusState private var fieldFocused: Bool

    private var trimmed: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isSearching: Bool { !trimmed.isEmpty }

    private var songResults: [Track] {
        guard isSearching else { return [] }
        let key = trimmed.searchKey
        return Fixtures.tracks.filter {
            $0.title.searchKey.contains(key)
                || $0.artist.name.searchKey.contains(key)
                || $0.album.searchKey.contains(key)
        }
    }

    private var artistResults: [Artist] {
        guard isSearching else { return [] }
        let key = trimmed.searchKey
        return Fixtures.artists.filter { $0.name.searchKey.contains(key) }
    }

    private var playlistResults: [Collection] {
        guard isSearching else { return [] }
        let key = trimmed.searchKey
        return Fixtures.collections.filter {
            $0.title.searchKey.contains(key)
                || $0.owner.searchKey.contains(key)
                || $0.blurb.searchKey.contains(key)
        }
    }

    private var hasResults: Bool {
        !songResults.isEmpty || !artistResults.isEmpty || !playlistResults.isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Search")
                    .font(Typo.heavy(28))
                    .foregroundStyle(Theme.text)
                searchField
                if isSearching {
                    results
                } else {
                    browseAll
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)
            .padding(.bottom, 28)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .background(Theme.bg)
        .toolbar(.hidden, for: .navigationBar)
    }

    private var searchField: some View {
        HStack(spacing: 9) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(fieldFocused || isSearching ? Theme.text : Theme.secondary)
            TextField("Artists, songs, or podcasts", text: $query)
                .font(Typo.regular(14))
                .foregroundStyle(Theme.text)
                .focused($fieldFocused)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)
                .onSubmit { fieldFocused = false }
            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(Theme.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 44)
        .background(Theme.surfaceRaised)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    @ViewBuilder
    private var results: some View {
        if hasResults {
            if !songResults.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    SectionTitle(title: "Songs")
                    ForEach(Array(songResults.prefix(6))) { track in
                        TrackRowView(track: track, isCurrent: player.current?.id == track.id) {
                            player.play(track, in: songResults, sourceID: "search", sourceName: "Search")
                        }
                    }
                }
            }
            if !artistResults.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    SectionTitle(title: "Artists")
                    ForEach(Array(artistResults.prefix(4))) { artist in
                        NavigationLink(value: Route.artist(artist)) {
                            artistRow(artist)
                        }
                        .buttonStyle(PressableButtonStyle())
                    }
                }
            }
            if !playlistResults.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    SectionTitle(title: "Playlists & Albums")
                    ForEach(Array(playlistResults.prefix(6))) { collection in
                        NavigationLink(value: Route.collection(collection)) {
                            playlistRow(collection)
                        }
                        .buttonStyle(PressableButtonStyle())
                    }
                }
            }
        } else {
            EmptyStateView(
                symbol: "magnifyingglass",
                title: "No results for “\(trimmed)”",
                message: "Try a different artist, song or playlist name."
            )
        }
    }

    private func artistRow(_ artist: Artist) -> some View {
        HStack(spacing: 12) {
            AvatarView(name: artist.name, size: 46)
            VStack(alignment: .leading, spacing: 2) {
                Text(artist.name)
                    .font(Typo.medium(15))
                    .foregroundStyle(Theme.text)
                    .lineLimit(1)
                Text("Artist")
                    .font(Typo.regular(12))
                    .foregroundStyle(Theme.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Theme.tertiary)
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }

    private func playlistRow(_ collection: Collection) -> some View {
        HStack(spacing: 12) {
            ArtworkView(
                seed: collection.artworkSeed,
                title: collection.title,
                cornerRadius: 6,
                showsMonogram: false
            )
            .frame(width: 46, height: 46)
            VStack(alignment: .leading, spacing: 2) {
                Text(collection.title)
                    .font(Typo.medium(15))
                    .foregroundStyle(Theme.text)
                    .lineLimit(1)
                Text(collection.subtitle)
                    .font(Typo.regular(12))
                    .foregroundStyle(Theme.secondary)
                    .lineLimit(1)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Theme.tertiary)
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }

    private var browseAll: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(title: "Browse all")
            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                spacing: 12
            ) {
                ForEach(Fixtures.genres) { genre in
                    GenreTile(genre: genre)
                }
            }
        }
    }
}

struct GenreTile: View {
    let genre: Genre

    private var collection: Collection { Fixtures.collection(genre.collectionID) }
    private var spec: ArtSpec { ArtSpec(seed: genre.title) }

    var body: some View {
        NavigationLink(value: Route.collection(collection)) {
            ZStack(alignment: .topLeading) {
                LinearGradient(
                    colors: [spec.colors[0], spec.colors[1]],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                Text(genre.title)
                    .font(Typo.bold(17))
                    .foregroundStyle(.white)
                    .padding(12)
                ArtworkView(
                    seed: collection.artworkSeed,
                    title: collection.title,
                    cornerRadius: 4,
                    showsMonogram: false
                )
                .frame(width: 46, height: 46)
                .rotationEffect(.degrees(24))
                .offset(x: 118, y: 48)
                .shadow(color: .black.opacity(0.4), radius: 4, y: 2)
            }
            .frame(height: 94)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityLabel("Browse \(genre.title)")
    }
}
