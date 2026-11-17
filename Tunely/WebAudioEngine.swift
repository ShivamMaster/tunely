import AVFAudio
import SwiftUI
import WebKit

/// Streams audio through a real HTML `<audio>` element inside a WKWebView.
/// No native AVPlayer is used for playback; JavaScript controls the media element
/// and reports timing, playback state and remote commands back over a script message channel.
/// Lock-screen and Control Center controls are provided through WebKit's Media Session API.
final class WebAudioEngine: NSObject, WKScriptMessageHandler, WKNavigationDelegate {
    var onTick: ((Double, Double) -> Void)?
    var onEnded: (() -> Void)?
    var onError: ((String) -> Void)?
    var onPlaybackState: ((Bool) -> Void)?
    var onRemoteCommand: ((String) -> Void)?

    private let webView: WKWebView
    private var isReady = false
    private var pendingScripts: [String] = []

    var surface: WKWebView { webView }

    override init() {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 2, height: 2), configuration: configuration)
        super.init()

        configuration.userContentController.add(self, name: "audio")
        webView.navigationDelegate = self
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.isUserInteractionEnabled = false
        webView.loadHTMLString(Self.playerHTML, baseURL: URL(string: "https://www.soundhelix.com"))

        activateAudioSession()
    }

    func load(url: URL, autoplay: Bool) {
        let autoplayValue = autoplay ? "true" : "false"
        activateAudioSession()
        evaluate("window.tunelyLoad('\(url.absoluteString)', \(autoplayValue));")
    }

    func play() {
        activateAudioSession()
        evaluate("window.tunelyPlay();")
    }

    func pause() {
        evaluate("window.tunelyPause();")
    }

    func seek(to seconds: Double) {
        evaluate("window.tunelySeek(\(String(format: "%.2f", seconds)));")
    }

    func updateNowPlaying(title: String, artist: String, album: String) {
        let script = "window.tunelySetMetadata(\(jsLiteral(title)), \(jsLiteral(artist)), \(jsLiteral(album)));"
        evaluate(script)
    }

    func updateArtwork(_ images: [ArtworkImage]) {
        let entries = images.map { image in
            "{src:\(jsLiteral(image.dataURL)),sizes:'\(image.size)x\(image.size)',type:'image/jpeg'}"
        }
        .joined(separator: ",")
        evaluate("window.tunelySetArtwork([\(entries)]);")
    }

    #if DEBUG
    func simulateRemoteCommand(_ action: String) {
        evaluate("window.tunelySimulateRemote(\(jsLiteral(action)));")
    }
    #endif

    func updatePlaybackState(_ playing: Bool) {
        evaluate("window.tunelySetPlaybackState('\(playing ? "playing" : "paused")');")
    }

    private func activateAudioSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: [])
        try? session.setActive(true, options: [])
    }

    private func jsLiteral(_ value: String) -> String {
        let escaped = value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "'", with: "\\'")
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\r", with: " ")
        return "'\(escaped)'"
    }

    private func evaluate(_ script: String) {
        if isReady {
            webView.evaluateJavaScript(script, completionHandler: nil)
        } else {
            pendingScripts.append(script)
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation?) {
        isReady = true
        let scripts = pendingScripts
        pendingScripts.removeAll()
        for script in scripts {
            webView.evaluateJavaScript(script, completionHandler: nil)
        }
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard
            let body = message.body as? [String: Any],
            let type = body["type"] as? String
        else { return }

        let time = body["t"] as? Double ?? 0
        let total = body["d"] as? Double ?? 0
        let detail = body["message"] as? String ?? "playback-error"

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            switch type {
            case "tick":
                self.onTick?(time, total)
            case "ended":
                self.onEnded?()
            case "error":
                self.onError?(detail)
            case "state":
                let playing = body["playing"] as? Bool ?? false
                self.onPlaybackState?(playing)
            case "remote":
                if let action = body["action"] as? String {
                    self.onRemoteCommand?(action)
                }
            default:
                break
            }
        }
    }

    private static let playerHTML = #"""
    <!doctype html>
    <html>
    <head>
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">
    <style>
      html, body { margin: 0; padding: 0; background: transparent; height: 100%; overflow: hidden; }
      audio { display: none; }
    </style>
    </head>
    <body>
    <audio id="tunely-audio" preload="auto" playsinline></audio>
    <script>
    (function () {
      var audio = document.getElementById('tunely-audio');
      var mediaSessionSupported = ('mediaSession' in navigator);

      try {
        if (navigator.audioSession) { navigator.audioSession.type = 'playback'; }
      } catch (e) {}

      function send(payload) {
        try { window.webkit.messageHandlers.audio.postMessage(payload); } catch (e) {}
      }

      function snapshot() {
        send({
          type: 'tick',
          t: audio.currentTime || 0,
          d: isFinite(audio.duration) ? audio.duration : 0,
          paused: audio.paused
        });
      }

      function syncPlaybackState() {
        if (!mediaSessionSupported) { return; }
        try { navigator.mediaSession.playbackState = audio.paused ? 'paused' : 'playing'; } catch (e) {}
      }

      function updatePositionState() {
        if (!mediaSessionSupported || !navigator.mediaSession.setPositionState) { return; }
        var total = audio.duration;
        if (!isFinite(total) || total <= 0) { return; }
        var position = Math.min(Math.max(audio.currentTime || 0, 0), total);
        try {
          navigator.mediaSession.setPositionState({
            duration: total,
            playbackRate: audio.playbackRate || 1,
            position: position
          });
        } catch (e) {}
      }

      window.tunelyLoad = function (url, autoplay) {
        audio.pause();
        audio.src = url;
        audio.load();
        send({ type: 'loaded' });
        if (autoplay) { window.tunelyPlay(); }
      };

      window.tunelyPlay = function () {
        var promise = audio.play();
        if (promise && promise.catch) {
          promise.catch(function (error) {
            send({ type: 'error', message: String(error) });
          });
        }
      };

      window.tunelyPause = function () { audio.pause(); };

      window.tunelySeek = function (seconds) {
        if (!isFinite(audio.duration)) { return; }
        var target = Math.max(0, Math.min(seconds, Math.max(0, audio.duration - 0.3)));
        try { audio.currentTime = target; } catch (e) {}
        updatePositionState();
        snapshot();
      };

      window.tunelySetMetadata = function (title, artist, album) {
        if (!mediaSessionSupported || !window.MediaMetadata) { return; }
        try {
          navigator.mediaSession.metadata = new MediaMetadata({
            title: title,
            artist: artist,
            album: album
          });
        } catch (e) {}
      };

      window.tunelySetArtwork = function (artworks) {
        if (!mediaSessionSupported || !window.MediaMetadata) { return; }
        var current = navigator.mediaSession.metadata;
        if (!current) { return; }
        try {
          navigator.mediaSession.metadata = new MediaMetadata({
            title: current.title || '',
            artist: current.artist || '',
            album: current.album || '',
            artwork: artworks || []
          });
        } catch (e) {}
      };

      window.tunelySetPlaybackState = function (state) {
        if (!mediaSessionSupported) { return; }
        try { navigator.mediaSession.playbackState = state; } catch (e) {}
      };

      var previousTrackHandler = function () {
        send({ type: 'remote', action: 'previous' });
      };
      var nextTrackHandler = function () {
        send({ type: 'remote', action: 'next' });
      };

      window.tunelySimulateRemote = function (action) {
        if (action === 'next') { nextTrackHandler(); }
        else if (action === 'previous') { previousTrackHandler(); }
      };

      if (mediaSessionSupported) {
        try {
          navigator.mediaSession.setActionHandler('play', function () { window.tunelyPlay(); });
          navigator.mediaSession.setActionHandler('pause', function () { window.tunelyPause(); });
          navigator.mediaSession.setActionHandler('previoustrack', previousTrackHandler);
          navigator.mediaSession.setActionHandler('nexttrack', nextTrackHandler);
          navigator.mediaSession.setActionHandler('seekto', function (details) {
            if (details && typeof details.seekTime === 'number') {
              window.tunelySeek(details.seekTime);
            }
          });
        } catch (e) {}
      }

      audio.addEventListener('play', function () {
        send({ type: 'state', playing: true });
        syncPlaybackState();
        updatePositionState();
        snapshot();
      });
      audio.addEventListener('pause', function () {
        send({ type: 'state', playing: false });
        syncPlaybackState();
        snapshot();
      });
      audio.addEventListener('timeupdate', snapshot);
      audio.addEventListener('durationchange', function () {
        updatePositionState();
        snapshot();
      });
      audio.addEventListener('loadedmetadata', function () {
        updatePositionState();
        syncPlaybackState();
        snapshot();
      });
      audio.addEventListener('seeked', function () {
        updatePositionState();
        snapshot();
      });
      audio.addEventListener('ended', function () {
        send({ type: 'ended', t: 0, d: 0, paused: true });
        syncPlaybackState();
      });
      audio.addEventListener('error', function () {
        send({ type: 'error', message: 'media-error' });
      });

      var positionCounter = 0;
      setInterval(function () {
        snapshot();
        positionCounter += 1;
        if (positionCounter >= 4) {
          positionCounter = 0;
          updatePositionState();
        }
      }, 250);

      snapshot();
      syncPlaybackState();
    })();
    </script>
    </body>
    </html>
    """#
}

struct WebAudioSurface: UIViewRepresentable {
    let webView: WKWebView

    func makeUIView(context: Context) -> WKWebView {
        webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
