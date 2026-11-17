import AVFAudio
import Foundation

/// Watches the shared audio session for interruptions and output-device loss.
/// Callbacks are delivered on the main queue.
final class AudioSessionObserver {
    var onInterruptionBegan: (() -> Void)?
    var onInterruptionEnded: ((Bool) -> Void)?
    var onOutputDisconnected: (() -> Void)?

    private var tokens: [NSObjectProtocol] = []
    private let center = NotificationCenter.default

    init() {
        tokens.append(center.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard
                let self,
                let rawType = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
                let type = AVAudioSession.InterruptionType(rawValue: rawType)
            else { return }

            switch type {
            case .began:
                self.onInterruptionBegan?()
            case .ended:
                let rawOptions = notification.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
                let options = AVAudioSession.InterruptionOptions(rawValue: rawOptions)
                self.onInterruptionEnded?(options.contains(.shouldResume))
            @unknown default:
                break
            }
        })

        tokens.append(center.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard
                let self,
                let rawReason = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt,
                let reason = AVAudioSession.RouteChangeReason(rawValue: rawReason)
            else { return }

            if reason == .oldDeviceUnavailable {
                self.onOutputDisconnected?()
            }
        })
    }

    deinit {
        for token in tokens {
            center.removeObserver(token)
        }
    }
}
