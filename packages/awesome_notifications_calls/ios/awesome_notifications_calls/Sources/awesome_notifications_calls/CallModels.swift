import Foundation
import CryptoKit
import IosAwnCore

/// Keys of the `call` block, the channel methods and the event channel (same
/// names as the Dart `CallKeys`).
public enum CallKeys {
    public static let call = "call"

    public static let callId = "callId"
    public static let caller = "caller"
    public static let handle = "handle"
    public static let video = "video"
    public static let groupName = "groupName"
    public static let state = "state"
    public static let startedAt = "startedAt"
    public static let ringTimeout = "ringTimeout"
    public static let missedNotification = "missedNotification"
    public static let controls = "controls"
    public static let commandTarget = "commandTarget"
    public static let systemCallUI = "systemCallUI"
    public static let texts = "texts"

    public static let textIncoming = "incoming"
    public static let textIncomingVideo = "incomingVideo"
    public static let textOutgoing = "outgoing"
    public static let textOngoing = "ongoing"
    public static let textHeld = "held"
    public static let textMissed = "missed"
    public static let textMissedVideo = "missedVideo"
    public static let textAccept = "accept"
    public static let textDecline = "decline"
    public static let textHangUp = "hangUp"

    /// Added to the content payload: which call an action came from.
    public static let payloadCallId = "callId"
    /// Prefix of the `buttonKeyPressed` of a call command.
    public static let commandPrefix = "awn.call."

    public static let methodEnd = "callEnd"
    public static let methodActiveCalls = "callActiveCalls"
    public static let methodVoipToken = "callVoipToken"
    public static let methodCanUseFullScreenIntent = "callCanUseFullScreenIntent"
    public static let methodRequestFullScreenIntent = "callRequestFullScreenIntent"
    public static let methodCapabilities = "callCapabilities"

    public static let reason = "reason"

    public static let eventsChannel = "awesome_notifications_calls/events"
    public static let kind = "kind"
    public static let kindCommand = "command"
    public static let kindVoipToken = "voipToken"
    public static let action = "action"
    public static let token = "token"

    /// A model with a `schedule` entry can't be a call.
    public static let schedule = "schedule"

    /// Detailed codes of the refusals.
    public static let invalidCall = ".notificationCall"
    public static let invalidSchedule = ".notificationCall.schedule"

    /// Top-level model keys (never sent to Dart: the events carry the content
    /// only) keeping the app's own title / body of a call shown as a
    /// notification, so it can be shown again in another state.
    static let appTitle = "awn.call.appTitle"
    static let appBody = "awn.call.appBody"
    static let transformed = "awn.call.transformed"
}

/// The moment of a call (Dart `CallState`).
public enum CallState: String, CaseIterable {
    case incoming, outgoing, ongoing, held, ended, missed

    /// The system shows the call (it is not over).
    public var isActive: Bool { self != .ended && self != .missed }
}

/// A control the system offers (Dart `CallControl`).
public enum CallControl: String, CaseIterable {
    case accept, decline, hangUp, mute, hold
}

/// What happened to a call (Dart `CallAction`).
public enum CallAction: String, CaseIterable {
    case accept, decline, hangUp, mute, unmute, hold, unhold, timeout
    case audioActivated, audioDeactivated

    /// The `buttonKeyPressed` of this action's commands.
    public var key: String { CallKeys.commandPrefix + rawValue }

    /// The action of a `buttonKeyPressed`, nil when it isn't a call command.
    public static func from(key: String) -> CallAction? {
        guard key.hasPrefix(CallKeys.commandPrefix) else { return nil }
        return CallAction(rawValue: String(key.dropFirst(CallKeys.commandPrefix.count)))
    }
}

/// Where a call's commands go (Dart `CallCommandTarget`).
public enum CallCommandTarget: String {
    case actionEvent, stream, both

    public var toActionEvent: Bool { self != .stream }
    public var toStream: Bool { self != .actionEvent }
}

/// Why a call ends (Dart `CallEndReason`). The raw values are CallKit's
/// `CXCallEndedReason` ones.
public enum CallEndReason: Int, CaseIterable {
    case failed = 1
    case remoteEnded = 2
    case unanswered = 3
    case answeredElsewhere = 4
    case declinedElsewhere = 5

    public var name: String {
        switch self {
        case .failed: return "failed"
        case .remoteEnded: return "remoteEnded"
        case .unanswered: return "unanswered"
        case .answeredElsewhere: return "answeredElsewhere"
        case .declinedElsewhere: return "declinedElsewhere"
        }
    }

    public static func from(name: String?) -> CallEndReason? {
        allCases.first { $0.name == name }
    }
}

/// The `call` block of a model, validated like the Dart
/// `NotificationCall.validate` (a push never passes through Dart).
public struct NotificationCall: Equatable {
    public static let defaultRingTimeout = 60_000
    public static let defaultTexts: [String: String] = [
        CallKeys.textIncoming: "Incoming call",
        CallKeys.textIncomingVideo: "Incoming video call",
        CallKeys.textOutgoing: "Calling…",
        CallKeys.textOngoing: "Ongoing call",
        CallKeys.textMissed: "Missed call",
        CallKeys.textMissedVideo: "Missed video call",
        CallKeys.textAccept: "Accept",
        CallKeys.textDecline: "Decline",
        CallKeys.textHangUp: "Hang up",
        CallKeys.textHeld: "On hold"
    ]

    public let callId: String
    public let caller: NotificationPerson
    public let handle: String?
    public let video: Bool
    public let groupName: String?
    public var state: CallState
    /// Milliseconds since the epoch (UTC).
    public var startedAt: Int?
    /// Milliseconds.
    public let ringTimeout: Int
    public let missedNotification: Bool
    public let controls: [CallControl]
    public let commandTarget: CallCommandTarget
    public var systemCallUI: Bool
    public let texts: [String: String]

    /// The name the call shows: the group's, else the caller's.
    public var name: String { groupName ?? caller.name }

    public func has(_ control: CallControl) -> Bool { controls.contains(control) }

    public func text(_ key: String) -> String { texts[key] ?? NotificationCall.defaultTexts[key] ?? "" }

    /// The words under the name for the call's state.
    public var stateText: String {
        switch state {
        case .incoming: return text(video ? CallKeys.textIncomingVideo : CallKeys.textIncoming)
        case .outgoing: return text(CallKeys.textOutgoing)
        case .missed: return text(video ? CallKeys.textMissedVideo : CallKeys.textMissed)
        case .held: return text(CallKeys.textHeld)
        case .ongoing, .ended: return text(CallKeys.textOngoing)
        }
    }

    /// The handle of the system call: [handle] when given (`tel:` a phone
    /// number, `mailto:` an e-mail address, anything else generic), else the
    /// caller's (its `tel:` / `mailto:` uri, else its key).
    public var systemHandle: NotificationPersonHandle {
        guard let handle = handle else { return caller.handle }
        if handle.hasPrefix("tel:") { return NotificationPersonHandle(value: String(handle.dropFirst(4)), type: .phoneNumber) }
        if handle.hasPrefix("mailto:") { return NotificationPersonHandle(value: String(handle.dropFirst(7)), type: .emailAddress) }
        return NotificationPersonHandle(value: handle, type: .unknown)
    }

    /// Parses and validates the block. The error is the message to report.
    public static func parse(_ block: Any?) -> (NotificationCall?, String?) {
        guard let map = block as? [String: Any] else { return (nil, "The call block must be a map") }
        func present(_ key: String) -> Any? {
            let value = map[key]
            return value is NSNull ? nil : value
        }
        func number(_ key: String) -> Int? {
            guard let value = present(key), !isBoolean(value) else { return nil }
            if let value = value as? Int { return value }
            return (value as? NSNumber)?.intValue
        }
        func bool(_ key: String, _ fallback: Bool) -> Bool? {
            guard let value = present(key) else { return fallback }
            return isBoolean(value) ? (value as? NSNumber)?.boolValue : nil
        }

        guard let callId = present(CallKeys.callId) as? String,
              !callId.trimmingCharacters(in: .whitespaces).isEmpty else {
            return (nil, "The call needs a non-empty callId")
        }
        guard let caller = NotificationPerson(present(CallKeys.caller)) else {
            return (nil, "The call needs a caller with a key and a name")
        }
        let handle = present(CallKeys.handle)
        if handle != nil, ((handle as? String) ?? "").trimmingCharacters(in: .whitespaces).isEmpty {
            return (nil, "The call handle can't be empty (leave it out to use the caller's key)")
        }
        let groupName = present(CallKeys.groupName)
        if groupName != nil, ((groupName as? String) ?? "").trimmingCharacters(in: .whitespaces).isEmpty {
            return (nil, "The call groupName can't be empty")
        }
        guard let video = bool(CallKeys.video, false) else { return (nil, "The call video must be a bool") }
        guard let state = CallState(rawValue: (present(CallKeys.state) as? String) ?? "") else {
            return (nil, "Unknown call state: \(present(CallKeys.state) ?? "null")")
        }
        let startedAt = number(CallKeys.startedAt)
        if present(CallKeys.startedAt) != nil, startedAt == nil {
            return (nil, "The call startedAt must be milliseconds")
        }
        let ringTimeout = present(CallKeys.ringTimeout) == nil ? defaultRingTimeout : number(CallKeys.ringTimeout)
        guard let timeout = ringTimeout, timeout > 0 else { return (nil, "The ring timeout must be positive") }
        guard let missed = bool(CallKeys.missedNotification, true) else {
            return (nil, "The call missedNotification must be a bool")
        }
        var controls: [CallControl] = []
        if let raw = present(CallKeys.controls) {
            guard let list = raw as? [Any] else { return (nil, "The call controls must be a list") }
            for name in list {
                guard let control = CallControl(rawValue: (name as? String) ?? "") else {
                    return (nil, "Unknown call control: \(name)")
                }
                if !controls.contains(control) { controls.append(control) }
            }
        } else {
            controls = CallControl.allCases
        }
        if state == .incoming, !controls.contains(.accept), !controls.contains(.decline) {
            return (nil, "An incoming call needs the accept or the decline control")
        }
        let targetName = (present(CallKeys.commandTarget) as? String) ?? CallCommandTarget.actionEvent.rawValue
        guard let target = CallCommandTarget(rawValue: targetName) else {
            return (nil, "Unknown call commandTarget: \(targetName)")
        }
        guard let systemCallUI = bool(CallKeys.systemCallUI, true) else {
            return (nil, "The call systemCallUI must be a bool")
        }
        var texts = defaultTexts
        if let raw = present(CallKeys.texts) {
            guard let given = raw as? [String: Any] else { return (nil, "The call texts must be a map") }
            for (key, value) in given { if let text = value as? String { texts[key] = text } }
        }
        return (NotificationCall(
            callId: callId, caller: caller, handle: handle as? String, video: video,
            groupName: groupName as? String, state: state, startedAt: startedAt,
            ringTimeout: timeout, missedNotification: missed, controls: controls,
            commandTarget: target, systemCallUI: systemCallUI, texts: texts), nil)
    }

    /// A boolean of the channel or JSON (a CFBoolean), not a number.
    static func isBoolean(_ value: Any) -> Bool {
        guard let number = value as? NSNumber else { return false }
        return CFGetTypeID(number) == CFBooleanGetTypeID()
    }

    /// The block as the model carries it (same shape as the Dart `toMap`).
    public func toMap() -> [String: Any] {
        var caller: [String: Any] = [
            NotificationPerson.keyKey: self.caller.key,
            NotificationPerson.keyName: self.caller.name,
            NotificationPerson.keyIsBot: self.caller.isBot,
            NotificationPerson.keyIsImportant: self.caller.isImportant
        ]
        if let avatar = self.caller.avatar { caller[NotificationPerson.keyAvatar] = avatar }
        if let uri = self.caller.uri { caller[NotificationPerson.keyUri] = uri }
        var map: [String: Any] = [
            CallKeys.callId: callId,
            CallKeys.caller: caller,
            CallKeys.video: video,
            CallKeys.state: state.rawValue,
            CallKeys.ringTimeout: ringTimeout,
            CallKeys.missedNotification: missedNotification,
            CallKeys.controls: controls.map(\.rawValue),
            CallKeys.commandTarget: commandTarget.rawValue,
            CallKeys.systemCallUI: systemCallUI,
            CallKeys.texts: texts
        ]
        if let handle = handle { map[CallKeys.handle] = handle }
        if let groupName = groupName { map[CallKeys.groupName] = groupName }
        if let startedAt = startedAt { map[CallKeys.startedAt] = startedAt }
        return map
    }
}

/// The stable ids of a call.
public enum CallIds {

    /// Java's `String.hashCode` (UTF-16 code units, 32-bit wrapping).
    public static func javaHash(_ text: String) -> Int32 {
        var hash: Int32 = 0
        for unit in text.utf16 { hash = hash &* 31 &+ Int32(unit) }
        return hash
    }

    /// The id of a call's missed notification, the same on every platform:
    /// `"missed:" + callId` hashed as Java does, positive.
    public static func missedNotificationId(_ callId: String) -> Int {
        Int(javaHash("missed:" + callId) & 0x7FFF_FFFF)
    }

    /// The notification id of a pushed call without one: its callId hashed.
    public static func notificationId(_ callId: String) -> Int {
        Int(javaHash(callId) & 0x7FFF_FFFF)
    }

    /// The CallKit UUID of a call: a name-based UUID (SHA-256 of the callId,
    /// version 5 / RFC 4122 bits), always the same for the same callId.
    public static func uuid(_ callId: String) -> UUID {
        var bytes = Array(SHA256.hash(data: Data(("awn.call:" + callId).utf8)).prefix(16))
        bytes[6] = (bytes[6] & 0x0F) | 0x50
        bytes[8] = (bytes[8] & 0x3F) | 0x80
        return UUID(uuid: (bytes[0], bytes[1], bytes[2], bytes[3], bytes[4], bytes[5], bytes[6], bytes[7],
                           bytes[8], bytes[9], bytes[10], bytes[11], bytes[12], bytes[13], bytes[14], bytes[15]))
    }
}
