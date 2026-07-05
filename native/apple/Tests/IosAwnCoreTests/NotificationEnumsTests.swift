import XCTest
@testable import IosAwnCore

/// The enums are the single source of truth for the strings serialized over the
/// channel. These lock the wire values (rawValue) and the tolerant `ActionType`
/// parser (plain `.name`, legacy `"ActionType.X"`, and fallback).
final class NotificationEnumsTests: XCTestCase {

    func testSourceRawValues() {
        XCTAssertEqual(NotificationSource.local.rawValue, "Local")
        XCTAssertEqual(NotificationSource.schedule.rawValue, "Schedule")
    }

    func testLifeCycleRawValues() {
        // Terminated, NOT the deprecated "AppKilled" the Dart side no longer parses.
        XCTAssertEqual(NotificationLifeCycle.foreground.rawValue, "Foreground")
        XCTAssertEqual(NotificationLifeCycle.background.rawValue, "Background")
        XCTAssertEqual(NotificationLifeCycle.terminated.rawValue, "Terminated")
    }

    func testActionTypeParsesExact() {
        XCTAssertEqual(ActionType.from("DismissAction"), .dismissAction)
        XCTAssertEqual(ActionType.from("KeepOnTop"), .keepOnTop)
        XCTAssertEqual(ActionType.from("SilentBackgroundAction"), .silentBackgroundAction)
    }

    func testActionTypeParsesLegacyPrefixed() {
        XCTAssertEqual(ActionType.from("ActionType.KeepOnTop"), .keepOnTop)
    }

    func testActionTypeFallsBackToDefault() {
        XCTAssertEqual(ActionType.from(nil), .default)
        XCTAssertEqual(ActionType.from(""), .default)
        XCTAssertEqual(ActionType.from("Bogus"), .default)
    }

    func testMediaSourcePrefixes() {
        XCTAssertEqual(MediaSourcePrefix.resource, "resource://")
        XCTAssertEqual(MediaSourcePrefix.asset, "asset://")
        XCTAssertEqual(MediaSourcePrefix.file, "file://")
        XCTAssertEqual(MediaSourcePrefix.networkHttps, "https://")
    }
}
