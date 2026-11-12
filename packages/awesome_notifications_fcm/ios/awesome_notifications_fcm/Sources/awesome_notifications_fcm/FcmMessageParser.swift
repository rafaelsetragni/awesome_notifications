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
        // Drop the other platform's overrides; ours are applied below.
        var data = userInfo
        data.removeValue(forKey: FcmDefinitions.MODEL_ANDROID)

        // (1) baseline content from aps.alert + the plain payload keys.
        var content = standardContent(notificationId: notificationId, userInfo: data)

        // (2) awesome sections: structured JSON strings, or dot-flattened keys.
        let sections = data[FcmDefinitions.MODEL_CONTENT] != nil
            ? structuredSections(data)
            : JsonFlattener.decode(stringEntries(of: data))

        if let awesomeContent = sections[FcmDefinitions.MODEL_CONTENT] as? [String: Any] {
            content = deepMerge(content, awesomeContent)
            content[Definitions.NOTIFICATION_ID] = resolveId(awesomeContent, fallback: notificationId)
        }

        var out: [String: Any] = [FcmDefinitions.MODEL_CONTENT: content]
        if let schedule = sections[FcmDefinitions.MODEL_SCHEDULE] as? [String: Any], !schedule.isEmpty {
            out[FcmDefinitions.MODEL_SCHEDULE] = schedule
        }
        if let buttons = sections[FcmDefinitions.MODEL_BUTTONS] as? [Any], !buttons.isEmpty {
            out[FcmDefinitions.MODEL_BUTTONS] = buttons
        }
        if let loc = sections[FcmDefinitions.MODEL_LOCALIZATIONS] as? [String: Any], !loc.isEmpty {
            out[FcmDefinitions.MODEL_LOCALIZATIONS] = loc
        }

        // (3) iOS overrides are model-shaped (`{content, actionButtons, …}`), as on Android.
        if let iosOverrides = sections[FcmDefinitions.MODEL_IOS] as? [String: Any] {
            out = deepMerge(out, iosOverrides)
        }

        // (4) stamp the FCM origin + created date (core only stamps if absent).
        var stamped = out[FcmDefinitions.MODEL_CONTENT] as? [String: Any] ?? [:]
        if stamped[Definitions.NOTIFICATION_CREATED_DATE] == nil {
            stamped[Definitions.NOTIFICATION_CREATED_DATE] = FcmDateUtils.nowUtc()
            stamped[Definitions.NOTIFICATION_CREATED_SOURCE] = NotificationSource.firebase.rawValue
            stamped[Definitions.NOTIFICATION_CREATED_LIFECYCLE] = lifeCycle.rawValue
        }
        out[FcmDefinitions.MODEL_CONTENT] = stamped
        return out
    }

    // MARK: - Helpers

    /// The awesome sections sent as structured JSON strings.
    private func structuredSections(_ data: [String: Any]) -> [String: Any] {
        var sections: [String: Any] = [:]
        sections[FcmDefinitions.MODEL_CONTENT] = FcmJson.parseObject(data[FcmDefinitions.MODEL_CONTENT])
        sections[FcmDefinitions.MODEL_SCHEDULE] = FcmJson.parseObject(data[FcmDefinitions.MODEL_SCHEDULE])
        sections[FcmDefinitions.MODEL_BUTTONS] = FcmJson.parseList(data[FcmDefinitions.MODEL_BUTTONS])
        sections[FcmDefinitions.MODEL_LOCALIZATIONS] = FcmJson.parseObject(data[FcmDefinitions.MODEL_LOCALIZATIONS])
        sections[FcmDefinitions.MODEL_IOS] = FcmJson.parseObject(data[FcmDefinitions.MODEL_IOS])
        return sections
    }

    /// The string pairs of the payload (drops `aps` and other non-string values).
    private func stringEntries(of data: [String: Any]) -> [String: String] {
        var entries: [String: String] = [:]
        for (key, value) in data {
            if let s = value as? String { entries[key] = s }
        }
        return entries
    }

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

    /// `aps` and the awesome sections — whole (structured) or dot-flattened.
    private func isReservedKey(_ key: String) -> Bool {
        if key == FcmDefinitions.APS { return true }
        let root = key.split(separator: ".", maxSplits: 1).first.map(String.init) ?? key
        return root == FcmDefinitions.MODEL_CONTENT ||
            root == FcmDefinitions.MODEL_SCHEDULE ||
            root == FcmDefinitions.MODEL_BUTTONS ||
            root == FcmDefinitions.MODEL_LOCALIZATIONS ||
            root == FcmDefinitions.MODEL_ANDROID ||
            root == FcmDefinitions.MODEL_IOS
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
