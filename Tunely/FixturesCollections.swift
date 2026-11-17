import Foundation

extension Fixtures {
    static let collections: [Collection] = [
        Collection(id: "mix1", title: "Daily Mix 1", kind: .mix, owner: "Tunely",
                   blurb: "Neveah Kade, Vela Ross, Junie Bloom and more",
                   saves: 1_204, trackIDs: ["t01", "t02", "t03", "t30", "t31", "t42", "t06", "t07"], order: 1),
        Collection(id: "mix2", title: "Daily Mix 2", kind: .mix, owner: "Tunely",
                   blurb: "Orin Vale, Halo Static, Cold Frame and more",
                   saves: 986, trackIDs: ["t10", "t11", "t38", "t39", "t34", "t35", "t45", "t13"], order: 2),
        Collection(id: "mix3", title: "Daily Mix 3", kind: .mix, owner: "Tunely",
                   blurb: "Kito Marsh, Saffron Lune, Neveah Kade and more",
                   saves: 874, trackIDs: ["t22", "t23", "t18", "t19", "t24", "t01", "t05", "t25"], order: 3),
        Collection(id: "mix4", title: "Daily Mix 4", kind: .mix, owner: "Tunely",
                   blurb: "Aster & Oleander, The Paper Tide, Glasshouse Sunday and more",
                   saves: 655, trackIDs: ["t26", "t27", "t14", "t15", "t46", "t08", "t28", "t09"], order: 4),
        Collection(id: "mix5", title: "Daily Mix 5", kind: .mix, owner: "Tunely",
                   blurb: "Monsoon Arcade, Vela Ross, Halo Static and more",
                   saves: 512, trackIDs: ["t36", "t37", "t32", "t33", "t40", "t41", "t43", "t44"], order: 5),

        Collection(id: "album-neon", title: "Neon Monsoon", kind: .album, owner: "Orin Vale",
                   blurb: "Recorded across three monsoons, mixed in one night.",
                   saves: 24_318, trackIDs: ["t10", "t11", "t12", "t13"], order: 20),
        Collection(id: "album-bloom", title: "Slow Bloom", kind: .album, owner: "Junie Bloom",
                   blurb: "Three songs about taking your time.",
                   saves: 8_421, trackIDs: ["t42", "t43", "t44"], order: 21),
        Collection(id: "album-garden", title: "Paper Garden", kind: .album, owner: "Aster & Oleander",
                   blurb: "Folk songs for the end of a long winter.",
                   saves: 6_290, trackIDs: ["t26", "t27", "t28", "t29"], order: 22),
        Collection(id: "album-midnight", title: "Midnight Arcade", kind: .album, owner: "Halo Static",
                   blurb: "Synthwave for the drive home with the windows down.",
                   saves: 15_872, trackIDs: ["t38", "t39", "t40", "t41"], order: 23),

        Collection(id: "pl-golden", title: "Golden Hour Drive", kind: .playlist, owner: "Tunely",
                   blurb: "Windows down, sun low, nowhere urgent to be.",
                   saves: 48_219, trackIDs: ["t30", "t31", "t06", "t07", "t26", "t36", "t42", "t03", "t16", "t32"], order: 30),
        Collection(id: "pl-code", title: "Late Night Coding", kind: .playlist, owner: "Tunely",
                   blurb: "Steady pulses for the long stretch after midnight.",
                   saves: 88_410, trackIDs: ["t10", "t13", "t38", "t40", "t45", "t41", "t11", "t39", "t46"], order: 31),
        Collection(id: "pl-sunday", title: "Sunday Reset", kind: .playlist, owner: "Tunely",
                   blurb: "Slow coffee, clean sheets, no notifications.",
                   saves: 7_310, trackIDs: ["t08", "t09", "t27", "t28", "t43", "t19", "t20", "t44", "t02", "t33"], order: 32),
        Collection(id: "pl-drive", title: "Ansh's Late Drives", kind: .playlist, owner: "Ansh",
                   blurb: "Made for the ring road at 1 a.m.",
                   saves: 3, trackIDs: ["t11", "t13", "t38", "t45", "t36", "t10", "t40"], order: 5),
        Collection(id: "pl-gym", title: "Gym, Probably", kind: .playlist, owner: "Ansh",
                   blurb: "Optimistic about legs day.",
                   saves: 12, trackIDs: ["t22", "t23", "t25", "t30", "t32", "t34", "t01"], order: 6),

        Collection(id: "pod-signal", title: "Signal & Noise", kind: .podcast, owner: "Tara Bose",
                   blurb: "A weekly show about the technology we live inside.",
                   saves: 9_210, trackIDs: ["t47", "t51"], order: 40),
        Collection(id: "pod-rewind", title: "The Long Rewind", kind: .podcast, owner: "Kabir Sen",
                   blurb: "One film, watched again, years later.",
                   saves: 7_180, trackIDs: ["t48", "t52"], order: 41),
        Collection(id: "pod-hours", title: "Small Hours", kind: .podcast, owner: "Mira Shah",
                   blurb: "Stories told by people who work while you sleep.",
                   saves: 5_240, trackIDs: ["t49", "t53"], order: 42),
        Collection(id: "pod-field", title: "Field Notes", kind: .podcast, owner: "Owen Pike",
                   blurb: "Six minutes of sound from somewhere specific.",
                   saves: 3_105, trackIDs: ["t50", "t54"], order: 43)
    ]

    private static let collectionIndex: [String: Collection] = Dictionary(uniqueKeysWithValues: collections.map { ($0.id, $0) })

    static func collection(_ id: String) -> Collection {
        collectionIndex[id] ?? collections[0]
    }

    // MARK: Home

    static let quickPicks: [Collection] = [
        collection("mix1"), collection("pl-golden"), collection("album-neon"), collection("mix3"),
        collection("album-midnight"), collection("pl-code"), collection("album-garden"), collection("album-bloom")
    ]

    static let madeForAnsh: [Collection] = ["mix1", "mix2", "mix3", "mix4", "mix5"].map(collection)

    static let recentlyPlayed: [Collection] = [
        "album-neon", "pl-golden", "mix2", "album-midnight", "album-garden", "pl-code"
    ].map(collection)

    static let topMixes: [Collection] = ["pl-golden", "pl-code", "pl-sunday", "mix5", "mix4"].map(collection)

    static let popularAlbums: [Collection] = ["album-neon", "album-midnight", "album-garden", "album-bloom"].map(collection)

    static let podcastPicks: [Collection] = ["pod-signal", "pod-rewind", "pod-hours", "pod-field"].map(collection)

    // MARK: Library

    static let libraryPlaylists: [Collection] = [
        "pl-drive", "pl-gym", "pl-golden", "pl-code", "pl-sunday", "mix1", "mix2", "mix3", "mix4", "mix5"
    ].map(collection)

    static let libraryAlbums: [Collection] = ["album-neon", "album-bloom", "album-garden", "album-midnight"].map(collection)

    static let libraryArtists: [Artist] = artists

    // MARK: Search

    static let genres: [Genre] = [
        Genre(id: "g-pop", title: "Pop", collectionID: "mix1"),
        Genre(id: "g-indie", title: "Indie", collectionID: "album-garden"),
        Genre(id: "g-hiphop", title: "Hip-Hop", collectionID: "mix3"),
        Genre(id: "g-electronic", title: "Electronic", collectionID: "mix2"),
        Genre(id: "g-rnb", title: "R&B", collectionID: "pl-sunday"),
        Genre(id: "g-folk", title: "Folk", collectionID: "album-garden"),
        Genre(id: "g-chill", title: "Chill", collectionID: "pl-sunday"),
        Genre(id: "g-workout", title: "Workout", collectionID: "pl-gym"),
        Genre(id: "g-focus", title: "Focus", collectionID: "pl-code"),
        Genre(id: "g-roadtrip", title: "Road Trip", collectionID: "pl-golden"),
        Genre(id: "g-sleep", title: "Sleep", collectionID: "mix5"),
        Genre(id: "g-fresh", title: "Fresh Finds", collectionID: "mix4")
    ]

    // MARK: Devices

    static let devices: [AudioDevice] = [
        AudioDevice(id: "iphone", name: "This iPhone", symbol: "iphone"),
        AudioDevice(id: "airpods", name: "Ansh's AirPods", symbol: "airpodspro"),
        AudioDevice(id: "speaker", name: "Living Room Speaker", symbol: "hifispeaker.fill"),
        AudioDevice(id: "mac", name: "Ansh's MacBook", symbol: "laptopcomputer")
    ]

    static func mixSubtitle(_ collection: Collection) -> String {
        var names: [String] = []
        for track in collection.tracks {
            let name = track.artist.name
            if !names.contains(name) { names.append(name) }
            if names.count == 2 { break }
        }
        return names.joined(separator: ", ")
    }
}
