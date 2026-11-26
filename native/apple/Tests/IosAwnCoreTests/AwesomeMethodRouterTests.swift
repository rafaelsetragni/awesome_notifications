import XCTest
@testable import IosAwnCore

/// The shared iOS/macOS method router: answers the core protocol, falls through
/// to registered decorators, and reports unknown methods as unhandled.
final class AwesomeMethodRouterTests: XCTestCase {

    private let router = AwesomeMethodRouter()

    private final class EchoHandler: AwesomeMethodHandler {
        func handle(method: String, arguments: Any?, result: @escaping (Any?) -> Void) -> Bool {
            guard method == "decoratorEcho" else { return false }
            result(arguments)
            return true
        }
    }

    private func call(_ method: String, _ arguments: Any? = nil) -> (handled: Bool, value: Any?) {
        var value: Any?
        let handled = router.handle(method: method, arguments: arguments) { value = $0 }
        return (handled, value)
    }

    func testTimeZoneIdentifiers() {
        XCTAssertEqual(call("getUtcTimeZoneIdentifier").value as? String, Definitions.UTC_TIMEZONE)
        XCTAssertEqual(call("getLocalTimeZoneIdentifier").value as? String, TimeZone.current.identifier)
    }

    func testSetEventHandlesIsAcknowledged() {
        let response = call("setEventHandles", ["any": 1])
        XCTAssertTrue(response.handled)
        XCTAssertEqual(response.value as? Bool, true)
    }

    func testCreateWithoutArgumentsAnswersFalse() {
        let response = call("createNewNotification", "not a map")
        XCTAssertTrue(response.handled)
        XCTAssertEqual(response.value as? Bool, false)
    }

    func testUnknownMethodIsNotHandled() {
        let response = call("noSuchMethod")
        XCTAssertFalse(response.handled)
        XCTAssertNil(response.value)
    }

    func testFallsThroughToRegisteredDecorators() {
        let handler = EchoHandler()
        AwesomeMethodHandlerRegistry.shared.register(handler: handler)
        defer { AwesomeMethodHandlerRegistry.shared.unregister(handler: handler) }

        let response = call("decoratorEcho", "hi")
        XCTAssertTrue(response.handled)
        XCTAssertEqual(response.value as? String, "hi")
    }
}
