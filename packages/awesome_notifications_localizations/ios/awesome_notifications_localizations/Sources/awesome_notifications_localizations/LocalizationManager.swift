import Foundation

/// Stores the current language code (persisted in UserDefaults). Mirrors the
/// 0.12 IosAwnCore LocalizationManager: the default is the system language, and
/// the code is normalized to lowercase with `_` turned into `-` both when it is
/// stored and when it is read (so "PT_BR" is used as "pt-br").
final class LocalizationManager {
    static let shared = LocalizationManager()
    private init() {}

    private let storageKey = "awn_localizations_languageCode"

    @discardableResult
    func setLocalization(_ languageCode: String?) -> Bool {
        let code = normalize(languageCode ?? systemLanguage())
        UserDefaults.standard.set(code, forKey: storageKey)
        return true
    }

    func getLocalization() -> String {
        return normalize(UserDefaults.standard.string(forKey: storageKey) ?? systemLanguage())
    }

    private func normalize(_ code: String) -> String {
        return code.lowercased().replacingOccurrences(of: "_", with: "-")
    }

    private func systemLanguage() -> String {
        return Locale.preferredLanguages.first ?? "en"
    }
}
