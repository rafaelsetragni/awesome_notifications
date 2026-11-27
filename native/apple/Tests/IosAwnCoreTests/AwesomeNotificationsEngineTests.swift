import XCTest
import UserNotifications
@testable import IosAwnCore

/// The engine (`AwesomeNotifications`) against a fake notification center:
/// what it posts, removes and registers, and the events it broadcasts.
///
/// The engine is a process-wide singleton whose launch phase only settles once.
/// `test00…` exercises that phase first (XCTest runs methods alphabetically), and
/// every other test that taps a notification lives in this class, after it.
final class AwesomeNotificationsEngineTests: XCTestCase {

    private let core = AwesomeNotifications.shared
    private let builder = NotificationBuilder()
    private var fake: FakeNotificationCenter { .shared }
    private var recorder: EventRecorder!

    override func setUp() {
        super.setUp()
        FakeNotificationCenter.install()
        NotificationBuilderRegistry.shared.clearForTest()
        ChannelManager.shared.clearForTest()
        RemoteModelProviderRegistry.shared.clearForTest()
        CriticalAlertUtils.setCache(false)
        AppLifeCycle.current = .foreground
        recorder = EventRecorder()
        AwesomeEventsReceiver.shared.subscribe(listener: recorder)
    }

    override func tearDown() {
        AwesomeEventsReceiver.shared.unsubscribe(listener: recorder)
        NotificationBuilderRegistry.shared.clearForTest()
        ChannelManager.shared.clearForTest()
        RemoteModelProviderRegistry.shared.clearForTest()
        CriticalAlertUtils.clearCache()
        AppLifeCycle.current = .foreground
        super.tearDown()
    }

    // MARK: - Helpers

    private func receive(_ response: UNNotificationResponse) {
        var completed = 0
        core.userNotificationCenter(
            UNUserNotificationCenter.current(), didReceive: response
        ) { completed += 1 }
        XCTAssertEqual(completed, 1, "didReceive must complete exactly once")
    }

    private func tap(_ model: [String: Any], action: String = UNNotificationDefaultActionIdentifier) {
        receive(FakeNotificationCenter.response(EngineFixtures.delivered(model), action: action))
    }

    private func present(_ notification: UNNotification) -> UNNotificationPresentationOptions? {
        var options: UNNotificationPresentationOptions?
        core.userNotificationCenter(
            UNUserNotificationCenter.current(), willPresent: notification
        ) { options = $0 }
        return options
    }

    private func create(_ model: [String: Any]) -> (created: Bool?, failure: AwesomeNotificationsException?) {
        let done = expectation(description: "create")
        var created: Bool?
        var failure: AwesomeNotificationsException?
        core.createNotification(
            model,
            completion: { created = $0; XCTAssertTrue(Thread.isMainThread); done.fulfill() },
            failure: { failure = $0; XCTAssertTrue(Thread.isMainThread); done.fulfill() })
        wait(for: [done], timeout: 5)
        return (created, failure)
    }

    private final class Throwing: NotificationBuilder {
        let error: Error
        init(inner: NotificationBuilder?, error: Error) {
            self.error = error
            super.init(inner: inner)
        }
        override func build(model: [String: Any]) throws -> BuiltNotification? { throw error }
    }

    private final class Rejecting: NotificationBuilder {
        override func build(model: [String: Any]) throws -> BuiltNotification? { return nil }
    }

    private final class Interceptor: NotificationActionInterceptor {
        var emit = false
        var seen: [String] = []
        func onNotificationAction(model: [String: Any], buttonKey: String) -> Bool {
            seen.append(buttonKey)
            return emit
        }
    }

    private final class Provider: RemoteModelProvider {
        let answer: [String: Any]?
        init(_ answer: [String: Any]?) { self.answer = answer }
        func model(from request: UNNotificationRequest) -> [String: Any]? { answer }
    }

    // MARK: - Launch (must run first)

    func test00TheTapThatLaunchedTheAppIsTheInitialAction() {
        // Before the launch settles, getInitialAction is parked.
        var answers: [[String: Any]?] = []
        core.getInitialAction(removeFromEvents: false) { answers.append($0) }
        XCTAssertTrue(answers.isEmpty)

        // The router parks its request the same way.
        var routedAnswers = 0
        var routed: Any?
        XCTAssertTrue(AwesomeMethodRouter().handle(method: "getInitialAction", arguments: false) {
            routedAnswers += 1
            routed = $0
        })
        XCTAssertEqual(routedAnswers, 0, "parked: not answered yet")

        tap(EngineFixtures.model(id: 501))

        // The launching tap is reported as an action of a terminated app and
        // settles the parked request with it.
        // Only the latest parked request is kept: the router's replaced the first.
        XCTAssertTrue(answers.isEmpty)
        XCTAssertEqual(routedAnswers, 1)
        let initial = routed as? [String: Any]
        XCTAssertEqual(initial?[Definitions.NOTIFICATION_ID] as? Int, 501)
        XCTAssertEqual(initial?[Definitions.NOTIFICATION_ACTION_LIFECYCLE] as? String, "Terminated")
        XCTAssertEqual(initial?[Definitions.NOTIFICATION_ACTION_TYPE] as? String, "Default")
        XCTAssertNotNil(initial?[Definitions.NOTIFICATION_ACTION_DATE])
        XCTAssertEqual(recorder.names, [Definitions.EVENT_DEFAULT_ACTION])
        XCTAssertEqual(recorder.events[0].data[Definitions.NOTIFICATION_ACTION_LIFECYCLE] as? String,
                       "Terminated")

        // finishLaunching is idempotent: nothing pending, nothing answered twice.
        core.finishLaunching()
        XCTAssertEqual(routedAnswers, 1)
        XCTAssertTrue(answers.isEmpty)

        // Once settled it answers at once; removeFromEvents consumes it.
        var again: [String: Any]?
        core.getInitialAction(removeFromEvents: true) { again = $0 }
        XCTAssertEqual(again?[Definitions.NOTIFICATION_ID] as? Int, 501)
        var after: [String: Any]? = ["sentinel": true]
        core.getInitialAction(removeFromEvents: false) { after = $0 }
        XCTAssertNil(after)

        // A later tap is a foreground action, not an initial one.
        recorder.clear()
        tap(EngineFixtures.model(id: 502))
        XCTAssertEqual(recorder.events.last?.data[Definitions.NOTIFICATION_ACTION_LIFECYCLE] as? String,
                       "Foreground")
        core.getInitialAction(removeFromEvents: false) { after = $0 }
        XCTAssertNil(after)
    }

    // MARK: - Initialization

    func testInitializeClaimsTheDelegateAndRegistersTheDismissCategory() {
        fake.categories = [UNNotificationCategory(
            identifier: "kept", actions: [], intentIdentifiers: [], options: [])]
        core.initialize(channels: [
            [Definitions.NOTIFICATION_CHANNEL_KEY: "alpha"],
            [Definitions.NOTIFICATION_CHANNEL_KEY: "beta", Definitions.NOTIFICATION_IMPORTANCE: "High"]
        ])

        XCTAssertTrue(fake.delegate === core)
        let ids = Set(fake.categories.map { $0.identifier })
        XCTAssertEqual(ids, ["kept", Definitions.DEFAULT_CATEGORY_IDENTIFIER])
        let category = fake.categories.first { $0.identifier == Definitions.DEFAULT_CATEGORY_IDENTIFIER }
        XCTAssertTrue(category!.options.contains(.customDismissAction))
        XCTAssertNotNil(ChannelManager.shared.channel(forKey: "alpha"))
        XCTAssertEqual(ChannelManager.shared.channel(forKey: "beta")?[Definitions.NOTIFICATION_IMPORTANCE] as? String,
                       "High")
    }

    func testAttachClaimsTheDelegateAndSetChannelRegisters() {
        core.attachToNotificationCenter()
        XCTAssertTrue(fake.delegate === core)
        core.setChannel([Definitions.NOTIFICATION_CHANNEL_KEY: "gamma"])
        XCTAssertNotNil(ChannelManager.shared.channel(forKey: "gamma"))
    }

    // MARK: - Permissions

    func testRequestPermissionAsksAlertBadgeSoundAndAnswersOnMain() {
        CriticalAlertUtils.setCache(true)
        let done = expectation(description: "answer")
        var granted: Bool?
        core.requestPermission { granted = $0; XCTAssertTrue(Thread.isMainThread); done.fulfill() }
        wait(for: [done], timeout: 5)
        XCTAssertEqual(granted, true)
        XCTAssertEqual(fake.read { $0.requestedOptions }, [.alert, .badge, .sound])
        // The answer may change the critical-alert availability: the cache is dropped.
        XCTAssertFalse(CriticalAlertUtils.canDeliverCriticalAlerts())
    }

    func testRequestPermissionFailureAnswersFalse() {
        fake.authorizationGranted = false
        fake.authorizationError = NSError(domain: "UNErrorDomain", code: 1)
        let done = expectation(description: "answer")
        var granted: Bool?
        core.requestPermission { granted = $0; done.fulfill() }
        wait(for: [done], timeout: 5)
        XCTAssertEqual(granted, false)
    }

    func testIsNotificationAllowedFollowsTheAuthorization() {
        let cases: [(UNAuthorizationStatus, Bool)] = [
            (.authorized, true), (.provisional, true), (.denied, false), (.notDetermined, false)
        ]
        for (status, expected) in cases {
            fake.settings = FakeNotificationCenter.makeSettings(
                authorizationStatus: status, criticalAlert: .enabled)
            let done = expectation(description: "allowed")
            var allowed: Bool?
            core.isNotificationAllowed { allowed = $0; XCTAssertTrue(Thread.isMainThread); done.fulfill() }
            wait(for: [done], timeout: 5)
            XCTAssertEqual(allowed, expected, "\(status.rawValue)")
            // Reading the settings refreshes the critical-alert availability.
            XCTAssertTrue(CriticalAlertUtils.canDeliverCriticalAlerts())
        }
    }

    func testGetPermissionStatusesReadsTheSettings() {
        fake.settings = FakeNotificationCenter.makeSettings(
            authorizationStatus: .authorized, alert: .enabled, sound: .disabled, badge: .enabled)
        let done = expectation(description: "statuses")
        var statuses: [String: String] = [:]
        core.getPermissionStatuses(["Alert", "Sound", "Badge", "Car", "Light"], filteringByChannelKey: nil) {
            statuses = $0
            XCTAssertTrue(Thread.isMainThread)
            done.fulfill()
        }
        wait(for: [done], timeout: 5)
        XCTAssertEqual(statuses, [
            "Alert": "granted", "Sound": "denied", "Badge": "granted",
            "Car": "notSupported", "Light": "granted"
        ])
    }

    func testPermissionsInsideAnExtensionAreAllGranted() {
        PermissionManager.isRunningOnExtension = true
        defer { PermissionManager.isRunningOnExtension = false }
        fake.settings = FakeNotificationCenter.makeSettings(authorizationStatus: .denied)
        var statuses: [String: String] = [:]
        PermissionManager.shared.getPermissionStatuses(["Alert", "CriticalAlert"], filteringByChannelKey: "x") {
            statuses = $0
        }
        XCTAssertEqual(statuses, ["Alert": "granted", "CriticalAlert": "granted"])
        XCTAssertEqual(fake.read { $0.settingsReads }, 0, "never asks the center")
    }

    func testPermissionSettingsFromTheSystemSettings() {
        let settings = PermissionSettings(FakeNotificationCenter.makeSettings(
            authorizationStatus: .provisional, alert: .disabled, sound: .enabled, badge: .notSupported,
            criticalAlert: .enabled))
        XCTAssertEqual(settings.authorizationStatus, .provisional)
        XCTAssertEqual(settings.alertSetting, .disabled)
        XCTAssertEqual(settings.soundSetting, .enabled)
        XCTAssertEqual(settings.badgeSetting, .notSupported)
        XCTAssertEqual(settings.carPlaySetting, .notSupported, "macOS has no CarPlay")
        XCTAssertEqual(settings.criticalAlertSetting, .enabled)
    }

    // MARK: - Create

    func testCreatePostsTheRequestAndEmitsCreated() {
        let answer = create(EngineFixtures.model(id: 10, content: [
            Definitions.NOTIFICATION_CATEGORY: "Call",
            Definitions.NOTIFICATION_FULL_SCREEN_INTENT: true,
            Definitions.NOTIFICATION_WAKE_UP_SCREEN: true
        ]))
        XCTAssertEqual(answer.created, true)
        XCTAssertNil(answer.failure)

        let added = fake.read { $0.added }
        XCTAssertEqual(added.map { $0.identifier }, ["10"])
        XCTAssertNil(added[0].trigger)
        XCTAssertEqual(added[0].content.title, "Title 10")
        XCTAssertEqual(added[0].content.categoryIdentifier, Definitions.DEFAULT_CATEGORY_IDENTIFIER)
        // The stored payload carries the predicted displayed lifecycle.
        let stored = builder.contentMap(fromModel: builder.notificationModel(
            fromUserInfo: added[0].content.userInfo)!)
        XCTAssertEqual(stored[Definitions.NOTIFICATION_DISPLAYED_LIFECYCLE] as? String, "Foreground")
        XCTAssertEqual(stored[Definitions.NOTIFICATION_WAKE_UP_SCREEN] as? Bool, true)

        waitUntil("created event") { recorder.names == [Definitions.EVENT_NOTIFICATION_CREATED] }
        let created = recorder.events[0].data
        XCTAssertEqual(created[Definitions.NOTIFICATION_ID] as? Int, 10)
        XCTAssertEqual(created[Definitions.NOTIFICATION_CREATED_SOURCE] as? String, "Local")
        XCTAssertEqual(created[Definitions.NOTIFICATION_CREATED_LIFECYCLE] as? String, "Foreground")
        // Fields the 0.12 events never carried.
        XCTAssertNil(created[Definitions.NOTIFICATION_CATEGORY])
        XCTAssertNil(created[Definitions.NOTIFICATION_FULL_SCREEN_INTENT])
        XCTAssertNil(created[Definitions.NOTIFICATION_WAKE_UP_SCREEN])
    }

    func testCreateRegistersTheButtonsCategory() {
        let answer = create(EngineFixtures.model(id: 11, buttons: [
            [Definitions.NOTIFICATION_BUTTON_KEY: "reply", Definitions.NOTIFICATION_BUTTON_LABEL: "Reply",
             Definitions.NOTIFICATION_REQUIRE_INPUT_TEXT: true,
             Definitions.NOTIFICATION_ACTION_TYPE: "SilentAction"],
            [Definitions.NOTIFICATION_BUTTON_KEY: "open",
             Definitions.NOTIFICATION_AUTHENTICATION_REQUIRED: true],
            [Definitions.NOTIFICATION_BUTTON_KEY: "delete", Definitions.NOTIFICATION_BUTTON_LABEL: "Delete",
             Definitions.NOTIFICATION_IS_DANGEROUS_OPTION: true,
             Definitions.NOTIFICATION_ACTION_TYPE: "DismissAction"],
            [Definitions.NOTIFICATION_BUTTON_LABEL: "No key: skipped"],
            [Definitions.NOTIFICATION_BUTTON_KEY: "", Definitions.NOTIFICATION_BUTTON_LABEL: "Empty: skipped"]
        ]))
        XCTAssertEqual(answer.created, true)

        let added = fake.read { $0.added }
        XCTAssertEqual(added.first?.content.categoryIdentifier, "reply,open,delete")
        waitUntil("category registered") { fake.read { $0.categories.count } == 1 }
        let category = fake.read { $0.categories.first }!
        XCTAssertEqual(category.identifier, "reply,open,delete")
        XCTAssertTrue(category.options.contains(.customDismissAction))
        XCTAssertEqual(category.actions.map { $0.identifier }, ["reply", "open", "delete"])

        let reply = category.actions[0]
        XCTAssertTrue(reply is UNTextInputNotificationAction)
        XCTAssertEqual(reply.title, "Reply")
        XCTAssertFalse(reply.options.contains(.foreground), "a silent action stays in background")

        let open = category.actions[1]
        XCTAssertFalse(open is UNTextInputNotificationAction)
        XCTAssertEqual(open.title, "open", "the key labels a button without a label")
        XCTAssertTrue(open.options.contains(.foreground))
        XCTAssertTrue(open.options.contains(.authenticationRequired))

        let delete = category.actions[2]
        XCTAssertTrue(delete.options.contains(.destructive))
        XCTAssertFalse(delete.options.contains(.foreground))
    }

    func testButtonsWithoutKeysRegisterNoCategory() {
        XCTAssertNil(builder.actionCategory(forModel: EngineFixtures.model(id: 1, buttons: [
            [Definitions.NOTIFICATION_BUTTON_LABEL: "No key"]
        ])))
        XCTAssertNil(builder.actionCategory(forModel: EngineFixtures.model(id: 1)))
    }

    func testANotificationWithoutGroupTakesItsChannelGroup() {
        core.setChannel([Definitions.NOTIFICATION_CHANNEL_KEY: "grouped",
                         Definitions.NOTIFICATION_GROUP_KEY: "channel-group"])
        XCTAssertEqual(create(EngineFixtures.model(id: 12, channelKey: "grouped")).created, true)
        XCTAssertEqual(create(EngineFixtures.model(
            id: 13, channelKey: "grouped", content: [Definitions.NOTIFICATION_GROUP_KEY: "own"])).created, true)
        XCTAssertEqual(create(EngineFixtures.model(id: 14, channelKey: "unknown")).created, true)
        core.setChannel([Definitions.NOTIFICATION_CHANNEL_KEY: "emptyGroup",
                         Definitions.NOTIFICATION_GROUP_KEY: ""])
        XCTAssertEqual(create(EngineFixtures.model(id: 15, channelKey: "emptyGroup")).created, true)

        let threads = fake.read { $0.added }.map { $0.content.threadIdentifier }
        XCTAssertEqual(threads, ["channel-group", "own", "", ""])
        let stored = builder.contentMap(fromModel: builder.notificationModel(
            fromUserInfo: fake.read { $0.added }[0].content.userInfo)!)
        XCTAssertEqual(stored[Definitions.NOTIFICATION_GROUP_KEY] as? String, "channel-group")
    }

    func testAFailedPostAnswersFalseWithoutEvent() {
        fake.addError = NSError(domain: "UNErrorDomain", code: 9)
        XCTAssertEqual(create(EngineFixtures.model(id: 16)).created, false)
        RunLoop.current.run(until: Date().addingTimeInterval(0.05))
        XCTAssertTrue(recorder.names.isEmpty)
    }

    func testAnInvalidModelIsNotCreated() {
        XCTAssertEqual(create([Definitions.NOTIFICATION_CONTENT: [
            Definitions.NOTIFICATION_CHANNEL_KEY: "basic"]]).created, false)
        XCTAssertTrue(fake.read { $0.added }.isEmpty)
    }

    func testADecoratorRejectionAnswersFalse() {
        NotificationBuilderRegistry.shared.register(priority: 10) { Rejecting(inner: $0) }
        XCTAssertEqual(create(EngineFixtures.model(id: 17)).created, false)
        XCTAssertTrue(fake.read { $0.added }.isEmpty)
    }

    func testADecoratorExceptionIsReportedAsFailure() {
        let exception = AwesomeNotificationsException(
            code: "INVALID_ARGUMENTS", message: "nope", detailedCode: "test.reject")
        NotificationBuilderRegistry.shared.register(priority: 10) { Throwing(inner: $0, error: exception) }
        let answer = create(EngineFixtures.model(id: 18))
        XCTAssertNil(answer.created)
        XCTAssertEqual(answer.failure?.detailedCode, "test.reject")

        // The two-argument variant reports it as false.
        let done = expectation(description: "false")
        var created: Bool?
        core.createNotification(EngineFixtures.model(id: 18)) { created = $0; done.fulfill() }
        wait(for: [done], timeout: 5)
        XCTAssertEqual(created, false)
    }

    func testAnyOtherBuildErrorAnswersFalse() {
        NotificationBuilderRegistry.shared.register(priority: 10) {
            Throwing(inner: $0, error: NSError(domain: "x", code: 1))
        }
        let answer = create(EngineFixtures.model(id: 19))
        XCTAssertEqual(answer.created, false)
        XCTAssertNil(answer.failure)
    }

    func testCreateResolvesTheCriticalAlertAvailabilityFirst() {
        CriticalAlertUtils.clearCache()
        fake.settings = FakeNotificationCenter.makeSettings(criticalAlert: .enabled)
        core.setChannel([Definitions.NOTIFICATION_CHANNEL_KEY: "critical",
                         Definitions.NOTIFICATION_CHANNEL_CRITICAL_ALERTS: true])
        XCTAssertEqual(create(EngineFixtures.model(id: 20, channelKey: "critical")).created, true)
        XCTAssertEqual(fake.read { $0.settingsReads }, 1)
        XCTAssertTrue(CriticalAlertUtils.canDeliverCriticalAlerts())
        if #available(macOS 12.0, iOS 15.0, *) {
            XCTAssertEqual(fake.read { $0.added }.first?.content.interruptionLevel, .critical)
        }
        // Cached now: the next one does not read the settings again.
        XCTAssertEqual(create(EngineFixtures.model(id: 21, channelKey: "critical")).created, true)
        XCTAssertEqual(fake.read { $0.settingsReads }, 1)
    }

    // MARK: - Foreground display

    func testWillPresentEmitsDisplayedAndShowsTheBanner() {
        AppLifeCycle.current = .background
        let options = present(EngineFixtures.delivered(EngineFixtures.model(id: 30, content: [
            Definitions.NOTIFICATION_WAKE_UP_SCREEN: true])))
        XCTAssertEqual(options, [.banner, .list, .sound, .badge])
        XCTAssertEqual(recorder.names, [Definitions.EVENT_NOTIFICATION_DISPLAYED])
        let displayed = recorder.events[0].data
        XCTAssertEqual(displayed[Definitions.NOTIFICATION_ID] as? Int, 30)
        XCTAssertEqual(displayed[Definitions.NOTIFICATION_DISPLAYED_LIFECYCLE] as? String, "Background")
        XCTAssertNil(displayed[Definitions.NOTIFICATION_WAKE_UP_SCREEN])

        // The later action reports the real displayed lifecycle, not the prediction.
        recorder.clear()
        AppLifeCycle.current = .foreground
        tap(EngineFixtures.model(id: 30))
        XCTAssertEqual(recorder.events.last?.data[Definitions.NOTIFICATION_DISPLAYED_LIFECYCLE] as? String,
                       "Background")
    }

    func testWillPresentOfAForeignNotificationOnlyShowsIt() {
        XCTAssertEqual(present(EngineFixtures.foreign()), [.banner, .list, .sound, .badge])
        XCTAssertTrue(recorder.names.isEmpty)
    }

    #if os(macOS)
    func testAPushAnAddOnRebuildsIsNotShownTwiceOnMacOS() {
        RemoteModelProviderRegistry.shared.register(Provider(EngineFixtures.model(id: 31)))
        let push = EngineFixtures.foreign(id: "push", trigger: FakeNotificationCenter.pushTrigger())
        XCTAssertEqual(present(push), [])
        XCTAssertTrue(recorder.names.isEmpty)
    }

    func testAPushNoAddOnKnowsIsShownOnMacOS() {
        RemoteModelProviderRegistry.shared.register(Provider(nil))
        let push = EngineFixtures.foreign(id: "push", trigger: FakeNotificationCenter.pushTrigger())
        XCTAssertEqual(present(push), [.banner, .list, .sound, .badge])
    }

    func testAnAwesomePushIsShownOnMacOS() {
        RemoteModelProviderRegistry.shared.register(Provider(EngineFixtures.model(id: 32)))
        let request = EngineFixtures.request(
            EngineFixtures.model(id: 32), trigger: FakeNotificationCenter.pushTrigger())
        XCTAssertEqual(present(FakeNotificationCenter.notification(request)), [.banner, .list, .sound, .badge])
        XCTAssertEqual(recorder.names, [Definitions.EVENT_NOTIFICATION_DISPLAYED])
    }
    #endif

    // MARK: - Responses

    func testASwipeIsADismissalWithoutRemoval() {
        tap(EngineFixtures.model(id: 40), action: UNNotificationDismissActionIdentifier)
        XCTAssertEqual(recorder.names, [Definitions.EVENT_NOTIFICATION_DISMISSED])
        let dismissed = recorder.events[0].data
        XCTAssertEqual(dismissed[Definitions.NOTIFICATION_ID] as? Int, 40)
        XCTAssertEqual(dismissed[Definitions.NOTIFICATION_ACTION_LIFECYCLE] as? String, "Foreground")
        XCTAssertNotNil(dismissed[Definitions.NOTIFICATION_DISMISSED_DATE])
        XCTAssertNil(dismissed[Definitions.NOTIFICATION_BUTTON_KEY_PRESSED])
        XCTAssertTrue(fake.read { $0.removedDelivered }.isEmpty, "the system already removed it")
    }

    func testTappingADismissActionNotificationDismissesIt() {
        tap(EngineFixtures.model(id: 41, content: [Definitions.NOTIFICATION_ACTION_TYPE: "DismissAction"]))
        XCTAssertEqual(recorder.names, [Definitions.EVENT_NOTIFICATION_DISMISSED])
        XCTAssertEqual(fake.read { $0.removedDelivered }, [["41"]])
    }

    func testADismissButtonDismissesWithItsKey() {
        tap(EngineFixtures.model(id: 42, buttons: [
            [Definitions.NOTIFICATION_BUTTON_KEY: "close", Definitions.NOTIFICATION_ACTION_TYPE: "DismissAction"]
        ]), action: "close")
        XCTAssertEqual(recorder.names, [Definitions.EVENT_NOTIFICATION_DISMISSED])
        XCTAssertEqual(recorder.events[0].data[Definitions.NOTIFICATION_BUTTON_KEY_PRESSED] as? String, "close")
        XCTAssertEqual(fake.read { $0.removedDelivered }, [["42"]])
    }

    func testATextInputButtonCarriesTheTypedText() {
        let model = EngineFixtures.model(id: 43, buttons: [
            [Definitions.NOTIFICATION_BUTTON_KEY: "reply", Definitions.NOTIFICATION_REQUIRE_INPUT_TEXT: true,
             Definitions.NOTIFICATION_ACTION_TYPE: "SilentAction"]
        ])
        receive(FakeNotificationCenter.textResponse(
            EngineFixtures.delivered(model), action: "reply", text: "on my way"))
        XCTAssertEqual(recorder.names, [Definitions.EVENT_DEFAULT_ACTION])
        let action = recorder.events[0].data
        XCTAssertEqual(action[Definitions.NOTIFICATION_BUTTON_KEY_PRESSED] as? String, "reply")
        XCTAssertEqual(action[Definitions.NOTIFICATION_BUTTON_KEY_INPUT] as? String, "on my way")
        XCTAssertEqual(action[Definitions.NOTIFICATION_ACTION_TYPE] as? String, "SilentAction")
        XCTAssertEqual(action[Definitions.NOTIFICATION_ACTION_LIFECYCLE] as? String, "Foreground")
        // autoDismissible defaults to true.
        XCTAssertEqual(fake.read { $0.removedDelivered }, [["43"]])
    }

    func testAKeepOnTopButtonKeepsTheNotification() {
        tap(EngineFixtures.model(id: 44, buttons: [
            [Definitions.NOTIFICATION_BUTTON_KEY: "pin", Definitions.NOTIFICATION_ACTION_TYPE: "KeepOnTop"]
        ]), action: "pin")
        XCTAssertEqual(recorder.names, [Definitions.EVENT_DEFAULT_ACTION])
        XCTAssertEqual(recorder.events[0].data[Definitions.NOTIFICATION_ACTION_TYPE] as? String, "KeepOnTop")
        XCTAssertTrue(fake.read { $0.removedDelivered }.isEmpty)
    }

    func testAPlainTapIsNotRemovedByTheCore() {
        tap(EngineFixtures.model(id: 45))
        XCTAssertEqual(recorder.names, [Definitions.EVENT_DEFAULT_ACTION])
        XCTAssertNil(recorder.events[0].data[Definitions.NOTIFICATION_BUTTON_KEY_PRESSED])
        XCTAssertTrue(fake.read { $0.removedDelivered }.isEmpty, "iOS removes a tapped notification")
    }

    func testAnInterceptorCanKeepTheEvent() {
        let interceptor = Interceptor()
        NotificationActionInterceptorRegistry.shared.register(interceptor: interceptor)
        defer { NotificationActionInterceptorRegistry.shared.unregister(interceptor: interceptor) }
        let model = EngineFixtures.model(id: 46, buttons: [
            [Definitions.NOTIFICATION_BUTTON_KEY: "accept"],
            [Definitions.NOTIFICATION_BUTTON_KEY: "decline", Definitions.NOTIFICATION_ACTION_TYPE: "DismissAction"]
        ])

        tap(model, action: "accept")
        tap(model, action: "decline")
        XCTAssertEqual(interceptor.seen, ["accept", "decline"])
        XCTAssertTrue(recorder.names.isEmpty)
        // The buttons still dismiss their notification.
        XCTAssertEqual(fake.read { $0.removedDelivered }, [["46"], ["46"]])

        // A plain tap is not the interceptor's to keep.
        tap(model)
        XCTAssertEqual(interceptor.seen, ["accept", "decline"])
        XCTAssertEqual(recorder.names, [Definitions.EVENT_DEFAULT_ACTION])

        // Allowed: the event goes out.
        interceptor.emit = true
        recorder.clear()
        tap(model, action: "accept")
        XCTAssertEqual(recorder.names, [Definitions.EVENT_DEFAULT_ACTION])
    }

    func testAResponseToAForeignNotificationIsIgnored() {
        receive(FakeNotificationCenter.response(EngineFixtures.foreign(), action: "x"))
        XCTAssertTrue(recorder.names.isEmpty)
        XCTAssertTrue(fake.read { $0.removedDelivered }.isEmpty)
    }

    // MARK: - Controls that are not buttons

    func testDispatchActionEmitsAndAutoDismisses() {
        core.dispatchAction(model: EngineFixtures.model(id: 50), buttonKey: "next", input: "7")
        XCTAssertEqual(recorder.names, [Definitions.EVENT_DEFAULT_ACTION])
        XCTAssertEqual(recorder.events[0].data[Definitions.NOTIFICATION_BUTTON_KEY_PRESSED] as? String, "next")
        XCTAssertEqual(recorder.events[0].data[Definitions.NOTIFICATION_BUTTON_KEY_INPUT] as? String, "7")
        XCTAssertEqual(fake.read { $0.removedDelivered }, [["50"]])

        recorder.clear()
        core.dispatchAction(
            model: EngineFixtures.model(id: 51), buttonKey: "seek",
            button: [Definitions.NOTIFICATION_BUTTON_KEY: "seek", Definitions.NOTIFICATION_ACTION_TYPE: "KeepOnTop"])
        XCTAssertEqual(recorder.names, [Definitions.EVENT_DEFAULT_ACTION])
        XCTAssertEqual(fake.read { $0.removedDelivered }, [["50"]], "KeepOnTop never dismisses")

        recorder.clear()
        core.dispatchAction(
            model: EngineFixtures.model(id: 52), buttonKey: "stop",
            button: [Definitions.NOTIFICATION_BUTTON_KEY: "stop",
                     Definitions.NOTIFICATION_ACTION_TYPE: "DismissAction"])
        XCTAssertEqual(recorder.names, [Definitions.EVENT_NOTIFICATION_DISMISSED])
        XCTAssertEqual(fake.read { $0.removedDelivered }, [["50"], ["52"]])
    }

    // MARK: - Dismiss / cancel

    func testDismissAndCancelById() {
        let removals = RemovalRecorder()
        NotificationRemovalRegistry.shared.register(listener: removals)
        defer { NotificationRemovalRegistry.shared.unregister(listener: removals) }

        core.dismiss(id: 60)
        XCTAssertEqual(fake.read { $0.removedDelivered }, [["60"]])
        XCTAssertTrue(fake.read { $0.removedPending }.isEmpty, "dismiss keeps the schedule")

        core.cancel(id: 61)
        XCTAssertEqual(fake.read { $0.removedDelivered }, [["60"], ["61"]])
        XCTAssertEqual(fake.read { $0.removedPending }, [["61"]])

        XCTAssertEqual(removals.removals.map { $0.0 }, [.id(60), .id(61)])
        XCTAssertEqual(removals.removals.map { $0.1 }, [false, true])
    }

    func testDismissAndCancelAll() {
        let removals = RemovalRecorder()
        NotificationRemovalRegistry.shared.register(listener: removals)
        defer { NotificationRemovalRegistry.shared.unregister(listener: removals) }

        core.dismissAllNotifications()
        XCTAssertEqual(fake.read { $0.removedAllDelivered }, 1)
        XCTAssertEqual(fake.read { $0.removedAllPending }, 0)
        core.cancelAll()
        XCTAssertEqual(fake.read { $0.removedAllDelivered }, 2)
        XCTAssertEqual(fake.read { $0.removedAllPending }, 1)
        XCTAssertEqual(removals.removals.map { $0.0 }, [.all, .all])
        XCTAssertEqual(removals.removals.map { $0.1 }, [false, true])
    }

    func testADismissedNotificationForgetsItsDisplayRecord() {
        _ = present(EngineFixtures.delivered(EngineFixtures.model(id: 62)))
        AppLifeCycle.current = .background
        _ = present(EngineFixtures.delivered(EngineFixtures.model(id: 63)))
        AppLifeCycle.current = .foreground
        core.dismiss(id: 63)
        recorder.clear()
        // Without the record the stored prediction (created lifecycle) stands.
        tap(EngineFixtures.model(id: 63))
        XCTAssertEqual(recorder.events.last?.data[Definitions.NOTIFICATION_DISPLAYED_LIFECYCLE] as? String,
                       "Foreground")
    }

    private func seedCenter() {
        fake.delivered = [
            EngineFixtures.delivered(EngineFixtures.model(id: 70, channelKey: "news",
                content: [Definitions.NOTIFICATION_GROUP_KEY: "sports"])),
            EngineFixtures.delivered(EngineFixtures.model(id: 71, channelKey: "chat")),
            EngineFixtures.delivered(EngineFixtures.model(id: 72, channelKey: "news")),
            EngineFixtures.foreign()
        ]
        fake.pending = [
            EngineFixtures.request(EngineFixtures.model(id: 73, channelKey: "news",
                content: [Definitions.NOTIFICATION_GROUP_KEY: "sports"])),
            EngineFixtures.request(EngineFixtures.model(id: 74, channelKey: "chat")),
            EngineFixtures.foreign(id: "pending-foreign").request
        ]
    }

    func testDismissByChannelAndGroupRemovesOnlyTheMatchingDelivered() {
        seedCenter()
        let removals = RemovalRecorder()
        NotificationRemovalRegistry.shared.register(listener: removals)
        defer { NotificationRemovalRegistry.shared.unregister(listener: removals) }

        core.dismissByChannelKey("news")
        waitUntil("delivered by channel") { fake.read { $0.removedDelivered }.count == 1 }
        XCTAssertEqual(fake.read { $0.removedDelivered }, [["70", "72"]])

        core.dismissByGroupKey("sports")
        waitUntil("delivered by group") { fake.read { $0.removedDelivered }.count == 2 }
        XCTAssertEqual(fake.read { $0.removedDelivered }.last, ["70"])
        XCTAssertTrue(fake.read { $0.removedPending }.isEmpty)

        // Nothing matches: the center is not asked to remove anything.
        core.dismissByChannelKey("nobody")
        RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        XCTAssertEqual(fake.read { $0.removedDelivered }.count, 2)

        XCTAssertEqual(removals.removals.map { $0.0 },
                       [.channelKey("news"), .groupKey("sports"), .channelKey("nobody")])
        XCTAssertEqual(removals.removals.map { $0.1 }, [false, false, false])
    }

    func testCancelByChannelAndGroupAlsoRemovesThePending() {
        seedCenter()
        let removals = RemovalRecorder()
        NotificationRemovalRegistry.shared.register(listener: removals)
        defer { NotificationRemovalRegistry.shared.unregister(listener: removals) }

        core.cancelByChannelKey("chat")
        waitUntil("cancel by channel") {
            fake.read { $0.removedDelivered.count == 1 && $0.removedPending.count == 1 }
        }
        XCTAssertEqual(fake.read { $0.removedDelivered }, [["71"]])
        XCTAssertEqual(fake.read { $0.removedPending }, [["74"]])

        core.cancelByGroupKey("sports")
        waitUntil("cancel by group") {
            fake.read { $0.removedDelivered.count == 2 && $0.removedPending.count == 2 }
        }
        XCTAssertEqual(fake.read { $0.removedDelivered }.last, ["70"])
        XCTAssertEqual(fake.read { $0.removedPending }.last, ["73"])

        XCTAssertEqual(removals.removals.map { $0.0 }, [.channelKey("chat"), .groupKey("sports")])
        XCTAssertEqual(removals.removals.map { $0.1 }, [true, true])
    }

    // MARK: - Method router (the calls that reach the engine)

    private func call(_ method: String, _ arguments: Any? = nil) -> Any? {
        let done = expectation(description: method)
        var value: Any?
        XCTAssertTrue(AwesomeMethodRouter.shared.handle(method: method, arguments: arguments) {
            value = $0
            done.fulfill()
        })
        wait(for: [done], timeout: 5)
        return value
    }

    func testRouterInitializeAndChannels() {
        XCTAssertEqual(call("initialize", [Definitions.INITIALIZE_CHANNELS: [
            [Definitions.NOTIFICATION_CHANNEL_KEY: "routed"]
        ]]) as? Bool, true)
        XCTAssertTrue(fake.delegate === core)
        XCTAssertNotNil(ChannelManager.shared.channel(forKey: "routed"))

        XCTAssertEqual(call("initialize", "no map") as? Bool, true)

        XCTAssertEqual(call("setNotificationChannel", [Definitions.NOTIFICATION_CHANNEL_KEY: "set"]) as? Bool, true)
        XCTAssertNotNil(ChannelManager.shared.channel(forKey: "set"))
        XCTAssertEqual(call("setNotificationChannel", "no map") as? Bool, true)
    }

    func testRouterPermissions() {
        XCTAssertEqual(call("isNotificationAllowed") as? Bool, true)

        let requested = ["Alert", "Sound"]
        XCTAssertEqual(call("requestNotifications", [Definitions.NOTIFICATION_PERMISSIONS: requested]) as? [String], [])
        fake.authorizationGranted = false
        XCTAssertEqual(call("requestNotifications", [Definitions.NOTIFICATION_PERMISSIONS: requested]) as? [String],
                       requested, "answers the permissions still missing")
        XCTAssertEqual(call("requestNotifications") as? [String], [])

        fake.settings = FakeNotificationCenter.makeSettings(authorizationStatus: .denied)
        XCTAssertEqual(call("getPermissionStatuses", [
            Definitions.NOTIFICATION_PERMISSIONS: ["Alert", "Vibration"],
            Definitions.NOTIFICATION_CHANNEL_KEY: "missing"
        ]) as? [String: String], ["Alert": "denied", "Vibration": "denied"])
    }

    func testRouterCreatesAndAnswersTheInitialAction() {
        XCTAssertEqual(call("createNewNotification", EngineFixtures.model(id: 80)) as? Bool, true)
        XCTAssertEqual(fake.read { $0.added }.map { $0.identifier }, ["80"])

        let exception = AwesomeNotificationsException(
            code: "INVALID_ARGUMENTS", message: "nope", detailedCode: "router.reject")
        NotificationBuilderRegistry.shared.register(priority: 10) { Throwing(inner: $0, error: exception) }
        XCTAssertEqual((call("createNewNotification", EngineFixtures.model(id: 81)) as? AwesomeNotificationsException)?
            .detailedCode, "router.reject")

        // The launch settled in test00: answered at once.
        XCTAssertNil(call("getInitialAction", true))
    }

    func testRouterRemovals() {
        XCTAssertEqual(call("dismissNotification", 90) as? Bool, true)
        XCTAssertEqual(call("cancelNotification", "91") as? Bool, true)
        XCTAssertEqual(call("dismissNotification", "not an id") as? Bool, true)
        XCTAssertEqual(call("cancelNotification", nil) as? Bool, true)
        XCTAssertEqual(fake.read { $0.removedDelivered }, [["90"], ["91"]])
        XCTAssertEqual(fake.read { $0.removedPending }, [["91"]])

        let removals = RemovalRecorder()
        NotificationRemovalRegistry.shared.register(listener: removals)
        defer { NotificationRemovalRegistry.shared.unregister(listener: removals) }
        for method in ["dismissNotificationsByChannelKey", "cancelNotificationsByChannelKey",
                       "dismissNotificationsByGroupKey", "cancelNotificationsByGroupKey"] {
            XCTAssertEqual(call(method, "k") as? Bool, true, method)
            XCTAssertEqual(call(method, 3) as? Bool, true, "a non-string key is ignored")
        }
        XCTAssertEqual(call("dismissAllNotifications") as? Bool, true)
        XCTAssertEqual(call("cancelAllNotifications") as? Bool, true)

        XCTAssertEqual(removals.removals.map { $0.0 }, [
            .channelKey("k"), .channelKey("k"), .groupKey("k"), .groupKey("k"), .all, .all])
        XCTAssertEqual(removals.removals.map { $0.1 }, [false, true, false, true, false, true])
        XCTAssertEqual(fake.read { $0.removedAllDelivered }, 2)
        XCTAssertEqual(fake.read { $0.removedAllPending }, 1)
    }
}
