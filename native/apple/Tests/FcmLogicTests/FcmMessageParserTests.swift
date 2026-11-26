import XCTest
import IosAwnCore
@testable import FcmLogic

/// The FCM push → core model translation on iOS: structured JSON strings and
/// dot-flattened keys must both reach the core (images included), with a clean
/// payload and the iOS overrides applied.
final class FcmMessageParserTests: XCTestCase {

    private let parser = FcmMessageParser()

    private func build(_ userInfo: [String: Any]) -> [String: Any] {
        parser.buildAwesomeMap(notificationId: 5, userInfo: userInfo, lifeCycle: .foreground)
    }

    private func content(_ model: [String: Any]) -> [String: Any] {
        model[Definitions.NOTIFICATION_CONTENT] as? [String: Any] ?? [:]
    }

    func testIsDisplayableForFlattenedContent() {
        XCTAssertTrue(parser.isDisplayable(["content.title": "Hi"]))
        XCTAssertFalse(parser.isDisplayable(["orderId": "9"]))
    }

    func testFlattenedPayloadReachesTheCore() {
        let model = build([
            "aps": ["content-available": 1],
            "orderId": "9",
            "content.id": "12",
            "content.channelKey": "push",
            "content.title": "Hi",
            "content.bigPicture": "https://example.com/big.jpg",
            "content.largeIcon": "https://example.com/icon.png",
            "content.displayOnForeground": "true",
            "content.privacy": "null",
            "content.payload.secret": "s3cr3t",
            "actionButtons.0.key": "OK",
            "actionButtons.1.key": "NO"
        ])
        let c = content(model)
        XCTAssertEqual(c[Definitions.NOTIFICATION_ID] as? Int, 12)
        XCTAssertEqual(c[Definitions.NOTIFICATION_CHANNEL_KEY] as? String, "push")
        XCTAssertEqual(c[Definitions.NOTIFICATION_BIG_PICTURE] as? String, "https://example.com/big.jpg")
        XCTAssertEqual(c[Definitions.NOTIFICATION_LARGE_ICON] as? String, "https://example.com/icon.png")
        XCTAssertEqual(c["displayOnForeground"] as? Bool, true)
        XCTAssertNil(c["privacy"])
        XCTAssertEqual(
            c[Definitions.NOTIFICATION_PAYLOAD] as? [String: String],
            ["orderId": "9", "secret": "s3cr3t"]
        )
        XCTAssertEqual((model[Definitions.NOTIFICATION_BUTTONS] as? [Any])?.count, 2)
    }

    func testStructuredPayloadStillWorks() {
        let model = build([
            "content": "{\"id\":3,\"channelKey\":\"push\",\"bigPicture\":\"https://example.com/big.jpg\"}",
            "actionButtons": "[{\"key\":\"OK\"}]"
        ])
        let c = content(model)
        XCTAssertEqual(c[Definitions.NOTIFICATION_ID] as? Int, 3)
        XCTAssertEqual(c[Definitions.NOTIFICATION_BIG_PICTURE] as? String, "https://example.com/big.jpg")
        XCTAssertEqual((model[Definitions.NOTIFICATION_BUTTONS] as? [Any])?.count, 1)
        XCTAssertNil(c[Definitions.NOTIFICATION_PAYLOAD], "section keys must not leak into the payload")
    }

    func testAConversationReachesTheCore() {
        let structured = build([
            "content": "{\"id\":7,\"channelKey\":\"chat\",\"notificationLayout\":\"Messaging\"}",
            "conversation": "{\"id\":\"ana\",\"me\":{\"key\":\"me\",\"name\":\"Me\"},\"message\":{\"sender\":{\"key\":\"ana\",\"name\":\"Ana\"},\"text\":\"Hi\"}}"
        ])
        XCTAssertEqual((structured["conversation"] as? [String: Any])?["id"] as? String, "ana")
        XCTAssertNil(content(structured)[Definitions.NOTIFICATION_PAYLOAD])

        let flattened = build([
            "content.id": "7",
            "content.channelKey": "chat",
            "conversation.id": "ana",
            "conversation.me.key": "me",
            "conversation.me.name": "Me",
            "conversation.message.sender.key": "ana",
            "conversation.message.sender.name": "Ana",
            "conversation.message.text": "Hi",
            "conversation.participants.0.key": "ana",
            "conversation.participants.0.name": "Ana"
        ])
        let conversation = flattened["conversation"] as? [String: Any]
        XCTAssertEqual(conversation?["id"] as? String, "ana")
        XCTAssertEqual(((conversation?["message"] as? [String: Any])?["sender"] as? [String: Any])?["name"] as? String, "Ana")
        XCTAssertEqual((conversation?["participants"] as? [Any])?.count, 1)
        XCTAssertNil(content(flattened)[Definitions.NOTIFICATION_PAYLOAD], "conversation keys must not leak")
    }

    func testIosOverridesApplyAndAndroidOnesAreIgnored() {
        // Overrides are model-shaped, like the Android ones and the original plugin.
        let structured = build([
            "content": "{\"title\":\"Base\",\"channelKey\":\"push\"}",
            "actionButtons": "[{\"key\":\"A\"},{\"key\":\"B\"}]",
            "iOS": "{\"content\":{\"title\":\"iOS\"},\"actionButtons\":[{\"key\":\"I\"}]}",
            "Android": "{\"content\":{\"title\":\"Android\"}}"
        ])
        let sc = content(structured)
        XCTAssertEqual(sc[Definitions.NOTIFICATION_TITLE] as? String, "iOS")
        XCTAssertEqual(sc[Definitions.NOTIFICATION_CHANNEL_KEY] as? String, "push")
        XCTAssertNil(sc[FcmDefinitions.MODEL_CONTENT], "override must not nest content in content")
        XCTAssertEqual((structured[Definitions.NOTIFICATION_BUTTONS] as? [Any])?.count, 1)
        XCTAssertNotNil(sc[Definitions.NOTIFICATION_CREATED_DATE])

        let flattened = build([
            "content.title": "Base",
            "iOS.content.title": "iOS",
            "Android.content.title": "Android"
        ])
        XCTAssertEqual(content(flattened)[Definitions.NOTIFICATION_TITLE] as? String, "iOS")
    }

    func testFlattenerCoercion() {
        XCTAssertEqual(JsonFlattener.coerce("true") as? Bool, true)
        XCTAssertEqual(JsonFlattener.coerce("false") as? Bool, false)
        XCTAssertNil(JsonFlattener.coerce("null"))
        XCTAssertEqual(JsonFlattener.coerce("42") as? String, "42")
    }

    func testNonContiguousIndicesStayAMap() {
        let decoded = JsonFlattener.decode(["x.0": "a", "x.2": "b"])
        XCTAssertNotNil(decoded["x"] as? [String: Any])
    }
}
