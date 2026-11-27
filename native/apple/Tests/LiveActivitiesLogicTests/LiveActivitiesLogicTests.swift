import XCTest
@testable import IosAwnCore
@testable import LiveActivitiesLogic
import AwesomeNotificationsLiveActivitiesWidget

private final class FakeTimer: LiveActivityTimerHandle {
    let seconds: TimeInterval
    let fire: () -> Void
    var cancelled = false
    init(_ seconds: TimeInterval, _ fire: @escaping () -> Void) {
        self.seconds = seconds
        self.fire = fire
    }
    func cancel() { cancelled = true }
}

private final class FakeSystem: LiveActivitySystem {
    var log: [String] = []
    var refuse = false
    var shown: [String: LiveActivityStatus] = [:]
    var lastState: AwnLiveActivityState?
    var lastAlert: LiveActivityAlert?
    var areEnabled = true
    var supportsButtons = true
    var pushToStartToken: String?

    func show(attributes: AwnLiveActivityAttributes, state: AwnLiveActivityState,
              activity: NotificationLiveActivity, alert: LiveActivityAlert?) throws {
        if refuse { throw NSError(domain: "test", code: 1) }
        log.append((shown[attributes.activityId] == .active ? "update " : "start ") + attributes.activityId)
        shown[attributes.activityId] = .active
        lastState = state
        lastAlert = alert
    }
    func end(_ activityId: String, state: AwnLiveActivityState?, dismissal: LiveActivityDismissal) {
        log.append("end \(activityId) \(dismissal)")
        shown[activityId] = dismissal == .immediate ? .dismissed : .ended
        lastState = state
    }
    func activities() -> [(activityId: String, status: LiveActivityStatus)] {
        shown.map { ($0.key, $0.value) }
    }
    func pushToken(_ activityId: String) -> String? { nil }
}

final class LiveActivitiesLogicTests: XCTestCase {

    private var system: FakeSystem!
    private var timers: [FakeTimer] = []
    private var dispatched: [(model: [String: Any], key: String)] = []
    private var removed: [Int] = []
    private var events: [[String: Any]] = []
    private var defaults: UserDefaults!
    private let clock = Date(timeIntervalSince1970: 1_700_000_000)

    override func setUp() {
        super.setUp()
        system = FakeSystem()
        timers = []
        dispatched = []
        removed = []
        events = []
        defaults = UserDefaults(suiteName: "LiveActivitiesLogicTests")
        defaults.removePersistentDomain(forName: "LiveActivitiesLogicTests")
    }

    private func manager(withSystem: Bool = true) -> LiveActivityManager {
        let system = self.system!
        let manager = LiveActivityManager(
            system: { _ in withSystem ? system : nil },
            dispatch: { [unowned self] model, key in self.dispatched.append((model, key)) },
            removeNotification: { [unowned self] id in self.removed.append(id) },
            timer: { [unowned self] seconds, fire in
                let timer = FakeTimer(seconds, fire)
                self.timers.append(timer)
                return timer
            },
            now: { [clock] in clock },
            store: LiveActivityModelStore(defaults: defaults))
        manager.eventSink = { [unowned self] in self.events.append($0) }
        return manager
    }

    private func model(id: Int = 7, block: [String: Any] = [:], title: String = "Order",
                       body: String = "On the way", progress: Double? = 60,
                       buttons: [[String: Any]]? = nil, extra: [String: Any] = [:]) -> [String: Any] {
        var content: [String: Any] = [
            "id": id, "channelKey": "live", "title": title, "body": body, "payload": ["order": "42"]
        ]
        if let progress = progress { content["progress"] = progress }
        var model: [String: Any] = ["content": content, "liveActivity": block.merging(["state": "active"]) { a, _ in a }]
        if let buttons = buttons { model["actionButtons"] = buttons }
        for (key, value) in extra { model[key] = value }
        return model
    }

    private func prepared(_ model: [String: Any]) throws -> LiveActivityNotifications.Prepared {
        try XCTUnwrap(try LiveActivityNotifications.prepare(model))
    }

    private func states(_ id: String) -> [String] {
        events.filter { $0["kind"] as? String == "state" && $0["activityId"] as? String == id }
            .compactMap { $0["state"] as? String }
    }

    private func detailedCode(_ work: () throws -> Void) -> String? {
        do { try work() } catch let error as AwesomeNotificationsException { return error.detailedCode } catch {}
        return nil
    }

    // MARK: - Models and refusals

    func testNoBlockIsNotALiveActivity() throws {
        XCTAssertNil(try LiveActivityNotifications.prepare(["content": ["id": 1]]))
        XCTAssertNil(try LiveActivityNotifications.prepare(["content": ["id": 1], "liveActivity": NSNull()]))
    }

    func testPayloadCarriesTheActivityIdDefaultingToTheNotificationId() throws {
        let plain = try prepared(model())
        XCTAssertEqual(plain.activity.activityId, "7")
        let payload = (plain.model["content"] as? [String: Any])?["payload"] as? [String: Any]
        XCTAssertEqual(payload?["activityId"] as? String, "7")
        XCTAssertEqual(payload?["order"] as? String, "42")
        XCTAssertEqual(try prepared(model(block: ["activityId": "ride-1"])).activity.activityId, "ride-1")
    }

    func testScheduleIsRefused() {
        let code = detailedCode { _ = try LiveActivityNotifications.prepare(model(extra: ["schedule": ["interval": 5]])) }
        XCTAssertEqual(code, "arguments.invalid.notificationLiveActivity.schedule")
    }

    func testInvalidBlocksAreRefused() {
        let invalid: [[String: Any]] = [
            ["activityId": " "],
            ["state": "paused"],
            ["metrics": [["label": "a", "value": "1"], ["label": "b", "value": "2"],
                         ["label": "c", "value": "3"], ["label": "d", "value": "4"]]],
            ["metrics": [["label": "", "value": "1"]]],
            ["shortText": ""],
            ["pushChannel": " "],
            ["progress": ["segments": [["length": 0]]]],
            ["progress": ["segments": [["length": 10]], "points": [["position": 11]]]],
            ["timer": ["start": 2000, "end": 1000, "countDown": true]],
            ["timer": ["countDown": true]],
            ["dismissal": "later"],
            ["layout": "grid"],
            ["customLayout": "Focus-Timer"],
            ["layout": "versus", "metrics": [["label": "a", "value": "1"]]]
        ]
        for block in invalid {
            let code = detailedCode { _ = try LiveActivityNotifications.prepare(model(block: block)) }
            XCTAssertEqual(code, "arguments.invalid.notificationLiveActivity", "\(block)")
        }
        let notAMap = detailedCode {
            _ = try LiveActivityNotifications.prepare(["content": ["id": 1], "liveActivity": "x"])
        }
        XCTAssertEqual(notAMap, "arguments.invalid.notificationLiveActivity")
    }

    func testParsesEveryField() throws {
        let activity = try prepared(model(block: [
            "activityId": "a", "state": "ended",
            "progress": ["segments": [["length": 30, "color": 0xFFFF0000], ["length": 70]],
                         "points": [["position": 30]], "trackerIcon": "asset://car.png"],
            "timer": ["start": 1000, "end": 5000, "countDown": true],
            "metrics": [["label": "Speed", "value": "42", "unit": "km/h"]],
            "shortText": "12 min", "accentColor": 0xFF2196F3, "staleAt": 9000, "relevance": 0.5,
            "alert": true, "dismissal": 12000, "pushChannel": "ch"
        ])).activity
        XCTAssertEqual(activity.state, .ended)
        XCTAssertEqual(activity.progress?.segments, [LiveActivitySegment(length: 30, color: 0xFFFF0000),
                                                     LiveActivitySegment(length: 70, color: nil)])
        XCTAssertEqual(activity.progress?.points, [LiveActivityPoint(position: 30, color: nil)])
        XCTAssertEqual(activity.progress?.total, 100)
        XCTAssertEqual(activity.timer, LiveActivityTimer(start: 1000, end: 5000, countDown: true))
        XCTAssertEqual(activity.metrics, [LiveActivityMetric(label: "Speed", value: "42", unit: "km/h")])
        XCTAssertEqual(activity.accentColor, 0xFF2196F3)
        XCTAssertEqual(activity.staleDate, Date(timeIntervalSince1970: 9))
        XCTAssertEqual(activity.relevance, 0.5)
        XCTAssertTrue(activity.alert)
        XCTAssertEqual(activity.dismissal, .at(Date(timeIntervalSince1970: 12)))
        XCTAssertEqual(activity.pushChannel, "ch")
    }

    func testDismissalMapping() {
        XCTAssertEqual(LiveActivityDismissal.parse(nil), .system)
        XCTAssertEqual(LiveActivityDismissal.parse("default"), .system)
        XCTAssertEqual(LiveActivityDismissal.parse("immediate"), .immediate)
        XCTAssertEqual(LiveActivityDismissal.parse(1_700_000_000_000), .at(Date(timeIntervalSince1970: 1_700_000_000)))
        XCTAssertNil(LiveActivityDismissal.parse("soon"))
        XCTAssertNil(LiveActivityDismissal.parse(true))
        XCTAssertEqual(LiveActivityDismissal.at(Date(timeIntervalSince1970: 2)).wireValue as? Int, 2000)
    }

    // MARK: - Content state (iOS)

    func testContentStateMapsTheLayout() throws {
        let buttons: [[String: Any]] = [
            ["key": "OPEN", "label": "Open"],
            ["key": "STOP", "label": "Stop", "actionType": "SilentAction", "isDangerousOption": true],
            ["key": "OFF", "label": "Off", "enabled": false]
        ]
        let prepared = try prepared(model(block: [
            "progress": ["segments": [["length": 1, "color": 1]], "points": [["position": 1]],
                         "trackerIcon": "asset://t.png", "startIcon": "asset://s.png"],
            "timer": ["end": 5000, "countDown": true],
            "metrics": [["label": "Stops", "value": "2"]],
            "shortText": "5 min", "accentColor": 255
        ], buttons: buttons, extra: [:]))
        var content = prepared.model["content"] as! [String: Any]
        content["largeIcon"] = "https://x/avatar.png"
        let withIcon = LiveActivityNotifications.Prepared(
            activity: prepared.activity, model: prepared.model.merging(["content": content]) { $1 },
            notificationId: 7)
        let state = LiveActivityNotifications.contentState(withIcon) { $0.map { "img:" + $0 } }
        XCTAssertEqual(state.title, "Order")
        XCTAssertEqual(state.body, "On the way")
        XCTAssertEqual(state.progress, 60)
        XCTAssertEqual(state.bar, true)
        XCTAssertEqual(state.segments, [.init(length: 1, color: 1)])
        XCTAssertEqual(state.points, [.init(position: 1)])
        XCTAssertEqual(state.trackerIcon, "img:asset://t.png")
        XCTAssertEqual(state.startIcon, "img:asset://s.png")
        XCTAssertNil(state.endIcon)
        XCTAssertEqual(state.largeIcon, "img:https://x/avatar.png")
        XCTAssertEqual(state.timerEnd, 5000)
        XCTAssertEqual(state.countDown, true)
        XCTAssertEqual(state.metrics, [.init(label: "Stops", value: "2")])
        XCTAssertEqual(state.shortText, "5 min")
        XCTAssertEqual(state.accentColor, 255)
        XCTAssertEqual(state.buttons, [.init(key: "OPEN", label: "Open", openApp: true),
                                       .init(key: "STOP", label: "Stop", destructive: true)])
        XCTAssertNil(state.ended)
        XCTAssertEqual(state.fraction, 0.6)
    }

    func testVersusMapsEachSidesImage() throws {
        let prepared = try prepared(model(block: [
            "layout": "versus",
            "metrics": [["label": "LIO", "value": "1", "image": "https://x/lions.png"],
                        ["label": "EAG", "value": "0", "image": "https://x/eagles.png"]],
            "shortText": "2nd half"
        ]))
        XCTAssertTrue(prepared.activity.versus)
        let state = LiveActivityNotifications.contentState(prepared) { $0.map { "img:" + $0 } }
        XCTAssertEqual(state.layout, "versus")
        XCTAssertTrue(state.isVersus)
        XCTAssertEqual(state.metrics, [.init(label: "LIO", value: "1", image: "img:https://x/lions.png"),
                                       .init(label: "EAG", value: "0", image: "img:https://x/eagles.png")])
        // The standard layout draws no side images: none is stored.
        let standard = try self.prepared(model(block: [
            "metrics": [["label": "LIO", "value": "1", "image": "https://x/lions.png"]]
        ]))
        let plain = LiveActivityNotifications.contentState(standard) { $0.map { "img:" + $0 } }
        XCTAssertNil(plain.layout)
        XCTAssertFalse(plain.isVersus)
        XCTAssertNil(plain.metrics?.first?.image)
    }

    func testCustomLayoutReachesTheAppsWidgetWithTheMetricImages() throws {
        let prepared = try prepared(model(block: [
            "customLayout": "focus_timer",
            "metrics": [["label": "LIO", "value": "1", "image": "https://x/lions.png"]]
        ]))
        XCTAssertEqual(prepared.activity.customLayout, "focus_timer")
        let state = LiveActivityNotifications.contentState(prepared) { $0.map { "img:" + $0 } }
        XCTAssertEqual(state.customLayout, "focus_timer")
        XCTAssertEqual(state.metrics?.first?.image, "img:https://x/lions.png")
    }

    func testIndeterminateBarAndNoBar() throws {
        let indeterminate = LiveActivityNotifications.contentState(
            try prepared(model(block: ["progress": [:] as [String: Any]], progress: nil)))
        XCTAssertEqual(indeterminate.bar, true)
        XCTAssertNil(indeterminate.progress)
        let none = LiveActivityNotifications.contentState(try prepared(model(progress: nil)))
        XCTAssertNil(none.bar)
        let ended = LiveActivityNotifications.contentState(try prepared(model(block: ["state": "ended"])))
        XCTAssertEqual(ended.ended, true)
    }

    func testContentStateEncodesCompactlyAndRoundTrips() throws {
        let state = AwnLiveActivityState(title: "A", progress: 10, bar: true)
        let json = String(data: try JSONEncoder().encode(state), encoding: .utf8)!
        XCTAssertFalse(json.contains("segments"), "absent fields are left out: \(json)")
        XCTAssertEqual(try JSONDecoder().decode(AwnLiveActivityState.self, from: Data(json.utf8)), state)
        // A push's content-state uses the same names.
        let pushed = try JSONDecoder().decode(AwnLiveActivityState.self, from: Data(
            #"{"title":"T","timerEnd":5000,"countDown":true,"buttons":[{"key":"k","label":"L"}]}"#.utf8))
        XCTAssertEqual(pushed.timerEndDate, Date(timeIntervalSince1970: 5))
        XCTAssertEqual(pushed.buttons?.first?.key, "k")
    }

    func testOver4KBIsRefused() throws {
        let attributes = AwnLiveActivityAttributes(activityId: "a", appGroup: "group.x")
        XCTAssertNoThrow(try LiveActivityNotifications.checkSize(AwnLiveActivityState(title: "ok"), attributes))
        let big = AwnLiveActivityState(title: "x", body: String(repeating: "y", count: 4100))
        XCTAssertGreaterThan(LiveActivityNotifications.payloadSize(big, attributes), 4096)
        let code = detailedCode { try LiveActivityNotifications.checkSize(big, attributes) }
        XCTAssertEqual(code, "arguments.invalid.notificationLiveActivity")
    }

    func testImageFileNamesAreStable() {
        let a = LiveActivityNotifications.imageFileName("asset://a.png")
        XCTAssertEqual(a, LiveActivityNotifications.imageFileName("asset://a.png"))
        XCTAssertNotEqual(a, LiveActivityNotifications.imageFileName("asset://b.png"))
        XCTAssertTrue(a.hasSuffix(".png"))
        XCTAssertEqual(a.count, 24 + 4)
    }

    func testNoAppGroupStoresNoImage() {
        let store = LiveActivityImageStore(appGroup: nil)
        XCTAssertNil(store.appGroup)
        XCTAssertNil(store.store("asset://a.png"))
        XCTAssertNil(LiveActivityImageStore(appGroup: "  ").appGroup)
    }

    // MARK: - Body text (macOS, iOS below 16.1), as the web

    private var utc: DateFormatter {
        let formatter = LiveActivityNotifications.defaultTimeFormatter()
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }

    func testFoldedBody() throws {
        // 2023-11-14 22:13:20 UTC
        let body = LiveActivityNotifications.foldedBody(try prepared(model(block: [
            "shortText": "12 min",
            "timer": ["end": 1_700_000_000_000.0, "countDown": true],
            "metrics": [["label": "Speed", "value": "42", "unit": "km/h"], ["label": "Stops", "value": "2"]]
        ])), timeFormatter: utc)
        XCTAssertEqual(body, "On the way\n▰▰▰▰▰▰▱▱▱▱ 60% · 12 min\nEnds at 22:13\nSpeed 42 km/h · Stops 2")

        let elapsed = LiveActivityNotifications.foldedBody(try prepared(model(block: [
            "timer": ["start": 1_700_000_000_000.0, "countDown": false]
        ], body: "", progress: nil)), timeFormatter: utc)
        XCTAssertEqual(elapsed, "Started at 22:13")

        let indeterminate = LiveActivityNotifications.foldedBody(try prepared(model(block: [
            "shortText": "soon", "progress": [:] as [String: Any]
        ], progress: nil)), timeFormatter: utc)
        XCTAssertEqual(indeterminate, "On the way\nsoon")
    }

    func testProgressLine() {
        XCTAssertEqual(LiveActivityNotifications.progressLine(0), "▱▱▱▱▱▱▱▱▱▱ 0%")
        XCTAssertEqual(LiveActivityNotifications.progressLine(44), "▰▰▰▰▱▱▱▱▱▱ 44%")
        XCTAssertEqual(LiveActivityNotifications.progressLine(45), "▰▰▰▰▰▱▱▱▱▱ 45%")
        XCTAssertEqual(LiveActivityNotifications.progressLine(150), "▰▰▰▰▰▰▰▰▰▰ 100%")
    }

    // MARK: - Notification presentation (macOS)

    private func posted(_ outcome: LiveActivityManager.NotificationOutcome) -> [String: Any]? {
        if case .post(let model) = outcome { return model["content"] as? [String: Any] }
        return nil
    }

    func testNotificationSoundOnlyOnFirstPostOrAlert() throws {
        let manager = self.manager(withSystem: false)
        XCTAssertEqual(manager.presentation(for: "7"), .notification)
        let first = posted(manager.applyNotification(try prepared(model())))
        XCTAssertNil(first?["playSound"])
        let update = posted(manager.applyNotification(try prepared(model())))
        XCTAssertEqual(update?["playSound"] as? Bool, false)
        let alerting = posted(manager.applyNotification(try prepared(model(block: ["alert": true]))))
        XCTAssertNil(alerting?["playSound"])
        XCTAssertEqual(manager.activities() as NSArray, [["activityId": "7", "state": "active"]] as NSArray)
    }

    func testNotificationEndedImmediatelyIsRemoved() throws {
        let manager = self.manager(withSystem: false)
        _ = manager.applyNotification(try prepared(model()))
        let outcome = manager.applyNotification(try prepared(model(block: ["state": "ended", "dismissal": "immediate"])))
        guard case .removed = outcome else { return XCTFail("expected removed") }
        XCTAssertEqual(removed, [7])
        XCTAssertEqual(states("7"), ["ended", "dismissed"])
        XCTAssertTrue(manager.activities().isEmpty)
    }

    func testNotificationEndedStaysOrLeavesAtItsDismissal() throws {
        let manager = self.manager(withSystem: false)
        _ = manager.applyNotification(try prepared(model()))
        XCTAssertNotNil(posted(manager.applyNotification(try prepared(model(block: ["state": "ended"])))))
        XCTAssertEqual(states("7"), ["ended"])
        XCTAssertTrue(timers.isEmpty)
        XCTAssertEqual(manager.activities() as NSArray, [["activityId": "7", "state": "ended"]] as NSArray)

        _ = manager.applyNotification(try prepared(model(id: 8)))
        _ = manager.applyNotification(try prepared(model(id: 8, block: [
            "state": "ended", "dismissal": (clock.timeIntervalSince1970 + 60) * 1000])))
        XCTAssertEqual(timers.last?.seconds, 60)
        timers.last?.fire()
        XCTAssertEqual(removed, [8])
        XCTAssertEqual(states("8"), ["ended", "dismissed"])
    }

    func testNotificationStaleAtRemovesIt() throws {
        let manager = self.manager(withSystem: false)
        _ = manager.applyNotification(try prepared(model(block: ["staleAt": (clock.timeIntervalSince1970 + 30) * 1000])))
        XCTAssertEqual(timers.count, 1)
        _ = manager.applyNotification(try prepared(model(block: ["staleAt": (clock.timeIntervalSince1970 + 90) * 1000])))
        XCTAssertTrue(timers[0].cancelled)
        timers[1].fire()
        XCTAssertEqual(removed, [7])
        XCTAssertEqual(states("7"), ["dismissed"])
    }

    func testAppEndOfANotification() throws {
        let manager = self.manager(withSystem: false)
        _ = manager.applyNotification(try prepared(model()))
        manager.end("7", dismissal: .immediate)
        XCTAssertEqual(removed, [7])
        XCTAssertEqual(states("7"), ["ended", "dismissed"])
    }

    func testCoreRemovalEndsTheNotificationActivity() throws {
        let manager = self.manager(withSystem: false)
        _ = manager.applyNotification(try prepared(model()))
        _ = manager.applyNotification(try prepared(model(id: 9)))
        manager.remove(.id(9))
        XCTAssertEqual(states("9"), ["ended", "dismissed"])
        XCTAssertTrue(states("7").isEmpty)
        XCTAssertTrue(removed.isEmpty, "the core removes the notification itself")
        manager.remove(.channelKey("live"))
        XCTAssertEqual(states("7"), ["ended", "dismissed"])
        XCTAssertTrue(manager.activities().isEmpty)
    }

    func testCapabilitiesWithoutTheSystem() {
        XCTAssertEqual(manager(withSystem: false).capabilities,
                       ["systemSurface": false, "progressSegments": false, "metrics": false,
                        "buttons": true, "push": false])
        XCTAssertTrue(manager(withSystem: false).areEnabled)
    }

    // MARK: - Live Activity presentation (iOS)

    private func apply(_ manager: LiveActivityManager, _ model: [String: Any]) throws -> Bool {
        let prepared = try self.prepared(model)
        let state = LiveActivityNotifications.contentState(prepared)
        return manager.applyActivity(prepared, attributes: AwnLiveActivityAttributes(activityId: prepared.activity.activityId),
                                     state: state)
    }

    func testActivityStartsUpdatesAndAlertsOnlyWhenAsked() throws {
        let manager = self.manager()
        XCTAssertEqual(manager.presentation(for: "7"), .activity)
        XCTAssertTrue(try apply(manager, model(block: ["alert": true])))
        XCTAssertNil(system.lastAlert, "the start alerts by itself")
        XCTAssertTrue(try apply(manager, model(body: "Closer")))
        XCTAssertNil(system.lastAlert)
        XCTAssertTrue(try apply(manager, model(block: ["alert": true], body: "Here")))
        XCTAssertEqual(system.lastAlert, LiveActivityAlert(title: "Order", body: "Here"))
        XCTAssertEqual(system.log, ["start 7", "update 7", "update 7"])
        XCTAssertEqual(manager.capabilities,
                       ["systemSurface": true, "progressSegments": true, "metrics": true, "buttons": true, "push": true])
    }

    func testActivityEndsWithItsDismissal() throws {
        let manager = self.manager()
        _ = try apply(manager, model())
        XCTAssertTrue(try apply(manager, model(block: ["state": "ended", "dismissal": "immediate"])))
        XCTAssertEqual(system.log.last, "end 7 immediate")
        XCTAssertEqual(system.lastState?.ended, true)
        // ActivityKit reports it gone without an ended state first.
        manager.systemStatusChanged("7", .dismissed)
        XCTAssertEqual(states("7"), ["ended", "dismissed"])
    }

    func testRefusedActivityFallsBackToTheNotification() throws {
        system.refuse = true
        let manager = self.manager()
        XCTAssertFalse(try apply(manager, model()))
        XCTAssertNotNil(posted(manager.applyNotification(try prepared(model()))))
        XCTAssertEqual(manager.presentation(for: "7"), .notification)
        XCTAssertEqual(manager.activities() as NSArray, [["activityId": "7", "state": "active"]] as NSArray)
    }

    func testAppEndAndCoreRemovalOfActivities() throws {
        let manager = self.manager()
        _ = try apply(manager, model())
        manager.end("7", dismissal: .system)
        XCTAssertEqual(system.log.last, "end 7 system")
        XCTAssertEqual(system.lastState?.ended, true)

        _ = try apply(manager, model(id: 8))
        system.shown["pushed"] = .active
        manager.remove(.all)
        XCTAssertTrue(system.log.contains("end 8 immediate"))
        XCTAssertTrue(system.log.contains("end pushed immediate"), "push-started ones end too")
    }

    func testStateEventsOncePerChange() throws {
        let manager = self.manager()
        _ = try apply(manager, model())
        manager.systemStatusChanged("7", .active)
        manager.systemStatusChanged("7", .stale)
        manager.systemStatusChanged("7", .stale)
        manager.systemStatusChanged("7", .ended)
        manager.systemStatusChanged("7", .dismissed)
        XCTAssertEqual(states("7"), ["stale", "ended", "dismissed"])
        // Started again with the same id: new events.
        _ = try apply(manager, model())
        manager.systemStatusChanged("7", .ended)
        XCTAssertEqual(states("7"), ["stale", "ended", "dismissed", "ended"])
    }

    func testPushTokensAreEventsAndReplayedOnListen() {
        let manager = self.manager()
        manager.systemPushToStartToken("start1")
        manager.systemPushToStartToken("start1")
        manager.systemPushToken("a", token: "tok")
        XCTAssertEqual(events.count, 2)
        XCTAssertEqual(manager.pushToStartToken, "start1")
        XCTAssertEqual(manager.pushToken("a"), "tok")
        events = []
        manager.eventSink = { [unowned self] in self.events.append($0) }
        XCTAssertEqual(events as NSArray, [
            ["kind": "pushToStartToken", "token": "start1"],
            ["kind": "pushToken", "activityId": "a", "token": "tok"]
        ] as NSArray)
        manager.systemStatusChanged("a", .ended)
        XCTAssertNil(manager.pushToken("a"))
    }

    // MARK: - Buttons

    func testButtonEmitsTheCoreActionWithTheActivityModel() throws {
        let manager = self.manager()
        _ = try apply(manager, model(buttons: [["key": "STOP", "label": "Stop"]]))
        manager.buttonPressed("7", buttonKey: "STOP")
        XCTAssertEqual(dispatched.count, 1)
        XCTAssertEqual(dispatched[0].key, "STOP")
        let payload = (dispatched[0].model["content"] as? [String: Any])?["payload"] as? [String: Any]
        XCTAssertEqual(payload?["activityId"] as? String, "7")

        // After a restart: the stored model.
        let restarted = self.manager()
        restarted.buttonPressed("7", buttonKey: "STOP")
        XCTAssertEqual((dispatched[1].model["actionButtons"] as? [[String: Any]])?.first?["key"] as? String, "STOP")

        // Started by push: a model with the activityId only.
        restarted.buttonPressed("ride", buttonKey: "X")
        let content = dispatched[2].model["content"] as? [String: Any]
        XCTAssertEqual((content?["payload"] as? [String: Any])?["activityId"] as? String, "ride")
        XCTAssertEqual(content?["id"] as? Int, LiveActivityNotifications.javaHash("ride"))
    }

    func testButtonsWaitForTheHandler() {
        var pressed: [String] = []
        AwnLiveActivityButtons.handler = nil
        AwnLiveActivityButtons.press(activityId: "a", buttonKey: "k")
        XCTAssertTrue(pressed.isEmpty)
        AwnLiveActivityButtons.handler = { pressed.append("\($0)/\($1)") }
        AwnLiveActivityButtons.press(activityId: "b", buttonKey: "j")
        XCTAssertEqual(pressed, ["a/k", "b/j"])
        AwnLiveActivityButtons.handler = nil
    }

    func testAPressWaitsForTheAppsChangeOrItsTimeout() {
        let changed = expectation(description: "changed")
        Task {
            await AwnLiveActivityButtons.waitForChange("w", timeout: 30)
            changed.fulfill()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { AwnLiveActivityButtons.activityChanged("w") }
        wait(for: [changed], timeout: 5)

        let timedOut = expectation(description: "timeout")
        Task {
            await AwnLiveActivityButtons.waitForChange("x", timeout: 0.2)
            timedOut.fulfill()
        }
        wait(for: [timedOut], timeout: 5)
    }

    func testSmallImageName() {
        XCTAssertEqual(AwnLiveActivityImages.smallName("abc.png"), "abc-small.png")
        XCTAssertNil(AwnLiveActivityImages.smallName(nil))
    }

    func testJavaHash() {
        XCTAssertEqual(LiveActivityNotifications.javaHash("ride"), 3500280)
        XCTAssertEqual(LiveActivityNotifications.javaHash(""), 0)
    }

    // MARK: - Builder

    private final class Recorder: NotificationBuilder {
        var built: [[String: Any]] = []
        override func build(model: [String: Any]) throws -> BuiltNotification? {
            built.append(model)
            return BuiltNotification(id: 1, content: .init(), model: model)
        }
    }

    func testBuilderPassesOtherModelsAndTakesOverLiveActivities() throws {
        let manager = self.manager()
        let inner = Recorder()
        let builder = LiveActivityBuilder(inner: inner, manager: { manager },
                                          images: { LiveActivityImageStore(appGroup: nil) })
        _ = try builder.build(model: ["content": ["id": 1]])
        XCTAssertEqual(inner.built.count, 1)
        let built = try XCTUnwrap(try builder.build(model: model()))
        XCTAssertTrue(built.isHandled)
        XCTAssertEqual(inner.built.count, 1, "nothing posted on iOS")
        XCTAssertEqual(system.log, ["start 7"])
        let content = built.model["content"] as? [String: Any]
        XCTAssertNotNil(content?["createdDate"])
        XCTAssertEqual((content?["payload"] as? [String: Any])?["activityId"] as? String, "7")

        let code = detailedCode {
            _ = try builder.build(model: model(id: 3, body: String(repeating: "z", count: 5000)))
        }
        XCTAssertEqual(code, "arguments.invalid.notificationLiveActivity")
    }

    func testBuilderPostsTheNotificationWithoutTheSystem() throws {
        let manager = self.manager(withSystem: false)
        let inner = Recorder()
        let builder = LiveActivityBuilder(inner: inner, manager: { manager },
                                          images: { LiveActivityImageStore(appGroup: nil) })
        let built = try XCTUnwrap(try builder.build(model: model()))
        XCTAssertFalse(built.isHandled)
        let body = (inner.built.first?["content"] as? [String: Any])?["body"] as? String
        XCTAssertEqual(body, "On the way\n▰▰▰▰▰▰▱▱▱▱ 60%")
    }
}
