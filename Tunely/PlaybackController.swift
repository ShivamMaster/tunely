import Combine
import Foundation

final class PlaybackController: ObservableObject {
    @Published private(set) var queue: [Track] = []
    @Published private(set) var index = 0
    @Published private(set) var isPlaying = false
    @Published private(set) var elapsed: Double = 0
    @Published private(set) var duration: Double = 0
    @Published private(set) var isBuffering = false
    @Published private(set) var sourceID: String?
    @Published private(set) var sourceName = ""
    @Published private(set) var likedIDs: Set<String> = Fixtures.defaultLikedIDs
    @Published private(set) var savedIDs: Set<String> = []
    @Published private(set) var downloadedIDs: Set<String> = []
    @Published var shuffle = false
    @Published var repeatMode: RepeatMode = .off
    @Published var outputDevice: AudioDevice = Fixtures.devices[0]
    @Published var errorText: String?

    let engine = WebAudioEngine()
    private let audioSession = AudioSessionObserver()
    private var wantsPlayback = false
    private var isInterrupted = false
    private var wasPlayingBeforeInterruption = false

    init() {
        engine.onTick = { [weak self] time, total in
            guard let self else { return }
            self.elapsed = time
            if total > 0.5 {
                self.duration = total
                self.isBuffering = false
            }
        }
        engine.onEnded = { [weak self] in
            self?.handleTrackEnded()
        }
        engine.onError = { [weak self] _ in
            guard let self else { return }
            self.isBuffering = false
            self.errorText = "Couldn't load this track. Check your connection and try again."
        }
        engine.onPlaybackState = { [weak self] playing in
            guard let self else { return }
            if self.isPlaying != playing {
                self.isPlaying = playing
            }
            if !self.isInterrupted {
                self.wantsPlayback = playing
            }
        }
        engine.onRemoteCommand = { [weak self] action in
            guard let self else { return }
            switch action {
            case "next":
                self.next()
            case "previous":
                self.previous()
            default:
                break
            }
        }
        audioSession.onInterruptionBegan = { [weak self] in
            self?.handleInterruptionBegan()
        }
        audioSession.onInterruptionEnded = { [weak self] shouldResume in
            self?.handleInterruptionEnded(shouldResume: shouldResume)
        }
        audioSession.onOutputDisconnected = { [weak self] in
            self?.handleOutputDisconnected()
        }
    }

    var current: Track? {
        queue.indices.contains(index) ? queue[index] : nil
    }

    var progress: Double {
        guard duration > 0 else { return 0 }
        return min(max(elapsed / duration, 0), 1)
    }

    var likedCount: Int { likedIDs.count }

    var upcomingTracks: [Track] {
        guard queue.indices.contains(index) else { return [] }
        let start = index + 1
        guard start < queue.count else { return [] }
        return Array(queue[start...])
    }

    // MARK: - Transport

    func play(_ track: Track, in tracks: [Track], sourceID: String, sourceName: String) {
        let resolved = tracks.isEmpty ? [track] : tracks
        queue = resolved
        index = resolved.firstIndex(where: { $0.id == track.id }) ?? 0
        self.sourceID = sourceID
        self.sourceName = sourceName
        loadCurrent(autoplay: true)
    }

    func playCollection(_ collection: Collection) {
        guard let first = collection.tracks.first else { return }
        play(first, in: collection.tracks, sourceID: collection.id, sourceName: collection.title)
    }

    func togglePlayPause() {
        guard current != nil else { return }
        if isPlaying {
            pause()
        } else {
            if duration > 1 && elapsed >= duration - 0.4 {
                elapsed = 0
                engine.seek(to: 0)
            }
            wantsPlayback = true
            isPlaying = true
            engine.play()
            engine.updatePlaybackState(true)
        }
    }

    func pause() {
        wantsPlayback = false
        pausePlayback()
    }

    private func pausePlayback() {
        isPlaying = false
        engine.pause()
        engine.updatePlaybackState(false)
    }

    func next() {
        guard queue.count > 1 else {
            restartCurrent()
            return
        }
        if shuffle {
            var candidate = index
            while candidate == index {
                candidate = Int.random(in: 0..<queue.count)
            }
            index = candidate
        } else {
            index = (index + 1) % queue.count
        }
        loadCurrent(autoplay: true)
    }

    func previous() {
        guard current != nil else { return }
        if elapsed > 3 {
            restartCurrent()
            return
        }
        guard queue.count > 1 else {
            restartCurrent()
            return
        }
        index = (index - 1 + queue.count) % queue.count
        loadCurrent(autoplay: true)
    }

    func seek(to fraction: Double) {
        guard duration > 0 else { return }
        let clamped = min(max(fraction, 0), 1)
        elapsed = clamped * duration
        engine.seek(to: elapsed)
    }

    func toggleShuffle() {
        shuffle.toggle()
    }

    func cycleRepeat() {
        repeatMode = repeatMode.next
    }

    func retry() {
        guard let current else { return }
        errorText = nil
        isBuffering = true
        updateNowPlaying(for: current)
        engine.load(url: current.audioURL, autoplay: isPlaying)
        engine.updatePlaybackState(isPlaying)
    }

    func setDevice(_ device: AudioDevice) {
        outputDevice = device
    }

    // MARK: - Queue

    func enqueue(_ track: Track) {
        guard !queue.isEmpty else {
            play(track, in: [track], sourceID: "queue", sourceName: "Queue")
            return
        }
        queue.insert(track, at: min(index + 1, queue.count))
    }

    func enqueue(contentsOf tracks: [Track]) {
        guard !queue.isEmpty else {
            if let first = tracks.first {
                play(first, in: tracks, sourceID: "queue", sourceName: "Queue")
            }
            return
        }
        queue.insert(contentsOf: tracks, at: min(index + 1, queue.count))
    }

    func jumpToUpcoming(at offset: Int) {
        let target = index + 1 + offset
        guard queue.indices.contains(target) else { return }
        index = target
        loadCurrent(autoplay: true)
    }

    func moveUpcoming(fromOffsets source: IndexSet, toOffset destination: Int) {
        guard queue.indices.contains(index) else { return }
        let start = index + 1
        guard start < queue.count else { return }

        var upcoming = Array(queue[start...])
        let valid = source.filter { upcoming.indices.contains($0) }
        guard !valid.isEmpty else { return }

        let moving = valid.map { upcoming[$0] }
        for offset in valid.sorted(by: >) {
            upcoming.remove(at: offset)
        }
        let removedBefore = valid.filter { $0 < destination }.count
        let insertAt = max(0, min(destination - removedBefore, upcoming.count))
        upcoming.insert(contentsOf: moving, at: insertAt)
        queue = Array(queue[..<start]) + upcoming
    }

    // MARK: - Library actions

    func isLiked(_ track: Track) -> Bool {
        likedIDs.contains(track.id)
    }

    func toggleLike(_ track: Track) {
        if likedIDs.contains(track.id) {
            likedIDs.remove(track.id)
        } else {
            likedIDs.insert(track.id)
        }
    }

    func isSaved(_ collection: Collection) -> Bool {
        savedIDs.contains(collection.id)
    }

    func toggleSave(_ collection: Collection) {
        if savedIDs.contains(collection.id) {
            savedIDs.remove(collection.id)
        } else {
            savedIDs.insert(collection.id)
        }
    }

    func isDownloaded(_ collection: Collection) -> Bool {
        downloadedIDs.contains(collection.id)
    }

    func toggleDownload(_ collection: Collection) {
        if downloadedIDs.contains(collection.id) {
            downloadedIDs.remove(collection.id)
        } else {
            downloadedIDs.insert(collection.id)
        }
    }

    func likedTracks() -> [Track] {
        Fixtures.tracks.filter { likedIDs.contains($0.id) }
    }

    // MARK: - Core

    private func loadCurrent(autoplay: Bool) {
        guard let current else { return }
        errorText = nil
        elapsed = 0
        duration = Double(current.duration)
        isBuffering = autoplay
        isPlaying = autoplay
        wantsPlayback = autoplay
        updateNowPlaying(for: current)
        engine.load(url: current.audioURL, autoplay: autoplay)
        engine.updatePlaybackState(autoplay)
    }

    private func updateNowPlaying(for track: Track) {
        engine.updateNowPlaying(title: track.title, artist: track.artist.name, album: track.album)
        let trackID = track.id
        let seed = track.artworkSeed
        let album = track.album
        Task { @MainActor [weak self] in
            guard let self, self.current?.id == trackID else { return }
            guard let artwork = ArtworkRenderer.images(for: seed, title: album) else { return }
            guard self.current?.id == trackID else { return }
            self.engine.updateArtwork(artwork)
        }
    }

    // MARK: - Audio session

    private func handleInterruptionBegan() {
        guard current != nil, wantsPlayback || isPlaying else { return }
        isInterrupted = true
        wasPlayingBeforeInterruption = true
        pausePlayback()
        isBuffering = false
    }

    private func handleInterruptionEnded(shouldResume: Bool) {
        isInterrupted = false
        let resume = shouldResume && wasPlayingBeforeInterruption && current != nil
        wasPlayingBeforeInterruption = false
        if resume {
            wantsPlayback = true
            isPlaying = true
            engine.play()
            engine.updatePlaybackState(true)
        } else {
            wantsPlayback = false
        }
    }

    private func handleOutputDisconnected() {
        isInterrupted = false
        wasPlayingBeforeInterruption = false
        wantsPlayback = false
        pausePlayback()
        isBuffering = false
    }

    private func restartCurrent() {
        guard current != nil else { return }
        elapsed = 0
        wantsPlayback = true
        isPlaying = true
        engine.seek(to: 0)
        engine.play()
        engine.updatePlaybackState(true)
    }

    private func handleTrackEnded() {
        guard !queue.isEmpty else { return }
        if repeatMode == .one {
            restartCurrent()
            return
        }
        if index < queue.count - 1 {
            index += 1
            loadCurrent(autoplay: true)
            return
        }
        if repeatMode == .all {
            index = 0
            loadCurrent(autoplay: true)
            return
        }
        wantsPlayback = false
        isPlaying = false
        elapsed = duration
        engine.updatePlaybackState(false)
    }
}
