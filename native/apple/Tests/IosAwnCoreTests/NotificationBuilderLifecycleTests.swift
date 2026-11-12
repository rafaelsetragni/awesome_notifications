import XCTest
import UserNotifications
@testable import IosAwnCore

/// Lifecycle stamping (the persistence that makes created/displayed round-trip to
/// the action) and the ActionType-based build decisions.
final class NotificationBuilderLifecycleTests: XCTestCase {

    private let builder = NotificationBuilder.newInstance()

    private func model(_ content: [String: Any]) -> [String: Any] {
        return [Definitions.NOTIFICATION_CONTENT: content]
    }

    // MARK: - created stamping

    func testStampCreatedAddsFieldsWithSource() {
        let stamped = builder.stampCreatedLifecycle(
            into: model([Definitions.NOTIFICATION_ID: 1]), source: .schedule)
        let content = builder.contentMap(fromModel: stamped)
        XCTAssertEqual(content[Definitions.NOTIFICATION_CREATED_SOURCE] as? String, "Schedule")
        XCTAssertEqual(content[Definitions.NOTIFICATION_CREATED_LIFECYCLE] as? String, "Foreground")
        XCTAssertNotNil(content[Definitions.NOTIFICATION_CREATED_DATE])
    }

    func testStampCreatedIsNoOpWhenAlreadyStamped() {
        let stamped = builder.stampCreatedLifecycle(
            into: model([
                Definitions.NOTIFICATION_ID: 1,
                Definitions.NOTIFICATION_CREATED_DATE: "2020-01-01 00:00:00",
                Definitions.NOTIFICATION_CREATED_SOURCE: "Local"
            ]),
            source: .schedule)
        let content = builder.contentMap(fromModel: stamped)
        // Date already present → the created block is preserved (source stays Local).
        XCTAssertEqual(content[Definitions.NOTIFICATION_CREATED_SOURCE] as? String, "Local")
        XCTAssertEqual(content[Definitions.NOTIFICATION_CREATED_DATE] as? String, "2020-01-01 00:00:00")
    }

    func testBuildStampsCreatedIntoStoredModel() {
        let out = builder.build(model: model([
            Definitions.NOTIFICATION_ID: 7,
            Definitions.NOTIFICATION_CHANNEL_KEY: "basic",
            Definitions.NOTIFICATION_TITLE: "Title"
        ]))
        XCTAssertNotNil(out)
        let content = builder.contentMap(fromModel: out!.model)
        XCTAssertNotNil(content[Definitions.NOTIFICATION_CREATED_DATE])
        XCTAssertEqual(content[Definitions.NOTIFICATION_CREATED_SOURCE] as? String, "Local")
    }

    // MARK: - displayed stamping

    func testStampDisplayedImmediateEqualsCreated() {
        let created = "2020-01-01 00:00:00"
        let built = BuiltNotification(
            id: 1,
            content: UNMutableNotificationContent(),
            trigger: nil,
            model: model([
                Definitions.NOTIFICATION_ID: 1,
                Definitions.NOTIFICATION_CREATED_DATE: created,
                Definitions.NOTIFICATION_CREATED_LIFECYCLE: "Foreground"
            ]))
        let out = builder.stampDisplayed(on: built)
        let content = builder.contentMap(fromModel: out.model)
        XCTAssertEqual(content[Definitions.NOTIFICATION_DISPLAYED_DATE] as? String, created)
        XCTAssertEqual(content[Definitions.NOTIFICATION_DISPLAYED_LIFECYCLE] as? String, "Foreground")
    }

    func testStampDisplayedScheduledUsesTriggerAndTerminated() {
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 60, repeats: false)
        let built = BuiltNotification(
            id: 1,
            content: UNMutableNotificationContent(),
            trigger: trigger,
            model: model([Definitions.NOTIFICATION_ID: 1]))
        let out = builder.stampDisplayed(on: built)
        let content = builder.contentMap(fromModel: out.model)
        XCTAssertEqual(content[Definitions.NOTIFICATION_DISPLAYED_LIFECYCLE] as? String, "Terminated")
        XCTAssertNotNil(content[Definitions.NOTIFICATION_DISPLAYED_DATE])
        // The stored payload is rewritten so the delivered notification carries it.
        XCTAssertNotNil(out.content.userInfo[Definitions.NOTIFICATION_JSON])
    }

    // MARK: - ActionType decisions

    func testButtonActionTypeParses() {
        XCTAssertEqual(
            builder.buttonActionType([Definitions.NOTIFICATION_ACTION_TYPE: "DismissAction"]),
            .dismissAction)
        XCTAssertEqual(builder.buttonActionType(nil), .default)
    }

    func testShouldButtonAutoDismissRules() {
        XCTAssertTrue(
            builder.shouldButtonAutoDismiss([Definitions.NOTIFICATION_ACTION_TYPE: "DismissAction"]))
        XCTAssertFalse(
            builder.shouldButtonAutoDismiss([Definitions.NOTIFICATION_ACTION_TYPE: "KeepOnTop"]))
        XCTAssertFalse(
            builder.shouldButtonAutoDismiss([Definitions.NOTIFICATION_AUTO_DISMISSIBLE: false]))
        XCTAssertTrue(builder.shouldButtonAutoDismiss([:])) // default true
    }
}
