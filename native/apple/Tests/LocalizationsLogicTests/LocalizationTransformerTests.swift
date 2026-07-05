import XCTest
@testable import LocalizationsLogic

/// Build-time translation: the `localizations` block overrides content and button
/// labels for the current language (with prefix fallback), tolerating the block
/// arriving as a JSON string (push path).
final class LocalizationTransformerTests: XCTestCase {

    private let transformer = LocalizationTransformer()

    private func model(_ localizations: Any?) -> [String: Any] {
        var m: [String: Any] = [
            "content": ["id": 1, "title": "Hello"],
            "actionButtons": [["key": "YES", "label": "Yes"]]
        ]
        if let localizations = localizations { m["localizations"] = localizations }
        return m
    }

    private func title(_ out: [String: Any]) -> String? {
        return (out["content"] as? [String: Any])?["title"] as? String
    }

    func testTranslatesTitleAndButtonLabel() {
        LocalizationManager.shared.setLocalization("pt-br")
        let out = transformer.transform(
            model(["pt-br": ["title": "Olá", "buttonLabels": ["YES": "Sim"]]]))
        XCTAssertEqual(title(out), "Olá")
        let buttons = out["actionButtons"] as? [[String: Any]]
        XCTAssertEqual(buttons?.first?["label"] as? String, "Sim")
    }

    func testFallsBackByLanguagePrefix() {
        LocalizationManager.shared.setLocalization("pt-br")
        let out = transformer.transform(model(["pt": ["title": "OlaPt"]]))
        XCTAssertEqual(title(out), "OlaPt")
    }

    func testUnmatchedLanguageLeavesTitle() {
        LocalizationManager.shared.setLocalization("fr")
        let out = transformer.transform(model(["pt-br": ["title": "Olá"]]))
        XCTAssertEqual(title(out), "Hello")
    }

    func testNoLocalizationsReturnsUnchanged() {
        LocalizationManager.shared.setLocalization("pt-br")
        XCTAssertEqual(title(transformer.transform(model(nil))), "Hello")
    }

    func testLocalizationsAsJsonStringIsDecoded() {
        LocalizationManager.shared.setLocalization("pt-br")
        let out = transformer.transform(model("{\"pt-br\":{\"title\":\"OlaJson\"}}"))
        XCTAssertEqual(title(out), "OlaJson")
    }
}
