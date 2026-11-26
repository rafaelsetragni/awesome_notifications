import XCTest
@testable import IosAwnCore

final class StringUtilsTests: XCTestCase {

    private let stringUtils = StringUtils.shared

    func testNilIsEmpty() {
        XCTAssertTrue(stringUtils.isNullOrEmpty(nil))
    }

    func testEmptyStringIsEmpty() {
        XCTAssertTrue(stringUtils.isNullOrEmpty(""))
    }

    func testWhitespaceOnlyIsEmpty() {
        XCTAssertTrue(stringUtils.isNullOrEmpty("   "))
        XCTAssertTrue(stringUtils.isNullOrEmpty("\n\t "))
    }

    func testNonEmptyIsNotEmpty() {
        XCTAssertFalse(stringUtils.isNullOrEmpty("hello"))
        XCTAssertFalse(stringUtils.isNullOrEmpty("  x  "))
    }
}
