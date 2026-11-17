import SwiftUI

enum HomeFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case music = "Music"
    case podcasts = "Podcasts"

    var id: String { rawValue }
}

struct HomeView: View {
    @EnvironmentObject private var player: PlaybackController
    @State private var filter: HomeFilter = .all

    private var quickPicks: [Collection] {
        switch filter {
        case .all: return Fixtures.quickPicks
        case .music: return Fixtures.quickPicks.filter { $0.kind != .podcast }
        case .podcasts: return Fixtures.podcastPicks
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header
                chips
                quickPickGrid
                if filter != .podcasts {
                    ShelfView(title: "Made For \(Fixtures.appOwner)", collections: Fixtures.madeForAnsh)
                    ShelfView(title: "Recently played", collections: Fixtures.recentlyPlayed)
                    ShelfView(title: "Your top mixes", collections: Fixtures.topMixes)
                    ShelfView(title: "Popular albums", collections: Fixtures.popularAlbums)
                }
                if filter != .music {
                    ShelfView(title: "Podcasts you might like", collections: Fixtures.podcastPicks)
                }
                footer
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)
            .padding(.bottom, 28)
        }
        .scrollIndicators(.hidden)
        .background(Theme.bg)
        .toolbar(.hidden, for: .navigationBar)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                TunelyWordmark(size: 30)
                Spacer()
                AvatarView(name: Fixtures.appOwner, size: 34)
            }
            HStack(alignment: .firstTextBaseline) {
                Text("Good evening")
                    .font(Typo.heavy(28))
                    .foregroundStyle(Theme.text)
                Spacer()
            }
        }
    }

    private var chips: some View {
        HStack(spacing: 8) {
            ForEach(HomeFilter.allCases) { option in
                ChipView(title: option.rawValue, isSelected: filter == option) {
                    withAnimation(.snappy(duration: 0.22)) {
                        filter = option
                    }
                }
            }
            Spacer(minLength: 0)
        }
    }

    private var quickPickGrid: some View {
        LazyVGrid(
            columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)],
            spacing: 8
        ) {
            ForEach(quickPicks) { collection in
                QuickPickTile(collection: collection)
            }
        }
        .animation(.snappy(duration: 0.25), value: filter)
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Tunely · Original demo catalog")
                .font(Typo.semibold(11))
                .foregroundStyle(Theme.tertiary)
            Text("Audio streamed from royalty-free SoundHelix recordings.")
                .font(Typo.regular(11))
                .foregroundStyle(Theme.tertiary)
        }
        .padding(.top, 8)
    }
}
