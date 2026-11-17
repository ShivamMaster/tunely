import SwiftUI

struct SeekSectionView: View {
    @ObservedObject var player: PlaybackController
    @Binding var scrubFraction: Double?

    var body: some View {
        VStack(spacing: 2) {
            ScrubBar(progress: scrubFraction ?? player.progress, accent: Theme.accent) { fraction in
                if let fraction {
                    scrubFraction = fraction
                } else {
                    if let value = scrubFraction {
                        player.seek(to: value)
                    }
                    scrubFraction = nil
                }
            }
            HStack {
                Text(Format.clock((scrubFraction ?? player.progress) * player.duration))
                    .accessibilityIdentifier("player-elapsed")
                Spacer()
                Text("-" + Format.clock(max(0, player.duration - (scrubFraction ?? player.progress) * player.duration)))
            }
            .font(.system(size: 11, weight: .medium).monospacedDigit())
            .foregroundStyle(Theme.text.opacity(0.6))
        }
        .padding(.top, 14)
    }
}

struct TransportControlsView: View {
    @ObservedObject var player: PlaybackController

    var body: some View {
        HStack(spacing: 0) {
            Button {
                player.toggleShuffle()
            } label: {
                Image(systemName: "shuffle")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(player.shuffle ? Theme.accent : Theme.text.opacity(0.9))
                    .frame(width: 48, height: 48)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .sensoryFeedback(.selection, trigger: player.shuffle)
            .accessibilityLabel("Shuffle")

            Spacer(minLength: 0)

            Button {
                player.previous()
            } label: {
                Image(systemName: "backward.fill")
                    .font(.system(size: 26, weight: .medium))
                    .foregroundStyle(Theme.text)
                    .frame(width: 54, height: 54)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Previous track")

            Spacer(minLength: 0)

            Button {
                player.togglePlayPause()
            } label: {
                ZStack {
                    Circle()
                        .fill(Theme.text)
                        .frame(width: 72, height: 72)
                    Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 27, weight: .bold))
                        .foregroundStyle(Theme.bgDeep)
                        .offset(x: player.isPlaying ? 0 : 2)
                }
            }
            .buttonStyle(PressableButtonStyle())
            .sensoryFeedback(.impact(weight: .medium), trigger: player.isPlaying)
            .accessibilityLabel(player.isPlaying ? "Pause" : "Play")

            Spacer(minLength: 0)

            Button {
                player.next()
            } label: {
                Image(systemName: "forward.fill")
                    .font(.system(size: 26, weight: .medium))
                    .foregroundStyle(Theme.text)
                    .frame(width: 54, height: 54)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Next track")

            Spacer(minLength: 0)

            Button {
                player.cycleRepeat()
            } label: {
                Image(systemName: player.repeatMode.symbol)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(player.repeatMode == .off ? Theme.text.opacity(0.9) : Theme.accent)
                    .frame(width: 48, height: 48)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .sensoryFeedback(.selection, trigger: player.repeatMode)
            .accessibilityLabel("Repeat \(player.repeatMode.rawValue)")
        }
        .padding(.top, 8)
    }
}

struct NowPlayingBottomBar: View {
    @ObservedObject var player: PlaybackController
    @Binding var showDevices: Bool
    @Binding var showQueue: Bool
    let shareText: String

    private var upcomingCount: Int { player.upcomingTracks.count }

    var body: some View {
        HStack {
            Button {
                showDevices = true
            } label: {
                HStack(spacing: 7) {
                    Image(systemName: player.outputDevice.symbol)
                        .font(.system(size: 14, weight: .semibold))
                    Text(player.outputDevice.name)
                        .font(Typo.medium(12))
                        .lineLimit(1)
                }
                .foregroundStyle(Theme.text.opacity(0.8))
                .padding(.horizontal, 12)
                .frame(height: 34)
                .background(Color.white.opacity(0.08))
                .clipShape(Capsule())
            }
            .buttonStyle(PressableButtonStyle())
            .accessibilityLabel("Choose playback device")

            Spacer()

            Button {
                showQueue = true
            } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Theme.text.opacity(0.8))
                        .frame(width: 44, height: 44)
                    if upcomingCount > 0 {
                        Text("\(min(upcomingCount, 99))")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(Theme.bgDeep)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Theme.accent)
                            .clipShape(Capsule())
                            .offset(x: 8, y: 0)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(PressableButtonStyle())
            .accessibilityLabel("Queue, \(upcomingCount) tracks up next")

            if player.current != nil {
                ShareLink(item: shareText) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Theme.text.opacity(0.8))
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Share track")
            }
        }
        .padding(.top, 18)
    }
}
