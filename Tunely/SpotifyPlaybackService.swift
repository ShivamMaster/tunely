import Combine
import SpotifyiOS
import UIKit

enum SpotifyPlaybackStatus: Equatable {
    case disabled
    case notConfigured
    case appMissing
    case ready
    case authorizing
    case connecting
    case connected
    case failed(String)
}

/// Bridges the official Spotify App Remote SDK into Tunely.
///
/// This is a licensed remote-control path: Spotify performs the actual playback
/// in its own app. Tunely never receives, buffers or caches Spotify audio.
/// Tokens are intentionally not persisted, matching Tunely's stateless demo.
final class SpotifyPlaybackService: NSObject, ObservableObject {
    @Published private(set) var status: SpotifyPlaybackStatus = .disabled
    @Published private(set) var trackTitle = ""
    @Published private(set) var artistName = ""
    @Published private(set) var albumName = ""
    @Published private(set) var contextTitle = ""
    @Published private(set) var isPaused = true
    @Published private(set) var duration: Double = 0
    @Published private(set) var position: Double = 0
    @Published private(set) var artwork: UIImage?
    @Published private(set) var lastError: String?
    @Published private(set) var playlists: [SpotifyPlaylist] = []
    @Published private(set) var isLoadingPlaylists = false
    @Published private(set) var playlistError: String?
    @Published private(set) var hasPlaylistAccess = false

    private var configuration: SPTConfiguration?
    private var sessionManager: SPTSessionManager?
    private var appRemote: SPTAppRemote?
    private var accessToken: String?
    private var playlistTask: Task<Void, Never>?
    private var currentTrackURI = ""
    private var stateDate = Date()
    private var playbackSpeed: Double = 1

    override init() {
        super.init()
        refreshAvailability()
    }

    deinit {
        playlistTask?.cancel()
    }

    var isEnabled: Bool { SpotifyFeature.isEnabled }
    var isConnected: Bool { status == .connected && appRemote?.isConnected == true }
    var redirectURIString: String { SpotifyFeature.redirectURI.absoluteString }

    func refreshAvailability() {
        guard SpotifyFeature.isEnabled else {
            status = .disabled
            return
        }
        guard SpotifyFeature.isConfigured else {
            status = .notConfigured
            return
        }

        prepareSDKIfNeeded()
        guard let sessionManager else {
            status = .failed("The Spotify SDK could not be initialized.")
            return
        }

        if appRemote?.isConnected == true {
            status = .connected
            return
        }
        if sessionManager.isSpotifyAppInstalled {
            switch status {
            case .ready, .authorizing, .connecting, .connected, .failed:
                break
            default:
                status = .ready
            }
        } else {
            status = .appMissing
        }
    }

    private func prepareSDKIfNeeded() {
        guard sessionManager == nil else { return }
        guard SpotifyFeature.isConfigured else { return }

        let configuration = SPTConfiguration(
            clientID: SpotifyFeature.clientID,
            redirectURL: SpotifyFeature.redirectURI
        )
        self.configuration = configuration

        let manager = SPTSessionManager(configuration: configuration, delegate: self)
        sessionManager = manager

        let remote = SPTAppRemote(configuration: configuration, logLevel: .error)
        remote.delegate = self
        appRemote = remote
    }

    func loadPlaylists() {
        guard let accessToken else { return }

        playlistTask?.cancel()
        isLoadingPlaylists = true
        playlistError = nil

        playlistTask = Task { [weak self] in
            do {
                let items = try await SpotifyWebAPI().playlists(accessToken: accessToken)
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    guard let self else { return }
                    self.playlists = items
                    self.isLoadingPlaylists = false
                }
            } catch {
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    guard let self else { return }
                    self.playlistError = error.localizedDescription
                    self.isLoadingPlaylists = false
                }
            }
        }
    }

    func connect() {
        guard SpotifyFeature.isEnabled else {
            status = .disabled
            return
        }
        guard SpotifyFeature.isConfigured else {
            status = .notConfigured
            return
        }

        prepareSDKIfNeeded()
        guard let sessionManager else {
            status = .failed("The Spotify SDK could not be initialized.")
            return
        }
        guard sessionManager.isSpotifyAppInstalled else {
            status = .appMissing
            return
        }

        lastError = nil
        status = .authorizing
        let scope: SPTScope = [.appRemoteControl, .playlistReadPrivate, .playlistReadCollaborative]
        sessionManager.initiateSession(with: scope, options: .clientOnly, campaign: nil)
    }

    func handleCallback(_ url: URL) {
        guard let sessionManager else {
            refreshAvailability()
            return
        }
        let handled = sessionManager.application(UIApplication.shared, open: url, options: [:])
        if !handled {
            lastError = "That link was not a Spotify authorization callback."
        }
    }

    func disconnect() {
        appRemote?.disconnect()
        accessToken = nil
        hasPlaylistAccess = false
        playlistTask?.cancel()
        playlistTask = nil
        playlists = []
        playlistError = nil
        isLoadingPlaylists = false
        resetPlayerState()
        if sessionManager?.isSpotifyAppInstalled == true {
            status = .ready
        } else {
            status = .appMissing
        }
    }

    func togglePlayPause() {
        guard let playerAPI = appRemote?.playerAPI else { return }
        if isPaused {
            playerAPI.resume(nil)
        } else {
            playerAPI.pause(nil)
        }
    }

    func next() {
        appRemote?.playerAPI?.skip(toNext: nil)
    }

    func previous() {
        appRemote?.playerAPI?.skip(toPrevious: nil)
    }

    func seek(to fraction: Double) {
        guard duration > 0 else { return }
        let clamped = min(max(fraction, 0), 1)
        let target = clamped * duration
        position = target
        stateDate = Date()
        appRemote?.playerAPI?.seek(toPosition: Int(target * 1000), callback: nil)
    }

    func position(at date: Date) -> Double {
        guard duration > 0 else { return 0 }
        guard !isPaused else { return min(max(position, 0), duration) }
        let speed = playbackSpeed > 0 ? playbackSpeed : 1
        let advanced = position + date.timeIntervalSince(stateDate) * speed
        return min(max(advanced, 0), duration)
    }

    // MARK: - State

    private func update(from state: SPTAppRemotePlayerState) {
        let track = state.track
        trackTitle = track.name
        artistName = track.artist.name
        albumName = track.album.name
        contextTitle = state.contextTitle
        isPaused = state.isPaused
        duration = Double(track.duration) / 1000
        position = Double(state.playbackPosition) / 1000
        playbackSpeed = Double(state.playbackSpeed)
        stateDate = Date()

        if track.uri != currentTrackURI {
            currentTrackURI = track.uri
            fetchArtwork(for: track)
        }
    }

    private func fetchArtwork(for track: SPTAppRemoteTrack) {
        guard let imageAPI = appRemote?.imageAPI else { return }
        imageAPI.fetchImage(forItem: track, with: CGSize(width: 600, height: 600)) { [weak self] image, _ in
            guard let image = image as? UIImage else { return }
            DispatchQueue.main.async {
                self?.artwork = image
            }
        }
    }

    private func resetPlayerState() {
        trackTitle = ""
        artistName = ""
        albumName = ""
        contextTitle = ""
        isPaused = true
        duration = 0
        position = 0
        artwork = nil
        currentTrackURI = ""
    }

    private func fail(_ message: String) {
        lastError = message
        status = .failed(message)
    }
}

extension SpotifyPlaybackService: SPTSessionManagerDelegate {
    func sessionManager(manager: SPTSessionManager, didInitiate session: SPTSession) {
        DispatchQueue.main.async {
            self.accessToken = session.accessToken
            self.hasPlaylistAccess = true
            self.status = .connecting
            self.appRemote?.connectionParameters.accessToken = session.accessToken
            self.appRemote?.connect()
            self.loadPlaylists()
        }
    }

    func sessionManager(manager: SPTSessionManager, didFailWith error: Error) {
        DispatchQueue.main.async {
            self.fail(error.localizedDescription)
        }
    }

    func sessionManager(manager: SPTSessionManager, didRenew session: SPTSession) {
        DispatchQueue.main.async {
            self.accessToken = session.accessToken
            self.hasPlaylistAccess = true
            self.appRemote?.connectionParameters.accessToken = session.accessToken
            self.loadPlaylists()
        }
    }
}

extension SpotifyPlaybackService: SPTAppRemoteDelegate {
    func appRemoteDidEstablishConnection(_ appRemote: SPTAppRemote) {
        DispatchQueue.main.async {
            self.status = .connected
            self.lastError = nil
            guard let playerAPI = appRemote.playerAPI else { return }
            playerAPI.delegate = self
            playerAPI.subscribe(toPlayerState: nil)
            playerAPI.getPlayerState { [weak self] result, error in
                DispatchQueue.main.async {
                    if let error {
                        self?.lastError = error.localizedDescription
                    }
                    if let state = result as? SPTAppRemotePlayerState {
                        self?.update(from: state)
                    }
                }
            }
        }
    }

    func appRemote(_ appRemote: SPTAppRemote, didFailConnectionAttemptWithError error: Error?) {
        DispatchQueue.main.async {
            self.fail(error?.localizedDescription ?? "Could not connect to Spotify. Make sure Spotify is installed and you have Premium.")
        }
    }

    func appRemote(_ appRemote: SPTAppRemote, didDisconnectWithError error: Error?) {
        DispatchQueue.main.async {
            self.resetPlayerState()
            if let error {
                self.fail(error.localizedDescription)
            } else if self.sessionManager?.isSpotifyAppInstalled == true {
                self.status = .ready
            } else {
                self.status = .appMissing
            }
        }
    }
}

extension SpotifyPlaybackService: SPTAppRemotePlayerStateDelegate {
    func playerStateDidChange(_ playerState: SPTAppRemotePlayerState) {
        DispatchQueue.main.async {
            self.update(from: playerState)
        }
    }
}
