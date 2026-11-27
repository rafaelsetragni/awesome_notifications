import XCTest
@testable import IosAwnCore
#if canImport(Intents)
import Intents
#endif

final class NotificationPersonTests: XCTestCase {

    func testParsesAPerson() {
        let person = NotificationPerson([
            "key": "u-1", "name": "Ana", "avatar": "asset://a.png", "uri": "tel:+55",
            "isBot": true, "isImportant": true
        ])
        XCTAssertEqual(person, NotificationPerson(
            key: "u-1", name: "Ana", avatar: "asset://a.png", uri: "tel:+55",
            isBot: true, isImportant: true))
    }

    func testOptionalFieldsDefault() {
        let person = NotificationPerson(["key": "u-1", "name": "Ana", "isBot": NSNull()])
        XCTAssertNil(person?.avatar)
        XCTAssertNil(person?.uri)
        XCTAssertEqual(person?.isBot, false)
        XCTAssertEqual(person?.isImportant, false)
        // Only a boolean true counts.
        XCTAssertEqual(NotificationPerson(["key": "k", "name": "n", "isBot": "true"])?.isBot, false)
    }

    func testRejectsInvalidPeople() {
        XCTAssertNil(NotificationPerson(nil))
        XCTAssertNil(NotificationPerson("Ana"))
        XCTAssertNil(NotificationPerson(["name": "Ana"]))
        XCTAssertNil(NotificationPerson(["key": "u-1"]))
        XCTAssertNil(NotificationPerson(["key": "  ", "name": "Ana"]))
        XCTAssertNil(NotificationPerson(["key": "u-1", "name": " "]))
        XCTAssertNil(NotificationPerson(["key": 1, "name": "Ana"]))
    }

    func testHandle() {
        XCTAssertEqual(NotificationPerson(key: "k", name: "n", uri: "tel:+5511999").handle,
                       NotificationPersonHandle(value: "+5511999", type: .phoneNumber))
        XCTAssertEqual(NotificationPerson(key: "k", name: "n", uri: "mailto:a@b.com").handle,
                       NotificationPersonHandle(value: "a@b.com", type: .emailAddress))
        XCTAssertEqual(NotificationPerson(key: "k", name: "n", uri: "https://x.com/u").handle,
                       NotificationPersonHandle(value: "k", type: .unknown))
        XCTAssertEqual(NotificationPerson(key: "k", name: "n").handle,
                       NotificationPersonHandle(value: "k", type: .unknown))
    }

    #if canImport(Intents)
    func testINPersonHandle() throws {
        guard #available(macOS 11.0, *) else { throw XCTSkip("needs macOS 11") }
        let handle = NotificationPerson(key: "k", name: "n", uri: "mailto:a@b.com").handle.inPersonHandle
        XCTAssertEqual(handle.value, "a@b.com")
        XCTAssertEqual(handle.type, .emailAddress)
        XCTAssertEqual(NotificationPerson(key: "k", name: "n").handle.inPersonHandle.type, .unknown)
    }
    #endif
}
