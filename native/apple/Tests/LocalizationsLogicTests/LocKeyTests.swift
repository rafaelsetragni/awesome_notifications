import XCTest
@testable import LocalizationsLogic

/// `titleLocKey` / `bodyLocKey` resolved from an app-like bundle with `.lproj`
/// folders (written to a temporary directory), with the 0.12 IosAwnCore rules:
/// the full language code's `.lproj` first, then only the language part.
final class LocKeyTests: XCTestCase {

    private var root: URL!

    override func setUpWithError() throws {
        root = FileManager.default.temporaryDirectory
            .appendingPathComponent("awn-lproj-\(UUID().uuidString)", isDirectory: true)
        try write("pt-BR", ["greeting": "Olá, %@!", "news": "%@ tem %@ novidades", "plain": "Texto BR"])
        try write("es", ["greeting": "¡Hola, %@!"])
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: root)
        LocalizationManager.shared.setLocalization(nil)
    }

    private func write(_ lproj: String, _ strings: [String: String]) throws {
        let folder = root.appendingPathComponent("\(lproj).lproj", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let body = strings.map { "\"\($0.key)\" = \"\($0.value)\";" }.joined(separator: "\n")
        try body.write(to: folder.appendingPathComponent("Localizable.strings"),
                       atomically: true, encoding: .utf8)
    }

    private func transform(_ language: String, _ content: [String: Any],
                           localizations: Any? = nil) throws -> [String: Any] {
        LocalizationManager.shared.setLocalization(language)
        let transformer = LocalizationTransformer(bundle: try XCTUnwrap(Bundle(path: root.path)))
        var model: [String: Any] = ["content": ["id": 1, "title": "Hello", "body": "Body"]
            .merging(content) { $1 }]
        if let localizations = localizations { model["localizations"] = localizations }
        return transformer.transform(model)["content"] as? [String: Any] ?? [:]
    }

    func testTitleAndBodyKeysWithArgs() throws {
        let content = try transform("pt-br", [
            "titleLocKey": "greeting", "titleLocArgs": ["Ana"],
            "bodyLocKey": "news", "bodyLocArgs": ["Ana", "3"]
        ])
        XCTAssertEqual(content["title"] as? String, "Olá, Ana!")
        XCTAssertEqual(content["body"] as? String, "Ana tem 3 novidades")
    }

    func testKeyWithoutArgsUsesTheText() throws {
        let content = try transform("pt-br", ["titleLocKey": "plain"])
        XCTAssertEqual(content["title"] as? String, "Texto BR")
    }

    func testFallsBackToTheLanguagePart() throws {
        let content = try transform("es-mx", ["titleLocKey": "greeting", "titleLocArgs": ["Ana"]])
        XCTAssertEqual(content["title"] as? String, "¡Hola, Ana!")
    }

    func testNoLprojForTheLanguageKeepsTheTitle() throws {
        let content = try transform("fr", ["titleLocKey": "greeting"])
        XCTAssertEqual(content["title"] as? String, "Hello")
    }

    func testMissingKeyFollowsNSLocalizedString() throws {
        // 0.12 behavior: NSLocalizedString answers the key itself.
        let content = try transform("pt-br", ["titleLocKey": "missing_key"])
        XCTAssertEqual(content["title"] as? String, "missing_key")
    }

    func testLocalizationsBlockOverridesLocKeys() throws {
        let content = try transform(
            "pt-br",
            ["titleLocKey": "greeting", "titleLocArgs": ["Ana"],
             "bodyLocKey": "news", "bodyLocArgs": ["Ana", "3"]],
            localizations: ["pt-br": ["title": "Do bloco"]])
        XCTAssertEqual(content["title"] as? String, "Do bloco")
        XCTAssertEqual(content["body"] as? String, "Ana tem 3 novidades")
    }

    func testWithoutLocKeysNothingChanges() throws {
        let content = try transform("pt-br", [:])
        XCTAssertEqual(content["title"] as? String, "Hello")
        XCTAssertEqual(content["body"] as? String, "Body")
    }
}
