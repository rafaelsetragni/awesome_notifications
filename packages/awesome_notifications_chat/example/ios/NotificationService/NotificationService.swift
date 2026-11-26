import AwesomeNotificationsChatExtension
import AwesomeNotificationsFcmExtension
import IosAwnCore

/// Rebuilds every awesome push before iOS shows it: FCM parses the payload and
/// the chat add-on turns a conversation into a communication notification.
class NotificationService: AwesomeServiceExtension {
    override func registerAddOns() {
        AwesomeFcmExtension.register()
        AwesomeChatExtension.register()
    }
}
