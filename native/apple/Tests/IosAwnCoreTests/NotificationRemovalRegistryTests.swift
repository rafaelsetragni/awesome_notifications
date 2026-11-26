import XCTest
@testable import IosAwnCore

/// The removal hook the core notifies on dismiss* / cancel*.
final class NotificationRemovalRegistryTests: XCTestCase {

    private final class Recorder: NotificationRemovalListener {
        var calls: [(NotificationRemoval, Bool)] = []
        func onNotificationsRemoved(_ removal: NotificationRemoval, cancel: Bool) {
            calls.append((removal, cancel))
        }
    }

    func testListenersAreNotifiedOnceUntilUnregistered() {
        let recorder = Recorder()
        let registry = NotificationRemovalRegistry.shared
        registry.register(listener: recorder)
        registry.register(listener: recorder)  // no duplicate
        registry.notify(.id(3), cancel: true)
        registry.notify(.channelKey("c"), cancel: false)
        registry.notify(.groupKey("g"), cancel: true)
        registry.notify(.all, cancel: false)
        registry.unregister(listener: recorder)
        registry.notify(.all, cancel: true)

        XCTAssertEqual(recorder.calls.map { $0.0 }, [.id(3), .channelKey("c"), .groupKey("g"), .all])
        XCTAssertEqual(recorder.calls.map { $0.1 }, [true, false, true, false])
    }
}
