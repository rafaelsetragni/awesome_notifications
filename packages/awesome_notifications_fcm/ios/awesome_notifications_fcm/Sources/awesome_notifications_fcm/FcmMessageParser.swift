import Foundation
import IosAwnCore

/// Turns a remote push userInfo into the serialized notification map the core
/// engine consumes, and decides display-vs-silent. Mirrors the Android
/// `FcmMessageParser`; the awesome payload may arrive as structured JSON strings
/// under `content` / `schedule` / `actionButtons` / `localizations`, merged over
/// the standard APNs `aps.alert` block.
final class FcmMessageParser {

    /// True when the message carries something to display (vs. pure silent data).
    func isDisplayable(_ userInfo: [String: Any]) -> Bool {
        if "\(userInfo[FcmDefinitions.FLAG_IS_SILENT_DATA] ?? "")" == "true" { return false }
        if let aps = userInfo[FcmDefinitions.APS] as? [String: Any],
           aps[FcmDefinitions.APS_ALERT] != nil { return true }
        if userInfo[FcmDefinitions.MODEL_CONTENT] != nil { return true }
        if userInfo.keys.contains(where: { $0.hasPrefix(FcmDefinitions.MODEL_CONTENT + ".") }) {
            return true
        }
        return false
    }

    func buildAwesomeMap(
        notificationId: Int,
        userInfo: [String: Any],
        lifeCycle: NotificationLifeCycle
    ) -> [String: Any] {
        var data = userInfo
        data.removeValue(forKey: FcmDefinitions.MODEL_IOS)

        // (1) baseline content from aps.alert + full payload.
        var content = standardContent(notificationId: notificationId, userInfo: data)

        // (2) awesome content overrides (structured JSON strings).
        var out: [String: Any] = [:]
        if let awesomeContent = FcmJson.parseObject(data[FcmDefinitions.MODEL_CONTENT]) {
            content = deepMerge(content, awesomeContent)
            content[Definitions.NOTIFICATION_ID] = resolveId(awesomeContent, fallback: notificationId)
        }
        if let iosOverrides = FcmJson.parseObject(data[FcmDefinitions.MODEL_IOS]) {
            content = deepMerge(content, iosOverrides)
        }

        // (3) stamp the FCM origin + created date (core only stamps if absent).
        if content[Definitions.NOTIFICATION_CREATED_DATE] == nil {
            content[Definitions.NOTIFICATION_CREATED_DATE] = FcmDateUtils.nowUtc()
            content[Definitions.NOTIFICATION_CREATED_SOURCE] = NotificationSource.firebase.rawValue
            content[Definitions.NOTIFICATION_CREATED_LIFECYCLE] = lifeCycle.rawValue
        }

        out[FcmDefinitions.MODEL_CONTENT] = content
        if let schedule = FcmJson.parseObject(data[FcmDefinitions.MODEL_SCHEDULE]), !schedule.isEmpty {
            out[FcmDefinitions.MODEL_SCHEDULE] = schedule
        }
        if let buttons = FcmJson.parseList(data[FcmDefinitions.MODEL_BUTTONS]), !buttons.isEmpty {
            out[FcmDefinitions.MODEL_BUTTONS] = buttons
        }
        if let loc = FcmJson.parseObject(data[FcmDefinitions.MODEL_LOCALIZATIONS]), !loc.isEmpty {
            out[FcmDefinitions.MODEL_LOCALIZATIONS] = loc
        }
        return out
    }

    // MARK: - Helpers

    private func standardContent(notificationId: Int, userInfo: [String: Any]) -> [String: Any] {
        var content: [String: Any] = [Definitions.NOTIFICATION_ID: notificationId]
        if let aps = userInfo[FcmDefinitions.APS] as? [String: Any] {
            if let alert = aps[FcmDefinitions.APS_ALERT] as? [String: Any] {
                if let title = alert[FcmDefinitions.APS_TITLE] as? String {
                    content[Definitions.NOTIFICATION_TITLE] = title
                }
                if let body = alert[FcmDefinitions.APS_BODY] as? String {
                    content[Definitions.NOTIFICATION_BODY] = body
                }
            } else if let alert = aps[FcmDefinitions.APS_ALERT] as? String {
                content[Definitions.NOTIFICATION_BODY] = alert
            }
        }
        // Attach the string payload (excludes aps + the structured sections).
        var payload: [String: String] = [:]
        for (key, value) in userInfo where !isReservedKey(key) {
            if let s = value as? String { payload[key] = s }
        }
        if !payload.isEmpty { content[Definitions.NOTIFICATION_PAYLOAD] = payload }
        return content
    }

    private func isReservedKey(_ key: String) -> Bool {
        return key == FcmDefinitions.APS ||
            key == FcmDefinitions.MODEL_CONTENT ||
            key == FcmDefinitions.MODEL_SCHEDULE ||
            key == FcmDefinitions.MODEL_BUTTONS ||
            key == FcmDefinitions.MODEL_LOCALIZATIONS ||
            key == FcmDefinitions.MODEL_ANDROID ||
            key == FcmDefinitions.MODEL_IOS
    }

    private func resolveId(_ content: [String: Any], fallback: Int) -> Int {
        if let n = content[Definitions.NOTIFICATION_ID] as? Int { return n }
        if let s = content[Definitions.NOTIFICATION_ID] as? String, let n = Int(s) { return n }
        return fallback
    }

    /// Recursive map merge; values from `override` win, nested maps merge.
    func deepMerge(_ base: [String: Any], _ override: [String: Any]) -> [String: Any] {
        var result = base
        for (key, value) in override {
            if let existing = result[key] as? [String: Any], let child = value as? [String: Any] {
                result[key] = deepMerge(existing, child)
            } else {
                result[key] = value
            }
        }
        return result
    }
}
