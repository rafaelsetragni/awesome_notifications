import Intents
import XCTest
@testable import ChatLogic
@testable import IosAwnCore

final class ChatBuilderTests: XCTestCase {

    private let me: [String: Any] = ["key": "u-1", "name": "Rafael"]
    private let ana: [String: Any] = ["key": "u-2", "name": "Ana", "uri": "tel:+5511999"]
    private let bia: [String: Any] = ["key": "u-3", "name": "Bia", "uri": "mailto:bia@x.com"]

    private func conversation(title: String? = nil, participants: [[String: Any]]? = nil,
                              sender: [String: Any]? = nil, text: String = "Chegando") -> [String: Any] {
        var map: [String: Any] = [
            "id": "family", "me": me,
            "message": ["sender": sender ?? ana, "text": text],
            "participants": participants ?? [ana]
        ]
        if let title = title { map["title"] = title }
        return map
    }

    private func model(layout: String?, conversation: [String: Any]?) -> [String: Any] {
        var content: [String: Any] = ["id": 1, "channelKey": "chat"]
        if let layout = layout { content["notificationLayout"] = layout }
        var model: [String: Any] = ["content": content]
        if let conversation = conversation { model["conversation"] = conversation }
        return model
    }

    private func detail(_ model: [String: Any]) -> String? {
        do {
            _ = try ChatBuilder(inner: NotificationBuilder()).build(model: model)
            return nil
        } catch let e as AwesomeNotificationsException {
            return e.detailedCode
        } catch {
            return "other"
        }
    }

    func testMessagingLayoutsRequireAConversation() {
        XCTAssertEqual(detail(model(layout: "Messaging", conversation: nil)),
                       "arguments.invalid.notificationConversation")
    }

    func testAConversationRequiresAMessagingLayout() {
        XCTAssertEqual(detail(model(layout: nil, conversation: conversation())),
                       "arguments.invalid.notificationConversation.layout")
    }

    func testGroupsNeedATitleAndParticipants() {
        XCTAssertEqual(detail(model(layout: "MessagingGroup", conversation: conversation())),
                       "arguments.invalid.notificationConversation")
        XCTAssertEqual(detail(model(layout: "MessagingGroup",
                                    conversation: conversation(title: "Família", participants: []))),
                       "arguments.invalid.notificationConversation")
    }

    func testRepeatedPersonKeysAreRejected() {
        XCTAssertEqual(detail(model(layout: "Messaging", conversation: conversation(participants: [ana, ana]))),
                       "arguments.invalid.notificationConversation")
    }

    func testOtherNotificationsAreUntouched() throws {
        let built = try ChatBuilder(inner: NotificationBuilder()).build(model: model(layout: nil, conversation: nil))
        XCTAssertNotNil(built)
    }

    /// Without the Communication Notifications entitlement (as in a test
    /// process) the conversion fails, and so does the create call: there is no
    /// plain-notification fallback.
    func testWithoutTheCapabilityTheCreateCallFails() {
        XCTAssertEqual(detail(model(layout: "Messaging", conversation: conversation())),
                       "insufficientPermissions.communicationNotifications")
    }

    func testTheIntentDescribesTheConversation() throws {
        guard #available(iOS 15.0, macOS 12.0, *) else { throw XCTSkip("needs iOS 15 / macOS 12") }
        let (parsed, _) = ChatConversation.parse(
            conversation(title: "Família", participants: [ana, bia]), isGroup: true)
        let intent = CommunicationContent.intent(for: parsed!, isGroup: true)
        XCTAssertEqual(intent.conversationIdentifier, "family")
        XCTAssertEqual(intent.content, "Chegando")
        XCTAssertEqual(intent.speakableGroupName?.spokenPhrase, "Família")
        XCTAssertEqual(intent.sender?.displayName, "Ana")
        XCTAssertEqual(intent.sender?.personHandle?.type, .phoneNumber)
        XCTAssertEqual(intent.sender?.personHandle?.value, "+5511999")
        // Me plus everyone but the sender.
        XCTAssertEqual(intent.recipients?.map { $0.displayName }, ["Rafael", "Bia"])
        XCTAssertEqual(intent.recipients?.first?.isMe, true)
        XCTAssertEqual(intent.recipients?.last?.personHandle?.type, .emailAddress)
    }

    func testOneToOneHasNoGroupName() throws {
        guard #available(iOS 15.0, macOS 12.0, *) else { throw XCTSkip("needs iOS 15 / macOS 12") }
        let (parsed, _) = ChatConversation.parse(conversation(), isGroup: false)
        let intent = CommunicationContent.intent(for: parsed!, isGroup: false)
        XCTAssertNil(intent.speakableGroupName)
        XCTAssertEqual(intent.recipients?.map { $0.displayName }, ["Rafael"])
    }
}
