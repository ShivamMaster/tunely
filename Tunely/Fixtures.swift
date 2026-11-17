import Foundation

enum Fixtures {
    static let appOwner = "Ansh"

    // MARK: - Artists

    static let artists: [Artist] = [
        Artist(id: "neveah", name: "Neveah Kade", bio: "Alt-pop with a film-score heart. Recorded mostly in a converted garage in Lisbon.", monthlyListeners: 4_820_140),
        Artist(id: "glasshouse", name: "Glasshouse Sunday", bio: "Four friends, one borrowed piano, and a habit of recording at dawn.", monthlyListeners: 2_140_880),
        Artist(id: "orin", name: "Orin Vale", bio: "Producer and sound designer building slow, humid electronic landscapes.", monthlyListeners: 6_302_510),
        Artist(id: "papertide", name: "The Paper Tide", bio: "Indie rock from a coastal town that never quite dried out.", monthlyListeners: 1_870_420),
        Artist(id: "saffron", name: "Saffron Lune", bio: "Velvet-voiced R&B for late kitchens and longer conversations.", monthlyListeners: 3_415_900),
        Artist(id: "kito", name: "Kito Marsh", bio: "Northside storyteller with a drummer's sense of timing.", monthlyListeners: 2_980_770),
        Artist(id: "aster", name: "Aster & Oleander", bio: "A folk duo who trade verses like postcards.", monthlyListeners: 942_310),
        Artist(id: "vela", name: "Vela Ross", bio: "Big-hearted pop songs with sharp little edges.", monthlyListeners: 8_114_260),
        Artist(id: "monsoon", name: "Monsoon Arcade", bio: "Electro-fusion built from field recordings, tabla and broken synths.", monthlyListeners: 1_560_040),
        Artist(id: "halo", name: "Halo Static", bio: "Synthwave for empty highways and full ashtrays.", monthlyListeners: 3_770_650),
        Artist(id: "junie", name: "Junie Bloom", bio: "Bedroom pop about softness, snacks and saying the wrong thing.", monthlyListeners: 5_206_780),
        Artist(id: "coldframe", name: "Cold Frame", bio: "Post-rock instrumentals for weather that refuses to decide.", monthlyListeners: 688_990),
        Artist(id: "tara", name: "Tara Bose", bio: "Host of Signal & Noise, a weekly show about the technology we live inside.", monthlyListeners: 410_220),
        Artist(id: "kabir", name: "Kabir Sen", bio: "Film critic and host of The Long Rewind.", monthlyListeners: 358_640),
        Artist(id: "mira", name: "Mira Shah", bio: "Night-shift storyteller. Host of Small Hours.", monthlyListeners: 289_115),
        Artist(id: "owen", name: "Owen Pike", bio: "Field recordist and host of Field Notes.", monthlyListeners: 174_530)
    ]

    private static let artistIndex: [String: Artist] = Dictionary(uniqueKeysWithValues: artists.map { ($0.id, $0) })

    static func artist(_ id: String) -> Artist {
        artistIndex[id] ?? artists[0]
    }

    // MARK: - Tracks

    static let tracks: [Track] = [
        make("t01", "Paper Crown", "neveah", "Paper Crown", "3:42", 1),
        make("t02", "Honey Static", "neveah", "Paper Crown", "3:18", 2),
        make("t03", "Blue Hour Confessional", "neveah", "Paper Crown", "4:05", 3, explicit: true),
        make("t04", "Runway Lights", "neveah", "Paper Crown", "3:29", 4),
        make("t05", "Half a Mind", "neveah", "Paper Crown", "3:02", 5),

        make("t06", "Sunday Furniture", "glasshouse", "Porchlight", "3:51", 6),
        make("t07", "Kitchen Window", "glasshouse", "Porchlight", "3:24", 7),
        make("t08", "Porchlight Choir", "glasshouse", "Porchlight", "4:12", 8),
        make("t09", "Everything We Borrowed", "glasshouse", "Porchlight", "3:47", 9),

        make("t10", "Neon Monsoon", "orin", "Neon Monsoon", "3:58", 10),
        make("t11", "Glass District", "orin", "Neon Monsoon", "4:26", 11),
        make("t12", "Night Bus 74", "orin", "Neon Monsoon", "5:02", 12),
        make("t13", "Low Orbit", "orin", "Neon Monsoon", "4:14", 13),

        make("t14", "Salt in the Wiring", "papertide", "Harbor Kids", "3:36", 14, explicit: true),
        make("t15", "Harbor Kids", "papertide", "Harbor Kids", "4:02", 15),
        make("t16", "Static on the Coast", "papertide", "Harbor Kids", "3:55", 16),
        make("t17", "Tin Roof Anthem", "papertide", "Harbor Kids", "3:28", 1),

        make("t18", "Velvet Patience", "saffron", "Velvet Patience", "3:44", 2),
        make("t19", "Slow Burn Reply", "saffron", "Velvet Patience", "4:08", 3, explicit: true),
        make("t20", "Peach Ember", "saffron", "Velvet Patience", "3:21", 4),
        make("t21", "Blue Room Theory", "saffron", "Velvet Patience", "4:31", 5),

        make("t22", "Corner Store Prophet", "kito", "Northside Gospel", "2:58", 6, explicit: true),
        make("t23", "Highway Grammar", "kito", "Northside Gospel", "3:12", 7, explicit: true),
        make("t24", "Loose Change Sermon", "kito", "Northside Gospel", "3:33", 8),
        make("t25", "Northside Gospel", "kito", "Northside Gospel", "3:05", 9, explicit: true),

        make("t26", "Foxglove", "aster", "Paper Garden", "3:40", 10),
        make("t27", "Two Rivers, One Coat", "aster", "Paper Garden", "4:22", 11),
        make("t28", "Winter Orchard", "aster", "Paper Garden", "3:57", 12),
        make("t29", "Moss & Copper", "aster", "Paper Garden", "4:11", 13),

        make("t30", "Superimposed", "vela", "Superimposed", "3:16", 14),
        make("t31", "Cherry Static", "vela", "Superimposed", "3:03", 15),
        make("t32", "Glitter on the Freeway", "vela", "Superimposed", "3:38", 16),
        make("t33", "TV Blue", "vela", "Superimposed", "3:27", 1),

        make("t34", "Monsoon Arcade", "monsoon", "Monsoon Arcade", "4:34", 2),
        make("t35", "Cardamom Circuit", "monsoon", "Monsoon Arcade", "3:49", 3),
        make("t36", "Rooftop Rain", "monsoon", "Monsoon Arcade", "4:07", 4),
        make("t37", "Deccan Nightdrive", "monsoon", "Monsoon Arcade", "4:52", 5),

        make("t38", "Midnight Arcade", "halo", "Midnight Arcade", "4:18", 6),
        make("t39", "Chrome Sunset", "halo", "Midnight Arcade", "3:59", 7),
        make("t40", "VHS Heartbeat", "halo", "Midnight Arcade", "4:03", 8),
        make("t41", "Afterglow Protocol", "halo", "Midnight Arcade", "4:44", 9),

        make("t42", "Slow Bloom", "junie", "Slow Bloom", "3:19", 10),
        make("t43", "Tangerine Pajamas", "junie", "Slow Bloom", "2:52", 11),
        make("t44", "Wish You Were Soft", "junie", "Slow Bloom", "3:34", 12),

        make("t45", "Pale Architecture", "coldframe", "Pale Architecture", "6:12", 13),
        make("t46", "Snow on the Overpass", "coldframe", "Pale Architecture", "5:47", 14),

        make("t47", "The Quiet Algorithm", "tara", "Signal & Noise", "8:12", 15),
        make("t48", "Why We Rewatch", "kabir", "The Long Rewind", "7:45", 16),
        make("t49", "Night Shift Stories: 4 a.m.", "mira", "Small Hours", "9:03", 1),
        make("t50", "Field Notes from a Rooftop", "owen", "Field Notes", "6:28", 2),
        make("t51", "The Cost of Convenience", "tara", "Signal & Noise", "7:30", 3),
        make("t52", "Soundtracks We Outgrew", "kabir", "The Long Rewind", "8:02", 4),
        make("t53", "Closing Time", "mira", "Small Hours", "6:55", 5),
        make("t54", "Monsoon, Recorded", "owen", "Field Notes", "5:44", 6)
    ]

    private static let trackIndex: [String: Track] = Dictionary(uniqueKeysWithValues: tracks.map { ($0.id, $0) })

    static func track(_ id: String) -> Track? {
        trackIndex[id]
    }

    static let defaultLikedIDs: Set<String> = ["t01", "t02", "t10", "t18", "t30", "t42"]

    static func likedCollection(_ ids: Set<String>) -> Collection {
        let ordered = tracks.filter { ids.contains($0.id) }.map { $0.id }
        return Collection(
            id: "liked",
            title: "Liked Songs",
            kind: .playlist,
            owner: appOwner,
            blurb: "Everything you've hearted, in one place.",
            saves: 0,
            trackIDs: ordered,
            order: 0
        )
    }

    static func collections(byArtist name: String) -> [Collection] {
        collections.filter { $0.owner == name }
    }

    // MARK: - Lyrics

    private static let lyricPool: [String] = [
        "I keep the city in my pocket",
        "Every neon light is a promise",
        "We were younger than the radio",
        "Hold the door, the night is coming",
        "Nothing here is built to last",
        "I learned to dance in the hallway",
        "Say it slower, say it true",
        "You are the weather I believe in",
        "Static on the kitchen radio",
        "I'll meet you where the sidewalk ends",
        "Blue hour, blue heart, blue everything",
        "Turn the porchlight on for me",
        "All my friends are turning into songs",
        "Time is a river with a bad memory",
        "We only break what we can carry",
        "I don't mind the quiet anymore",
        "Somewhere a kettle starts to sing",
        "Half of me is still on that bus",
        "Keep the engine running, love",
        "Let the rain write the chorus",
        "Every ending has a softer version",
        "Call it morning when it hurts less",
        "I fold the daylight into letters",
        "Nobody knows the second verse",
        "We are the echo, not the sound",
        "Take the long way, take your time",
        "Put your hands where the light is",
        "Everything is louder in the dark"
    ]

    static func lyrics(for track: Track) -> [LyricLine] {
        let offset = Int(tunelyHash(track.id) % UInt64(lyricPool.count))
        var texts: [String] = [track.title]
        texts.append("[Verse 1]")
        for i in 0..<5 {
            texts.append(lyricPool[(offset + i) % lyricPool.count])
        }
        texts.append("[Chorus]")
        for i in 5..<9 {
            texts.append(lyricPool[(offset + i) % lyricPool.count])
        }
        texts.append("\(track.title) — \(track.artist.name)")
        for i in 9..<12 {
            texts.append(lyricPool[(offset + i) % lyricPool.count])
        }
        texts.append("[Outro]")
        texts.append(lyricPool[(offset + 12) % lyricPool.count])

        let step = 0.9 / Double(max(texts.count - 1, 1))
        return texts.enumerated().map { index, text in
            LyricLine(id: index, at: 0.015 + Double(index) * step, text: text)
        }
    }

    // MARK: - Helpers

    private static func make(
        _ id: String,
        _ title: String,
        _ artistID: String,
        _ album: String,
        _ length: String,
        _ audioIndex: Int,
        explicit: Bool = false
    ) -> Track {
        let parts = length.split(separator: ":").map(String.init).compactMap(Int.init)
        let seconds = parts.count >= 2 ? parts[0] * 60 + parts[1] : (parts.first ?? 0)
        return Track(
            id: id,
            title: title,
            artistID: artistID,
            album: album,
            duration: seconds,
            explicit: explicit,
            audioIndex: audioIndex
        )
    }
}
