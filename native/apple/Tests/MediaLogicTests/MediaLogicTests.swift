import MediaPlayer
import XCTest
@testable import IosAwnCore
@testable import MediaLogic

private final class FakeSurface: NowPlayingSurface {
    var shown: [MediaSession?] = []
    var elapsed: [Int] = []
    func show(_ session: MediaSession?, artwork: MPMediaItemArtwork?) { shown.append(session) }
    func updateElapsed(milliseconds: Int) { elapsed.append(milliseconds) }
}

final class MediaLogicTests: XCTestCase {

    private func media(_ overrides: [String: Any] = [:]) -> [String: Any] {
        var map: [String: Any] = [
            "sessionId": "main", "title": "Champagne Supernova", "artist": "Bright Sharp",
            "album": "Morning", "duration": 261_000, "position": 37_000, "playbackSpeed": 1.0,
            "state": "playing", "controls": ["play", "pause", "skipNext"],
            "skipInterval": 15_000, "commandTarget": "actionEvent"
        ]
        for (key, value) in overrides { map[key] = value }
        return map
    }

    private func model(layout: String? = "MediaPlayer", media: [String: Any]?,
                       content extra: [String: Any] = [:]) -> [String: Any] {
        var content: [String: Any] = ["id": 100, "channelKey": "media_player"]
        if let layout = layout { content["notificationLayout"] = layout }
        for (key, value) in extra { content[key] = value }
        var model: [String: Any] = ["content": content]
        if let media = media { model["media"] = media }
        return model
    }

    private func detail(_ model: [String: Any]) -> String? {
        do {
            _ = try MediaBuilder.prepare(model)
            return nil
        } catch let e as AwesomeNotificationsException {
            return e.detailedCode
        } catch {
            return "other"
        }
    }

    // MARK: - Validation

    func testTheLayoutRequiresMedia() {
        XCTAssertEqual(detail(model(media: nil)), "arguments.invalid.notificationMedia")
    }

    func testMediaRequiresTheLayout() {
        XCTAssertEqual(detail(model(layout: "BigPicture", media: media())),
                       "arguments.invalid.notificationMedia.layout")
        XCTAssertEqual(detail(model(layout: nil, media: media())),
                       "arguments.invalid.notificationMedia.layout")
    }

    func testOtherModelsAreUntouched() throws {
        XCTAssertNil(try MediaBuilder.prepare(model(layout: "Default", media: nil)))
        let built = try MediaBuilder(inner: NotificationBuilder(), loadArtwork: false)
            .build(model: model(layout: "Default", media: nil))
        XCTAssertNotNil(built)
        XCTAssertFalse(built!.isHandled)
    }

    func testInvalidBlocksAreRejected() {
        let invalid: [[String: Any]] = [
            ["sessionId": " "], ["title": ""], ["position": -1], ["duration": 0],
            ["position": 300_000], ["playbackSpeed": -1.0], ["skipInterval": 0],
            ["state": "dancing"], ["controls": ["play", "shuffle"]], ["commandTarget": "nowhere"]
        ]
        for overrides in invalid {
            XCTAssertEqual(detail(model(media: media(overrides))), "arguments.invalid.notificationMedia",
                           "\(overrides)")
        }
        XCTAssertNil(detail(model(media: media())))
    }

    func testALiveStreamHasNoDuration() {
        var map = media()
        map.removeValue(forKey: "duration")
        let (session, error) = MediaSession.parse(map)
        XCTAssertNil(error)
        XCTAssertNil(session?.duration)
        XCTAssertEqual(NowPlaying.info(for: session!)[MPNowPlayingInfoPropertyIsLiveStream] as? Bool, true)
        XCTAssertNil(NowPlaying.info(for: session!)[MPMediaItemPropertyPlaybackDuration])
    }

    // MARK: - Content

    func testTitleBodyAndPayloadAreFilled() throws {
        let (_, prepared) = try XCTUnwrap(MediaBuilder.prepare(
            model(media: media(), content: ["payload": ["song": "42"]])))
        let content = prepared["content"] as! [String: Any]
        XCTAssertEqual(content["title"] as? String, "Champagne Supernova")
        XCTAssertEqual(content["body"] as? String, "Bright Sharp")
        let payload = content["payload"] as! [String: Any]
        XCTAssertEqual(payload["mediaSessionId"] as? String, "main")
        XCTAssertEqual(payload["song"] as? String, "42")
    }

    func testTheContentKeepsItsOwnTitleAndBody() throws {
        let (_, prepared) = try XCTUnwrap(MediaBuilder.prepare(
            model(media: media(), content: ["title": "Radio", "body": "Live"])))
        let content = prepared["content"] as! [String: Any]
        XCTAssertEqual(content["title"] as? String, "Radio")
        XCTAssertEqual(content["body"] as? String, "Live")
    }

    func testAMediaModelPostsNothing() throws {
        let sessions = MediaSessions(surface: { _ in FakeSurface() }, dispatch: { _, _, _, _ in })
        let built = try MediaBuilder(inner: NotificationBuilder(), sessions: { sessions }, loadArtwork: false)
            .build(model: model(media: media()))
        XCTAssertEqual(built?.isHandled, true)
        XCTAssertEqual(built?.id, 100)
        // Built on the main thread (the test's), the session is shown at once.
        XCTAssertEqual(sessions.ownerId, "main")
    }

    // MARK: - Now Playing

    func testNowPlayingInfoMapping() throws {
        let session = try XCTUnwrap(MediaSession.parse(media(["playbackSpeed": 1.5])).0)
        let info = NowPlaying.info(for: session)
        XCTAssertEqual(info[MPMediaItemPropertyTitle] as? String, "Champagne Supernova")
        XCTAssertEqual(info[MPMediaItemPropertyArtist] as? String, "Bright Sharp")
        XCTAssertEqual(info[MPMediaItemPropertyAlbumTitle] as? String, "Morning")
        XCTAssertEqual(info[MPMediaItemPropertyPlaybackDuration] as? Double, 261)
        XCTAssertEqual(info[MPNowPlayingInfoPropertyElapsedPlaybackTime] as? Double, 37)
        XCTAssertEqual(info[MPNowPlayingInfoPropertyPlaybackRate] as? Double, 1.5)
        XCTAssertEqual(info[MPNowPlayingInfoPropertyDefaultPlaybackRate] as? Double, 1.0)
        XCTAssertEqual(info[MPNowPlayingInfoPropertyIsLiveStream] as? Bool, false)
    }

    func testTheRateIsZeroWhenNotPlaying() throws {
        let paused = try XCTUnwrap(MediaSession.parse(media(["state": "paused", "playbackSpeed": 1.0])).0)
        XCTAssertEqual(NowPlaying.info(for: paused)[MPNowPlayingInfoPropertyPlaybackRate] as? Double, 0)
        var noSpeed = media(["state": "paused"])
        noSpeed.removeValue(forKey: "playbackSpeed")
        XCTAssertEqual(MediaSession.parse(noSpeed).0?.playbackSpeed, 0)
    }

    #if os(macOS)
    func testMacPlaybackState() {
        XCTAssertEqual(NowPlaying.playbackState(for: .playing), .playing)
        XCTAssertEqual(NowPlaying.playbackState(for: .paused), .paused)
        XCTAssertEqual(NowPlaying.playbackState(for: .stopped), .stopped)
        XCTAssertEqual(NowPlaying.playbackState(for: .buffering), .interrupted)
    }
    #endif

    // MARK: - Commands

    func testCommandsFollowTheControls() {
        XCTAssertEqual(NowPlaying.commands(for: [.play, .pause]), [.play, .pause, .togglePlayPause])
        XCTAssertEqual(NowPlaying.commands(for: [.pause]), [.pause])
        XCTAssertEqual(NowPlaying.commands(for: [.stop, .seekTo, .fastForward, .rewind]),
                       [.stop, .changePlaybackPosition, .seekForward, .seekBackward])
        XCTAssertEqual(NowPlaying.commands(for: []), [])
    }

    func testTrackSkipsWinTheirSlot() {
        XCTAssertEqual(NowPlaying.commands(for: [.skipForward, .skipBackward]), [.skipForward, .skipBackward])
        XCTAssertEqual(NowPlaying.commands(for: [.skipNext, .skipForward, .skipBackward]),
                       [.nextTrack, .skipBackward])
        XCTAssertEqual(NowPlaying.commands(for: [.skipNext, .skipPrevious, .skipForward, .skipBackward]),
                       [.nextTrack, .previousTrack])
    }

    func testTogglePlayPauseFollowsTheState() {
        XCTAssertEqual(NowPlaying.control(for: .togglePlayPause, state: .playing), .pause)
        XCTAssertEqual(NowPlaying.control(for: .togglePlayPause, state: .paused), .play)
        XCTAssertEqual(NowPlaying.control(for: .seekForward, state: .playing), .fastForward)
        XCTAssertEqual(NowPlaying.control(for: .previousTrack, state: .playing), .skipPrevious)
    }

    func testActionData() {
        let seek = MediaSessions.action(.seekTo, position: 90_500)
        XCTAssertEqual(seek.key, "awn.media.seekTo")
        XCTAssertEqual(seek.input, "90500")
        XCTAssertEqual(seek.button["key"] as? String, "awn.media.seekTo")
        XCTAssertEqual(seek.button["actionType"] as? String, "SilentAction")
        XCTAssertEqual(seek.button["autoDismissible"] as? Bool, false)
        XCTAssertNil(MediaSessions.action(.pause, position: 3).input)
    }

    /// The core turns the synthetic button into a silent action that keeps
    /// the notification.
    func testTheCoreEventOfACommand() throws {
        let (_, prepared) = try XCTUnwrap(MediaBuilder.prepare(model(media: media())))
        let action = MediaSessions.action(.seekTo, position: 1_000)
        let event = NotificationBuilder().controlEvent(
            model: prepared, buttonKey: action.key, input: action.input, button: action.button,
            lifeCycle: .foreground)
        XCTAssertEqual(event.eventName, Definitions.EVENT_DEFAULT_ACTION)
        XCTAssertNil(event.dismissId)
        XCTAssertEqual(event.data["buttonKeyPressed"] as? String, "awn.media.seekTo")
        XCTAssertEqual(event.data["buttonKeyInput"] as? String, "1000")
        XCTAssertEqual(event.data["actionType"] as? String, "SilentAction")
        XCTAssertEqual((event.data["payload"] as? [String: Any])?["mediaSessionId"] as? String, "main")
    }

    // MARK: - Sessions

    private func sessions(_ surface: FakeSurface, dispatched: @escaping ([String]) -> Void = { _ in })
        -> MediaSessions {
        MediaSessions(surface: { _ in surface }, dispatch: { _, key, input, _ in
            dispatched([key, input ?? "-"])
        })
    }

    private func session(_ overrides: [String: Any] = [:]) -> (MediaSession, [String: Any]) {
        try! MediaBuilder.prepare(model(media: media(overrides)))!
    }

    func testCommandsReachTheirTargets() {
        let surface = FakeSurface()
        var dispatched: [[String]] = []
        var streamed: [[String: Any]] = []
        let store = sessions(surface) { dispatched.append($0) }
        store.streamSink = { streamed.append($0) }

        XCTAssertFalse(store.handle(.pause))  // no session yet

        let (actionOnly, model) = session()
        store.update(actionOnly, model: model, artwork: nil)
        XCTAssertTrue(store.handle(.togglePlayPause))
        XCTAssertEqual(dispatched, [["awn.media.pause", "-"]])
        XCTAssertTrue(streamed.isEmpty)

        let (both, bothModel) = session(["commandTarget": "both"])
        store.update(both, model: bothModel, artwork: nil)
        store.handle(.changePlaybackPosition, position: 42_000)
        XCTAssertEqual(dispatched.last, ["awn.media.seekTo", "42000"])
        XCTAssertEqual(streamed.last?["control"] as? String, "seekTo")
        XCTAssertEqual(streamed.last?["sessionId"] as? String, "main")
        XCTAssertEqual(streamed.last?["position"] as? Int, 42_000)

        let (stream, streamModel) = session(["commandTarget": "stream"])
        store.update(stream, model: streamModel, artwork: nil)
        store.handle(.nextTrack, position: 5)
        XCTAssertEqual(dispatched.count, 2)
        XCTAssertEqual(streamed.last?["control"] as? String, "skipNext")
        XCTAssertNil(streamed.last?["position"])

        store.streamSink = nil  // Dart stopped listening
        XCTAssertTrue(store.handle(.pause))
        XCTAssertEqual(streamed.count, 2)
    }

    func testTheLastSessionUpdatedOwnsNowPlaying() {
        let surface = FakeSurface()
        let store = sessions(surface)
        let (a, aModel) = session(["sessionId": "a"])
        let (b, bModel) = session(["sessionId": "b"])
        store.update(a, model: aModel, artwork: nil)
        store.update(b, model: bModel, artwork: nil)
        XCTAssertEqual(store.ownerId, "b")

        // Stopping a session that doesn't own Now Playing leaves it alone.
        store.stop("a")
        XCTAssertEqual(surface.shown.count, 2)
        store.updatePosition("a", position: 1)
        XCTAssertTrue(surface.elapsed.isEmpty)

        store.updatePosition("b", position: 90_000)
        XCTAssertEqual(surface.elapsed, [90_000])
        XCTAssertEqual(store.session("b")?.position, 90_000)
        XCTAssertEqual(store.session("b")?.state, .playing)
        store.updatePosition("b", position: 999_999)
        XCTAssertEqual(surface.elapsed.last, 261_000)  // clamped to the duration

        store.stop("b")
        XCTAssertNil(store.ownerId)
        XCTAssertEqual(surface.shown.count, 3)
        XCTAssertNil(surface.shown.last!)
        XCTAssertFalse(store.handle(.play))
    }

    func testMethodHandler() {
        let surface = FakeSurface()
        let store = sessions(surface)
        let (a, aModel) = session()
        store.update(a, model: aModel, artwork: nil)
        let handler = MediaMethodHandler(sessions: { store })

        var answers: [Any?] = []
        XCTAssertTrue(handler.handle(method: "mediaUpdatePosition",
                                     arguments: ["sessionId": "main", "position": 12_000]) { answers.append($0) })
        XCTAssertEqual(surface.elapsed, [12_000])
        XCTAssertTrue(handler.handle(method: "mediaCapabilities", arguments: nil) { answers.append($0) })
        let capabilities = answers.last as? [String: Bool]
        XCTAssertEqual(capabilities?["seekBar"], true)
        XCTAssertEqual(capabilities?["customButtons"], false)
        #if os(macOS)
        XCTAssertEqual(capabilities?["lockScreen"], false)
        #else
        XCTAssertEqual(capabilities?["lockScreen"], true)
        #endif
        XCTAssertTrue(handler.handle(method: "mediaStop", arguments: "main") { answers.append($0) })
        XCTAssertNil(store.ownerId)
        XCTAssertFalse(handler.handle(method: "chatCapabilities", arguments: nil) { _ in })
        XCTAssertEqual(answers.count, 3)
        XCTAssertNil(answers[0] ?? nil)
    }
}
