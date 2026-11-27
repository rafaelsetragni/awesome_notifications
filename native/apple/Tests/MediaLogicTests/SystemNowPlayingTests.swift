import MediaPlayer
import ObjectiveC
import XCTest
@testable import IosAwnCore
@testable import MediaLogic

/// A position change at `positionTime` (the system's events have no public
/// initializer; this one is allocated through the runtime).
private final class PositionEvent: MPChangePlaybackPositionCommandEvent {
    override var positionTime: TimeInterval { 12.3456 }
}

/// The end of a press-and-hold seek.
private final class EndSeekEvent: MPSeekCommandEvent {
    override var type: MPSeekCommandEventType { .endSeeking }
}

/// The start of a press-and-hold seek.
private final class BeginSeekEvent: MPSeekCommandEvent {
    override var type: MPSeekCommandEventType { .beginSeeking }
}

private func makeEvent<T: MPRemoteCommandEvent>(_ type: T.Type) -> T {
    return class_createInstance(type, 0) as! T
}

/// The system's Now Playing (`MPNowPlayingInfoCenter` + `MPRemoteCommandCenter`)
/// driven by the media sessions, on macOS where the test runs.
final class SystemNowPlayingTests: XCTestCase {

    private func session(_ overrides: [String: Any] = [:]) -> (MediaSession, [String: Any]) {
        var media: [String: Any] = [
            "sessionId": "system", "title": "Wonderwall", "artist": "Bright Sharp",
            "album": "Morning", "duration": 258_000, "position": 10_000, "playbackSpeed": 1.0,
            "state": "playing", "controls": ["play", "pause", "skipForward", "skipBackward", "seekTo"],
            "skipInterval": 15_000, "commandTarget": "actionEvent"
        ]
        for (key, value) in overrides { media[key] = value }
        let model: [String: Any] = [
            "content": ["id": 300, "channelKey": "media_player", "notificationLayout": "MediaPlayer"],
            "media": media
        ]
        return try! MediaBuilder.prepare(model)!
    }

    private var commands: MPRemoteCommandCenter { .shared() }
    private var info: MPNowPlayingInfoCenter { .default() }

    override func tearDown() {
        // Leave the host's Now Playing as it was.
        SystemNowPlaying { _, _ in .success }.show(nil, artwork: nil)
        super.tearDown()
    }

    func testShowsTheSessionAndEnablesOnlyItsCommands() throws {
        var received: [RemoteCommand] = []
        let surface = SystemNowPlaying { command, _ in received.append(command); return .success }
        let (media, _) = session()
        surface.show(media, artwork: nil)

        XCTAssertTrue(commands.playCommand.isEnabled)
        XCTAssertTrue(commands.pauseCommand.isEnabled)
        XCTAssertTrue(commands.togglePlayPauseCommand.isEnabled)
        XCTAssertTrue(commands.skipForwardCommand.isEnabled)
        XCTAssertTrue(commands.skipBackwardCommand.isEnabled)
        XCTAssertTrue(commands.changePlaybackPositionCommand.isEnabled)
        XCTAssertFalse(commands.nextTrackCommand.isEnabled)
        XCTAssertFalse(commands.previousTrackCommand.isEnabled)
        XCTAssertFalse(commands.stopCommand.isEnabled)
        XCTAssertFalse(commands.seekForwardCommand.isEnabled)
        XCTAssertFalse(commands.seekBackwardCommand.isEnabled)
        XCTAssertEqual(commands.skipForwardCommand.preferredIntervals, [15])
        XCTAssertEqual(commands.skipBackwardCommand.preferredIntervals, [15])

        let shown = try XCTUnwrap(info.nowPlayingInfo)
        XCTAssertEqual(shown[MPMediaItemPropertyTitle] as? String, "Wonderwall")
        XCTAssertEqual(shown[MPNowPlayingInfoPropertyElapsedPlaybackTime] as? Double, 10)
        #if os(macOS)
        XCTAssertEqual(info.playbackState, .playing)
        #endif

        surface.updateElapsed(milliseconds: 42_500)
        XCTAssertEqual(info.nowPlayingInfo?[MPNowPlayingInfoPropertyElapsedPlaybackTime] as? Double, 42.5)
        XCTAssertEqual(info.nowPlayingInfo?[MPMediaItemPropertyTitle] as? String, "Wonderwall")

        // A new session replaces the targets: only its commands stay enabled.
        let (paused, _) = session(["state": "paused", "controls": ["stop", "skipNext", "fastForward"]])
        surface.show(paused, artwork: nil)
        XCTAssertFalse(commands.playCommand.isEnabled)
        XCTAssertTrue(commands.stopCommand.isEnabled)
        XCTAssertTrue(commands.nextTrackCommand.isEnabled)
        XCTAssertTrue(commands.seekForwardCommand.isEnabled)
        #if os(macOS)
        XCTAssertEqual(info.playbackState, .paused)
        #endif

        // Cleared: nothing shown, every command off, elapsed updates ignored.
        surface.show(nil, artwork: nil)
        XCTAssertNil(info.nowPlayingInfo)
        for kind in RemoteCommand.allCases {
            XCTAssertFalse(SystemNowPlaying.command(kind, in: commands).isEnabled, "\(kind)")
        }
        #if os(macOS)
        XCTAssertEqual(info.playbackState, .stopped)
        #endif
        surface.updateElapsed(milliseconds: 1_000)
        XCTAssertNil(info.nowPlayingInfo)
    }

    func testAnEnabledCommandCallsBackWithItsKind() throws {
        var received: [RemoteCommand] = []
        let surface = SystemNowPlaying { command, event in
            received.append(command)
            return event is PositionEvent ? .success : .commandFailed
        }
        let (media, _) = session()
        surface.show(media, artwork: nil)

        // What the system does when the user presses the command.
        typealias Invoke = @convention(c) (AnyObject, Selector, AnyObject, AnyObject?) -> Void
        let selector = NSSelectorFromString("invokeCommandWithEvent:completion:")
        let command = commands.changePlaybackPositionCommand
        guard command.responds(to: selector) else { throw XCTSkip("no invokeCommandWithEvent on this OS") }
        let invoke = unsafeBitCast(command.method(for: selector), to: Invoke.self)
        let completion: @convention(block) (UnsafeRawPointer?) -> Void = { _ in }
        invoke(command, selector, makeEvent(PositionEvent.self), completion as AnyObject)
        let deadline = Date().addingTimeInterval(2)
        while received.isEmpty && Date() < deadline {
            RunLoop.current.run(until: Date().addingTimeInterval(0.01))
        }
        XCTAssertEqual(received, [.changePlaybackPosition])
        surface.show(nil, artwork: nil)
    }

    func testEveryCommandMapsToItsSystemCommand() {
        let expected: [(RemoteCommand, MPRemoteCommand)] = [
            (.play, commands.playCommand), (.pause, commands.pauseCommand),
            (.togglePlayPause, commands.togglePlayPauseCommand), (.stop, commands.stopCommand),
            (.nextTrack, commands.nextTrackCommand), (.previousTrack, commands.previousTrackCommand),
            (.skipForward, commands.skipForwardCommand), (.skipBackward, commands.skipBackwardCommand),
            (.changePlaybackPosition, commands.changePlaybackPositionCommand),
            (.seekForward, commands.seekForwardCommand), (.seekBackward, commands.seekBackwardCommand)
        ]
        for (kind, command) in expected {
            XCTAssertTrue(SystemNowPlaying.command(kind, in: commands) === command, "\(kind)")
        }
    }

    func testArtworkLoadsFromAMediaSource() {
        XCTAssertNil(NowPlaying.artwork(from: nil))
        XCTAssertNil(NowPlaying.artwork(from: "file:///no/such/cover.png"))
        #if os(macOS)
        let artwork = NowPlaying.artwork(from: "resource://" + NSImage.computerName)
        XCTAssertNotNil(artwork)
        XCTAssertGreaterThan(artwork?.bounds.width ?? 0, 0)
        XCTAssertNotNil(artwork?.image(at: CGSize(width: 8, height: 8)))
        #endif
    }

    // MARK: - System events reaching the sessions

    func testSystemEventsReachTheOwnerSession() {
        var dispatched: [[String]] = []
        let store = MediaSessions(surface: { _ in SystemNowPlaying { _, _ in .success } },
                                  dispatch: { _, key, input, _ in dispatched.append([key, input ?? "-"]) })
        // No owner yet.
        XCTAssertEqual(store.handle(.play, event: makeEvent(BeginSeekEvent.self)), .noActionableNowPlayingItem)

        let (media, model) = session()
        store.update(media, model: model, artwork: nil)
        XCTAssertEqual(store.handle(.changePlaybackPosition, event: makeEvent(PositionEvent.self)), .success)
        XCTAssertEqual(dispatched.last, ["awn.media.seekTo", "12346"], "seconds → rounded milliseconds")

        // The end of a hold-to-seek is acknowledged without a new action.
        XCTAssertEqual(store.handle(.seekForward, event: makeEvent(EndSeekEvent.self)), .success)
        XCTAssertEqual(dispatched.count, 1)
        // Its start is a fastForward.
        XCTAssertEqual(store.handle(.seekForward, event: makeEvent(BeginSeekEvent.self)), .success)
        XCTAssertEqual(dispatched.last, ["awn.media.fastForward", "-"])
        store.stop("system")
    }

    func testTheDefaultSessionsUseTheSystemAndTheCore() {
        final class Recorder: AwesomeEventListener {
            var events: [(String, [String: Any])] = []
            func onNewAwesomeEvent(eventType: String, content: [String: Any]) {
                events.append((eventType, content))
            }
        }
        let recorder = Recorder()
        AwesomeEventsReceiver.shared.subscribe(listener: recorder)
        defer { AwesomeEventsReceiver.shared.unsubscribe(listener: recorder) }

        let store = MediaSessions()
        let (media, model) = session()
        store.update(media, model: model, artwork: nil)
        XCTAssertEqual(info.nowPlayingInfo?[MPMediaItemPropertyTitle] as? String, "Wonderwall")

        // A command becomes the core's silent action event of the notification.
        XCTAssertTrue(store.handle(.pause))
        XCTAssertEqual(recorder.events.map { $0.0 }, [Definitions.EVENT_DEFAULT_ACTION])
        XCTAssertEqual(recorder.events.first?.1[Definitions.NOTIFICATION_BUTTON_KEY_PRESSED] as? String,
                       "awn.media.pause")
        XCTAssertEqual(recorder.events.first?.1[Definitions.NOTIFICATION_ID] as? Int, 300)
        XCTAssertEqual(recorder.events.first?.1[Definitions.NOTIFICATION_ACTION_TYPE] as? String, "SilentAction")

        store.stop("system")
        XCTAssertNil(info.nowPlayingInfo)
    }

    func testTheDefaultBuilderUsesTheSharedSessions() throws {
        let builder = MediaBuilder(inner: NotificationBuilder(), loadArtwork: false)
        let (_, model) = session(["sessionId": "shared-test"])
        let built = try XCTUnwrap(builder.build(model: model))
        XCTAssertTrue(built.isHandled)
        XCTAssertEqual(MediaSessions.shared.ownerId, "shared-test")
        MediaSessions.shared.stop("shared-test")
        XCTAssertNil(MediaSessions.shared.ownerId)
    }
}
