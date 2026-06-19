import Foundation

/// Instance-based JSON helpers (singleton, instance methods — no static
/// utilities): map <-> JSON string. Mirrors the original IosAwnCore `JsonUtils`.
public final class JsonUtils {
    public static let shared = JsonUtils()
    private init() {}

    public func toJson(_ map: [String: Any]?) -> String? {
        guard let map = map else { return nil }
        let sanitized = sanitize(map)
        guard
            JSONSerialization.isValidJSONObject(sanitized),
            let data = try? JSONSerialization.data(withJSONObject: sanitized),
            let json = String(data: data, encoding: .utf8)
        else { return nil }
        return json
    }

    public func fromJson(_ json: String?) -> [String: Any]? {
        guard
            let json = json,
            let data = json.data(using: .utf8),
            let object = try? JSONSerialization.jsonObject(with: data),
            let map = object as? [String: Any]
        else { return nil }
        return map
    }

    /// Drops NSNull / non-serializable values recursively so JSONSerialization
    /// accepts the map.
    private func sanitize(_ value: Any) -> Any {
        if let dict = value as? [String: Any] {
            var result: [String: Any] = [:]
            for (key, item) in dict where !(item is NSNull) {
                result[key] = sanitize(item)
            }
            return result
        }
        if let array = value as? [Any] {
            return array.filter { !($0 is NSNull) }.map { sanitize($0) }
        }
        return value
    }
}
