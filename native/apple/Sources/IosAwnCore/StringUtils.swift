import Foundation

/// Instance-based string helpers (singleton, instance methods — no static
/// utilities), mirroring the original IosAwnCore `StringUtils`.
public final class StringUtils {
    public static let shared = StringUtils()
    private init() {}

    public func isNullOrEmpty(_ value: String?) -> Bool {
        guard let value = value else { return true }
        return value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
