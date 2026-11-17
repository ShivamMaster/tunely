import SwiftUI

struct DevicesSheet: View {
    @EnvironmentObject private var player: PlaybackController
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Connect to a device")
                .font(Typo.bold(21))
                .foregroundStyle(Theme.text)
                .padding(.horizontal, 20)
                .padding(.top, 22)
                .padding(.bottom, 10)

            ForEach(Fixtures.devices) { device in
                Button {
                    player.setDevice(device)
                    dismiss()
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: device.symbol)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(player.outputDevice == device ? Theme.accent : Theme.secondary)
                            .frame(width: 28)
                        Text(device.name)
                            .font(Typo.medium(15))
                            .foregroundStyle(Theme.text)
                        Spacer()
                        if player.outputDevice == device {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(Theme.accent)
                        }
                    }
                    .padding(.horizontal, 20)
                    .frame(height: 52)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface)
    }
}
