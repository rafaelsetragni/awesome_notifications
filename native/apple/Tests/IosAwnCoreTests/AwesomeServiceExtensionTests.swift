import XCTest
import UserNotifications
@testable import IosAwnCore

/// The Notification Service Extension base: registers the add-ons once,
/// rebuilds a push through the builder chain, registers its button category and
/// hands the content to the system exactly once (render or expiry).
final class AwesomeServiceExtensionTests: XCTestCase {

    private final class Extension: AwesomeServiceExtension {
        static var registrations = 0
        override func registerAddOns() { Self.registrations += 1 }
    }

    private final class Provider: RemoteModelProvider {
        let answer: [String: Any]?
        init(_ answer: [String: Any]?) { self.answer = answer }
        func model(from request: UNNotificationRequest) -> [String: Any]? { answer }
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
        override func build(model: [String: Any]) throws -> BuiltNotification? { nil }
    }

    private var fake: FakeNotificationCenter { .shared }

    override func setUp() {
        super.setUp()
        FakeNotificationCenter.install()
        RemoteModelProviderRegistry.shared.clearForTest()
        NotificationBuilderRegistry.shared.clearForTest()
        CriticalAlertUtils.setCache(false)
    }

    override func tearDown() {
        RemoteModelProviderRegistry.shared.clearForTest()
        NotificationBuilderRegistry.shared.clearForTest()
        CriticalAlertUtils.clearCache()
        super.tearDown()
    }

    private func push(title: String = "Raw push") -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = title
        return UNNotificationRequest(identifier: "push", content: content, trigger: nil)
    }

    private func pushModel(buttons: [[String: Any]]? = nil) -> [String: Any] {
        var model: [String: Any] = [Definitions.NOTIFICATION_CONTENT: [
            Definitions.NOTIFICATION_ID: 7, Definitions.NOTIFICATION_CHANNEL_KEY: "basic",
            Definitions.NOTIFICATION_TITLE: "Rebuilt"]]
        if let buttons = buttons { model[Definitions.NOTIFICATION_BUTTONS] = buttons }
        return model
    }

    func testRendersThePushOnceAndRegistersTheAddOnsOnce() {
        RemoteModelProviderRegistry.shared.register(Provider(pushModel(buttons: [
            [Definitions.NOTIFICATION_BUTTON_KEY: "reply"]
        ])))
        fake.categories = [UNNotificationCategory(
            identifier: "reply", actions: [], intentIdentifiers: [], options: [])]

        // The first push of the process registers the add-ons (reset here:
        // other test classes in the same process receive pushes too).
        AwesomeServiceExtension.resetAddOnsForTest()
        Extension.registrations = 0
        let first = Extension()
        var delivered: [UNNotificationContent] = []
        first.didReceive(push()) { delivered.append($0) }
        waitUntil("rendered") { delivered.count == 1 }
        XCTAssertEqual(Extension.registrations, 1)
        XCTAssertEqual(delivered[0].title, "Rebuilt")
        XCTAssertEqual(delivered[0].categoryIdentifier, "reply")

        // The button category replaced the same-identifier one.
        let categories = fake.read { $0.categories }
        XCTAssertEqual(categories.count, 1)
        XCTAssertEqual(categories.first?.actions.map { $0.identifier }, ["reply"])

        // The expiry after the render hands nothing more.
        first.serviceExtensionTimeWillExpire()
        XCTAssertEqual(delivered.count, 1)

        // A second push in the same process doesn't register the add-ons again.
        let second = Extension()
        var secondDelivered: [UNNotificationContent] = []
        second.didReceive(push()) { secondDelivered.append($0) }
        waitUntil("second rendered") { secondDelivered.count == 1 }
        XCTAssertEqual(Extension.registrations, 1)
    }

    func testTheExpiryDeliversThePushAsItArrivedOnce() {
        RemoteModelProviderRegistry.shared.register(Provider(pushModel()))
        CriticalAlertUtils.clearCache()
        fake.holdSettings = true

        let ext = Extension()
        var delivered: [UNNotificationContent] = []
        ext.didReceive(push(title: "As it arrived")) { delivered.append($0) }
        XCTAssertTrue(delivered.isEmpty, "waits for the critical-alert availability")

        ext.serviceExtensionTimeWillExpire()
        XCTAssertEqual(delivered.map { $0.title }, ["As it arrived"])

        // The late render finds the handler already used.
        fake.releaseSettings()
        RunLoop.current.run(until: Date().addingTimeInterval(0.05))
        XCTAssertEqual(delivered.count, 1)
    }

    func testTheExpiryWithoutAPushDoesNothing() {
        Extension().serviceExtensionTimeWillExpire()
    }

    func testTheBaseExtensionRegistersNoAddOn() {
        AwesomeServiceExtension().registerAddOns()
        XCTAssertNil(RemoteModelProviderRegistry.shared.model(from: push()))
    }

    func testAPushNoProviderKnowsIsShownAsItArrived() {
        let request = push()
        XCTAssertTrue(AwesomeServiceExtension.render(request) === request.content)
    }

    func testARejectedPushIsShownAsItArrived() {
        RemoteModelProviderRegistry.shared.register(Provider(pushModel()))
        let request = push()

        NotificationBuilderRegistry.shared.register(priority: 10) { Rejecting(inner: $0) }
        XCTAssertTrue(AwesomeServiceExtension.render(request) === request.content)

        NotificationBuilderRegistry.shared.clearForTest()
        NotificationBuilderRegistry.shared.register(priority: 10) {
            Throwing(inner: $0, error: AwesomeNotificationsException(
                code: "INVALID_ARGUMENTS", message: "bad", detailedCode: "ext.reject"))
        }
        XCTAssertTrue(AwesomeServiceExtension.render(request) === request.content)

        NotificationBuilderRegistry.shared.clearForTest()
        NotificationBuilderRegistry.shared.register(priority: 10) {
            Throwing(inner: $0, error: NSError(domain: "x", code: 2))
        }
        XCTAssertTrue(AwesomeServiceExtension.render(request) === request.content)
        XCTAssertTrue(fake.read { $0.categories }.isEmpty)
    }

    func testTheFirstProviderThatKnowsThePushWins() {
        RemoteModelProviderRegistry.shared.register(Provider(nil))
        let winner = Provider(pushModel())
        RemoteModelProviderRegistry.shared.register(winner)
        RemoteModelProviderRegistry.shared.register(winner) // registered once
        RemoteModelProviderRegistry.shared.register(Provider([Definitions.NOTIFICATION_CONTENT: [
            Definitions.NOTIFICATION_ID: 99]]))
        let model = RemoteModelProviderRegistry.shared.model(from: push())
        XCTAssertEqual((model?[Definitions.NOTIFICATION_CONTENT] as? [String: Any])?[Definitions.NOTIFICATION_ID] as? Int, 7)
    }
}
