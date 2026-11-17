import SwiftUI

struct QueueView: View {
    @EnvironmentObject private var player: PlaybackController
    @Environment(\.dismiss) private var dismiss
    @State private var editMode: EditMode = .inactive

    private var upcoming: [Track] { player.upcomingTracks }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if let current = player.current {
                        QueueCurrentRow(track: current, isPlaying: player.isPlaying)
                            .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                            .listRowBackground(Theme.bg)
                            .listRowSeparator(.hidden)
                    }
                } header: {
                    sectionLabel("NOW PLAYING")
                }

                Section {
                    if upcoming.isEmpty {
                        EmptyStateView(
                            symbol: "text.line.last.and.arrowtriangle.forward",
                            title: "Nothing up next",
                            message: "Add tracks from any playlist and they'll wait here."
                        )
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    } else {
                        ForEach(Array(upcoming.enumerated()), id: \.offset) { offset, track in
                            Button {
                                player.jumpToUpcoming(at: offset)
                            } label: {
                                QueueTrackRow(track: track)
                            }
                            .buttonStyle(.plain)
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                            .listRowBackground(Theme.bg)
                        }
                        .onMove { source, destination in
                            withAnimation(.snappy(duration: 0.22)) {
                                player.moveUpcoming(fromOffsets: source, toOffset: destination)
                            }
                        }
                    }
                } header: {
                    HStack {
                        sectionLabel("NEXT UP")
                        Spacer()
                        Text(upcoming.count == 1 ? "1 track" : "\(upcoming.count) tracks")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Theme.tertiary)
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Theme.bg)
            .environment(\.editMode, $editMode)
            .navigationTitle("Queue")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.bg, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundStyle(Theme.text)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(editMode.isEditing ? "Done" : "Reorder") {
                        withAnimation(.snappy(duration: 0.22)) {
                            editMode = editMode.isEditing ? .inactive : .active
                        }
                    }
                    .foregroundStyle(Theme.accent)
                    .disabled(upcoming.count < 2)
                }
            }
        }
        .sensoryFeedback(.selection, trigger: editMode.isEditing)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .bold))
            .tracking(1.2)
            .foregroundStyle(Theme.secondary)
            .textCase(nil)
    }
}

private struct QueueCurrentRow: View {
    let track: Track
    let isPlaying: Bool

    var body: some View {
        HStack(spacing: 12) {
            ArtworkView(
                seed: track.artworkSeed,
                title: track.album,
                cornerRadius: 5,
                showsMonogram: false
            )
            .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    EqualizerBars(isPlaying: isPlaying)
                    Text(track.title)
                        .font(Typo.semibold(15))
                        .foregroundStyle(Theme.accent)
                        .lineLimit(1)
                    if track.explicit {
                        ExplicitBadge()
                    }
                }
                Text(track.artist.name)
                    .font(Typo.regular(12))
                    .foregroundStyle(Theme.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            Text(track.durationLabel)
                .font(.system(size: 11, weight: .medium).monospacedDigit())
                .foregroundStyle(Theme.tertiary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Now playing \(track.title) by \(track.artist.name)")
    }
}

private struct QueueTrackRow: View {
    let track: Track

    var body: some View {
        HStack(spacing: 12) {
            ArtworkView(
                seed: track.artworkSeed,
                title: track.album,
                cornerRadius: 5,
                showsMonogram: false
            )
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 3) {
                Text(track.title)
                    .font(Typo.medium(15))
                    .foregroundStyle(Theme.text)
                    .lineLimit(1)
                Text(track.artist.name)
                    .font(Typo.regular(12))
                    .foregroundStyle(Theme.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            Text(track.durationLabel)
                .font(.system(size: 11, weight: .medium).monospacedDigit())
                .foregroundStyle(Theme.tertiary)
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(track.title) by \(track.artist.name). Play now")
    }
}
