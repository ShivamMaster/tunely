import SwiftUI
import UIKit

struct ArtworkImage {
    let size: Int
    let dataURL: String
}

/// Renders the same generated cover used in the app into data URLs that can be
/// handed to the Media Session API for the lock screen and Control Center.
enum ArtworkRenderer {
    private final class Payload: NSObject {
        let images: [ArtworkImage]

        init(images: [ArtworkImage]) {
            self.images = images
        }
    }

    private static let cache: NSCache<NSString, Payload> = {
        let cache = NSCache<NSString, Payload>()
        cache.countLimit = 6
        return cache
    }()

    @MainActor
    static func images(for seed: String, title: String?) -> [ArtworkImage]? {
        let key = "\(seed)|\(title ?? "")" as NSString
        if let cached = cache.object(forKey: key) {
            return cached.images
        }

        let view = ArtworkView(seed: seed, title: title, cornerRadius: 0)
            .frame(width: 1024, height: 1024)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 1
        renderer.isOpaque = true

        guard let base = renderer.uiImage else { return nil }

        let images = [512, 256, 128].compactMap { size -> ArtworkImage? in
            guard let data = jpegData(from: base, size: CGFloat(size)) else { return nil }
            return ArtworkImage(
                size: size,
                dataURL: "data:image/jpeg;base64,\(data.base64EncodedString())"
            )
        }
        guard !images.isEmpty else { return nil }

        cache.setObject(Payload(images: images), forKey: key)
        return images
    }

    @MainActor
    private static func jpegData(from image: UIImage, size: CGFloat) -> Data? {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(
            size: CGSize(width: size, height: size),
            format: format
        )
        let scaled = renderer.image { _ in
            image.draw(in: CGRect(x: 0, y: 0, width: size, height: size))
        }
        return scaled.jpegData(compressionQuality: 0.9)
    }
}
