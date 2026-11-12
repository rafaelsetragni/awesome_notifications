import XCTest
@testable import IosAwnCore
#if canImport(UIKit)
import UIKit
#endif

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
        let result = builder.registerCreatedEvent(["id": 1], lifeCycle: .foreground)
        XCTAssertEqual(result[Definitions.NOTIFICATION_CREATED_LIFECYCLE] as? String, "Foreground")
        XCTAssertEqual(result[Definitions.NOTIFICATION_CREATED_SOURCE] as? String, "Local")
        assertIsTimestamp(result[Definitions.NOTIFICATION_CREATED_DATE])
    }

    func testRegisterDisplayedEventStampsFields() {
        let result = builder.registerDisplayedEvent(["id": 1], lifeCycle: .foreground)
        XCTAssertEqual(result[Definitions.NOTIFICATION_DISPLAYED_LIFECYCLE] as? String, "Foreground")
        assertIsTimestamp(result[Definitions.NOTIFICATION_DISPLAYED_DATE])
    }

    func testRegisterActionEventStampsFields() {
        let result = builder.registerActionEvent(["id": 1], lifeCycle: .foreground)
        XCTAssertEqual(result[Definitions.NOTIFICATION_ACTION_TYPE] as? String, "Default")
        XCTAssertEqual(result[Definitions.NOTIFICATION_ACTION_LIFECYCLE] as? String, "Foreground")
        assertIsTimestamp(result[Definitions.NOTIFICATION_ACTION_DATE])
    }

    func testRegisterDismissedEventStampsFields() {
        let result = builder.registerDismissedEvent(["id": 1], lifeCycle: .foreground)
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
        let result = builder.registerCreatedEvent(["id": 99], lifeCycle: .foreground)
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

    // MARK: - images

    #if canImport(UIKit)
    /// Writes a 1x1 PNG to a temp file and returns its `file://` reference.
    private func tempImageReference() throws -> String {
        let image = UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1)).image { ctx in
            UIColor.red.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        }
        let url = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString + ".png")
        try XCTUnwrap(image.pngData()).write(to: url)
        return "file://" + url.path
    }

    func testFirstAttachmentFallsBackWhenBigPictureCannotLoad() throws {
        let largeIcon = try tempImageReference()
        let attachment = builder.firstAttachment(from: ["file:///no/such/image.png", largeIcon])
        XCTAssertNotNil(attachment, "a dead big picture must fall back to the large icon")
    }

    func testFirstAttachmentPrefersBigPicture() throws {
        let bigPicture = try tempImageReference()
        XCTAssertNotNil(builder.firstAttachment(from: [bigPicture, nil]))
    }

    func testFirstAttachmentNilWhenNoSourceLoads() {
        XCTAssertNil(builder.firstAttachment(from: [nil, "", "file:///no/such/image.png"]))
    }

    func testCreateNotificationContentAttachesLargeIconWhenBigPictureIsDead() throws {
        var model = sampleModel()
        var content = model[Definitions.NOTIFICATION_CONTENT] as! [String: Any]
        content[Definitions.NOTIFICATION_BIG_PICTURE] = "file:///no/such/image.png"
        content[Definitions.NOTIFICATION_LARGE_ICON] = try tempImageReference()
        model[Definitions.NOTIFICATION_CONTENT] = content

        let built = try XCTUnwrap(builder.createNotificationContent(fromModel: model))
        XCTAssertEqual(built.content.attachments.count, 1)
    }
    #endif
}
