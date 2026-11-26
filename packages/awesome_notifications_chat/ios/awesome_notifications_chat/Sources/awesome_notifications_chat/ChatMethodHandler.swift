import Foundation
import Intents
import IosAwnCore
import UserNotifications

/// Answers the AwesomeNotificationsChat channel methods on iOS and macOS.
public final class ChatMethodHandler: AwesomeMethodHandler {

    public init() {}

    private var center: UNUserNotificationCenter { .current() }

    public func handle(method: String, arguments: Any?, result: @escaping (Any?) -> Void) -> Bool {
        switch method {
        case ChatKeys.methodAddReply:
            // iOS never shows the user's own messages in a notification: the
            // reply is already in the app.
            result(true)
        case ChatKeys.methodMarkAsRead:
            removeDelivered(arguments as? String) { result(true) }
        case ChatKeys.methodRemoveConversation:
            let id = arguments as? String
            removeDelivered(id) {
                guard let id = id else { result(true); return }
                // Also forget the donated interactions of the conversation.
                INInteraction.delete(with: id) { _ in result(true) }
            }
        case ChatKeys.methodListActive:
            center.getDeliveredNotifications { delivered in
                var ids: [String] = []
                for notification in delivered {
                    if let id = notification.request.content.userInfo[ChatKeys.userInfoConversationId] as? String,
                       !ids.contains(id) {
                        ids.append(id)
                    }
                }
                result(ids)
            }
        case ChatKeys.methodCapabilities:
            result([
                "history": false,  // each message is its own notification, threaded
                "reply": true,
                "avatar": true,
                "systemConversation": true
            ])
        default:
            return false
        }
        return true
    }

    private func removeDelivered(_ conversationId: String?, done: @escaping () -> Void) {
        guard let conversationId = conversationId else { done(); return }
        center.getDeliveredNotifications { delivered in
            let ids = delivered
                .filter { $0.request.content.userInfo[ChatKeys.userInfoConversationId] as? String == conversationId }
                .map { $0.request.identifier }
            self.center.removeDeliveredNotifications(withIdentifiers: ids)
            done()
        }
    }
}
