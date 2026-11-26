import XCTest
@testable import IosAwnCore

/// `NotificationBuilder.controlEvent`: a control that is not a notification
/// button (a media remote command) takes the path of a pressed button.
final class ControlEventTests: XCTestCase {

    private let builder = NotificationBuilder.newInstance()

    private let model: [String: Any] = [
        Definitions.NOTIFICATION_CONTENT: [Definitions.NOTIFICATION_ID: 5, "title": "Track"],
        Definitions.NOTIFICATION_BUTTONS: [[
            Definitions.NOTIFICATION_BUTTON_KEY: "DEL",
            Definitions.NOTIFICATION_ACTION_TYPE: "DismissAction"
        ]]
    ]

    private let seek: [String: Any] = [
        Definitions.NOTIFICATION_BUTTON_KEY: "awn.media.seekTo",
        Definitions.NOTIFICATION_ACTION_TYPE: "SilentAction",
        Definitions.NOTIFICATION_AUTO_DISMISSIBLE: false
    ]

    func testAControlEmitsItsActionWithItsInput() {
        let event = builder.controlEvent(
            model: model, buttonKey: "awn.media.seekTo", input: "37000", button: seek,
            lifeCycle: .foreground)
        XCTAssertEqual(event.eventName, Definitions.EVENT_DEFAULT_ACTION)
        XCTAssertEqual(event.data[Definitions.NOTIFICATION_BUTTON_KEY_PRESSED] as? String, "awn.media.seekTo")
        XCTAssertEqual(event.data[Definitions.NOTIFICATION_BUTTON_KEY_INPUT] as? String, "37000")
        XCTAssertEqual(event.data[Definitions.NOTIFICATION_ACTION_TYPE] as? String, "SilentAction")
        XCTAssertEqual(event.data[Definitions.NOTIFICATION_ID] as? Int, 5)
        XCTAssertNotNil(event.data[Definitions.NOTIFICATION_ACTION_DATE])
        XCTAssertNil(event.dismissId)
    }

    func testWithoutAControlTheModelButtonIsUsed() {
        let event = builder.controlEvent(model: model, buttonKey: "DEL", lifeCycle: .foreground)
        XCTAssertEqual(event.eventName, Definitions.EVENT_NOTIFICATION_DISMISSED)
        XCTAssertEqual(event.dismissId, 5)
        XCTAssertNil(event.data[Definitions.NOTIFICATION_BUTTON_KEY_INPUT])
    }
}
