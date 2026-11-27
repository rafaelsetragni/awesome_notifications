import Intents
import XCTest
import UserNotifications
@testable import ChatLogic
@testable import IosAwnCore
#if canImport(AppKit)
import AppKit
#endif

/// The chat method channel against a fake notification center: conversations
/// are found by the conversation id stored in the delivered notifications.
final class ChatMethodHandlerTests: XCTestCase {

    private let handler = ChatMethodHandler()
    private var fake: FakeNotificationCenter { .shared }

    override func setUp() {
        super.setUp()
        FakeNotificationCenter.install()
    }

    private func delivered(_ id: String, conversation: String?) -> UNNotification {
        let content = UNMutableNotificationContent()
        if let conversation = conversation {
            content.userInfo = [ChatKeys.userInfoConversationId: conversation]
        }
        return FakeNotificationCenter.notification(
            UNNotificationRequest(identifier: id, content: content, trigger: nil))
    }

    private func call(_ method: String, _ arguments: Any? = nil) -> (handled: Bool, value: Any?) {
        let done = XCTestExpectation(description: method)
        var value: Any?
        let handled = handler.handle(method: method, arguments: arguments) {
            value = $0
            done.fulfill()
        }
        if handled { wait(for: [done], timeout: 5) }
        return (handled, value)
    }

    func testAReplyIsAcknowledged() {
        let answer = call(ChatKeys.methodAddReply, ["id": "family"])
        XCTAssertTrue(answer.handled)
        XCTAssertEqual(answer.value as? Bool, true)
        XCTAssertTrue(fake.read { $0.removedDelivered }.isEmpty)
    }

    func testCapabilities() {
        let answer = call(ChatKeys.methodCapabilities)
        XCTAssertEqual(answer.value as? [String: Bool], [
            "history": false, "reply": true, "avatar": true, "systemConversation": true
        ])
    }

    func testUnknownMethodsAreNotHandled() {
        XCTAssertFalse(call("chatNoSuchMethod").handled)
    }

    func testListsTheActiveConversationsOnce() {
        fake.delivered = [
            delivered("1", conversation: "family"),
            delivered("2", conversation: "work"),
            delivered("3", conversation: "family"),
            delivered("4", conversation: nil)
        ]
        XCTAssertEqual(call(ChatKeys.methodListActive).value as? [String], ["family", "work"])

        fake.delivered = []
        XCTAssertEqual(call(ChatKeys.methodListActive).value as? [String], [])
    }

    func testMarkAsReadRemovesTheConversationNotifications() {
        fake.delivered = [
            delivered("1", conversation: "family"),
            delivered("2", conversation: "work"),
            delivered("3", conversation: "family")
        ]
        XCTAssertEqual(call(ChatKeys.methodMarkAsRead, "family").value as? Bool, true)
        XCTAssertEqual(fake.read { $0.removedDelivered }, [["1", "3"]])

        // Without a conversation id there is nothing to remove.
        XCTAssertEqual(call(ChatKeys.methodMarkAsRead, nil).value as? Bool, true)
        XCTAssertEqual(fake.read { $0.removedDelivered }.count, 1)
    }

    func testRemoveConversationRemovesItsNotifications() {
        fake.delivered = [delivered("1", conversation: "family"), delivered("2", conversation: "work")]
        XCTAssertEqual(call(ChatKeys.methodRemoveConversation, "work").value as? Bool, true)
        XCTAssertEqual(fake.read { $0.removedDelivered }, [["2"]])

        XCTAssertEqual(call(ChatKeys.methodRemoveConversation, 3).value as? Bool, true)
        XCTAssertEqual(fake.read { $0.removedDelivered }.count, 1)
    }
}

/// Conversation validation and the communication-notification setup check.
final class ChatConversationTests: XCTestCase {

    private let me: [String: Any] = ["key": "u-1", "name": "Rafael"]
    private let ana: [String: Any] = ["key": "u-2", "name": "Ana"]

    private func error(_ block: Any?, isGroup: Bool = false) -> String? {
        let (parsed, error) = ChatConversation.parse(block, isGroup: isGroup)
        XCTAssertEqual(parsed == nil, error != nil)
        return error
    }

    func testEveryRequiredPartIsReported() {
        let message: [String: Any] = ["sender": ana, "text": "Oi"]
        XCTAssertEqual(error("not a map"), "The conversation is not a map")
        XCTAssertEqual(error(["me": me, "message": message]), "The conversation needs a non-empty id")
        XCTAssertEqual(error(["id": "  ", "me": me, "message": message]), "The conversation needs a non-empty id")
        XCTAssertEqual(error(["id": "c", "me": ["key": "u-1"], "message": message]),
                       "The conversation needs a person (key and name) as me")
        XCTAssertEqual(error(["id": "c", "me": me, "message": ["sender": ana, "text": " "]]),
                       "The conversation needs a message with a sender (key and name) and a text")
        XCTAssertEqual(error(["id": "c", "me": me, "message": ["text": "Oi"]]),
                       "The conversation needs a message with a sender (key and name) and a text")
        XCTAssertEqual(error(["id": "c", "me": me, "message": message, "participants": [ana, ["name": "x"]]]),
                       "Every participant needs a key and a name")
        XCTAssertEqual(error(["id": "c", "me": me, "message": message, "participants": [me]]),
                       "The person key \"u-1\" is repeated in the conversation")
        XCTAssertEqual(error(["id": "c", "me": me, "message": message, "participants": [ana],
                              "title": "  "], isGroup: true),
                       "A MessagingGroup conversation needs a title")
        XCTAssertNil(error(["id": "c", "me": me, "message": message]))
    }

    func testADisplayNameIsTheGroupTitleOrTheSender() {
        let (group, _) = ChatConversation.parse(
            ["id": "c", "me": me, "message": ["sender": ana, "text": "Oi"], "participants": [ana],
             "title": "Família"], isGroup: true)
        XCTAssertEqual(group?.displayName(isGroup: true), "Família")
        XCTAssertEqual(group?.displayName(isGroup: false), "Ana")
    }

    private func bundle(activityTypes: [String]?) throws -> Bundle {
        let root = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString + ".bundle")
        let contents = root.appendingPathComponent("Contents")
        try FileManager.default.createDirectory(at: contents, withIntermediateDirectories: true)
        addTeardownBlock { try? FileManager.default.removeItem(at: root) }
        var info: [String: Any] = ["CFBundleIdentifier": "test.chat." + UUID().uuidString]
        if let types = activityTypes { info["NSUserActivityTypes"] = types }
        let data = try PropertyListSerialization.data(fromPropertyList: info, format: .xml, options: 0)
        try data.write(to: contents.appendingPathComponent("Info.plist"))
        return try XCTUnwrap(Bundle(url: root))
    }

    func testTheSetupNeedsTheMessageActivityType() throws {
        XCTAssertFalse(CommunicationContent.isConfigured(bundle: try bundle(activityTypes: nil)))
        XCTAssertFalse(CommunicationContent.isConfigured(bundle: try bundle(activityTypes: ["OtherIntent"])))
        #if os(macOS)
        // Declared, but the test process lacks the Communication Notifications
        // entitlement: still not set up.
        XCTAssertFalse(CommunicationContent.isConfigured(
            bundle: try bundle(activityTypes: ["INSendMessageIntent"])))
        #else
        XCTAssertTrue(CommunicationContent.isConfigured(
            bundle: try bundle(activityTypes: ["INSendMessageIntent"])))
        #endif
    }

    #if os(macOS)
    func testAGroupPictureIsLoadedFromItsSource() throws {
        guard #available(macOS 12.0, *) else { throw XCTSkip("needs macOS 12") }
        // Pictures load through the core's media sources.
        XCTAssertNil(CommunicationContent.image(nil))
        XCTAssertNil(CommunicationContent.image(""))
        XCTAssertNil(CommunicationContent.image("file:///no/such/picture.png"))
        let source = "resource://" + NSImage.computerName
        XCTAssertNotNil(CommunicationContent.image(source))

        let (parsed, _) = ChatConversation.parse(
            ["id": "c", "me": me, "message": ["sender": ana, "text": "Oi"],
             "participants": [ana, ["key": "u-3", "name": "Bia", "avatar": source]],
             "title": "Família", "image": source], isGroup: true)
        let intent = CommunicationContent.intent(for: try XCTUnwrap(parsed), isGroup: true)
        XCTAssertNotNil(intent.keyImage(), "the group picture is on the group name")

        // Without a picture the group has none.
        let (plain, _) = ChatConversation.parse(
            ["id": "c", "me": me, "message": ["sender": ana, "text": "Oi"],
             "participants": [ana], "title": "Família"], isGroup: true)
        XCTAssertNil(CommunicationContent.intent(for: try XCTUnwrap(plain), isGroup: true).keyImage())
    }

    func testMyOwnMessageIsSentByMe() throws {
        guard #available(macOS 12.0, *) else { throw XCTSkip("needs macOS 12") }
        let (parsed, _) = ChatConversation.parse(
            ["id": "c", "me": me, "message": ["sender": me, "text": "Oi"], "participants": [ana]],
            isGroup: false)
        let intent = CommunicationContent.intent(for: try XCTUnwrap(parsed), isGroup: false)
        XCTAssertEqual(intent.sender?.isMe, true)
        XCTAssertEqual(intent.sender?.displayName, "Rafael")
    }
    #endif
}
