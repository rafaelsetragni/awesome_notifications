import XCTest
import UserNotifications
@testable import IosAwnCore

/// Records the events the engine broadcasts.
final class EventRecorder: AwesomeEventListener {
    private let lock = NSLock()
    private var recorded: [(name: String, data: [String: Any])] = []

    var events: [(name: String, data: [String: Any])] {
        lock.lock(); defer { lock.unlock() }
        return recorded
    }
    var names: [String] { events.map { $0.name } }

    func onNewAwesomeEvent(eventType: String, content: [String: Any]) {
        lock.lock(); recorded.append((eventType, content)); lock.unlock()
    }

    func clear() { lock.lock(); recorded.removeAll(); lock.unlock() }
}

/// Records the removals the core announces to the add-ons.
final class RemovalRecorder: NotificationRemovalListener {
    private(set) var removals: [(NotificationRemoval, Bool)] = []
    func onNotificationsRemoved(_ removal: NotificationRemoval, cancel: Bool) {
        removals.append((removal, cancel))
    }
}

extension XCTestCase {
    /// Spins the run loop until [condition] holds (or fails after [timeout]).
    func waitUntil(
        _ description: String, timeout: TimeInterval = 5,
        file: StaticString = #filePath, line: UInt = #line,
        _ condition: () -> Bool
    ) {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition() {
            if Date() > deadline {
                XCTFail("timed out waiting for \(description)", file: file, line: line)
                return
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.01))
        }
    }
}

enum EngineFixtures {
    /// A serialized NotificationModel as Dart sends it.
    static func model(
        id: Int,
        channelKey: String = "basic",
        content extra: [String: Any] = [:],
        buttons: [[String: Any]]? = nil
    ) -> [String: Any] {
        var content: [String: Any] = [
            Definitions.NOTIFICATION_ID: id,
            Definitions.NOTIFICATION_CHANNEL_KEY: channelKey,
            Definitions.NOTIFICATION_TITLE: "Title \(id)",
            Definitions.NOTIFICATION_BODY: "Body \(id)"
        ]
        for (key, value) in extra { content[key] = value }
        var model: [String: Any] = [Definitions.NOTIFICATION_CONTENT: content]
        if let buttons = buttons { model[Definitions.NOTIFICATION_BUTTONS] = buttons }
        return model
    }

    /// The request the core posts for [model] (built and stamped as it does).
    static func request(
        _ model: [String: Any], trigger: UNNotificationTrigger? = nil
    ) -> UNNotificationRequest {
        let builder = NotificationBuilder()
        let built = builder.stampDisplayed(on: try! builder.build(model: model)!)
        return UNNotificationRequest(
            identifier: String(built.id), content: built.content, trigger: trigger)
    }

    /// The system's delivered notification of [model].
    static func delivered(_ model: [String: Any]) -> UNNotification {
        return FakeNotificationCenter.notification(request(model))
    }

    /// A notification that is not an awesome notification (no stored model).
    static func foreign(id: String = "foreign", trigger: UNNotificationTrigger? = nil) -> UNNotification {
        let content = UNMutableNotificationContent()
        content.title = "Not ours"
        return FakeNotificationCenter.notification(
            UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }
}
