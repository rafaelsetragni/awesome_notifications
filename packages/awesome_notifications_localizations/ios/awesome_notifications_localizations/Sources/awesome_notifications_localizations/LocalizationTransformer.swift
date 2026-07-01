import Foundation
import IosAwnCore

/// Content transformer that translates the notification at build time, using the
/// `localizations` map carried by the model and the current language. Mirrors the
/// original IosAwnCore `setCurrentTranslation`: pick the matching locale (with
/// fallback) and overwrite the content's title/body/summary/largeIcon/bigPicture
/// and the action button labels.
///
/// The core builder runs this without knowing it exists — the decorator seam.
final class LocalizationTransformer: NotificationContentTransformer {

    func transform(_ model: [String: Any]) -> [String: Any] {
        guard let localizations = localizationsMap(model), !localizations.isEmpty else {
            return model
        }

        let languageCode = LocalizationManager.shared.getLocalization()
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

        if let buttonLabels = localization[Keys.buttonLabels] as? [String: Any],
           let buttons = model[Keys.buttons] as? [[String: Any]] {
            result[Keys.buttons] = buttons.map { button in
                guard let key = button[Keys.buttonKey] as? String,
                      let label = buttonLabels[key] as? String, !label.isEmpty
                else { return button }
                var translated = button
                translated[Keys.buttonLabel] = label
                return translated
            }
        }

        return result
    }

    /// The `localizations` block, accepting either a dictionary or — for push/JSON
    /// payloads where it arrives JSON-encoded — a JSON string.
    private func localizationsMap(_ model: [String: Any]) -> [String: Any]? {
        if let map = model[Keys.localizations] as? [String: Any] { return map }
        if let json = model[Keys.localizations] as? String {
            return JsonUtils.shared.fromJson(json)
        }
        return nil
    }

    /// exact → key-as-prefix → code-as-prefix (e.g. "pt-br" falls back to "pt").
    private func matchLanguage(_ keys: [String], _ languageCode: String) -> String? {
        let code = languageCode.lowercased()
        if let exact = keys.first(where: { $0.lowercased() == code }) { return exact }
        for key in keys.sorted(by: >) {
            let lowerKey = key.lowercased()
            if lowerKey == code { return key }
            if lowerKey.hasPrefix("\(code)-") { return key }
            if code.hasPrefix("\(lowerKey)-") { return key }
        }
        return nil
    }

    private enum Keys {
        static let localizations = "localizations"
        static let content = "content"
        static let buttons = "actionButtons"
        static let buttonKey = "key"
        static let buttonLabel = "label"
        static let buttonLabels = "buttonLabels"
        static let translatable = ["title", "body", "summary", "largeIcon", "bigPicture"]
    }
}
