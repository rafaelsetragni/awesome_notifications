import XCTest
@testable import IosAwnCore

final class NotificationBuilderTests: XCTestCase {

    private let builder = NotificationBuilder.newInstance()
    private let mapUtils = MapUtils.shared

    private func sampleModel() -> [String: Any] {
        return [
            Definitions.NOTIFICATION_CONTENT: [
                Definitions.NOTIFICATION_ID: 7,
                Definitions.NOTIFICATION_CHANNEL_KEY: "basic",
                Definitions.NOTIFICATION_TITLE: "Title",
                Definitions.NOTIFICATION_BODY: "Body"
            ]
        ]
    }

    // MARK: - contentMap

    func testContentMapExtractsContent() {
        let content = builder.contentMap(fromModel: sampleModel())
        XCTAssertEqual(mapUtils.getInt(content[Definitions.NOTIFICATION_ID]), 7)
    }

    func testContentMapWithoutContentReturnsEmpty() {
        XCTAssertTrue(builder.contentMap(fromModel: [:]).isEmpty)
    }

    // MARK: - createNotificationContent

    func testCreateNotificationContentBuildsContent() {
        guard let built = builder.createNotificationContent(fromModel: sampleModel()) else {
            return XCTFail("builder returned nil for a valid model")
        }

        XCTAssertEqual(built.id, 7)
        XCTAssertEqual(built.content.title, "Title")
        XCTAssertEqual(built.content.body, "Body")
        XCTAssertEqual(
            built.content.categoryIdentifier,
            Definitions.DEFAULT_CATEGORY_IDENTIFIER
        )
        XCTAssertNotNil(built.content.userInfo[Definitions.NOTIFICATION_JSON])
    }

    func testCreateNotificationContentWithoutIdReturnsNil() {
        let model: [String: Any] = [
            Definitions.NOTIFICATION_CONTENT: [
                Definitions.NOTIFICATION_CHANNEL_KEY: "basic"
            ]
        ]
        XCTAssertNil(builder.createNotificationContent(fromModel: model))
    }

    // MARK: - payload injection round-trip

    func testInjectedPayloadCanBeRecovered() {
        guard let built = builder.createNotificationContent(fromModel: sampleModel()),
              let model = builder.notificationModel(fromUserInfo: built.content.userInfo) else {
            return XCTFail("could not recover the injected model")
        }

        let content = builder.contentMap(fromModel: model)
        XCTAssertEqual(mapUtils.getInt(content[Definitions.NOTIFICATION_ID]), 7)
        XCTAssertEqual(content[Definitions.NOTIFICATION_TITLE] as? String, "Title")
    }

    func testNotificationModelFromEmptyUserInfoReturnsNil() {
        XCTAssertNil(builder.notificationModel(fromUserInfo: [:]))
    }

    // MARK: - event registration

    func testRegisterCreatedEventStampsFields() {
        let result = builder.registerCreatedEvent(["id": 1], lifeCycle: "Foreground")
        XCTAssertEqual(result[Definitions.NOTIFICATION_CREATED_LIFECYCLE] as? String, "Foreground")
        XCTAssertEqual(result[Definitions.NOTIFICATION_CREATED_SOURCE] as? String, "Local")
        assertIsTimestamp(result[Definitions.NOTIFICATION_CREATED_DATE])
    }

    func testRegisterDisplayedEventStampsFields() {
        let result = builder.registerDisplayedEvent(["id": 1], lifeCycle: "Foreground")
        XCTAssertEqual(result[Definitions.NOTIFICATION_DISPLAYED_LIFECYCLE] as? String, "Foreground")
        assertIsTimestamp(result[Definitions.NOTIFICATION_DISPLAYED_DATE])
    }

    func testRegisterActionEventStampsFields() {
        let result = builder.registerActionEvent(["id": 1], lifeCycle: "Foreground")
        XCTAssertEqual(result[Definitions.NOTIFICATION_ACTION_TYPE] as? String, "Default")
        XCTAssertEqual(result[Definitions.NOTIFICATION_ACTION_LIFECYCLE] as? String, "Foreground")
        assertIsTimestamp(result[Definitions.NOTIFICATION_ACTION_DATE])
    }

    func testRegisterDismissedEventStampsFields() {
        let result = builder.registerDismissedEvent(["id": 1], lifeCycle: "Foreground")
        XCTAssertEqual(result[Definitions.NOTIFICATION_ACTION_LIFECYCLE] as? String, "Foreground")
        assertIsTimestamp(result[Definitions.NOTIFICATION_DISMISSED_DATE])
    }

    // MARK: - dismiss concepts

    func testReadId() {
        XCTAssertEqual(builder.readId([Definitions.NOTIFICATION_ID: 9]), 9)
        XCTAssertNil(builder.readId([:]))
    }

    func testIsDismissActionTrueForDismissActionType() {
        XCTAssertTrue(
            builder.isDismissAction(
                [Definitions.NOTIFICATION_ACTION_TYPE: "DismissAction"]))
        XCTAssertTrue(
            builder.isDismissAction(
                [Definitions.NOTIFICATION_ACTION_TYPE: "ActionType.DismissAction"]))
    }

    func testIsDismissActionFalseOtherwise() {
        XCTAssertFalse(
            builder.isDismissAction(
                [Definitions.NOTIFICATION_ACTION_TYPE: "Default"]))
        XCTAssertFalse(builder.isDismissAction([:]))
    }

    func testRegistrationPreservesOriginalContent() {
        let result = builder.registerCreatedEvent(["id": 99], lifeCycle: "Foreground")
        XCTAssertEqual(mapUtils.getInt(result["id"]), 99)
    }

    /// Asserts the value is a "yyyy-MM-dd HH:mm:ss" timestamp string.
    private func assertIsTimestamp(_ value: Any?) {
        guard let string = value as? String else {
            return XCTFail("expected a timestamp string, got \(String(describing: value))")
        }
        let pattern = #"^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$"#
        XCTAssertNotNil(
            string.range(of: pattern, options: .regularExpression),
            "‘\(string)’ is not a valid timestamp"
        )
    }
}
