import XCTest
@testable import IosAwnCore

/// A decorator that delivers a notification itself (BuiltNotification.handled)
/// posts nothing, yet the core reports it created and displayed.
final class HandledNotificationTests: XCTestCase {

    private final class Handling: NotificationBuilder {
        override func build(model: [String: Any]) throws -> BuiltNotification? {
            return .handled(model: model)
        }
    }

    private final class Recorder: AwesomeEventListener {
        var events: [(String, [String: Any])] = []
        let lock = NSLock()
        func onNewAwesomeEvent(eventType: String, content: [String: Any]) {
            lock.lock(); events.append((eventType, content)); lock.unlock()
        }
    }

    override func setUp() {
        super.setUp()
        NotificationBuilderRegistry.shared.clearForTest()
    }

    override func tearDown() {
        NotificationBuilderRegistry.shared.clearForTest()
        super.tearDown()
    }

    func testStampHandledLifecycle() {
        let builder = NotificationBuilder()
        let stamped = builder.stampHandledLifecycle(
            into: [Definitions.NOTIFICATION_CONTENT: [Definitions.NOTIFICATION_ID: 7]],
            lifeCycle: .background)
        let content = builder.contentMap(fromModel: stamped)
        XCTAssertNotNil(content[Definitions.NOTIFICATION_CREATED_DATE])
        XCTAssertEqual(content[Definitions.NOTIFICATION_DISPLAYED_DATE] as? String,
                       content[Definitions.NOTIFICATION_CREATED_DATE] as? String)
        XCTAssertEqual(content[Definitions.NOTIFICATION_CREATED_LIFECYCLE] as? String, "Background")
        XCTAssertEqual(content[Definitions.NOTIFICATION_DISPLAYED_LIFECYCLE] as? String, "Background")
        XCTAssertEqual(content[Definitions.NOTIFICATION_CREATED_SOURCE] as? String, "Local")

        // Idempotent: stamping again keeps the first dates.
        let again = builder.contentMap(fromModel: builder.stampHandledLifecycle(into: stamped))
        XCTAssertEqual(again[Definitions.NOTIFICATION_CREATED_DATE] as? String,
                       content[Definitions.NOTIFICATION_CREATED_DATE] as? String)
        XCTAssertEqual(again[Definitions.NOTIFICATION_DISPLAYED_LIFECYCLE] as? String, "Background")
    }

    func testAHandledNotificationIsCreatedAndDisplayed() {
        NotificationBuilderRegistry.shared.register(priority: 40) { inner in Handling(inner: inner) }
        let recorder = Recorder()
        AwesomeEventsReceiver.shared.subscribe(listener: recorder)
        defer { AwesomeEventsReceiver.shared.unsubscribe(listener: recorder) }

        let done = expectation(description: "created")
        var answer: Bool?
        AwesomeNotifications.shared.createNotification(
            [Definitions.NOTIFICATION_CONTENT: [
                Definitions.NOTIFICATION_ID: 42, Definitions.NOTIFICATION_CHANNEL_KEY: "media",
                // As Dart sends the unset fields.
                Definitions.NOTIFICATION_CREATED_DATE: NSNull(),
                Definitions.NOTIFICATION_CREATED_SOURCE: NSNull()]],
            completion: { answer = $0; done.fulfill() },
            failure: { _ in done.fulfill() })
        wait(for: [done], timeout: 5)

        XCTAssertEqual(answer, true)
        recorder.lock.lock(); let events = recorder.events; recorder.lock.unlock()
        XCTAssertEqual(events.map { $0.0 },
                       [Definitions.EVENT_NOTIFICATION_CREATED, Definitions.EVENT_NOTIFICATION_DISPLAYED])
        let created = events[0].1, displayed = events[1].1
        XCTAssertEqual(created[Definitions.NOTIFICATION_ID] as? Int, 42)
        XCTAssertNotNil(created[Definitions.NOTIFICATION_CREATED_DATE])
        XCTAssertEqual(created[Definitions.NOTIFICATION_CREATED_SOURCE] as? String, "Local")
        XCTAssertEqual(displayed[Definitions.NOTIFICATION_DISPLAYED_DATE] as? String,
                       created[Definitions.NOTIFICATION_CREATED_DATE] as? String)
        XCTAssertEqual(displayed[Definitions.NOTIFICATION_DISPLAYED_LIFECYCLE] as? String,
                       created[Definitions.NOTIFICATION_CREATED_LIFECYCLE] as? String)
    }
}
