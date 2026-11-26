import XCTest
@testable import IosAwnCore
@testable import CallsLogic

private final class FakeTimer: CallTimer {
    let seconds: TimeInterval
    let fire: () -> Void
    var cancelled = false
    init(_ seconds: TimeInterval, _ fire: @escaping () -> Void) {
        self.seconds = seconds
        self.fire = fire
    }
    func cancel() { cancelled = true }
}

private final class FakeSystem: CallSystem {
    var log: [String] = []
    var refuse = false
    var pendingCompletion: ((Error?) -> Void)?
    var deferCompletion = false

    func reportIncoming(_ call: NotificationCall, uuid: UUID, completion: @escaping (Error?) -> Void) {
        log.append("incoming \(call.callId) \(call.name)")
        let error: Error? = refuse ? NSError(domain: "test", code: 1) : nil
        if deferCompletion { pendingCompletion = completion } else { completion(error) }
    }
    func update(_ call: NotificationCall, uuid: UUID) { log.append("update \(call.callId) \(call.state.rawValue)") }
    func startOutgoing(_ call: NotificationCall, uuid: UUID) { log.append("start \(call.callId)") }
    func reportConnected(uuid: UUID, at date: Date) {
        log.append("connected \(Int(date.timeIntervalSince1970 * 1000))")
    }
    func answer(uuid: UUID) { log.append("answer") }
    func setHeld(uuid: UUID, onHold: Bool) { log.append("held \(onHold)") }
    func reportEnded(uuid: UUID, reason: CallEndReason) { log.append("ended \(reason.name)") }
}

final class CallsLogicTests: XCTestCase {

    private var system: FakeSystem!
    private var timers: [FakeTimer] = []
    private var dispatched: [(model: [String: Any], key: String, button: [String: Any])] = []
    private var created: [[String: Any]] = []
    private var removed: [Int] = []
    private var stream: [[String: Any]] = []
    private var clock = Date(timeIntervalSince1970: 1_700_000_000)

    override func setUp() {
        super.setUp()
        system = FakeSystem()
        timers = []
        dispatched = []
        created = []
        removed = []
        stream = []
    }

    private func manager(withSystem: Bool = true) -> CallManager {
        let system = self.system!
        let manager = CallManager(
            system: { _ in withSystem ? system : nil },
            dispatch: { [unowned self] model, key, _, button in self.dispatched.append((model, key, button)) },
            createNotification: { [unowned self] in self.created.append($0) },
            removeNotification: { [unowned self] in self.removed.append($0) },
            timer: { [unowned self] seconds, fire in
                let timer = FakeTimer(seconds, fire)
                self.timers.append(timer)
                return timer
            },
            now: { [unowned self] in self.clock })
        manager.eventSink = { [unowned self] in self.stream.append($0) }
        return manager
    }

    private func call(_ overrides: [String: Any] = [:]) -> [String: Any] {
        var map: [String: Any] = [
            "callId": "c-1",
            "caller": ["key": "ana", "name": "Ana", "uri": "tel:+5511999999999", "isBot": false, "isImportant": false],
            "video": false, "state": "incoming", "ringTimeout": 30_000, "missedNotification": true,
            "controls": ["accept", "decline", "hangUp", "mute", "hold"],
            "commandTarget": "actionEvent", "systemCallUI": true
        ]
        for (key, value) in overrides { map[key] = value }
        return map
    }

    private func model(_ call: [String: Any]?, content extra: [String: Any] = [:]) -> [String: Any] {
        var content: [String: Any] = ["id": 300, "channelKey": "calls"]
        for (key, value) in extra { content[key] = value }
        var model: [String: Any] = ["content": content]
        if let call = call { model["call"] = call }
        return model
    }

    private func prepared(_ overrides: [String: Any] = [:], content: [String: Any] = [:]) throws
        -> CallNotifications.Prepared {
        try XCTUnwrap(CallNotifications.prepare(model(call(overrides), content: content)))
    }

    private func detail(_ model: [String: Any]) -> String? {
        do {
            _ = try CallNotifications.prepare(model)
            return nil
        } catch let e as AwesomeNotificationsException {
            return e.detailedCode
        } catch {
            return "other"
        }
    }

    private func parseError(_ overrides: [String: Any], removing: [String] = []) -> String? {
        var map = call(overrides)
        for key in removing { map.removeValue(forKey: key) }
        return NotificationCall.parse(map).1
    }

    // MARK: - Parse / validate

    func testAValidCallWithItsDefaults() throws {
        let (parsed, error) = NotificationCall.parse([
            "callId": "c-9", "caller": ["key": "k", "name": "Bob"], "state": "incoming"
        ])
        XCTAssertNil(error)
        let call = try XCTUnwrap(parsed)
        XCTAssertEqual(call.ringTimeout, 60_000)
        XCTAssertTrue(call.missedNotification)
        XCTAssertEqual(call.controls, CallControl.allCases)
        XCTAssertEqual(call.commandTarget, .actionEvent)
        XCTAssertTrue(call.systemCallUI)
        XCTAssertFalse(call.video)
        XCTAssertEqual(call.text(CallKeys.textAccept), "Accept")
        XCTAssertEqual(call.stateText, "Incoming call")
    }

    func testInvalidCallsAreRefused() {
        XCTAssertNotNil(NotificationCall.parse("nope").1)
        XCTAssertNotNil(parseError(["callId": "  "]))
        XCTAssertNotNil(parseError([:], removing: ["callId"]))
        XCTAssertNotNil(parseError(["caller": ["key": "k"]]))
        XCTAssertNotNil(parseError([:], removing: ["caller"]))
        XCTAssertNotNil(parseError(["handle": " "]))
        XCTAssertNotNil(parseError(["groupName": ""]))
        XCTAssertNotNil(parseError(["state": "ringing"]))
        XCTAssertNotNil(parseError(["ringTimeout": 0]))
        XCTAssertNotNil(parseError(["ringTimeout": -5]))
        XCTAssertNotNil(parseError(["controls": ["accept", "transfer"]]))
        XCTAssertNotNil(parseError(["controls": "accept"]))
        XCTAssertNotNil(parseError(["controls": ["hangUp", "mute"]]))
        XCTAssertNotNil(parseError(["commandTarget": "everywhere"]))
        XCTAssertNotNil(parseError(["texts": "Hi"]))
        XCTAssertNotNil(parseError(["video": "yes"]))
        XCTAssertNotNil(parseError(["startedAt": "today"]))
        // Without accept / decline, a call that doesn't ring is fine.
        XCTAssertNil(parseError(["state": "ongoing", "controls": ["hangUp"]]))
    }

    func testChannelValuesAreRead() throws {
        // As the platform channel delivers them: NSNumbers, NSNull for unset.
        let (parsed, error) = NotificationCall.parse(call([
            "video": NSNumber(value: true), "ringTimeout": NSNumber(value: 1),
            "startedAt": NSNumber(value: 1_700_000_000_123 as Int64), "groupName": NSNull(), "handle": NSNull(),
            "texts": ["accept": "Atender"]
        ]))
        XCTAssertNil(error)
        let call = try XCTUnwrap(parsed)
        XCTAssertTrue(call.video)
        XCTAssertEqual(call.ringTimeout, 1)
        XCTAssertEqual(call.startedAt, 1_700_000_000_123)
        XCTAssertNil(call.groupName)
        XCTAssertEqual(call.text(CallKeys.textAccept), "Atender")
        XCTAssertEqual(call.text(CallKeys.textDecline), "Decline")
        // A number isn't a boolean.
        XCTAssertNotNil(parseError(["missedNotification": NSNumber(value: 1)]))
    }

    func testTheSerializedBlockParsesBack() throws {
        let original = try XCTUnwrap(NotificationCall.parse(call(["groupName": "Team", "startedAt": 5])).0)
        XCTAssertEqual(NotificationCall.parse(original.toMap()).0, original)
    }

    // MARK: - Prepare / refusals

    func testModelsWithoutACallAreLeftAlone() throws {
        XCTAssertNil(try CallNotifications.prepare(model(nil)))
        XCTAssertNil(try CallNotifications.prepare(model(nil, content: ["category": "Call"])))
        XCTAssertNil(try CallNotifications.prepare(["content": ["id": 1], "call": NSNull()]))
    }

    func testRefusals() {
        XCTAssertEqual(detail(model(call(["callId": ""]))), "arguments.invalid.notificationCall")
        var scheduled = model(call())
        scheduled["schedule"] = ["interval": 60]
        XCTAssertEqual(detail(scheduled), "arguments.invalid.notificationCall.schedule")
        var unscheduled = model(call())
        unscheduled["schedule"] = NSNull()
        XCTAssertNil(detail(unscheduled))
    }

    func testPrepareFillsThePayloadTitleAndBody() throws {
        let plain = try prepared([:], content: ["payload": ["mine": "1"]])
        let content = plain.model["content"] as? [String: Any]
        XCTAssertEqual(content?["payload"] as? [String: String], ["mine": "1", "callId": "c-1"])
        XCTAssertEqual(content?["title"] as? String, "Ana")
        XCTAssertEqual(content?["body"] as? String, "Incoming call")
        XCTAssertNil(plain.appTitle)

        let group = try prepared(["groupName": "Team", "video": true], content: ["title": "Mine"])
        let groupContent = group.model["content"] as? [String: Any]
        XCTAssertEqual(groupContent?["title"] as? String, "Mine")
        XCTAssertEqual(groupContent?["body"] as? String, "Incoming video call")
        XCTAssertEqual(group.appTitle, "Mine")
        XCTAssertEqual(group.call.name, "Team")
    }

    // MARK: - Ids, handles, reasons, keys

    func testTheMissedNotificationIdIsJavasHashCode() {
        XCTAssertEqual(CallIds.missedNotificationId("c-2026-001"), 506_794_831)
        XCTAssertEqual(CallIds.missedNotificationId("call-ü"), 318_297_868)
        XCTAssertEqual(CallIds.missedNotificationId("📞-1"), 1_318_641_444)
        XCTAssertEqual(CallIds.javaHash("c-1"), 96583)
    }

    func testTheCallUUIDIsStablePerCallId() {
        let uuid = CallIds.uuid("c-1")
        XCTAssertEqual(uuid, CallIds.uuid("c-1"))
        XCTAssertNotEqual(uuid, CallIds.uuid("c-2"))
        let bytes = uuid.uuid
        XCTAssertEqual(bytes.6 >> 4, 5)
        XCTAssertEqual(bytes.8 >> 6, 2)
    }

    func testTheSystemHandle() throws {
        XCTAssertEqual(try prepared().call.systemHandle,
                       NotificationPersonHandle(value: "+5511999999999", type: .phoneNumber))
        XCTAssertEqual(try prepared(["handle": "mailto:ana@example.com"]).call.systemHandle,
                       NotificationPersonHandle(value: "ana@example.com", type: .emailAddress))
        XCTAssertEqual(try prepared(["handle": "ana#42"]).call.systemHandle,
                       NotificationPersonHandle(value: "ana#42", type: .unknown))
        XCTAssertEqual(try prepared(["caller": ["key": "ana", "name": "Ana"]]).call.systemHandle,
                       NotificationPersonHandle(value: "ana", type: .unknown))
    }

    func testEndReasonsMapToCallKitsRawValues() {
        // CXCallEndedReason: failed 1, remoteEnded 2, unanswered 3,
        // answeredElsewhere 4, declinedElsewhere 5.
        XCTAssertEqual(CallEndReason.from(name: "failed")?.rawValue, 1)
        XCTAssertEqual(CallEndReason.from(name: "remoteEnded")?.rawValue, 2)
        XCTAssertEqual(CallEndReason.from(name: "unanswered")?.rawValue, 3)
        XCTAssertEqual(CallEndReason.from(name: "answeredElsewhere")?.rawValue, 4)
        XCTAssertEqual(CallEndReason.from(name: "declinedElsewhere")?.rawValue, 5)
        XCTAssertNil(CallEndReason.from(name: "bored"))
    }

    func testCommandKeys() {
        XCTAssertEqual(CallAction.hangUp.key, "awn.call.hangUp")
        XCTAssertEqual(CallAction.from(key: "awn.call.audioActivated"), .audioActivated)
        XCTAssertNil(CallAction.from(key: "awn.media.play"))
        XCTAssertNil(CallAction.from(key: "awn.call.transfer"))
    }

    // MARK: - System call: state machine

    func testAnIncomingCallRingsAndTimesOut() throws {
        let manager = self.manager()
        manager.apply(try prepared(["commandTarget": "both"]))
        XCTAssertEqual(system.log, ["incoming c-1 Ana"])
        XCTAssertEqual(timers.count, 1)
        XCTAssertEqual(timers[0].seconds, 30)
        XCTAssertEqual(manager.activeCalls() as NSArray, [["callId": "c-1", "state": "incoming"]] as NSArray)

        timers[0].fire()
        XCTAssertEqual(system.log.last, "ended unanswered")
        XCTAssertEqual(manager.activeCalls().count, 0)
        let missed = try XCTUnwrap(created.first?["content"] as? [String: Any])
        XCTAssertEqual(missed["id"] as? Int, CallIds.missedNotificationId("c-1"))
        XCTAssertEqual(missed["channelKey"] as? String, "calls")
        XCTAssertEqual(missed["title"] as? String, "Ana")
        XCTAssertEqual(missed["body"] as? String, "Missed call")
        XCTAssertEqual(missed["payload"] as? [String: String], ["callId": "c-1"])
        XCTAssertEqual(dispatched.map(\.key), ["awn.call.timeout"])
        XCTAssertEqual(stream as NSArray, [["kind": "command", "action": "timeout", "callId": "c-1"]] as NSArray)
    }

    func testATimeoutWithoutTheMissedNotification() throws {
        let manager = self.manager()
        manager.apply(try prepared(["missedNotification": false]))
        timers[0].fire()
        XCTAssertTrue(created.isEmpty)
        XCTAssertEqual(dispatched.map(\.key), ["awn.call.timeout"])
    }

    func testAnUpdateWhileRingingKeepsTheTimer() throws {
        let manager = self.manager()
        manager.apply(try prepared())
        manager.apply(try prepared(["groupName": "Team"]))
        XCTAssertEqual(timers.count, 1)
        XCTAssertFalse(timers[0].cancelled)
        XCTAssertEqual(system.log, ["incoming c-1 Ana", "update c-1 incoming"])
    }

    func testTheUserAcceptsInCallKit() throws {
        let manager = self.manager()
        manager.apply(try prepared())
        XCTAssertTrue(manager.systemAnswered(CallIds.uuid("c-1")))
        XCTAssertTrue(timers[0].cancelled)
        XCTAssertEqual(manager.state("c-1"), .ongoing)
        XCTAssertEqual(manager.entry("c-1")?.call.startedAt, 1_700_000_000_000)
        XCTAssertEqual(dispatched.map(\.key), ["awn.call.accept"])
        XCTAssertEqual(dispatched[0].button["actionType"] as? String, "Default")
        XCTAssertEqual(dispatched[0].button["autoDismissible"] as? Bool, false)
        let payload = (dispatched[0].model["content"] as? [String: Any])?["payload"] as? [String: Any]
        XCTAssertEqual(payload?["callId"] as? String, "c-1")
        // The default target: no stream event.
        XCTAssertTrue(stream.isEmpty)

        // The app follows with ongoing: CallKit is updated, nothing answered again.
        manager.apply(try prepared(["state": "ongoing"]))
        XCTAssertEqual(system.log.last, "update c-1 ongoing")
        XCTAssertEqual(manager.entry("c-1")?.call.startedAt, 1_700_000_000_000)
        XCTAssertFalse(manager.systemAnswered(CallIds.uuid("other")))
    }

    func testTheAppAnswersAndCallKitComesBackSilently() throws {
        let manager = self.manager()
        manager.apply(try prepared())
        manager.apply(try prepared(["state": "ongoing", "startedAt": 42]))
        XCTAssertEqual(system.log.last, "answer")
        XCTAssertTrue(timers[0].cancelled)
        XCTAssertTrue(manager.systemAnswered(CallIds.uuid("c-1")))
        XCTAssertTrue(dispatched.isEmpty)
    }

    func testDeclineAndHangUpFromCallKit() throws {
        let manager = self.manager()
        manager.apply(try prepared(["commandTarget": "stream"]))
        manager.systemEnded(CallIds.uuid("c-1"))
        XCTAssertEqual(stream.last?["action"] as? String, "decline")
        XCTAssertTrue(dispatched.isEmpty)
        XCTAssertTrue(timers[0].cancelled)
        XCTAssertTrue(manager.activeCalls().isEmpty)

        manager.apply(try prepared(["callId": "c-2", "state": "ongoing", "commandTarget": "stream"]))
        manager.systemEnded(CallIds.uuid("c-2"))
        XCTAssertEqual(stream.last?["action"] as? String, "hangUp")
        // Already over (ended by the app): ignored.
        manager.systemEnded(CallIds.uuid("c-2"))
        XCTAssertEqual(stream.count, 2)
    }

    func testHoldAndMute() throws {
        let manager = self.manager()
        manager.apply(try prepared(["state": "ongoing"]))
        XCTAssertEqual(system.log, ["start c-1", "connected 1700000000000"])
        XCTAssertTrue(manager.systemHeld(CallIds.uuid("c-1"), onHold: true))
        XCTAssertEqual(manager.state("c-1"), .held)
        XCTAssertTrue(manager.systemMuted(CallIds.uuid("c-1"), muted: true))
        XCTAssertTrue(manager.systemMuted(CallIds.uuid("c-1"), muted: true))
        XCTAssertTrue(manager.systemMuted(CallIds.uuid("c-1"), muted: false))
        XCTAssertTrue(manager.systemHeld(CallIds.uuid("c-1"), onHold: false))
        XCTAssertEqual(dispatched.map(\.key), ["awn.call.hold", "awn.call.mute", "awn.call.unmute", "awn.call.unhold"])
        XCTAssertTrue(dispatched.allSatisfy { $0.button["actionType"] as? String == "SilentAction" })

        // The app holds: CallKit is told; its action coming back is silent.
        manager.apply(try prepared(["state": "held"]))
        XCTAssertEqual(system.log.last, "held true")
        XCTAssertTrue(manager.systemHeld(CallIds.uuid("c-1"), onHold: true))
        manager.apply(try prepared(["state": "ongoing"]))
        XCTAssertEqual(system.log.last, "held false")
        XCTAssertEqual(dispatched.count, 4)
    }

    func testOutgoingThenConnected() throws {
        let manager = self.manager()
        manager.apply(try prepared(["state": "outgoing"]))
        manager.apply(try prepared(["state": "ongoing", "startedAt": 1_700_000_005_000]))
        XCTAssertEqual(system.log, ["start c-1", "connected 1700000005000"])
        XCTAssertTrue(timers.isEmpty)
    }

    func testEndedAndMissedFromTheApp() throws {
        let manager = self.manager()
        manager.apply(try prepared())
        manager.apply(try prepared(["state": "ended"]))
        XCTAssertEqual(system.log.last, "ended remoteEnded")
        XCTAssertTrue(timers[0].cancelled)
        XCTAssertTrue(created.isEmpty)

        manager.apply(try prepared())
        manager.apply(try prepared(["state": "missed", "video": true]))
        XCTAssertEqual(system.log.last, "ended unanswered")
        XCTAssertEqual((created.last?["content"] as? [String: Any])?["body"] as? String, "Missed video call")
        XCTAssertTrue(dispatched.isEmpty)
        XCTAssertTrue(stream.isEmpty)
    }

    func testCallEnd() throws {
        let manager = self.manager()
        manager.apply(try prepared())
        manager.end("c-1", reason: .declinedElsewhere)
        XCTAssertEqual(system.log.last, "ended declinedElsewhere")
        XCTAssertTrue(created.isEmpty)
        manager.apply(try prepared())
        manager.end("c-1", reason: .unanswered)
        XCTAssertEqual(created.count, 1)
        XCTAssertTrue(dispatched.isEmpty)
        // Unknown here: the system call is ended anyway.
        manager.end("c-9", reason: .failed)
        XCTAssertEqual(system.log.last, "ended failed")
    }

    func testRemovingTheNotificationEndsTheCall() throws {
        let manager = self.manager()
        manager.apply(try prepared())
        manager.remove(.id(301))
        XCTAssertEqual(manager.activeCalls().count, 1)
        manager.remove(.channelKey("calls"))
        XCTAssertEqual(system.log.last, "ended remoteEnded")
        XCTAssertTrue(manager.activeCalls().isEmpty)
        XCTAssertTrue(timers[0].cancelled)
        XCTAssertTrue(dispatched.isEmpty)
    }

    func testARefusedIncomingCallIsForgotten() throws {
        system.refuse = true
        let manager = self.manager()
        manager.apply(try prepared())
        XCTAssertTrue(manager.activeCalls().isEmpty)
        XCTAssertTrue(timers[0].cancelled)
    }

    func testAudioSessionEvents() throws {
        let manager = self.manager()
        manager.apply(try prepared(["state": "ongoing", "commandTarget": "both"]))
        manager.systemAudio(activated: true)
        manager.systemAudio(activated: false)
        XCTAssertEqual(dispatched.map(\.key), ["awn.call.audioActivated", "awn.call.audioDeactivated"])
        XCTAssertEqual(stream.map { $0["action"] as? String }, ["audioActivated", "audioDeactivated"])
    }

    func testTheBuilderHandsCallsToCallKit() throws {
        let manager = self.manager()
        let builder = CallBuilder(inner: NotificationBuilder(), manager: { manager })
        let built = try XCTUnwrap(builder.build(model: model(call())))
        XCTAssertTrue(built.isHandled)
        XCTAssertEqual(built.id, 300)
        let content = built.model["content"] as? [String: Any]
        XCTAssertNotNil(content?["createdDate"])
        XCTAssertNotNil(content?["displayedDate"])
        XCTAssertEqual(system.log, ["incoming c-1 Ana"])

        let plain = try XCTUnwrap(builder.build(model: model(nil, content: ["title": "Hi"])))
        XCTAssertFalse(plain.isHandled)
        XCTAssertThrowsError(try builder.build(model: model(call(["state": "?"]))))
    }

    // MARK: - VoIP pushes

    func testAVoipPushIsReportedBeforeItsCompletion() throws {
        system.deferCompletion = true
        let manager = self.manager()
        let (parsed, _) = VoipPayload.parse(["call": call(["systemCallUI": false]), "content": ["channelKey": "calls"]])
        let pushed = try XCTUnwrap(parsed)
        var completed = false
        manager.reportPushed(pushed) { completed = true }
        XCTAssertEqual(system.log, ["incoming c-1 Ana"])
        XCTAssertFalse(completed)
        system.pendingCompletion?(nil)
        XCTAssertTrue(completed)
        XCTAssertEqual(timers.count, 1)

        // Then the core applies its model: same call, same timer, CallKit.
        manager.apply(try XCTUnwrap(CallNotifications.prepare(pushed.model)))
        XCTAssertEqual(system.log.last, "update c-1 incoming")
        XCTAssertEqual(timers.count, 1)
        XCTAssertEqual(manager.presentation(for: pushed.call), .systemCall)
    }

    func testVoipPayloads() throws {
        let json = String(data: try JSONSerialization.data(withJSONObject: call()), encoding: .utf8)!
        let (fromJson, error) = VoipPayload.parse(["call": json, "content": "{\"id\": 7, \"channelKey\": \"calls\"}"])
        XCTAssertNil(error)
        let content = try XCTUnwrap(fromJson?.model["content"] as? [String: Any])
        XCTAssertEqual(content["id"] as? Int, 7)
        XCTAssertEqual(content["createdSource"] as? String, "CallKit")
        XCTAssertEqual(fromJson?.call.systemCallUI, true)

        let (noContent, _) = VoipPayload.parse(["call": call(["systemCallUI": false]), "aps": [:]])
        XCTAssertEqual(CallNotifications.id(try XCTUnwrap(noContent).model), CallIds.notificationId("c-1"))
        XCTAssertTrue(noContent!.call.systemCallUI)

        XCTAssertNotNil(VoipPayload.parse(["aps": ["alert": "hi"]]).1)
        XCTAssertNotNil(VoipPayload.parse(["call": "{not json"]).1)
        XCTAssertNotNil(VoipPayload.parse(["call": call(["callId": ""])]).1)
        XCTAssertEqual(VoipPayload.hex(Data([0x00, 0xAB, 0x10])), "00ab10")
        XCTAssertEqual(VoipPayload.placeholder.state, .incoming)
    }

    func testTheVoipTokenGoesToTheStream() {
        let manager = self.manager()
        manager.voipToken = "abcd"
        manager.voipToken = "abcd"
        XCTAssertEqual(stream as NSArray, [["kind": "voipToken", "token": "abcd"]] as NSArray)
        // A new listener gets the token at once.
        var late: [[String: Any]] = []
        manager.eventSink = { late.append($0) }
        XCTAssertEqual(late.first?["token"] as? String, "abcd")
    }

    // MARK: - Notification presentation (macOS, systemCallUI: false)

    func testWithoutCallKitTheCallIsANotification() throws {
        let manager = self.manager(withSystem: false)
        let builder = CallBuilder(inner: NotificationBuilder(), manager: { manager })
        let built = try XCTUnwrap(builder.build(model: model(call(), content: ["title": "Mine"])))
        XCTAssertFalse(built.isHandled)
        XCTAssertEqual(built.content.title, "Mine")
        XCTAssertEqual(built.content.body, "Incoming call")
        let buttons = try XCTUnwrap(built.model["actionButtons"] as? [[String: Any]])
        XCTAssertEqual(buttons.map { $0["key"] as? String }, ["awn.call.accept", "awn.call.decline"])
        XCTAssertEqual(buttons.map { $0["label"] as? String }, ["Accept", "Decline"])
        XCTAssertEqual(buttons.map { $0["actionType"] as? String }, ["Default", "SilentAction"])
        XCTAssertEqual((built.model["content"] as? [String: Any])?["wakeUpScreen"] as? Bool, true)
        if #available(macOS 12.0, iOS 15.0, *) {
            XCTAssertEqual(built.content.interruptionLevel, .timeSensitive)
        }
        XCTAssertEqual(timers.count, 1)
        XCTAssertTrue(system.log.isEmpty)
    }

    func testSystemCallUIFalseIsANotificationToo() throws {
        let manager = self.manager()
        let builder = CallBuilder(inner: NotificationBuilder(), manager: { manager })
        let built = try XCTUnwrap(builder.build(model: model(call(["systemCallUI": false]))))
        XCTAssertFalse(built.isHandled)
        XCTAssertTrue(system.log.isEmpty)
    }

    func testAcceptOnTheNotification() throws {
        let manager = self.manager(withSystem: false)
        let posted = CallNotifications.notificationModel(try prepared(content: ["body": "Ring!"]))
        manager.apply(try prepared(content: ["body": "Ring!"]))

        // The core emits the action event itself (actionEvent target).
        XCTAssertTrue(manager.notificationAction(model: posted, buttonKey: "awn.call.accept"))
        XCTAssertTrue(dispatched.isEmpty)
        XCTAssertTrue(timers[0].cancelled)
        XCTAssertEqual(manager.state("c-1"), .ongoing)
        // Shown again, ongoing, through the core: the app's own body is kept.
        let again = try XCTUnwrap(created.first)
        let reposted = try XCTUnwrap(CallNotifications.prepare(again))
        XCTAssertEqual(reposted.call.state, .ongoing)
        XCTAssertEqual(reposted.call.startedAt, 1_700_000_000_000)
        XCTAssertEqual(reposted.appBody, "Ring!")
        XCTAssertNil(reposted.appTitle)
        let shown = CallNotifications.notificationModel(reposted)
        XCTAssertEqual((shown["actionButtons"] as? [[String: Any]])?.map { $0["key"] as? String }, ["awn.call.hangUp"])
        XCTAssertEqual((shown["content"] as? [String: Any])?["playSound"] as? Bool, false)

        // Not a call button: the core's behavior.
        XCTAssertTrue(manager.notificationAction(model: posted, buttonKey: "reply"))
    }

    func testDeclineOnTheNotificationOfAKilledApp() throws {
        let manager = self.manager(withSystem: false)
        let posted = CallNotifications.notificationModel(try prepared(["commandTarget": "stream"]))
        // Nothing known (the app was launched by the button): from the model.
        XCTAssertFalse(manager.notificationAction(model: posted, buttonKey: "awn.call.decline"))
        XCTAssertEqual(stream as NSArray, [["kind": "command", "action": "decline", "callId": "c-1"]] as NSArray)
        XCTAssertEqual(removed, [300])
        XCTAssertTrue(manager.activeCalls().isEmpty)
    }

    func testTheNotificationsTimeoutAndEnd() throws {
        let manager = self.manager(withSystem: false)
        manager.apply(try prepared())
        timers[0].fire()
        XCTAssertEqual(removed, [300])
        XCTAssertEqual(created.count, 1)
        XCTAssertEqual(dispatched.map(\.key), ["awn.call.timeout"])

        manager.apply(try prepared(["state": "ongoing"]))
        manager.apply(try prepared(["state": "ended"]))
        XCTAssertEqual(removed, [300, 300])
        XCTAssertEqual(dispatched.count, 1)
    }

    // MARK: - Methods

    func testMethods() throws {
        let manager = self.manager()
        let handler = CallMethodHandler(manager: { manager })
        manager.apply(try prepared())
        var answers: [Any?] = []
        XCTAssertTrue(handler.handle(method: "callActiveCalls", arguments: nil) { answers.append($0) })
        XCTAssertEqual(answers.last as? NSArray, [["callId": "c-1", "state": "incoming"]] as NSArray)
        XCTAssertTrue(handler.handle(method: "callEnd", arguments: ["callId": "c-1", "reason": "unanswered"]) {
            answers.append($0)
        })
        XCTAssertEqual(system.log.last, "ended unanswered")
        XCTAssertEqual(created.count, 1)
        XCTAssertTrue(handler.handle(method: "callVoipToken", arguments: nil) { answers.append($0) })
        XCTAssertNil(answers.last!)
        XCTAssertTrue(handler.handle(method: "callCanUseFullScreenIntent", arguments: nil) { answers.append($0) })
        XCTAssertEqual(answers.last as? Bool, true)
        XCTAssertTrue(handler.handle(method: "callCapabilities", arguments: nil) { answers.append($0) })
        let capabilities = try XCTUnwrap(answers.last as? [String: Bool])
        #if os(iOS)
        XCTAssertEqual(capabilities, ["systemCallUI": true, "lockScreen": true, "muteAndHold": true, "push": true])
        #else
        XCTAssertEqual(capabilities, ["systemCallUI": false, "lockScreen": false, "muteAndHold": false, "push": false])
        #endif
        XCTAssertFalse(handler.handle(method: "mediaStop", arguments: nil) { _ in })
    }

    // MARK: - Core seam

    func testTheActionInterceptorRegistry() {
        final class Interceptor: NotificationActionInterceptor {
            var seen: [String] = []
            let answer: Bool
            init(_ answer: Bool) { self.answer = answer }
            func onNotificationAction(model: [String: Any], buttonKey: String) -> Bool {
                seen.append(buttonKey)
                return answer
            }
        }
        let registry = NotificationActionInterceptorRegistry.shared
        XCTAssertTrue(registry.shouldEmit(model: [:], buttonKey: "a"))
        let yes = Interceptor(true), no = Interceptor(false)
        registry.register(interceptor: yes)
        registry.register(interceptor: yes)
        XCTAssertTrue(registry.shouldEmit(model: [:], buttonKey: "b"))
        registry.register(interceptor: no)
        XCTAssertFalse(registry.shouldEmit(model: [:], buttonKey: "c"))
        XCTAssertEqual(yes.seen, ["b", "c"])
        XCTAssertEqual(no.seen, ["c"])
        registry.unregister(interceptor: yes)
        registry.unregister(interceptor: no)
        XCTAssertTrue(registry.shouldEmit(model: [:], buttonKey: "d"))
    }
}
