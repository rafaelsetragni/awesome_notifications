import Foundation
import UserNotifications

/// The parts of `UNNotificationSettings` the permission statuses are resolved
/// from. A plain value, so the 0.12.1 rules can be tested without the
/// notification center (`UNNotificationSettings` has no public initializer).
public struct PermissionSettings {
    public var authorizationStatus: UNAuthorizationStatus
    public var alertSetting: UNNotificationSetting
    public var soundSetting: UNNotificationSetting
    public var badgeSetting: UNNotificationSetting
    /// Always `.notSupported` on macOS, which has no CarPlay.
    public var carPlaySetting: UNNotificationSetting
    public var criticalAlertSetting: UNNotificationSetting

    public init(
        authorizationStatus: UNAuthorizationStatus,
        alertSetting: UNNotificationSetting = .notSupported,
        soundSetting: UNNotificationSetting = .notSupported,
        badgeSetting: UNNotificationSetting = .notSupported,
        carPlaySetting: UNNotificationSetting = .notSupported,
        criticalAlertSetting: UNNotificationSetting = .notSupported
    ) {
        self.authorizationStatus = authorizationStatus
        self.alertSetting = alertSetting
        self.soundSetting = soundSetting
        self.badgeSetting = badgeSetting
        self.carPlaySetting = carPlaySetting
        self.criticalAlertSetting = criticalAlertSetting
    }

    public init(_ settings: UNNotificationSettings) {
        #if os(macOS)
        let carPlay: UNNotificationSetting = .notSupported
        #else
        let carPlay = settings.carPlaySetting
        #endif
        self.init(
            authorizationStatus: settings.authorizationStatus,
            alertSetting: settings.alertSetting,
            soundSetting: settings.soundSetting,
            badgeSetting: settings.badgeSetting,
            carPlaySetting: carPlay,
            criticalAlertSetting: settings.criticalAlertSetting)
    }
}

/// Permission statuses, ported from the 0.12.1 `PermissionManager`
/// (`getPermissionStatuses`, IosAwnCore a3e4808).
public final class PermissionManager {

    public static let shared = PermissionManager()
    private init() {}

    /// Whether this process is an app extension (a Notification Service
    /// Extension), where 0.12 reports every permission as granted.
    static var isRunningOnExtension: Bool = Bundle.main.bundlePath.hasSuffix(".appex")

    /// Answers each of [permissions] (the Dart `NotificationPermission` names)
    /// with its status name: `granted`, `denied`, `notDetermined` or
    /// `notSupported`. [channelKey] only matters for the channel-level
    /// permissions (Vibration, Light, …).
    public func getPermissionStatuses(
        _ permissions: [String],
        filteringByChannelKey channelKey: String?,
        whenGotResults completion: @escaping ([String: String]) -> Void
    ) {
        if Self.isRunningOnExtension {
            var statuses: [String: String] = [:]
            for permission in permissions {
                statuses[permission] = NotificationPermissionStatus.granted.rawValue
            }
            completion(statuses)
            return
        }

        UNUserNotificationCenter.current().getNotificationSettings { settings in
            CriticalAlertUtils.updateCache(from: settings)
            completion(self.resolveStatuses(
                permissions, settings: PermissionSettings(settings), channelKey: channelKey))
        }
    }

    /// The status of each permission under [settings] (pure; 0.12.1 rules).
    public func resolveStatuses(
        _ permissions: [String],
        settings: PermissionSettings,
        channelKey: String?
    ) -> [String: String] {
        var statuses: [String: String] = [:]
        for permission in permissions {
            statuses[permission] = resolvePermissionStatus(
                permission, settings: settings, channelKey: channelKey).rawValue
        }
        return statuses
    }

    func resolvePermissionStatus(
        _ permission: String,
        settings: PermissionSettings,
        channelKey: String?
    ) -> NotificationPermissionStatus {
        guard let permissionEnum = NotificationPermission(rawValue: permission) else {
            return .notSupported
        }

        switch permissionEnum {
        case .criticalAlert, .overrideDnD:
            return resolveCriticalAlertStatus(settings)

        case .alert:
            return resolveSettingStatus(settings, settings.alertSetting)

        case .sound:
            return resolveSettingStatus(settings, settings.soundSetting)

        case .badge:
            return resolveSettingStatus(settings, settings.badgeSetting)

        case .car:
            return resolveSettingStatus(settings, settings.carPlaySetting)

        case .provisional:
            switch settings.authorizationStatus {
            case .provisional: return .granted
            case .notDetermined: return .notDetermined
            case .denied: return .denied
            default: return .notDetermined
            }

        default:
            // Vibration, Light, PreciseAlarms, FullScreenIntent: allowed without
            // a channel, otherwise as the channel configures them.
            if channelKey == nil
                || isSpecifiedChannelPermissionAllowed(channelKey: channelKey!, permission: permissionEnum) {
                return .granted
            }
            return .denied
        }
    }

    private func resolveSettingStatus(
        _ settings: PermissionSettings,
        _ setting: UNNotificationSetting
    ) -> NotificationPermissionStatus {
        if settings.authorizationStatus == .notDetermined { return .notDetermined }
        if settings.authorizationStatus == .denied { return .denied }
        switch setting {
        case .enabled: return .granted
        case .notSupported: return .notSupported
        default: return .denied
        }
    }

    /// Critical alerts: granted once enabled. Without the entitlement the
    /// setting is `.notSupported`: then, once the base notifications are
    /// granted, it reads `notDetermined` (never requested yet) — 0.12.1 quirk —
    /// and `notSupported` otherwise.
    private func resolveCriticalAlertStatus(_ settings: PermissionSettings) -> NotificationPermissionStatus {
        switch settings.criticalAlertSetting {
        case .enabled:
            return .granted
        case .notSupported:
            return isBaseNotificationAuthorizationGranted(settings) ? .notDetermined : .notSupported
        default:
            break
        }
        if settings.authorizationStatus == .notDetermined { return .notDetermined }
        if settings.authorizationStatus == .denied { return .denied }
        return .notDetermined
    }

    private func isBaseNotificationAuthorizationGranted(_ settings: PermissionSettings) -> Bool {
        return settings.authorizationStatus == .authorized
            || settings.authorizationStatus == .provisional
    }

    /// 0.12 `isSpecifiedChannelPermissionAllowed`: an unknown channel or a
    /// channel of importance None allows nothing; otherwise each permission
    /// follows its channel switch (defaults as 0.12: vibration and lights on,
    /// sound on, badge off).
    func isSpecifiedChannelPermissionAllowed(
        channelKey: String,
        permission: NotificationPermission
    ) -> Bool {
        guard let channel = ChannelManager.shared.channel(forKey: channelKey) else { return false }
        let importance = NotificationImportance.from(channel[Definitions.NOTIFICATION_IMPORTANCE])
        if importance == .none { return false }
        let mapUtils = MapUtils.shared
        switch permission {
        case .alert:
            return importance == .max || importance == .high
        case .sound:
            return mapUtils.getBool(channel[Definitions.NOTIFICATION_PLAY_SOUND]) ?? true
        case .vibration:
            return mapUtils.getBool(channel[Definitions.NOTIFICATION_ENABLE_VIBRATION]) ?? true
        case .light:
            return mapUtils.getBool(channel[Definitions.NOTIFICATION_ENABLE_LIGHTS]) ?? true
        case .badge:
            return mapUtils.getBool(channel[Definitions.NOTIFICATION_CHANNEL_SHOW_BADGE]) ?? false
        case .criticalAlert:
            return CriticalAlertUtils.isCriticalAlertRequested(channel: channel)
        default:
            return true
        }
    }
}
