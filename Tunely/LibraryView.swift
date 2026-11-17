import SwiftUI

enum LibraryFilter: String, CaseIterable, Identifiable {
    case playlists = "Playlists"
    case artists = "Artists"
    case albums = "Albums"
    case podcasts = "Podcasts"

    var id: String { rawValue }
}

enum LibrarySort: String, CaseIterable, Identifiable {
    case recent = "Recents"
    case alpha = "A–Z"
    case creator = "Creator"

    var id: String { rawValue }
}

enum LibraryLayout {
    case grid
    case list
}

struct LibraryView: View {
    @EnvironmentObject private var player: PlaybackController
    @EnvironmentObject private var spotify: SpotifyPlaybackService
    @State private var filter: LibraryFilter = .playlists
    @State private var sort: LibrarySort = .recent
    @State private var layout: LibraryLayout = .grid
    @State private var showSpotify = false

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    private var collections: [Collection] {
        let items: [Collection]
        switch filter {
        case .playlists: items = Fixtures.libraryPlaylists
        case .albums: items = Fixtures.libraryAlbums
        case .podcasts: items = Fixtures.podcastPicks
        case .artists: items = []
        }
        switch sort {
        case .recent: return items.sorted { $0.order < $1.order }
        case .alpha: return items.sorted { $0.title < $1.title }
        case .creator: return items.sorted { $0.owner < $1.owner }
        }
    }

    private var artists: [Artist] {
        let items = Fixtures.libraryArtists
        switch sort {
        case .recent: return items
        case .alpha, .creator: return items.sorted { $0.name < $1.name }
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                chips
                if SpotifyFeature.isEnabled {
                    Button {
                        showSpotify = true
                    } label: {
                        SpotifyLibraryCard(status: spotify.status, playlistCount: spotify.playlists.count)
                    }
                    .buttonStyle(PressableButtonStyle())
                }
                if filter == .playlists {
                    likedTile
                }
                content
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)
            .padding(.bottom, 28)
        }
        .scrollIndicators(.hidden)
        .background(Theme.bg)
        .toolbar(.hidden, for: .navigationBar)
        .animation(.snappy(duration: 0.25), value: filter)
        .animation(.snappy(duration: 0.25), value: sort)
        .sheet(isPresented: $showSpotify) {
            SpotifyPlaybackView()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationBackground(Theme.bg)
        }
    }

    private var header: some View {
        HStack(spacing: 6) {
            Text("Your Library")
                .font(Typo.heavy(28))
                .foregroundStyle(Theme.text)
            Spacer(minLength: 0)
            Menu {
                Picker("Sort", selection: $sort) {
                    ForEach(LibrarySort.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
            } label: {
                Image(systemName: "arrow.up.arrow.down")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.text)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Sort library")

            Button {
                withAnimation(.snappy(duration: 0.22)) {
                    layout = layout == .grid ? .list : .grid
                }
            } label: {
                Image(systemName: layout == .grid ? "list.bullet" : "square.grid.2x2")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.text)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .sensoryFeedback(.selection, trigger: layout == .grid)
            .accessibilityLabel(layout == .grid ? "Show list" : "Show grid")
        }
    }

    private var chips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(LibraryFilter.allCases) { option in
                    ChipView(title: option.rawValue, isSelected: filter == option) {
                        withAnimation(.snappy(duration: 0.22)) {
                            filter = option
                        }
                    }
                }
            }
            .padding(.trailing, 8)
        }
        .scrollClipDisabled()
    }

    private var likedTile: some View {
        NavigationLink(value: Route.liked) {
            HStack(spacing: 14) {
                ZStack {
                    LinearGradient(
                        colors: [Theme.accent, Color(hex: 0x7C5CFF)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    Image(systemName: "heart.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text("Liked Songs")
                        .font(Typo.semibold(16))
                        .foregroundStyle(Theme.text)
                    Text("\(player.likedCount) songs")
                        .font(Typo.regular(12))
                        .foregroundStyle(Theme.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.tertiary)
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: player.likedCount)
    }

    @ViewBuilder
    private var content: some View {
        if filter == .artists {
            if layout == .grid {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(artists) { artist in
                        NavigationLink(value: Route.artist(artist)) {
                            ArtistTile(artist: artist)
                        }
                        .buttonStyle(PressableButtonStyle())
                    }
                }
                .padding(.top, 4)
            } else {
                VStack(spacing: 0) {
                    ForEach(artists) { artist in
                        NavigationLink(value: Route.artist(artist)) {
                            ArtistRow(artist: artist)
                        }
                        .buttonStyle(PressableButtonStyle())
                        Divider().overlay(Theme.hairline)
                    }
                }
            }
        } else {
            if layout == .grid {
                LazyVGrid(columns: columns, spacing: 18) {
                    ForEach(collections) { collection in
                        NavigationLink(value: Route.collection(collection)) {
                            LibraryTile(collection: collection)
                        }
                        .buttonStyle(PressableButtonStyle())
                    }
                }
                .padding(.top, 4)
            } else {
                VStack(spacing: 0) {
                    ForEach(collections) { collection in
                        NavigationLink(value: Route.collection(collection)) {
                            LibraryRow(collection: collection)
                        }
                        .buttonStyle(PressableButtonStyle())
                        .padding(.vertical, 6)
                        Divider().overlay(Theme.hairline)
                    }
                }
            }
        }
    }
}

struct ArtistTile: View {
    let artist: Artist

    var body: some View {
        VStack(spacing: 8) {
            AvatarView(name: artist.name, size: 118)
                .shadow(color: .black.opacity(0.3), radius: 6, y: 3)
            Text(artist.name)
                .font(Typo.semibold(14))
                .foregroundStyle(Theme.text)
                .lineLimit(1)
            Text("Artist")
                .font(Typo.regular(12))
                .foregroundStyle(Theme.secondary)
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
    }
}

struct ArtistRow: View {
    let artist: Artist

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(name: artist.name, size: 52)
            VStack(alignment: .leading, spacing: 3) {
                Text(artist.name)
                    .font(Typo.semibold(14))
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
        .padding(.vertical, 7)
        .contentShape(Rectangle())
    }
}
