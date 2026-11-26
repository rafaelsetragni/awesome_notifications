import Foundation

/// Instance-based map helpers (singleton, instance methods — no static
/// utilities): typed extraction from a `[String: Any]` map. Mirrors the original
/// IosAwnCore `MapUtils` intent. Flutter encodes Dart ints/bools as Int/NSNumber
/// depending on the path, so read tolerantly.
public final class MapUtils {
    public static let shared = MapUtils()
    private init() {}

    public func getInt(_ value: Any?) -> Int? {
        if let value = value as? Int { return value }
        if let value = value as? NSNumber { return value.intValue }
        if let value = value as? String { return Int(value) }
        return nil
    }

    public func getString(_ value: Any?) -> String? {
        return value as? String
    }

    public func getBool(_ value: Any?) -> Bool? {
        if let value = value as? Bool { return value }
        if let value = value as? NSNumber { return value.boolValue }
        return nil
    }
}
