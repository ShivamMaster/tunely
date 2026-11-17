import SwiftUI

struct ShelfView: View {
    let title: String
    let collections: [Collection]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(title: title)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 14) {
                    ForEach(collections) { collection in
                        NavigationLink(value: Route.collection(collection)) {
                            ShelfCard(collection: collection)
                        }
                        .buttonStyle(PressableButtonStyle())
                    }
                }
                .padding(.trailing, 8)
            }
            .scrollClipDisabled()
        }
    }
}

struct ShelfCard: View {
    let collection: Collection

    private var subtitle: String {
        switch collection.kind {
        case .mix: return Fixtures.mixSubtitle(collection)
        case .podcast, .album: return collection.owner
        case .playlist: return collection.owner
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ArtworkView(seed: collection.artworkSeed, title: collection.title, cornerRadius: 10)
                .frame(width: 150, height: 150)
                .shadow(color: .black.opacity(0.35), radius: 8, y: 4)
            Text(collection.title)
                .font(Typo.semibold(14))
                .foregroundStyle(Theme.text)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .frame(height: 36, alignment: .topLeading)
            Text(subtitle)
                .font(Typo.regular(12))
                .foregroundStyle(Theme.secondary)
                .lineLimit(1)
        }
        .frame(width: 150, alignment: .leading)
        .contentShape(Rectangle())
    }
}

struct QuickPickTile: View {
    let collection: Collection

    var body: some View {
        NavigationLink(value: Route.collection(collection)) {
            HStack(spacing: 10) {
                ArtworkView(
                    seed: collection.artworkSeed,
                    title: collection.title,
                    cornerRadius: 6,
                    showsMonogram: false
                )
                .frame(width: 52, height: 52)

                Text(collection.title)
                    .font(Typo.semibold(13))
                    .foregroundStyle(Theme.text)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Spacer(minLength: 0)
            }
            .padding(6)
            .background(Theme.surfaceRaised)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(PressableButtonStyle())
    }
}

struct LibraryTile: View {
    let collection: Collection

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ArtworkView(seed: collection.artworkSeed, title: collection.title, cornerRadius: 9)
                .aspectRatio(1, contentMode: .fit)
                .shadow(color: .black.opacity(0.3), radius: 6, y: 3)
            Text(collection.title)
                .font(Typo.semibold(14))
                .foregroundStyle(Theme.text)
                .lineLimit(1)
            Text(collection.subtitle)
                .font(Typo.regular(12))
                .foregroundStyle(Theme.secondary)
                .lineLimit(1)
        }
        .contentShape(Rectangle())
    }
}

struct LibraryRow: View {
    let collection: Collection

    var body: some View {
        HStack(spacing: 12) {
            ArtworkView(
                seed: collection.artworkSeed,
                title: collection.title,
                cornerRadius: 6,
                showsMonogram: false
            )
            .frame(width: 52, height: 52)
            VStack(alignment: .leading, spacing: 3) {
                Text(collection.title)
                    .font(Typo.semibold(14))
                    .foregroundStyle(Theme.text)
                    .lineLimit(1)
                Text(collection.subtitle)
                    .font(Typo.regular(12))
                    .foregroundStyle(Theme.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .contentShape(Rectangle())
    }
}
