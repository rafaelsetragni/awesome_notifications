import Foundation
import IosAwnCore

/// UTC timestamp formatted exactly like the core lifecycle dates.
enum FcmDateUtils {
    static func nowUtc() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: Definitions.UTC_TIMEZONE)
        return formatter.string(from: Date())
    }
}

/// Tolerant JSON decoding for FCM payload sections (returns nil on malformed
/// input instead of throwing, so a bad section is skipped, not the whole push).
enum FcmJson {
    static func parseObject(_ raw: Any?) -> [String: Any]? {
        if let dict = raw as? [String: Any] { return dict }
        guard let string = raw as? String, let data = string.data(using: .utf8) else { return nil }
        return (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
    }

    static func parseList(_ raw: Any?) -> [Any]? {
        if let list = raw as? [Any] { return list }
        guard let string = raw as? String, let data = string.data(using: .utf8) else { return nil }
        return (try? JSONSerialization.jsonObject(with: data)) as? [Any]
    }
}
