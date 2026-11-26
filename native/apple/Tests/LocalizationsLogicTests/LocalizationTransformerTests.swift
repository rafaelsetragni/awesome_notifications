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

    func testTranslatesEveryContentField() {
        LocalizationManager.shared.setLocalization("pt-br")
        let out = transformer.transform(model(["pt-br": [
            "title": "Olá", "summary": "Resumo",
            "largeIcon": "asset://pt.png", "bigPicture": "https://x/pt.png"
        ]]))
        let content = out["content"] as? [String: Any]
        XCTAssertEqual(content?["title"] as? String, "Olá")
        XCTAssertEqual(content?["summary"] as? String, "Resumo")
        XCTAssertEqual(content?["largeIcon"] as? String, "asset://pt.png")
        XCTAssertEqual(content?["bigPicture"] as? String, "https://x/pt.png")
    }

    func testEmptyTranslationsKeepTheOriginal() {
        LocalizationManager.shared.setLocalization("pt-br")
        let out = transformer.transform(model(["pt-br": ["title": "", "buttonLabels": ["YES": ""]]]))
        XCTAssertEqual(title(out), "Hello")
        // 0.12 applies any label given for the key, even an empty one.
        let buttons = out["actionButtons"] as? [[String: Any]]
        XCTAssertEqual(buttons?.first?["label"] as? String, "")
    }

    func testUnderscoreLanguageCodeIsNormalized() {
        LocalizationManager.shared.setLocalization("PT_BR")
        XCTAssertEqual(LocalizationManager.shared.getLocalization(), "pt-br")
        XCTAssertEqual(title(transformer.transform(model(["pt-br": ["title": "Olá"]]))), "Olá")
    }

    func testUnderscoreKeyIsNotMatched() {
        LocalizationManager.shared.setLocalization("pt-br")
        XCTAssertEqual(title(transformer.transform(model(["pt_BR": ["title": "Olá"]]))), "Hello")
    }

    func testPicksTheFirstCandidateInAscendingOrder() {
        LocalizationManager.shared.setLocalization("pt")
        let out = transformer.transform(model([
            "pt-pt": ["title": "PT"], "pt-br": ["title": "BR"]
        ]))
        XCTAssertEqual(title(out), "BR")
    }

    func testEmptyTranslationIsNotACandidate() {
        LocalizationManager.shared.setLocalization("pt")
        let out = transformer.transform(model([
            "pt-br": [String: Any](), "pt-pt": ["title": "PT"]
        ]))
        XCTAssertEqual(title(out), "PT")
    }

    func testSiblingRegionIsNotMatched() {
        LocalizationManager.shared.setLocalization("pt-br")
        XCTAssertEqual(title(transformer.transform(model(["pt-pt": ["title": "PT"]]))), "Hello")
    }

    func testMoreSpecificKeyIsUsedForAGenericLanguage() {
        LocalizationManager.shared.setLocalization("pt")
        XCTAssertEqual(title(transformer.transform(model(["pt-br": ["title": "OlaBr"]]))), "OlaBr")
    }

    func testInvalidJsonLocalizationsAreIgnored() {
        LocalizationManager.shared.setLocalization("pt-br")
        XCTAssertEqual(title(transformer.transform(model("not json"))), "Hello")
    }
}
