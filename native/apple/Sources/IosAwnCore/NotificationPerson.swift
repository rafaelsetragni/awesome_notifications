import Foundation
#if canImport(Intents)
import Intents
#endif

/// Someone taking part in a notification — a conversation's sender, a call's
/// caller — as the Dart `NotificationPerson` serializes it. Add-ons (chat,
/// calls) parse their people with it, so they read and validate them alike.
public struct NotificationPerson: Equatable {

    /// The map keys, shared with the Dart side.
    public static let keyKey = "key"
    public static let keyName = "name"
    public static let keyAvatar = "avatar"
    public static let keyUri = "uri"
    public static let keyIsBot = "isBot"
    public static let keyIsImportant = "isImportant"

    /// A stable, unique identifier of the person.
    public let key: String
    /// The name shown in the notification.
    public let name: String
    /// The avatar: `asset://`, `file://`, `https://` or `resource://`.
    public let avatar: String?
    /// A `tel:`, `mailto:` or contact URI.
    public let uri: String?
    /// A machine rather than a human (only Android shows it).
    public let isBot: Bool
    /// Someone the user talks to often (only Android shows it).
    public let isImportant: Bool

    public init(
        key: String,
        name: String,
        avatar: String? = nil,
        uri: String? = nil,
        isBot: Bool = false,
        isImportant: Bool = false
    ) {
        self.key = key
        self.name = name
        self.avatar = avatar
        self.uri = uri
        self.isBot = isBot
        self.isImportant = isImportant
    }

    /// Parses a person map; nil unless it is a map with a non-blank `key` and
    /// `name`. A missing or non-boolean `isBot` / `isImportant` is false.
    public init?(_ value: Any?) {
        guard let map = value as? [String: Any],
              let key = map[Self.keyKey] as? String,
              !key.trimmingCharacters(in: .whitespaces).isEmpty,
              let name = map[Self.keyName] as? String,
              !name.trimmingCharacters(in: .whitespaces).isEmpty
        else { return nil }
        self.init(
            key: key,
            name: name,
            avatar: map[Self.keyAvatar] as? String,
            uri: map[Self.keyUri] as? String,
            isBot: (map[Self.keyIsBot] as? Bool) == true,
            isImportant: (map[Self.keyIsImportant] as? Bool) == true)
    }

    /// The person's handle: a `tel:` URI is a phone number, a `mailto:` URI an
    /// e-mail address (both without the scheme); otherwise the key, of unknown
    /// type. CallKit's `CXHandle` and Intents' `INPersonHandle` both use it.
    public var handle: NotificationPersonHandle {
        return NotificationPersonHandle(person: self)
    }
}

/// The kind of a person's handle.
public enum NotificationPersonHandleType: Equatable {
    case phoneNumber
    case emailAddress
    case unknown
}

/// How a person is reached: a phone number, an e-mail address, or an opaque
/// identifier (the person's key).
public struct NotificationPersonHandle: Equatable {
    public let value: String
    public let type: NotificationPersonHandleType

    public init(value: String, type: NotificationPersonHandleType) {
        self.value = value
        self.type = type
    }

    public init(person: NotificationPerson) {
        if let uri = person.uri {
            if uri.hasPrefix("tel:") {
                self.init(value: String(uri.dropFirst(4)), type: .phoneNumber)
                return
            }
            if uri.hasPrefix("mailto:") {
                self.init(value: String(uri.dropFirst(7)), type: .emailAddress)
                return
            }
        }
        self.init(value: person.key, type: .unknown)
    }
}

#if canImport(Intents)
extension NotificationPersonHandle {
    /// The Intents handle (communication notifications, `INPerson`).
    public var inPersonHandle: INPersonHandle {
        let inType: INPersonHandleType
        switch type {
        case .phoneNumber: inType = .phoneNumber
        case .emailAddress: inType = .emailAddress
        case .unknown: inType = .unknown
        }
        return INPersonHandle(value: value, type: inType)
    }
}
#endif
