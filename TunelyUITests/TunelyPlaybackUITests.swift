import XCTest

final class TunelyPlaybackUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitest-autoplay", "--uitest-remote-bridge"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app.terminate()
    }

    func testPlaybackContinuesWhenBackgrounded() throws {
        let before = try startPlaybackAndOpenNowPlaying()

        XCUIDevice.shared.press(.home)
        Thread.sleep(forTimeInterval: 4)
        app.activate()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5))

        let elapsed = app.staticTexts["player-elapsed"]
        XCTAssertTrue(elapsed.waitForExistence(timeout: 5))
        let after = clockSeconds(elapsed.label)
        XCTAssertGreaterThanOrEqual(
            after,
            before + 2,
            "Playback did not advance while backgrounded (before \(before)s, after \(after)s)"
        )
    }

    func testRemoteNextAndPreviousControls() throws {
        _ = try startPlaybackAndOpenNowPlaying()
        waitForTitle("Paper Crown")

        // The simulator does not publish lock-screen or Control Center transport
        // controls for WKWebView audio. These buttons invoke the same Media
        // Session next/previous handlers the system remote controls use.
        let next = app.buttons["test-remote-next"]
        XCTAssertTrue(next.waitForExistence(timeout: 5), "Remote next bridge unavailable")
        next.tap()
        waitForTitle("Honey Static")

        let previous = app.buttons["test-remote-previous"]
        XCTAssertTrue(previous.waitForExistence(timeout: 5), "Remote previous bridge unavailable")
        previous.tap()
        waitForTitle("Paper Crown")
    }

    private func startPlaybackAndOpenNowPlaying() throws -> Int {
        let mini = app.descendants(matching: .any)["mini-player"]
        XCTAssertTrue(mini.waitForExistence(timeout: 15), "Playback did not start")
        mini.tap()

        XCTAssertTrue(
            app.staticTexts["now-playing-title"].waitForExistence(timeout: 5),
            "Now Playing did not appear"
        )
        let elapsed = app.staticTexts["player-elapsed"]
        XCTAssertTrue(elapsed.waitForExistence(timeout: 5), "Elapsed time is unavailable")

        let initial = clockSeconds(elapsed.label)
        Thread.sleep(forTimeInterval: 2)
        if clockSeconds(elapsed.label) <= initial {
            let play = app.buttons["Play"].firstMatch
            if play.exists { play.tap() }
            Thread.sleep(forTimeInterval: 2)
        }

        let started = clockSeconds(elapsed.label)
        XCTAssertGreaterThan(
            started,
            initial,
            "Audio did not advance after starting playback (initial \(initial)s, current \(started)s)"
        )
        return started
    }

    private func waitForTitle(_ expected: String) {
        let title = app.staticTexts["now-playing-title"]
        let predicate = NSPredicate(format: "label == %@", expected)
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: title)
        XCTAssertEqual(
            XCTWaiter.wait(for: [expectation], timeout: 5),
            .completed,
            "Now Playing title did not become '\(expected)' (current '\(title.label)')"
        )
    }

    private func clockSeconds(_ label: String) -> Int {
        let parts = label.split(separator: ":").compactMap { Int($0) }
        guard parts.count == 2 else { return -1 }
        return parts[0] * 60 + parts[1]
    }
}
