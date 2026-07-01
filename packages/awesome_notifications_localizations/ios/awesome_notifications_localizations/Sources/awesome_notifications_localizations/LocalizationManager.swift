import Foundation

/// Stores the current language code (persisted in UserDefaults). Mirrors the
/// original IosAwnCore LocalizationManager: default is the system language,
/// normalized to lowercase.
final class LocalizationManager {
    static let shared = LocalizationManager()
    private init() {}

    private let storageKey = "awn_localizations_languageCode"

    @discardableResult
    func setLocalization(_ languageCode: String?) -> Bool {
        let code = (languageCode ?? systemLanguage()).lowercased()
        UserDefaults.standard.set(code, forKey: storageKey)
        return true
    }

    func getLocalization() -> String {
        return UserDefaults.standard.string(forKey: storageKey) ?? systemLanguage()
    }

    private func systemLanguage() -> String {
        return (Locale.preferredLanguages.first ?? "en").lowercased()
    }
}
