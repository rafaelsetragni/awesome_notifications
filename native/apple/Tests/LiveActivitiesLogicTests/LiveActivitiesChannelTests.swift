import XCTest
@testable import IosAwnCore
@testable import LiveActivitiesLogic
import AwesomeNotificationsLiveActivitiesWidget

private final class ChannelFakeSystem: LiveActivitySystem {
    var areEnabled = true
    var supportsButtons = false
    var pushToStartToken: String?
    var shown: [String: LiveActivityStatus] = [:]
    var ended: [(String, LiveActivityDismissal)] = []
    var tokens: [String: String] = [:]

    func show(attributes: AwnLiveActivityAttributes, state: AwnLiveActivityState,
              activity: NotificationLiveActivity, alert: LiveActivityAlert?) throws {
        shown[attributes.activityId] = .active
    }
    func end(_ activityId: String, state: AwnLiveActivityState?, dismissal: LiveActivityDismissal) {
        ended.append((activityId, dismissal))
        shown[activityId] = .ended
    }
    func activities() -> [(activityId: String, status: LiveActivityStatus)] {
        shown.map { ($0.key, $0.value) }
    }
    func pushToken(_ activityId: String) -> String? { tokens[activityId] }
}

/// The live activities' method channel, the default manager and installer,
/// and the widget's helpers.
final class LiveActivitiesChannelTests: XCTestCase {

    private var system: ChannelFakeSystem!
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        FakeNotificationCenter.install()
        CriticalAlertUtils.setCache(false)
        system = ChannelFakeSystem()
        defaults = UserDefaults(suiteName: "LiveActivitiesChannelTests")
        defaults.removePersistentDomain(forName: "LiveActivitiesChannelTests")
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: "LiveActivitiesChannelTests")
        CriticalAlertUtils.clearCache()
        super.tearDown()
    }

    private func manager(withSystem: Bool = true) -> LiveActivityManager {
        let system = self.system!
        return LiveActivityManager(
            system: { _ in withSystem ? system : nil },
            dispatch: { _, _ in },
            removeNotification: { _ in },
            timer: { seconds, fire in DispatchLiveActivityTimer(seconds: seconds, fire: fire) },
            now: Date.init,
            store: LiveActivityModelStore(defaults: defaults))
    }

    private func model(id: Int, block: [String: Any] = [:]) -> [String: Any] {
        ["content": ["id": id, "channelKey": "live", "title": "Order", "body": "On the way"],
         "liveActivity": block.merging(["state": "active"]) { mine, _ in mine }]
    }

    private func call(_ handler: LiveActivityMethodHandler, _ method: String,
                      _ arguments: Any? = nil) -> (handled: Bool, value: Any?) {
        var value: Any?
        var answers = 0
        let handled = handler.handle(method: method, arguments: arguments) { value = $0; answers += 1 }
        XCTAssertEqual(answers, handled ? 1 : 0, method)
        return (handled, value)
    }

    // MARK: - Method channel

    func testTheChannelAnswersFromTheManager() throws {
        let manager = self.manager()
        let handler = LiveActivityMethodHandler(manager: { manager })
        let prepared = try XCTUnwrap(LiveActivityNotifications.prepare(model(id: 5, block: ["activityId": "ride"])))
        XCTAssertTrue(manager.applyActivity(
            prepared, attributes: AwnLiveActivityAttributes(activityId: "ride"),
            state: LiveActivityNotifications.contentState(prepared)))

        XCTAssertEqual(call(handler, LiveActivityKeys.methodList).value as? [[String: String]],
                       [["activityId": "ride", "state": "active"]])
        XCTAssertEqual(call(handler, LiveActivityKeys.methodCapabilities).value as? [String: Bool], [
            "systemSurface": true, "progressSegments": true, "metrics": true, "buttons": false, "push": true
        ])
        XCTAssertEqual(call(handler, LiveActivityKeys.methodAreEnabled).value as? Bool, true)
        system.areEnabled = false
        // macOS has no Settings page to send the user to: it answers at once.
        XCTAssertEqual(call(handler, LiveActivityKeys.methodRequestPermission).value as? Bool, false)

        XCTAssertNil(call(handler, LiveActivityKeys.methodPushToStartToken).value)
        manager.systemPushToStartToken("start-token")
        XCTAssertEqual(call(handler, LiveActivityKeys.methodPushToStartToken).value as? String, "start-token")

        system.tokens["ride"] = "ride-token"
        XCTAssertEqual(call(handler, LiveActivityKeys.methodPushToken, ["activityId": "ride"]).value as? String,
                       "ride-token")
        XCTAssertNil(call(handler, LiveActivityKeys.methodPushToken, [String: Any]()).value)

        // End: immediately, or as the system decides when the dismissal is unknown.
        let end = call(handler, LiveActivityKeys.methodEnd, ["activityId": "ride", "dismissal": "immediate"])
        XCTAssertTrue(end.handled)
        XCTAssertNil(end.value)
        XCTAssertEqual(system.ended.map { $0.0 }, ["ride"])
        XCTAssertEqual(system.ended.last?.1, .immediate)
        _ = call(handler, LiveActivityKeys.methodEnd, ["activityId": "other", "dismissal": "whenever"])
        XCTAssertEqual(system.ended.last?.0, "other")
        XCTAssertEqual(system.ended.last?.1, .system)
        // Without an activity: nothing ends.
        _ = call(handler, LiveActivityKeys.methodEnd, "not a map")
        XCTAssertEqual(system.ended.count, 2)

        XCTAssertFalse(call(handler, "liveActivityNoSuchMethod").handled)
    }

    func testTheChannelWorksOffTheMainThread() {
        let manager = self.manager(withSystem: false)
        let handler = LiveActivityMethodHandler(manager: { manager })
        let done = expectation(description: "answered")
        var capabilities: Any?
        DispatchQueue.global().async {
            _ = handler.handle(method: LiveActivityKeys.methodCapabilities, arguments: nil) {
                capabilities = $0
                done.fulfill()
            }
        }
        wait(for: [done], timeout: 5)
        // Without the system: shown as notifications, which have buttons.
        XCTAssertEqual(capabilities as? [String: Bool], [
            "systemSurface": false, "progressSegments": false, "metrics": false, "buttons": true, "push": false
        ])
    }

    // MARK: - Timers

    func testADispatchTimerFiresOnMainUnlessCancelled() {
        let fired = expectation(description: "fired")
        var firedOnMain = false
        let timer = DispatchLiveActivityTimer(seconds: -5) {
            firedOnMain = Thread.isMainThread
            fired.fulfill()
        }
        wait(for: [fired], timeout: 2)
        XCTAssertTrue(firedOnMain)
        timer.cancel()

        var cancelledFired = false
        let cancelled = DispatchLiveActivityTimer(seconds: 0.05) { cancelledFired = true }
        cancelled.cancel()
        cancelled.cancel()
        RunLoop.current.run(until: Date().addingTimeInterval(0.15))
        XCTAssertFalse(cancelledFired)
    }

    // MARK: - The default manager

    func testTheDefaultManagerShowsNotificationsAndUsesTheCore() throws {
        let manager = LiveActivityManager()
        manager.start()
        XCTAssertNil(manager.system, "no ActivityKit on macOS")
        XCTAssertEqual(manager.presentation(for: "default-1"), .notification)
        XCTAssertTrue(manager.areEnabled)

        let prepared = try XCTUnwrap(LiveActivityNotifications.prepare(model(id: 61, block: ["activityId": "default-1"])))
        guard case .post = manager.applyNotification(prepared) else { return XCTFail("posts its notification") }
        XCTAssertEqual(manager.entry("default-1")?.presentation, .notification)
        XCTAssertNil(manager.entry("unknown"))

        // A button is the core's action event (auto-dismissing its notification).
        let recorder = EventRecorder()
        AwesomeEventsReceiver.shared.subscribe(listener: recorder)
        defer { AwesomeEventsReceiver.shared.unsubscribe(listener: recorder) }
        manager.buttonPressed("default-1", buttonKey: "OPEN")
        XCTAssertEqual(recorder.names, [Definitions.EVENT_DEFAULT_ACTION])
        XCTAssertEqual(recorder.events[0].data[Definitions.NOTIFICATION_BUTTON_KEY_PRESSED] as? String, "OPEN")
        XCTAssertEqual(FakeNotificationCenter.shared.read { $0.removedDelivered }, [["61"]])

        // Ending at once removes its notification from the center.
        manager.end("default-1", dismissal: .immediate)
        XCTAssertEqual(FakeNotificationCenter.shared.read { $0.removedDelivered }.last, ["61"])
        XCTAssertNil(manager.entry("default-1"))
    }

    func testTheCoreRemovalHookEndsActivitiesOnAnyThread() throws {
        let manager = self.manager(withSystem: false)
        var events: [[String: Any]] = []
        manager.eventSink = { events.append($0) }
        for (id, activityId) in [(71, "a"), (72, "b")] {
            let prepared = try XCTUnwrap(LiveActivityNotifications.prepare(model(id: id, block: ["activityId": activityId])))
            _ = manager.applyNotification(prepared)
        }

        manager.onNotificationsRemoved(.id(71), cancel: false)
        XCTAssertNil(manager.entry("a"))
        XCTAssertNotNil(manager.entry("b"))

        let done = expectation(description: "removed")
        DispatchQueue.global().async {
            manager.onNotificationsRemoved(.all, cancel: true)
            DispatchQueue.main.async { done.fulfill() }
        }
        wait(for: [done], timeout: 5)
        XCTAssertNil(manager.entry("b"))
        XCTAssertEqual(events.compactMap { $0["state"] as? String }, ["ended", "dismissed", "ended", "dismissed"])
    }

    // MARK: - Installer and builder

    func testTheInstallerWiresThePackageOnce() throws {
        NotificationBuilderRegistry.shared.clearForTest()
        defer {
            NotificationBuilderRegistry.shared.clearForTest()
            AwesomeMethodHandlerRegistry.shared.unregister(handler: LiveActivitiesInstaller.methodHandler)
            NotificationRemovalRegistry.shared.unregister(listener: LiveActivityManager.shared)
            AwnLiveActivityButtons.handler = nil
        }
        let done = expectation(description: "installed")
        DispatchQueue.global().async {
            LiveActivitiesInstaller.install()
            done.fulfill()
        }
        wait(for: [done], timeout: 5)
        LiveActivitiesInstaller.install()  // idempotent

        // The builder joined the chain: a live activity is shown as a notification here.
        let built = try XCTUnwrap(NotificationBuilderRegistry.shared.makeBuilder().build(
            model: model(id: 81, block: ["activityId": "installed"])))
        XCTAssertFalse(built.isHandled)
        XCTAssertEqual(built.id, 81)

        // Its methods answer through the core's router.
        var capabilities: Any?
        XCTAssertTrue(AwesomeMethodRouter.shared.handle(
            method: LiveActivityKeys.methodCapabilities, arguments: nil) { capabilities = $0 })
        XCTAssertEqual((capabilities as? [String: Bool])?["systemSurface"], false)

        // An activity's button reaches the core.
        let recorder = EventRecorder()
        AwesomeEventsReceiver.shared.subscribe(listener: recorder)
        defer { AwesomeEventsReceiver.shared.unsubscribe(listener: recorder) }
        AwnLiveActivityButtons.press(activityId: "installed", buttonKey: "STOP")
        XCTAssertEqual(recorder.events.first?.data[Definitions.NOTIFICATION_BUTTON_KEY_PRESSED] as? String, "STOP")
        XCTAssertNotNil(AwnLiveActivityButtons.handler)

        // The core's removals end it.
        AwesomeNotifications.shared.cancel(id: 81)
        XCTAssertNil(LiveActivityManager.shared.entry("installed"))
    }

    func testAnActivityTheSystemShowsPostsNothing() throws {
        let manager = self.manager()
        let builder = LiveActivityBuilder(
            inner: NotificationBuilder(), manager: { manager }, images: { LiveActivityImageStore(appGroup: nil) })
        let built = try XCTUnwrap(builder.build(model: model(id: 91, block: ["activityId": "shown"])))
        XCTAssertTrue(built.isHandled)
        XCTAssertEqual(system.shown["shown"], .active)
        let content = built.model["content"] as? [String: Any]
        XCTAssertNotNil(content?[Definitions.NOTIFICATION_DISPLAYED_DATE], "reported displayed as a posted one")
    }

    func testAnActivityEndedAtOnceAsANotificationPostsNothing() throws {
        let manager = self.manager(withSystem: false)
        let builder = LiveActivityBuilder(
            inner: NotificationBuilder(), manager: { manager }, images: { LiveActivityImageStore(appGroup: nil) })
        _ = try builder.build(model: model(id: 92, block: ["activityId": "gone"]))
        XCTAssertNotNil(manager.entry("gone"))

        let built = try XCTUnwrap(builder.build(
            model: model(id: 92, block: ["activityId": "gone", "state": "ended", "dismissal": "immediate"])))
        XCTAssertTrue(built.isHandled, "nothing to post: the notification is removed")
        XCTAssertNil(manager.entry("gone"))
    }

    // MARK: - Models and widget helpers

    func testMalformedProgressAndDismissals() {
        func error(_ block: [String: Any]) -> String? {
            do { _ = try LiveActivityNotifications.prepare(model(id: 1, block: block)); return nil }
            catch let e as AwesomeNotificationsException { return e.detailedCode }
            catch { return "other" }
        }
        XCTAssertEqual(error(["progress": ["segments": [["color": 1]]]]), "arguments.invalid.notificationLiveActivity")
        XCTAssertEqual(error(["progress": ["segments": ["not a map"]]]), "arguments.invalid.notificationLiveActivity")
        XCTAssertEqual(error(["progress": ["points": [["color": 1]]]]), "arguments.invalid.notificationLiveActivity")
        XCTAssertNil(LiveActivityDismissal.parse([1000]))
        XCTAssertNil(LiveActivityDismissal.parse(Date()))
    }

    func testWidgetStateHelpers() {
        var state = AwnLiveActivityState()
        XCTAssertNil(state.accentComponents)
        XCTAssertNil(state.timerStartDate)
        XCTAssertEqual(state.totalLength, 100)

        state.accentColor = Int(0x80FF0000)
        let accent = state.accentComponents
        XCTAssertEqual(accent?.red, 1)
        XCTAssertEqual(accent?.green, 0)
        XCTAssertEqual(accent?.blue, 0)
        XCTAssertEqual(accent?.opacity ?? 0, 128.0 / 255, accuracy: 0.0001)

        state.timerStart = 1_500
        XCTAssertEqual(state.timerStartDate, Date(timeIntervalSince1970: 1.5))

        state.segments = [.init(length: 30), .init(length: -5), .init(length: 20)]
        XCTAssertEqual(state.totalLength, 50, "negative lengths count as zero")
        state.segments = [.init(length: 0)]
        XCTAssertEqual(state.totalLength, 100)
    }

    func testImageFilesNeedAPlainNameAndAnAppGroup() {
        XCTAssertNil(AwnLiveActivityImages.file(nil, appGroup: "group.test"))
        XCTAssertNil(AwnLiveActivityImages.file("", appGroup: "group.test"))
        XCTAssertNil(AwnLiveActivityImages.file("../escape.png", appGroup: "group.test"))
        XCTAssertNil(AwnLiveActivityImages.file("ok.png", appGroup: nil))
        XCTAssertNil(AwnLiveActivityImages.directory(appGroup: ""))
    }
}
