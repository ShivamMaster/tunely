import Foundation

struct SpotifyPlaylist: Identifiable, Decodable, Hashable {
    struct Owner: Decodable, Hashable {
        let displayName: String?
    }

    struct Image: Decodable, Hashable {
        let url: URL
        let width: Int?
        let height: Int?
    }

    struct Tracks: Decodable, Hashable {
        let total: Int?
    }

    let id: String
    let name: String
    let owner: Owner?
    let images: [Image]?
    let tracks: Tracks?
    let uri: String?
    let externalURLs: [String: String]?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case owner
        case images
        case tracks
        case uri
        case externalURLs = "external_urls"
    }

    var ownerName: String {
        owner?.displayName ?? "Spotify"
    }

    var trackCount: Int {
        tracks?.total ?? 0
    }

    var imageURL: URL? {
        images?.first?.url
    }

    var spotifyURL: URL {
        if let uri, let url = URL(string: uri) {
            return url
        }
        if let external = externalURLs?["spotify"], let url = URL(string: external) {
            return url
        }
        return webURL
    }

    var webURL: URL {
        URL(string: "https://open.spotify.com/playlist/\(id)")!
    }
}

enum SpotifyWebAPIError: LocalizedError {
    case invalidResponse
    case expiredSession
    case forbidden
    case server(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Spotify returned an unexpected response."
        case .expiredSession:
            return "Your Spotify session expired. Reconnect to refresh your playlists."
        case .forbidden:
            return "Spotify didn't allow this app to read your playlists. Check that playlist-read-private is granted."
        case .server(let message):
            return message
        }
    }
}

struct SpotifyWebAPI {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func playlists(accessToken: String) async throws -> [SpotifyPlaylist] {
        var components = URLComponents(string: "https://api.spotify.com/v1/me/playlists")!
        components.queryItems = [
            URLQueryItem(name: "limit", value: "50")
        ]
        guard let url = components.url else {
            throw SpotifyWebAPIError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 20
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw SpotifyWebAPIError.invalidResponse
        }

        guard (200..<300).contains(http.statusCode) else {
            switch http.statusCode {
            case 401:
                throw SpotifyWebAPIError.expiredSession
            case 403:
                throw SpotifyWebAPIError.forbidden
            default:
                let message = (try? JSONDecoder().decode(ErrorEnvelope.self, from: data))?.error.message
                throw SpotifyWebAPIError.server(message ?? "Spotify returned HTTP \(http.statusCode).")
            }
        }

        do {
            let page = try JSONDecoder().decode(PlaylistPage.self, from: data)
            return page.items.compactMap { $0 }
        } catch {
            throw SpotifyWebAPIError.invalidResponse
        }
    }
}

private struct PlaylistPage: Decodable {
    let items: [SpotifyPlaylist?]
}

private struct ErrorEnvelope: Decodable {
    struct APIError: Decodable {
        let message: String
    }

    let error: APIError
}
