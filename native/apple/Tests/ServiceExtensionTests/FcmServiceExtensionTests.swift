import UserNotifications
import XCTest
@testable import AwesomeNotificationsFcmExtension
@testable import IosAwnCore

/// The 0.12-named FCM service extension and the push → model provider.
final class FcmServiceExtensionTests: XCTestCase {

    override func setUp() {
        super.setUp()
        FakeNotificationCenter.install()
        RemoteModelProviderRegistry.shared.clearForTest()
        NotificationBuilderRegistry.shared.clearForTest()
        AwesomeServiceExtension.resetAddOnsForTest()
        CriticalAlertUtils.setCache(false)
    }

    override func tearDown() {
        RemoteModelProviderRegistry.shared.clearForTest()
        NotificationBuilderRegistry.shared.clearForTest()
        CriticalAlertUtils.clearCache()
        super.tearDown()
    }

    private func request(_ userInfo: [String: Any]) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = "Original"
        content.userInfo = userInfo
        return UNNotificationRequest(identifier: "push", content: content, trigger: nil)
    }

    private func id(_ model: [String: Any]?) -> Int? {
        (model?[Definitions.NOTIFICATION_CONTENT] as? [String: Any])?[Definitions.NOTIFICATION_ID] as? Int
    }

    func testTheDartServiceExtensionHandlesFcmPushes() {
        let ext = DartAwesomeServiceExtension()
        var delivered: [UNNotificationContent] = []
        ext.didReceive(request([
            "content": "{\"id\":4,\"channelKey\":\"push\",\"title\":\"From the server\"}"
        ])) { delivered.append($0) }
        waitUntil("rendered") { delivered.count == 1 }
        XCTAssertEqual(delivered[0].title, "From the server")
        // registerAddOns registered the FCM provider.
        XCTAssertNotNil(RemoteModelProviderRegistry.shared.model(from: request(["content.title": "x"])))
    }

    func testTheIdComesFromTheContentOrTheTime() {
        let provider = FcmRemoteModelProvider()
        XCTAssertNil(provider.model(from: request(["orderId": "9"])), "not displayable")
        XCTAssertEqual(id(provider.model(from: request(["content": "{\"id\":12}"]))), 12)
        XCTAssertEqual(id(provider.model(from: request(["content.id": "13", "content.title": "Hi"]))), 13)

        // Without an id: one derived from the time, a positive 31-bit value.
        let before = Int(Date().timeIntervalSince1970 * 1000) & 0x7fffffff
        let derived = id(provider.model(from: request(["content.title": "Hi"])))
        let after = Int(Date().timeIntervalSince1970 * 1000) & 0x7fffffff
        XCTAssertNotNil(derived)
        XCTAssertGreaterThanOrEqual(derived ?? -1, 0)
        if before <= after {
            XCTAssertTrue((before...after).contains(derived ?? -1))
        }
        // A non-numeric flattened id also falls back to the time.
        XCTAssertNotNil(id(provider.model(from: request(["content.id": "abc", "content.title": "Hi"]))))
    }
}
