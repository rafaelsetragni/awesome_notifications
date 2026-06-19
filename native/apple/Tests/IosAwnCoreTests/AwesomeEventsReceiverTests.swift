import XCTest
@testable import IosAwnCore

private final class RecordingListener: AwesomeEventListener {
    private(set) var events: [(eventType: String, content: [String: Any])] = []

    func onNewAwesomeEvent(eventType: String, content: [String: Any]) {
        events.append((eventType, content))
    }
}

final class AwesomeEventsReceiverTests: XCTestCase {

    private let receiver = AwesomeEventsReceiver.shared
    private var listener: RecordingListener!

    override func setUp() {
        super.setUp()
        listener = RecordingListener()
    }

    override func tearDown() {
        receiver.unsubscribe(listener: listener)
        listener = nil
        super.tearDown()
    }

    func testSubscribedListenerReceivesEvents() {
        receiver.subscribe(listener: listener)
        receiver.notifyAwesomeEvent(eventType: "notificationCreated", content: ["id": 1])

        XCTAssertEqual(listener.events.count, 1)
        XCTAssertEqual(listener.events.first?.eventType, "notificationCreated")
        XCTAssertEqual(listener.events.first?.content["id"] as? Int, 1)
    }

    func testUnsubscribedListenerStopsReceiving() {
        receiver.subscribe(listener: listener)
        receiver.notifyAwesomeEvent(eventType: "first", content: [:])
        receiver.unsubscribe(listener: listener)
        receiver.notifyAwesomeEvent(eventType: "second", content: [:])

        XCTAssertEqual(listener.events.count, 1)
        XCTAssertEqual(listener.events.first?.eventType, "first")
    }

    func testSubscribingTwiceDoesNotDuplicateDelivery() {
        receiver.subscribe(listener: listener)
        receiver.subscribe(listener: listener)
        receiver.notifyAwesomeEvent(eventType: "once", content: [:])

        XCTAssertEqual(listener.events.count, 1)
    }
}
