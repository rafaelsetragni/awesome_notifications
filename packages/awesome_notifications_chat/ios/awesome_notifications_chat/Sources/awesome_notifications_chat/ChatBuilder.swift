import Foundation
import Intents
import IosAwnCore
import UserNotifications

/// Takes over the `Messaging` / `MessagingGroup` layouts on iOS and macOS: every
/// message is a communication notification (an `INSendMessageIntent` the content
/// is updated from), threaded by its conversation. There is no fallback: when the
/// conversion fails (the app lacks the Communication Notifications capability,
/// or the OS is older than iOS 15 / macOS 12) the create call fails.
public final class ChatBuilder: NotificationBuilder {

    public static let priority = 50

    public override func build(model: [String: Any]) throws -> BuiltNotification? {
        var content = contentMap(fromModel: model)
        let layout = content["notificationLayout"] as? String
        let isMessaging = layout == ChatKeys.layoutMessaging || layout == ChatKeys.layoutMessagingGroup
        let block = model[ChatKeys.conversation]

        guard block != nil else {
            if isMessaging {
                throw Self.invalid("The \(layout!) layout requires a NotificationConversation",
                                   ".notificationConversation")
            }
            return try next(model)
        }
        guard isMessaging else {
            throw Self.invalid("A NotificationConversation requires the Messaging or MessagingGroup layout",
                               ".notificationConversation.layout")
        }
        let isGroup = layout == ChatKeys.layoutMessagingGroup
        let (parsed, error) = ChatConversation.parse(block, isGroup: isGroup)
        guard let conversation = parsed else {
            throw Self.invalid(error ?? "Invalid conversation", ".notificationConversation")
        }

        // What platforms without a conversation UI show, and the payload that
        // tells actions which conversation they came from.
        if ((content["title"] as? String) ?? "").isEmpty {
            content["title"] = conversation.displayName(isGroup: isGroup)
        }
        if ((content["body"] as? String) ?? "").isEmpty {
            content["body"] = conversation.message.text
        }
        var payload = (content["payload"] as? [String: Any]) ?? [:]
        if payload[ChatKeys.conversationId] == nil { payload[ChatKeys.conversationId] = conversation.id }
        content["payload"] = payload
        // The person avatars are the notification's images; a message image
        // is its attachment.
        content.removeValue(forKey: "largeIcon")
        content["bigPicture"] = conversation.message.image

        var updated = model
        updated["content"] = content
        guard let built = try next(updated) else { return nil }

        let communication = try CommunicationContent.make(
            from: built.content, conversation: conversation, isGroup: isGroup)
        return BuiltNotification(id: built.id, content: communication,
                                 trigger: built.trigger, model: built.model)
    }

    static func invalid(_ message: String, _ detail: String) -> AwesomeNotificationsException {
        AwesomeNotificationsException(
            code: AwesomeNotificationsException.CODE_INVALID_ARGUMENTS,
            message: message,
            detailedCode: AwesomeNotificationsException.DETAILED_INVALID_ARGUMENTS + detail)
    }
}

/// Builds the `INSendMessageIntent` of a message and turns a notification's
/// content into a communication notification.
enum CommunicationContent {

    static let notSetUp = AwesomeNotificationsException(
        code: "INSUFFICIENT_PERMISSIONS",
        message: "Communication notifications are not set up: add the Communication Notifications "
            + "capability and INSendMessageIntent to NSUserActivityTypes (see the package README)",
        detailedCode: "insufficientPermissions.communicationNotifications")

    static func make(
        from content: UNMutableNotificationContent,
        conversation: ChatConversation,
        isGroup: Bool
    ) throws -> UNMutableNotificationContent {
        guard #available(iOS 15.0, macOS 12.0, *), isConfigured() else { throw notSetUp }
        let intent = intent(for: conversation, isGroup: isGroup)

        let interaction = INInteraction(intent: intent, response: nil)
        interaction.direction = .incoming
        interaction.groupIdentifier = conversation.id
        interaction.donate(completion: nil)

        let updated: UNNotificationContent
        do {
            updated = try content.updating(from: intent)
        } catch {
            throw notSetUp
        }
        guard let mutable = updated.mutableCopy() as? UNMutableNotificationContent else {
            throw notSetUp
        }
        mutable.threadIdentifier = conversation.id
        var userInfo = mutable.userInfo
        // updating(from:) keeps the content; restore the core's payload anyway.
        for (key, value) in content.userInfo where userInfo[key] == nil { userInfo[key] = value }
        userInfo[ChatKeys.userInfoConversationId] = conversation.id
        mutable.userInfo = userInfo
        return mutable
    }

    /// `updating(from:)` succeeds even without the capability (the system then
    /// shows a plain notification), so the setup is checked first: the
    /// `INSendMessageIntent` activity type in the Info.plist and, on macOS, the
    /// Communication Notifications entitlement (iOS doesn't let an app read
    /// its entitlements).
    static func isConfigured(bundle: Bundle = .main) -> Bool {
        let types = bundle.object(forInfoDictionaryKey: "NSUserActivityTypes") as? [String] ?? []
        guard types.contains("INSendMessageIntent") else { return false }
        #if os(macOS)
        guard let task = SecTaskCreateFromSelf(nil),
              let value = SecTaskCopyValueForEntitlement(
                  task, "com.apple.developer.usernotifications.communication" as CFString, nil)
        else { return false }
        return (value as? Bool) == true
        #else
        return true
        #endif
    }

    @available(iOS 15.0, macOS 12.0, *)
    static func intent(for conversation: ChatConversation, isGroup: Bool) -> INSendMessageIntent {
        let me = person(conversation.me, isMe: true)
        let sender = conversation.message.sender.key == conversation.me.key
            ? me : person(conversation.message.sender, isMe: false)
        // A group's recipients are all its members, the sender included: iOS
        // reads a group (and shows the group's picture) only when the message
        // goes to more than one person besides the user.
        let members = conversation.participants
            .filter { $0.key != conversation.me.key }
            .map { $0.key == conversation.message.sender.key ? sender : person($0, isMe: false) }
        let recipients = isGroup ? [me] + members : [me]

        let intent = INSendMessageIntent(
            recipients: recipients,
            outgoingMessageType: .outgoingMessageText,
            content: conversation.message.text,
            speakableGroupName: isGroup ? INSpeakableString(spokenPhrase: conversation.title ?? "") : nil,
            conversationIdentifier: conversation.id,
            serviceName: nil,
            sender: sender,
            attachments: nil)
        if isGroup, let image = image(conversation.image) {
            setGroupImage(image, on: intent)
        }
        return intent
    }

    /// The group's picture, on the group name. The macOS SDK hides
    /// `setImage(_:forParameterNamed:)` from AppKit apps (only Mac Catalyst
    /// sees it), but the system's Intents framework implements it, so macOS
    /// calls it through the Objective-C runtime.
    @available(iOS 15.0, macOS 12.0, *)
    static func setGroupImage(_ image: INImage, on intent: INSendMessageIntent) {
        #if os(iOS)
        intent.setImage(image, forParameterNamed: \.speakableGroupName)
        #else
        let selector = NSSelectorFromString("setImage:forParameterNamed:")
        guard intent.responds(to: selector) else { return }
        typealias SetImage = @convention(c) (AnyObject, Selector, INImage?, NSString) -> Void
        let call = unsafeBitCast(intent.method(for: selector), to: SetImage.self)
        call(intent, selector, image, "speakableGroupName")
        #endif
    }

    @available(iOS 15.0, macOS 12.0, *)
    static func person(_ person: NotificationPerson, isMe: Bool) -> INPerson {
        INPerson(
            personHandle: handle(person),
            nameComponents: nil,
            displayName: person.name,
            image: image(person.avatar),
            contactIdentifier: nil,
            customIdentifier: person.key,
            isMe: isMe,
            suggestionType: .none)
    }

    /// A `tel:` / `mailto:` URI is the person's phone / e-mail handle; otherwise
    /// the key identifies them (the core's `NotificationPerson.handle`).
    @available(iOS 15.0, macOS 12.0, *)
    static func handle(_ person: NotificationPerson) -> INPersonHandle {
        return person.handle.inPersonHandle
    }

    @available(iOS 15.0, macOS 12.0, *)
    static func image(_ source: String?) -> INImage? {
        guard let source = source, !source.isEmpty,
              let bitmap = BitmapUtils.shared.getBitmapFromSource(source),
              let data = BitmapUtils.shared.pngData(bitmap)
        else { return nil }
        return INImage(imageData: data)
    }
}
