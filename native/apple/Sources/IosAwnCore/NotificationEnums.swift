import Foundation

/// Origin of a notification. The raw value is the exact string the Dart
/// `NotificationSource` enum (de)serializes, so it is the single source of truth
/// shared across the channel — no magic strings at the call sites.
public enum NotificationSource: String {
    case local = "Local"
    case schedule = "Schedule"
    case firebase = "Firebase"
    case oneSignal = "OneSignal"
    case callKit = "CallKit"
}

/// App lifecycle state when a notification event happened. The raw value matches
/// the Dart `NotificationLifeCycle` enum exactly (note: `Terminated`, not the
/// deprecated `AppKilled`, which the Dart side no longer parses).
public enum NotificationLifeCycle: String {
    case foreground = "Foreground"
    case background = "Background"
    case terminated = "Terminated"
}

/// Type of a notification action button / content tap. The raw value matches the
/// Dart `ActionType` enum name exactly (the wire format is `.name`).
public enum ActionType: String {
    case `default` = "Default"
    case inputField = "InputField"
    case disabledAction = "DisabledAction"
    case keepOnTop = "KeepOnTop"
    case silentAction = "SilentAction"
    case silentBackgroundAction = "SilentBackgroundAction"
    case dismissAction = "DismissAction"

    /// Parses the wire value, tolerating a legacy "ActionType."-prefixed form;
    /// an unknown/nil/empty value falls back to `.default`.
    public static func from(_ raw: String?) -> ActionType {
        guard let raw = raw, !raw.isEmpty else { return .default }
        if let exact = ActionType(rawValue: raw) { return exact }
        let suffix = raw.split(separator: ".").last.map(String.init) ?? raw
        return ActionType(rawValue: suffix) ?? .default
    }
}

/// Scheme prefixes that identify a media reference's source, matching the Dart
/// `MediaSourcePrefix` constants. Single source of truth for scheme handling.
public enum MediaSourcePrefix {
    public static let resource = "resource://"
    public static let asset = "asset://"
    public static let file = "file://"
    public static let networkHttps = "https://"
    public static let networkHttp = "http://"
    /// Loose prefix used to keep any http(s) URL whole.
    public static let http = "http"
}
