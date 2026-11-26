import Foundation

/// Reconstructs a nested map from a push payload whose keys use dot notation.
/// Mirrors the Android `JsonFlattener`.
///
/// FCM data messages can only carry flat string pairs, so a server may send the
/// awesome payload flattened, e.g.:
///
///     "content.id" = "1", "content.title" = "Hi", "actionButtons.0.key" = "OK"
///
/// decodes to:
///
///     { content: { id: "1", title: "Hi" }, actionButtons: [ { key: "OK" } ] }
///
/// A numeric path segment turns the parent into a list. Since every value arrives
/// as a string, `"true"` / `"false"` become booleans (the core reads flags with
/// `getBool`, which does not parse strings) and `"null"` drops the key; anything
/// else stays a string (the core parses numeric strings itself).
enum JsonFlattener {

    static func decode(_ flat: [String: String]) -> [String: Any] {
        var root: [String: Any] = [:]
        for (key, value) in flat {
            guard let coerced = coerce(value) else { continue }
            insert(&root, path: key.split(separator: ".").map(String.init), value: coerced)
        }
        return (normalize(root) as? [String: Any]) ?? [:]
    }

    /// Typed value of a flattened string, or nil to drop the key.
    static func coerce(_ value: String) -> Any? {
        switch value {
        case "true": return true
        case "false": return false
        case "null": return nil
        default: return value
        }
    }

    private static func insert(_ node: inout [String: Any], path: [String], value: Any) {
        guard let head = path.first else { return }
        if path.count == 1 {
            node[head] = value
            return
        }
        var child = node[head] as? [String: Any] ?? [:]
        insert(&child, path: Array(path.dropFirst()), value: value)
        node[head] = child
    }

    /// Turns any map whose keys are the contiguous indices 0..n-1 into a list, so
    /// `actionButtons.0.*` / `actionButtons.1.*` become a real list.
    private static func normalize(_ value: Any) -> Any {
        guard let map = value as? [String: Any] else { return value }
        var normalized: [String: Any] = [:]
        for (key, child) in map { normalized[key] = normalize(child) }
        return asListIfIndexed(normalized) ?? normalized
    }

    private static func asListIfIndexed(_ map: [String: Any]) -> [Any]? {
        if map.isEmpty { return nil }
        let indices = map.keys.compactMap { Int($0) }
        guard indices.count == map.count,
              indices.sorted() == Array(0..<map.count) else { return nil }
        return indices.sorted().compactMap { map[String($0)] }
    }
}
