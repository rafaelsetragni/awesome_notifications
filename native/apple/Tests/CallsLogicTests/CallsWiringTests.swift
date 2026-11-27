import XCTest
@testable import IosAwnCore
@testable import CallsLogic

private final class WiringSystem: CallSystem {
    var log: [String] = []
    func reportIncoming(_ call: NotificationCall, uuid: UUID, completion: @escaping (Error?) -> Void) {
        log.append("incoming \(call.callId)")
        completion(nil)
    }
    func update(_ call: NotificationCall, uuid: UUID) { log.append("update \(call.callId)") }
    func startOutgoing(_ call: NotificationCall, uuid: UUID) { log.append("start \(call.callId)") }
    func reportConnected(uuid: UUID, at date: Date) { log.append("connected") }
    func answer(uuid: UUID) { log.append("answer") }
    func setHeld(uuid: UUID, onHold: Bool) { log.append("held \(onHold)") }
    func reportEnded(uuid: UUID, reason: CallEndReason) { log.append("ended") }
}

/// The calls' default manager (wired to the core), the installer, the system
/// call UI's reset and the hooks on any thread.
final class CallsWiringTests: XCTestCase {

    private var timers: [() -> Void] = []

    override func setUp() {
        super.setUp()
        FakeNotificationCenter.install()
        CriticalAlertUtils.setCache(false)
        NotificationBuilderRegistry.shared.clearForTest()
    }

    override func tearDown() {
        NotificationBuilderRegistry.shared.clearForTest()
        CriticalAlertUtils.clearCache()
        super.tearDown()
    }

    private func callMap(_ id: String, _ overrides: [String: Any] = [:]) -> [String: Any] {
        var map: [String: Any] = [
            "callId": id, "caller": ["key": "ana", "name": "Ana"], "state": "incoming",
            "ringTimeout": 30_000, "controls": ["accept", "decline", "hangUp"],
            "commandTarget": "actionEvent", "systemCallUI": false
        ]
        for (key, value) in overrides { map[key] = value }
        return map
    }

    private func model(_ id: Int, _ call: [String: Any]) -> [String: Any] {
        ["content": ["id": id, "channelKey": "calls"], "call": call]
    }

    private func manager(_ system: WiringSystem?) -> CallManager {
        CallManager(
            system: { _ in system },
            dispatch: { _, _, _, _ in },
            createNotification: { _ in },
            removeNotification: { _ in },
            timer: { [unowned self] _, fire in
                self.timers.append(fire)
                return DispatchCallTimer(seconds: 3600, fire: {})
            },
            now: Date.init)
    }

    func testADispatchTimerFiresOnMainUnlessCancelled() {
        let fired = expectation(description: "fired")
        var onMain = false
        let timer = DispatchCallTimer(seconds: 0) { onMain = Thread.isMainThread; fired.fulfill() }
        wait(for: [fired], timeout: 2)
        XCTAssertTrue(onMain)
        timer.cancel()

        var cancelledFired = false
        let cancelled = DispatchCallTimer(seconds: 0.05) { cancelledFired = true }
        cancelled.cancel()
        cancelled.cancel()
        RunLoop.current.run(until: Date().addingTimeInterval(0.15))
        XCTAssertFalse(cancelledFired)
    }

    func testTheDefaultManagerGoesThroughTheCore() throws {
        let manager = CallManager()
        XCTAssertFalse(manager.hasSystemCallUI, "no CallKit on macOS")
        let recorder = EventRecorder()
        AwesomeEventsReceiver.shared.subscribe(listener: recorder)
        defer { AwesomeEventsReceiver.shared.unsubscribe(listener: recorder) }

        let prepared = try XCTUnwrap(CallNotifications.prepare(model(401, callMap("wired"))))
        manager.apply(prepared)

        // Accept: shown again as ongoing, created through the core.
        XCTAssertTrue(manager.userAction("wired", .accept))
        waitUntil("posted as ongoing") { FakeNotificationCenter.shared.read { $0.added.count } == 1 }
        XCTAssertEqual(FakeNotificationCenter.shared.read { $0.added }.first?.identifier, "401")
        // ...and reported as the core's action event of its Accept button.
        XCTAssertTrue(recorder.events.contains {
            $0.name == Definitions.EVENT_DEFAULT_ACTION
                && $0.data[Definitions.NOTIFICATION_BUTTON_KEY_PRESSED] as? String == CallAction.accept.key
        })

        // Hang up: its notification is removed from the center.
        XCTAssertTrue(manager.userAction("wired", .hangUp))
        XCTAssertEqual(FakeNotificationCenter.shared.read { $0.removedDelivered }.last, ["401"])
    }

    func testTheSystemResetForgetsItsCallsOnly() throws {
        let system = WiringSystem()
        let manager = self.manager(system)
        manager.apply(try XCTUnwrap(CallNotifications.prepare(model(1, callMap("system", ["systemCallUI": true])))))
        manager.apply(try XCTUnwrap(CallNotifications.prepare(model(2, callMap("notified")))))
        XCTAssertEqual(manager.activeCalls().count, 2)

        manager.systemReset()
        let left = manager.activeCalls().compactMap { $0["callId"] as? String }
        XCTAssertEqual(left, ["notified"])
    }

    func testAPushedCallAlreadyShownIsReportedAgain() throws {
        let system = WiringSystem()
        let manager = self.manager(system)
        let prepared = try XCTUnwrap(CallNotifications.prepare(model(3, callMap("pushed", ["systemCallUI": true]))))
        var completions = 0
        manager.reportPushed(prepared) { completions += 1 }
        manager.reportPushed(prepared) { completions += 1 }
        XCTAssertEqual(completions, 2)
        XCTAssertEqual(system.log, ["incoming pushed", "incoming pushed"])
        XCTAssertEqual(manager.activeCalls().count, 1)
    }

    func testACommandWithoutAStateChangeIsOnlyDelivered() throws {
        var dispatched: [String] = []
        let manager = CallManager(
            system: { _ in nil }, dispatch: { _, key, _, _ in dispatched.append(key) },
            createNotification: { _ in }, removeNotification: { _ in },
            timer: { _, _ in DispatchCallTimer(seconds: 3600, fire: {}) }, now: Date.init)
        manager.apply(try XCTUnwrap(CallNotifications.prepare(model(6, callMap("quiet")))))
        XCTAssertTrue(manager.userAction("quiet", .audioActivated))
        XCTAssertEqual(dispatched, [CallAction.audioActivated.key])
        XCTAssertEqual(manager.activeCalls().first?["state"] as? String, "incoming")
        XCTAssertFalse(manager.userAction("unknown", .timeout))
    }

    func testTheHooksWorkFromAnyThread() throws {
        let manager = self.manager(nil)
        let prepared = try XCTUnwrap(CallNotifications.prepare(model(5, callMap("hooked"))))
        manager.apply(prepared)

        // A button of its notification, from a background thread.
        var emit: Bool?
        let done = expectation(description: "intercepted")
        DispatchQueue.global().async {
            emit = manager.onNotificationAction(model: prepared.model, buttonKey: CallAction.accept.key)
            done.fulfill()
        }
        wait(for: [done], timeout: 5)
        XCTAssertEqual(emit, true, "actionEvent target: the core emits it")
        XCTAssertEqual(manager.activeCalls().first?["state"] as? String, "ongoing")
        // On main, a button that isn't a call command is left to the core.
        XCTAssertTrue(manager.onNotificationAction(model: prepared.model, buttonKey: "other"))

        // The core's removal, from a background thread then on main.
        let removed = expectation(description: "removed")
        DispatchQueue.global().async {
            manager.onNotificationsRemoved(.channelKey("other"), cancel: false)
            DispatchQueue.main.async { removed.fulfill() }
        }
        wait(for: [removed], timeout: 5)
        XCTAssertEqual(manager.activeCalls().count, 1)
        manager.onNotificationsRemoved(.id(5), cancel: true)
        XCTAssertTrue(manager.activeCalls().isEmpty)
    }

    func testTheInstallerWiresThePackageOnce() throws {
        defer {
            AwesomeMethodHandlerRegistry.shared.unregister(handler: CallsInstaller.methodHandler)
            NotificationRemovalRegistry.shared.unregister(listener: CallManager.shared)
            NotificationActionInterceptorRegistry.shared.unregister(interceptor: CallManager.shared)
        }
        let done = expectation(description: "installed")
        DispatchQueue.global().async {
            CallsInstaller.install()
            done.fulfill()
        }
        wait(for: [done], timeout: 5)
        CallsInstaller.install()  // idempotent

        // The builder joined the chain: a call is shown as its notification here.
        let built = try XCTUnwrap(NotificationBuilderRegistry.shared.makeBuilder().build(
            model: model(501, callMap("installed"))))
        XCTAssertEqual(built.id, 501)

        // Its methods answer through the core's router.
        var capabilities: Any?
        XCTAssertTrue(AwesomeMethodRouter.shared.handle(method: CallKeys.methodCapabilities, arguments: nil) {
            capabilities = $0
        })
        XCTAssertNotNil(capabilities as? [String: Any])
    }

    func testVoipPayloadsWithNonStringKeys() {
        // A push map can mix key types: only the string keys are read.
        let call: [AnyHashable: Any] = [
            "callId": "mixed", "caller": ["key": "ana", "name": "Ana"], "state": "incoming",
            "controls": ["accept", "decline"], 42: "ignored"]
        let content: [AnyHashable: Any] = ["channelKey": "calls", 7: "ignored"]
        let (prepared, error) = VoipPayload.parse(["content": content, "call": call])
        XCTAssertNil(error)
        XCTAssertEqual(prepared?.call.callId, "mixed")
        XCTAssertEqual(prepared?.call.systemCallUI, true, "a VoIP push always uses the system call UI")
        XCTAssertEqual(prepared?.model["content"].flatMap { $0 as? [String: Any] }?["channelKey"] as? String, "calls")
    }

    func testSystemCallUIMustBeABool() {
        XCTAssertEqual(NotificationCall.parse(callMap("c", ["systemCallUI": "yes"])).1,
                       "The call systemCallUI must be a bool")
    }
}
