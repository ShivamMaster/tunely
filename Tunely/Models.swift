import Foundation

enum CollectionKind: String, Hashable {
    case playlist
    case album
    case mix
    case podcast

    var label: String {
        switch self {
        case .playlist: return "Playlist"
        case .album: return "Album"
        case .mix: return "Mix"
        case .podcast: return "Podcast"
        }
    }
}

struct Artist: Identifiable, Hashable {
    let id: String
    let name: String
    let bio: String
    let monthlyListeners: Int

    var seed: String { id }
}

struct Track: Identifiable, Hashable {
    let id: String
    let title: String
    let artistID: String
    let album: String
    let duration: Int
    let explicit: Bool
    let audioIndex: Int

    var artist: Artist { Fixtures.artist(artistID) }
    var artworkSeed: String { album.isEmpty ? id : album }
    var durationLabel: String { Format.clock(Double(duration)) }

    var audioURL: URL {
        let base = "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-\(audioIndex).mp3"
        return URL(string: base) ?? URL(string: "https://www.soundhelix.com")!
    }
}

struct Collection: Identifiable, Hashable {
    let id: String
    let title: String
    let kind: CollectionKind
    let owner: String
    let blurb: String
    let saves: Int
    let trackIDs: [String]
    let order: Int

    var tracks: [Track] { trackIDs.compactMap { Fixtures.track($0) } }
    var totalSeconds: Int { tracks.reduce(0) { $0 + $1.duration } }
    var durationLabel: String { Format.total(totalSeconds) }
    var countLabel: String { "\(tracks.count) songs" }
    var artworkSeed: String { title }

    var metaLine: String {
        "\(Format.number(saves)) saves · \(durationLabel)"
    }

    var subtitle: String {
        switch kind {
        case .album, .mix: return "\(kind.label) · \(owner)"
        case .podcast: return "Podcast · \(owner)"
        case .playlist: return "Playlist · \(owner)"
        }
    }
}

struct LyricLine: Identifiable, Hashable {
    let id: Int
    let at: Double
    let text: String
}

struct Genre: Identifiable, Hashable {
    let id: String
    let title: String
    let collectionID: String
}

struct AudioDevice: Identifiable, Hashable {
    let id: String
    let name: String
    let symbol: String
}

enum RepeatMode: String, CaseIterable {
    case off
    case all
    case one

    var next: RepeatMode {
        switch self {
        case .off: return .all
        case .all: return .one
        case .one: return .off
        }
    }

    var symbol: String {
        switch self {
        case .one: return "repeat.1"
        default: return "repeat"
        }
    }
}

enum Route: Hashable {
    case collection(Collection)
    case artist(Artist)
    case liked
}

enum Format {
    static func clock(_ seconds: Double) -> String {
        guard seconds.isFinite, seconds > 0 else { return "0:00" }
        let total = Int(seconds.rounded(.down))
        return String(format: "%d:%02d", total / 60, total % 60)
    }

    static func total(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        if hours > 0 { return "\(hours)h \(minutes)m" }
        return "\(max(minutes, 1)) min"
    }

    static func number(_ value: Int) -> String {
        value.formatted(.number.grouping(.automatic))
    }
}

extension String {
    var searchKey: String {
        folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
    }
}
