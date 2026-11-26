import XCTest
@testable import IosAwnCore

/// 0.12 threading: the messaging layouts thread their channel's messages; any
/// other notification is threaded by its group key.
final class MessagingThreadTests: XCTestCase {

    private let builder = NotificationBuilder.newInstance()

    private func thread(_ content: [String: Any]) -> String? {
        builder.createNotificationContent(fromModel: [
            Definitions.NOTIFICATION_CONTENT: [Definitions.NOTIFICATION_ID: 1].merging(content) { $1 }
        ])?.content.threadIdentifier
    }

    func testMessagingThreadsByChannel() {
        XCTAssertEqual(thread(["channelKey": "chat", "notificationLayout": "Messaging",
                               "groupKey": "family"]), "Messaging.chat")
        XCTAssertEqual(thread(["channelKey": "chat", "notificationLayout": "MessagingGroup"]),
                       "MessagingGR.chat")
    }

    func testOtherLayoutsThreadByGroupKey() {
        XCTAssertEqual(thread(["channelKey": "chat", "groupKey": "family"]), "family")
        XCTAssertEqual(thread(["channelKey": "chat", "notificationLayout": "BigPicture",
                               "groupKey": "g"]), "g")
    }

    func testNoGroupKeyNoThread() {
        XCTAssertEqual(thread(["channelKey": "chat"]), "")
    }
}
