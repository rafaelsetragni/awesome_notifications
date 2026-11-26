import Foundation
import IosAwnCore

/// Content transformer that translates the notification at build time. Mirrors
/// the original IosAwnCore `setCurrentTranslation`:
///  1. resolve `titleLocKey`/`bodyLocKey` from the app's `<lang>.lproj` strings
///     for the current language (applying `titleLocArgs`/`bodyLocArgs`);
///  2. pick the matching locale of the `localizations` map (with fallback) and
///     overwrite the content's title/body/summary/largeIcon/bigPicture and the
///     action button labels.
///
/// The core builder runs this without knowing it exists — the decorator seam.
final class LocalizationTransformer {

    /// The bundle holding the app's `.lproj` folders (injectable for tests).
    private let bundle: Bundle

    init(bundle: Bundle = .main) {
        self.bundle = bundle
    }

    func transform(_ model: [String: Any]) -> [String: Any] {
        let languageCode = LocalizationManager.shared.getLocalization()
        let model = applyLocKeys(model, languageCode)

        guard let localizations = localizationsMap(model), !localizations.isEmpty else {
            return model
        }

        guard let matched = matchLanguage(Array(localizations.keys), languageCode),
              let localization = localizations[matched] as? [String: Any] else {
            return model
        }

        var result = model

        if var content = model[Keys.content] as? [String: Any] {
            for key in Keys.translatable {
                if let value = localization[key] as? String, !value.isEmpty {
                    content[key] = value
                }
            }
            result[Keys.content] = content
        }

        // Like 0.12: any label given for the button key replaces it (even "").
        if let buttonLabels = localization[Keys.buttonLabels] as? [String: String],
           let buttons = model[Keys.buttons] as? [[String: Any]] {
            result[Keys.buttons] = buttons.map { button in
                guard let key = button[Keys.buttonKey] as? String,
                      let label = buttonLabels[key]
                else { return button }
                var translated = button
                translated[Keys.buttonLabel] = label
                return translated
            }
        }

        return result
    }

    /// Loc keys → the app's localized strings (same as the 0.12 core).
    private func applyLocKeys(_ model: [String: Any], _ languageCode: String) -> [String: Any] {
        guard var content = model[Keys.content] as? [String: Any] else { return model }

        if let titleLocKey = content[Keys.titleLocKey] as? String,
           let format = localized(titleLocKey, languageCode) {
            if let args = content[Keys.titleLocArgs] as? [String] {
                content[Keys.title] = String(format: format, arguments: args)
            } else {
                content[Keys.title] = format
            }
        }

        if let bodyLocKey = content[Keys.bodyLocKey] as? String,
           let format = localized(bodyLocKey, languageCode) {
            if let args = content[Keys.bodyLocArgs] as? [String] {
                content[Keys.body] = String(format: format, arguments: args)
            } else {
                content[Keys.body] = format
            }
        }

        var result = model
        result[Keys.content] = content
        return result
    }

    /// The 0.12 `String.localized(forLanguageCode:)`: the full code's `.lproj`
    /// first (e.g. "en-US"), then only the language part (e.g. "en").
    private func localized(_ key: String, _ languageCode: String) -> String? {
        let formattedLanguageCode = formatLanguageCode(languageCode)

        if let path = bundle.path(forResource: formattedLanguageCode, ofType: "lproj"),
           let lproj = Bundle(path: path) {
            return NSLocalizedString(key, bundle: lproj, comment: "")
        }

        let primaryLanguageCode = onlyFirstLanguageCode(formattedLanguageCode)
        if let path = bundle.path(forResource: primaryLanguageCode, ofType: "lproj"),
           let lproj = Bundle(path: path) {
            return NSLocalizedString(key, bundle: lproj, comment: "")
        }

        return nil
    }

    private func formatLanguageCode(_ code: String) -> String {
        let parts = code.split(separator: "-")
        guard let first = parts.first else { return code }
        var formattedCode = first.lowercased()
        if parts.count > 1 {
            formattedCode += "-" + parts[1].uppercased()
        }
        return formattedCode
    }

    private func onlyFirstLanguageCode(_ code: String) -> String {
        return code.split(separator: "-").first.map { $0.lowercased() } ?? code
    }

    /// The `localizations` block, accepting either a dictionary or — for push/JSON
    /// payloads where it arrives JSON-encoded — a JSON string.
    /// Like 0.12's `extractLocalizations`, a language whose translation is
    /// empty (or not a map) is not a candidate at all.
    private func localizationsMap(_ model: [String: Any]) -> [String: Any]? {
        var map: [String: Any]?
        if let dictionary = model[Keys.localizations] as? [String: Any] {
            map = dictionary
        } else if let json = model[Keys.localizations] as? String {
            map = JsonUtils.shared.fromJson(json)
        }
        return map?.filter { !(($0.value as? [String: Any])?.isEmpty ?? true) }
    }

    /// The 0.12 `getMatchedLanguageCode`: the lowercase code itself when it is
    /// a key; otherwise, walking the keys in ascending order, the first that
    /// equals the code ignoring case, starts with "<code>-", or is the language
    /// part of the code ("pt" for "pt-br"). So "pt" picks "pt-br" over "pt-pt".
    private func matchLanguage(_ keys: [String], _ languageCode: String) -> String? {
        let english = Locale(identifier: "en")
        let lowercaseLanguageCode = languageCode.lowercased(with: english)
        if keys.contains(lowercaseLanguageCode) {
            return lowercaseLanguageCode
        }
        for key in keys.sorted(by: <) {
            let lowercaseKey = key.lowercased(with: english)
            if lowercaseKey == lowercaseLanguageCode { return key }
            if lowercaseKey.hasPrefix("\(lowercaseLanguageCode)-") { return key }
            if lowercaseLanguageCode.hasPrefix("\(lowercaseKey)-") { return key }
        }
        return nil
    }

    private enum Keys {
        static let localizations = "localizations"
        static let content = "content"
        static let title = "title"
        static let body = "body"
        static let titleLocKey = "titleLocKey"
        static let bodyLocKey = "bodyLocKey"
        static let titleLocArgs = "titleLocArgs"
        static let bodyLocArgs = "bodyLocArgs"
        static let buttons = "actionButtons"
        static let buttonKey = "key"
        static let buttonLabel = "label"
        static let buttonLabels = "buttonLabels"
        static let translatable = ["title", "body", "summary", "largeIcon", "bigPicture"]
    }
}
