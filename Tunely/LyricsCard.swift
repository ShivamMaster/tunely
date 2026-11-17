import SwiftUI

struct LyricsCard: View {
    @EnvironmentObject private var player: PlaybackController
    let track: Track

    private var lines: [LyricLine] { Fixtures.lyrics(for: track) }

    private var activeIndex: Int {
        let progress = player.progress
        var found = 0
        for line in lines where progress >= line.at {
            found = line.id
        }
        return found
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text("Lyrics")
                    .font(Typo.bold(16))
                    .foregroundStyle(Theme.text)
                Text("LIVE")
                    .font(.system(size: 8, weight: .heavy))
                    .tracking(0.8)
                    .foregroundStyle(Theme.bgDeep)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Theme.accent)
                    .clipShape(Capsule())
                Spacer()
                Text(track.title)
                    .font(Typo.regular(11))
                    .foregroundStyle(Theme.text.opacity(0.5))
                    .lineLimit(1)
            }

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(lines) { line in
                            Text(line.text)
                                .font(Typo.bold(17))
                                .foregroundStyle(line.id == activeIndex ? Theme.text : Theme.text.opacity(0.38))
                                .scaleEffect(line.id == activeIndex ? 1.01 : 1, anchor: .leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .id(line.id)
                        }
                    }
                    .padding(.vertical, 8)
                }
                .scrollIndicators(.hidden)
                .frame(height: 156)
                .onAppear {
                    proxy.scrollTo(activeIndex, anchor: .center)
                }
                .onChange(of: activeIndex) { _, newValue in
                    withAnimation(.snappy(duration: 0.3)) {
                        proxy.scrollTo(newValue, anchor: .center)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.white.opacity(0.06), lineWidth: 0.5)
        }
        .animation(.snappy(duration: 0.25), value: activeIndex)
    }
}
