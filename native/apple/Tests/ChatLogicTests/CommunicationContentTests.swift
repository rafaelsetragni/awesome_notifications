import Intents
import ObjectiveC
import UserNotifications
import XCTest
@testable import ChatLogic
@testable import IosAwnCore

#if os(macOS)
/// What a correctly set-up chat app has and the test runner lacks: the
/// `INSendMessageIntent` activity type in the main bundle's Info.plist and the
/// Communication Notifications entitlement. Both are stood in for during a test.
private enum CommunicationSetup {
    static let entitlement = "com.apple.developer.usernotifications.communication"

    /// `SecTaskCopyValueForEntitlement` answering true for the entitlement.
    static let copyEntitlement: @convention(c) (
        OpaquePointer?, CFString, UnsafeMutableRawPointer?
    ) -> UnsafeMutableRawPointer? = { _, key, _ in
        guard (key as String) == CommunicationSetup.entitlement else { return nil }
        return Unmanaged.passRetained(kCFBooleanTrue as CFTypeRef).toOpaque()
    }

    static var declaresActivityType = false
}

extension Bundle {
    /// Swapped with `object(forInfoDictionaryKey:)` while a test declares the
    /// activity type in the main bundle.
    @objc fileprivate func awnTest_object(forInfoDictionaryKey key: String) -> Any? {
        if CommunicationSetup.declaresActivityType, self == Bundle.main, key == "NSUserActivityTypes" {
            return ["INSendMessageIntent"]
        }
        return awnTest_object(forInfoDictionaryKey: key)  // the original, once swapped
    }
}

/// A message of a set-up app becomes a communication notification threaded by
/// its conversation.
final class CommunicationContentTests: XCTestCase {

    private let rebinder = SymbolRebinder()
    private var swapped: (Method, Method)?

    override func setUpWithError() throws {
        try super.setUpWithError()
        guard #available(macOS 12.0, *) else { throw XCTSkip("needs macOS 12") }
        let patched = rebinder.rebind(
            "SecTaskCopyValueForEntitlement",
            to: unsafeBitCast(CommunicationSetup.copyEntitlement, to: UnsafeRawPointer.self),
            inImage: "ChatLogicTests")
        guard patched > 0 else { throw XCTSkip("could not stand in for the entitlement") }

        let original = class_getInstanceMethod(Bundle.self, #selector(Bundle.object(forInfoDictionaryKey:)))!
        let replacement = class_getInstanceMethod(Bundle.self, #selector(Bundle.awnTest_object(forInfoDictionaryKey:)))!
        method_exchangeImplementations(original, replacement)
        swapped = (original, replacement)
        CommunicationSetup.declaresActivityType = true
    }

    override func tearDown() {
        CommunicationSetup.declaresActivityType = false
        if let (original, replacement) = swapped { method_exchangeImplementations(original, replacement) }
        swapped = nil
        rebinder.restore()
        super.tearDown()
    }

    private let me: [String: Any] = ["key": "u-1", "name": "Rafael"]
    private let ana: [String: Any] = ["key": "u-2", "name": "Ana", "uri": "tel:+5511999"]
    private let bia: [String: Any] = ["key": "u-3", "name": "Bia"]

    private func build(layout: String, conversation: [String: Any],
                       content extra: [String: Any] = [:]) throws -> BuiltNotification {
        var content: [String: Any] = ["id": 9, "channelKey": "chat", "notificationLayout": layout]
        for (key, value) in extra { content[key] = value }
        return try XCTUnwrap(ChatBuilder(inner: NotificationBuilder()).build(
            model: ["content": content, "conversation": conversation]))
    }

    func testTheStandInsMakeTheAppSetUp() {
        XCTAssertTrue(CommunicationContent.isConfigured())
    }

    func testAMessageBecomesACommunicationNotification() throws {
        let built = try build(layout: "Messaging", conversation: [
            "id": "family", "me": me, "participants": [ana],
            "message": ["sender": ana, "text": "Chegando"]
        ], content: ["payload": ["order": "42"]])

        XCTAssertEqual(built.id, 9)
        XCTAssertEqual(built.content.threadIdentifier, "family")
        XCTAssertEqual(built.content.body, "Chegando")
        XCTAssertEqual(built.content.userInfo["awn.chat.conversationId"] as? String, "family")
        // The core's stored model survives the conversion (a tap reaches Dart).
        let stored = try XCTUnwrap(NotificationBuilder().notificationModel(fromUserInfo: built.content.userInfo))
        let payload = (stored["content"] as? [String: Any])?["payload"] as? [String: Any]
        XCTAssertEqual(payload?["conversationId"] as? String, "family")
        XCTAssertEqual(payload?["order"] as? String, "42")
        XCTAssertEqual((built.model["content"] as? [String: Any])?["title"] as? String, "Ana")
    }

    func testAGroupMessageKeepsTheTriggerAndModel() throws {
        let built = try build(layout: "MessagingGroup", conversation: [
            "id": "friends", "title": "Amigos", "me": me, "participants": [ana, bia],
            "message": ["sender": bia, "text": "Oi"]
        ])
        XCTAssertEqual(built.content.threadIdentifier, "friends")
        XCTAssertEqual(built.content.userInfo["awn.chat.conversationId"] as? String, "friends")
        XCTAssertNil(built.trigger)
        XCTAssertEqual((built.model["content"] as? [String: Any])?["title"] as? String, "Amigos")
    }
}
#endif
