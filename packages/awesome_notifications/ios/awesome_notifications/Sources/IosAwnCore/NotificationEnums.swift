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

/// Importance of a channel. The raw value matches the Dart
/// `NotificationImportance` enum name (the wire format is `.name`).
public enum NotificationImportance: String, CaseIterable {
    case none = "None"
    case min = "Min"
    case low = "Low"
    case `default` = "Default"
    case high = "High"
    case max = "Max"

    /// 0.12 `EnumUtils.getEnumOrDefault`: a missing or unknown value is
    /// `Default`.
    public static func from(_ raw: Any?) -> NotificationImportance {
        guard let raw = raw as? String else { return .default }
        return NotificationImportance(rawValue: raw) ?? .default
    }
}

/// A permission the app may ask for. The raw value matches the Dart
/// `NotificationPermission` enum name.
public enum NotificationPermission: String, CaseIterable {
    case alert = "Alert"
    case sound = "Sound"
    case badge = "Badge"
    case vibration = "Vibration"
    case light = "Light"
    case criticalAlert = "CriticalAlert"
    case overrideDnD = "OverrideDnD"
    case provisional = "Provisional"
    case preciseAlarms = "PreciseAlarms"
    case fullScreenIntent = "FullScreenIntent"
    case car = "Car"
}

/// The status of a permission, as `getPermissionStatuses` answers it. The raw
/// value matches the Dart `NotificationPermissionStatus` enum name.
public enum NotificationPermissionStatus: String, CaseIterable {
    case granted = "granted"
    case denied = "denied"
    case notDetermined = "notDetermined"
    case notSupported = "notSupported"
}
