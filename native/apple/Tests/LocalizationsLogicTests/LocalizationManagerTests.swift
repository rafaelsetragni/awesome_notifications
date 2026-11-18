import XCTest
@testable import LocalizationsLogic

/// The current-language store and its channel methods. 
final class LocalizationManagerTests: XCTestCase {

    private let manager = LocalizationManager.shared

    override func tearDown() {
        manager.setLocalization(nil)
    }

    func testSetAndGetPersists() {
        XCTAssertTrue(manager.setLocalization("zh"))
        XCTAssertEqual(manager.getLocalization(), "zh")
    }

    func testCodeIsLowercased() {
        manager.setLocalization("PT-BR")
        XCTAssertEqual(manager.getLocalization(), "pt-br")
    }

    func testUnderscoresBecomeHyphens() {
        manager.setLocalization("EN_us")
        XCTAssertEqual(manager.getLocalization(), "en-us")
    }

    func testEmptyCodeIsStored() {
        manager.setLocalization("")
        XCTAssertEqual(manager.getLocalization(), "")
    }

    func testNullFallsBackToSystemLanguage() {
        manager.setLocalization(nil)
        let language = manager.getLocalization()
        XCTAssertFalse(language.isEmpty)
        XCTAssertEqual(language, language.lowercased())
    }

    func testMethodHandler() {
        let handler = LocalizationMethodHandler()
        var answer: Any?

        XCTAssertTrue(handler.handle(method: "setLocalization", arguments: "ES") { answer = $0 })
        XCTAssertEqual(answer as? Bool, true)

        XCTAssertTrue(handler.handle(method: "getLocalization", arguments: nil) { answer = $0 })
        XCTAssertEqual(answer as? String, "es")

        XCTAssertFalse(handler.handle(method: "createNotification", arguments: nil) { _ in
            XCTFail("unhandled methods must not answer")
        })
    }
}
