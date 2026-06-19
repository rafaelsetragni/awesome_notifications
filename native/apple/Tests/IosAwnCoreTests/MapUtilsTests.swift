import XCTest
@testable import IosAwnCore

final class MapUtilsTests: XCTestCase {

    private let mapUtils = MapUtils.shared

    func testGetIntFromInt() {
        XCTAssertEqual(mapUtils.getInt(5), 5)
    }

    func testGetIntFromNSNumber() {
        XCTAssertEqual(mapUtils.getInt(NSNumber(value: 7)), 7)
    }

    func testGetIntFromNumericString() {
        XCTAssertEqual(mapUtils.getInt("42"), 42)
    }

    func testGetIntFromInvalidValues() {
        XCTAssertNil(mapUtils.getInt("abc"))
        XCTAssertNil(mapUtils.getInt(nil))
        XCTAssertNil(mapUtils.getInt(["x"]))
    }

    func testGetString() {
        XCTAssertEqual(mapUtils.getString("text"), "text")
        XCTAssertNil(mapUtils.getString(5))
        XCTAssertNil(mapUtils.getString(nil))
    }

    func testGetBool() {
        XCTAssertEqual(mapUtils.getBool(true), true)
        XCTAssertEqual(mapUtils.getBool(false), false)
        XCTAssertEqual(mapUtils.getBool(NSNumber(value: true)), true)
        XCTAssertNil(mapUtils.getBool("true"))
        XCTAssertNil(mapUtils.getBool(nil))
    }
}
