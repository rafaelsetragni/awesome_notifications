import UserNotifications
import XCTest
@testable import AwesomeNotificationsChatExtension
@testable import AwesomeNotificationsFcmExtension
@testable import IosAwnCore

/// The service extension rebuilds a push through the builder chain.
final class ServiceExtensionTests: XCTestCase {

    override func setUp() {
        RemoteModelProviderRegistry.shared.clearForTest()
        NotificationBuilderRegistry.shared.clearForTest()
    }

    private func request(_ userInfo: [String: Any], title: String = "Original") -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = title
        content.userInfo = userInfo
        return UNNotificationRequest(identifier: "push", content: content, trigger: nil)
    }

    func testAPushNoProviderKnowsIsShownAsItArrived() {
        let rendered = AwesomeServiceExtension.render(request(["orderId": "9"]))
        XCTAssertEqual(rendered.title, "Original")
    }

    func testAnFcmPushIsRebuiltThroughTheChain() {
        AwesomeFcmExtension.register()
        let rendered = AwesomeServiceExtension.render(request([
            "content": "{\"id\":4,\"channelKey\":\"push\",\"title\":\"From the server\",\"body\":\"Hi\"}"
        ]))
        XCTAssertEqual(rendered.title, "From the server")
        XCTAssertEqual(rendered.body, "Hi")
        // The model travels in userInfo, so a tap reaches the app's listeners.
        XCTAssertNotNil(rendered.userInfo[Definitions.NOTIFICATION_JSON])
    }

    /// In a test process the communication-notification setup is missing, so
    /// the chat builder rejects the message and the push is shown as it came.
    func testAChatPushTheChainRejectsIsShownAsItArrived() {
        AwesomeFcmExtension.register()
        AwesomeChatExtension.register()
        let rendered = AwesomeServiceExtension.render(request([
            "content": "{\"id\":4,\"channelKey\":\"chat\",\"notificationLayout\":\"Messaging\"}",
            "conversation": "{\"id\":\"ana\",\"me\":{\"key\":\"me\",\"name\":\"Me\"},\"message\":{\"sender\":{\"key\":\"ana\",\"name\":\"Ana\"},\"text\":\"Hi\"}}"
        ]))
        XCTAssertEqual(rendered.title, "Original")
    }
}
