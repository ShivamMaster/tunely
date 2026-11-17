import Foundation
import SwiftUI

@main
struct TunelyApp: App {
    @StateObject private var player = PlaybackController()
    @StateObject private var spotify = SpotifyPlaybackService()
    @State private var didStartUITestPlayback = false

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(player)
                .environmentObject(spotify)
                .onOpenURL { url in
                    spotify.handleCallback(url)
                }
                .onAppear {
                    startUITestPlaybackIfNeeded()
                }
                .preferredColorScheme(.dark)
                .tint(Theme.accent)
        }
    }

    private func startUITestPlaybackIfNeeded() {
        #if DEBUG
        guard
            !didStartUITestPlayback,
            ProcessInfo.processInfo.arguments.contains("--uitest-autoplay"),
            let first = Fixtures.tracks.first
        else { return }

        didStartUITestPlayback = true
        player.play(first, in: Fixtures.tracks, sourceID: "uitest", sourceName: "UI Test")
        #endif
    }
}
