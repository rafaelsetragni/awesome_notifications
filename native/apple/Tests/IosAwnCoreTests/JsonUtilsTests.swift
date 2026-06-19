import XCTest
@testable import IosAwnCore

final class JsonUtilsTests: XCTestCase {

    private let jsonUtils = JsonUtils.shared
    private let mapUtils = MapUtils.shared

    func testRoundTripPreservesValues() {
        let original: [String: Any] = [
            "id": 42,
            "channelKey": "basic",
            "title": "Hello"
        ]

        guard let json = jsonUtils.toJson(original),
              let restored = jsonUtils.fromJson(json) else {
            return XCTFail("round-trip returned nil")
        }

        XCTAssertEqual(mapUtils.getInt(restored["id"]), 42)
        XCTAssertEqual(mapUtils.getString(restored["channelKey"]), "basic")
        XCTAssertEqual(mapUtils.getString(restored["title"]), "Hello")
    }

    func testNestedMapRoundTrip() {
        let original: [String: Any] = [
            "content": ["id": 1, "title": "Nested"]
        ]

        guard let json = jsonUtils.toJson(original),
              let restored = jsonUtils.fromJson(json),
              let content = restored["content"] as? [String: Any] else {
            return XCTFail("nested round-trip failed")
        }

        XCTAssertEqual(mapUtils.getInt(content["id"]), 1)
        XCTAssertEqual(mapUtils.getString(content["title"]), "Nested")
    }

    func testNullValuesAreDropped() {
        let original: [String: Any] = [
            "id": 1,
            "title": NSNull()
        ]

        guard let json = jsonUtils.toJson(original),
              let restored = jsonUtils.fromJson(json) else {
            return XCTFail("round-trip returned nil")
        }

        XCTAssertEqual(mapUtils.getInt(restored["id"]), 1)
        XCTAssertNil(restored["title"])
    }

    func testFromJsonWithInvalidInputReturnsNil() {
        XCTAssertNil(jsonUtils.fromJson(nil))
        XCTAssertNil(jsonUtils.fromJson(""))
        XCTAssertNil(jsonUtils.fromJson("not json"))
        XCTAssertNil(jsonUtils.fromJson("[1,2,3]")) // array, not an object
    }

    func testToJsonWithNilReturnsNil() {
        XCTAssertNil(jsonUtils.toJson(nil))
    }
}
