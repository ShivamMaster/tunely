import SwiftUI
import WebKit

enum AppTab: String, CaseIterable, Identifiable {
    case home
    case search
    case library

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: return "Home"
        case .search: return "Search"
        case .library: return "Your Library"
        }
    }

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .search: return "magnifyingglass"
        case .library: return "books.vertical.fill"
        }
    }
}

struct RootView: View {
    @EnvironmentObject private var player: PlaybackController
    @State private var tab: AppTab = .home
    @State private var showPlayer = false

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            content
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    ChromeBar(tab: $tab, showPlayer: $showPlayer)
                }
        }
        .overlay(alignment: .bottomLeading) {
            WebAudioSurface(webView: player.engine.surface)
                .frame(width: 4, height: 4)
                .opacity(0.02)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
        .fullScreenCover(isPresented: $showPlayer) {
            NowPlayingView()
        }
        .onChange(of: player.current?.id) { _, newValue in
            if newValue == nil {
                showPlayer = false
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch tab {
        case .home:
            NavigationStack { HomeView().tunelyRoutes() }
        case .search:
            NavigationStack { SearchView().tunelyRoutes() }
        case .library:
            NavigationStack { LibraryView().tunelyRoutes() }
        }
    }
}

extension View {
    func tunelyRoutes() -> some View {
        navigationDestination(for: Route.self) { route in
            switch route {
            case .collection(let collection):
                PlaylistView(collection: collection)
            case .artist(let artist):
                ArtistView(artist: artist)
            case .liked:
                PlaylistView(liked: true)
            }
        }
    }
}

struct ChromeBar: View {
    @EnvironmentObject private var player: PlaybackController
    @Binding var tab: AppTab
    @Binding var showPlayer: Bool

    var body: some View {
        VStack(spacing: 0) {
            if player.current != nil {
                MiniPlayerView(onOpen: { showPlayer = true })
                    .padding(.horizontal, 8)
                    .padding(.top, 6)
                    .padding(.bottom, 4)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            TunelyTabBar(selection: $tab)
        }
        .background {
            VStack(spacing: 0) {
                Rectangle()
                    .fill(Theme.hairline)
                    .frame(height: 0.5)
                Rectangle()
                    .fill(Theme.chrome)
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .animation(.snappy(duration: 0.28), value: player.current?.id)
    }
}

struct TunelyTabBar: View {
    @Binding var selection: AppTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases) { item in
                Button {
                    selection = item
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: item.icon)
                            .font(.system(size: 19, weight: .semibold))
                            .frame(height: 22)
                        Text(item.title)
                            .font(.system(size: 10, weight: .semibold))
                            .lineLimit(1)
                    }
                    .foregroundStyle(selection == item ? Theme.text : Theme.tertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(item.title)
                .accessibilityAddTraits(selection == item ? .isSelected : [])
            }
        }
        .padding(.horizontal, 12)
        .sensoryFeedback(.selection, trigger: selection)
    }
}
