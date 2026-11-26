import Foundation
import IosAwnCore

/// Keys of the `conversation` block (same names as the Dart `ChatKeys`).
enum ChatKeys {
    static let conversation = "conversation"

    static let id = "id"
    static let title = "title"
    static let me = "me"
    static let message = "message"
    static let participants = "participants"
    static let image = "image"
    static let history = "history"

    static let sender = "sender"
    static let text = "text"
    static let timestamp = "timestamp"

    /// Added to the content payload: which conversation an action came from.
    static let conversationId = "conversationId"
    /// Stored in the delivered notification's userInfo, to find a conversation.
    static let userInfoConversationId = "awn.chat.conversationId"

    static let methodAddReply = "chatAddReply"
    static let methodMarkAsRead = "chatMarkAsRead"
    static let methodRemoveConversation = "chatRemoveConversation"
    static let methodListActive = "chatListActiveConversations"
    static let methodCapabilities = "chatCapabilities"

    static let layoutMessaging = "Messaging"
    static let layoutMessagingGroup = "MessagingGroup"
}

struct ChatMessage {
    let sender: NotificationPerson
    let text: String
    let image: String?

    init?(_ value: Any?) {
        guard let map = value as? [String: Any],
              let sender = NotificationPerson(map[ChatKeys.sender]),
              let text = map[ChatKeys.text] as? String, !text.trimmingCharacters(in: .whitespaces).isEmpty
        else { return nil }
        self.sender = sender
        self.text = text
        image = map[ChatKeys.image] as? String
    }
}

struct ChatConversation {
    let id: String
    let me: NotificationPerson
    let message: ChatMessage
    let title: String?
    let participants: [NotificationPerson]
    let image: String?

    func displayName(isGroup: Bool) -> String {
        if isGroup, let title = title, !title.isEmpty { return title }
        return message.sender.name
    }

    /// Parses and validates the block like the Dart side (push messages never
    /// pass through Dart). The error is the message to report.
    static func parse(_ block: Any?, isGroup: Bool) -> (ChatConversation?, String?) {
        guard let map = block as? [String: Any] else { return (nil, "The conversation is not a map") }
        guard let id = map[ChatKeys.id] as? String, !id.trimmingCharacters(in: .whitespaces).isEmpty else {
            return (nil, "The conversation needs a non-empty id")
        }
        guard let me = NotificationPerson(map[ChatKeys.me]) else {
            return (nil, "The conversation needs a person (key and name) as me")
        }
        guard let message = ChatMessage(map[ChatKeys.message]) else {
            return (nil, "The conversation needs a message with a sender (key and name) and a text")
        }
        var participants: [NotificationPerson] = []
        for raw in (map[ChatKeys.participants] as? [Any]) ?? [] {
            guard let person = NotificationPerson(raw) else {
                return (nil, "Every participant needs a key and a name")
            }
            participants.append(person)
        }
        var keys: Set<String> = [me.key]
        for person in participants where !keys.insert(person.key).inserted {
            return (nil, "The person key \"\(person.key)\" is repeated in the conversation")
        }
        let title = (map[ChatKeys.title] as? String).flatMap { $0.trimmingCharacters(in: .whitespaces).isEmpty ? nil : $0 }
        if isGroup && title == nil { return (nil, "A MessagingGroup conversation needs a title") }
        if isGroup && participants.isEmpty {
            return (nil, "A MessagingGroup conversation needs its participants")
        }
        return (ChatConversation(id: id, me: me, message: message, title: title,
                                 participants: participants, image: map[ChatKeys.image] as? String), nil)
    }
}
