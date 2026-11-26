import XCTest
import UserNotifications
@testable import IosAwnCore

/// 0.12.1 `getPermissionStatuses` rules.
final class PermissionStatusTests: XCTestCase {

    private let manager = PermissionManager.shared

    override func setUp() {
        super.setUp()
        ChannelManager.shared.clearForTest()
    }

    override func tearDown() {
        ChannelManager.shared.clearForTest()
        super.tearDown()
    }

    private func status(
        _ permission: String, _ settings: PermissionSettings, channelKey: String? = nil
    ) -> String? {
        return manager.resolveStatuses([permission], settings: settings, channelKey: channelKey)[permission]
    }

    private let authorized = PermissionSettings(
        authorizationStatus: .authorized,
        alertSetting: .enabled, soundSetting: .disabled, badgeSetting: .enabled,
        carPlaySetting: .notSupported, criticalAlertSetting: .notSupported)

    func testBaseSettingsFollowTheAuthorization() {
        XCTAssertEqual(status("Alert", authorized), "granted")
        XCTAssertEqual(status("Sound", authorized), "denied")
        XCTAssertEqual(status("Badge", authorized), "granted")
        XCTAssertEqual(status("Car", authorized), "notSupported")

        let notDetermined = PermissionSettings(authorizationStatus: .notDetermined, alertSetting: .enabled)
        XCTAssertEqual(status("Alert", notDetermined), "notDetermined")
        let denied = PermissionSettings(authorizationStatus: .denied, alertSetting: .enabled)
        XCTAssertEqual(status("Alert", denied), "denied")
        XCTAssertEqual(status("Car", denied), "denied")
    }

    func testCriticalAlert() {
        // Without the entitlement: notSupported, unless the base notifications
        // are granted — then never requested yet: notDetermined (0.12.1 quirk).
        XCTAssertEqual(status("CriticalAlert", authorized), "notDetermined")
        XCTAssertEqual(status("OverrideDnD", authorized), "notDetermined")
        var settings = PermissionSettings(authorizationStatus: .provisional)
        XCTAssertEqual(status("CriticalAlert", settings), "notDetermined")
        settings = PermissionSettings(authorizationStatus: .denied)
        XCTAssertEqual(status("CriticalAlert", settings), "notSupported")
        settings = PermissionSettings(authorizationStatus: .notDetermined)
        XCTAssertEqual(status("CriticalAlert", settings), "notSupported")

        // With the entitlement.
        settings = PermissionSettings(authorizationStatus: .authorized, criticalAlertSetting: .enabled)
        XCTAssertEqual(status("CriticalAlert", settings), "granted")
        settings = PermissionSettings(authorizationStatus: .authorized, criticalAlertSetting: .disabled)
        XCTAssertEqual(status("CriticalAlert", settings), "notDetermined")
        settings = PermissionSettings(authorizationStatus: .denied, criticalAlertSetting: .disabled)
        XCTAssertEqual(status("CriticalAlert", settings), "denied")
        settings = PermissionSettings(authorizationStatus: .notDetermined, criticalAlertSetting: .disabled)
        XCTAssertEqual(status("CriticalAlert", settings), "notDetermined")
    }

    func testProvisional() {
        XCTAssertEqual(status("Provisional", PermissionSettings(authorizationStatus: .provisional)), "granted")
        XCTAssertEqual(status("Provisional", PermissionSettings(authorizationStatus: .notDetermined)), "notDetermined")
        XCTAssertEqual(status("Provisional", PermissionSettings(authorizationStatus: .denied)), "denied")
        XCTAssertEqual(status("Provisional", authorized), "notDetermined")
    }

    func testUnknownPermissionIsNotSupported() {
        XCTAssertEqual(status("Telepathy", authorized), "notSupported")
    }

    func testChannelPermissions() {
        // Without a channel key: granted, whatever the authorization.
        let denied = PermissionSettings(authorizationStatus: .denied)
        for permission in ["Vibration", "Light", "PreciseAlarms", "FullScreenIntent"] {
            XCTAssertEqual(status(permission, denied), "granted", permission)
        }
        // An unknown channel allows nothing.
        XCTAssertEqual(status("Vibration", authorized, channelKey: "nope"), "denied")

        ChannelManager.shared.setChannel([
            Definitions.NOTIFICATION_CHANNEL_KEY: "calm",
            Definitions.NOTIFICATION_ENABLE_VIBRATION: false
        ])
        XCTAssertEqual(status("Vibration", authorized, channelKey: "calm"), "denied")
        XCTAssertEqual(status("Light", authorized, channelKey: "calm"), "granted")
        XCTAssertEqual(status("PreciseAlarms", authorized, channelKey: "calm"), "granted")
        // The system-level permissions ignore the channel.
        XCTAssertEqual(status("Alert", authorized, channelKey: "calm"), "granted")

        // A channel of importance None allows nothing.
        ChannelManager.shared.setChannel([
            Definitions.NOTIFICATION_CHANNEL_KEY: "off",
            Definitions.NOTIFICATION_IMPORTANCE: "None"
        ])
        XCTAssertEqual(status("Light", authorized, channelKey: "off"), "denied")
    }

    func testEveryPermissionIsAnswered() {
        let all = NotificationPermission.allCases.map { $0.rawValue }
        let statuses = manager.resolveStatuses(all, settings: authorized, channelKey: nil)
        XCTAssertEqual(Set(statuses.keys), Set(all))
        let valid = Set(NotificationPermissionStatus.allCases.map { $0.rawValue })
        XCTAssertTrue(statuses.values.allSatisfy { valid.contains($0) })
    }

    func testRouterRequiresAPermissionList() {
        var answer: Any?
        XCTAssertTrue(AwesomeMethodRouter().handle(method: "getPermissionStatuses", arguments: nil) {
            answer = $0
        })
        XCTAssertEqual((answer as? AwesomeNotificationsException)?.code, "MISSING_ARGUMENTS")

        answer = nil
        XCTAssertTrue(AwesomeMethodRouter().handle(
            method: "getPermissionStatuses", arguments: ["permissions": [String]()]
        ) { answer = $0 })
        XCTAssertEqual((answer as? AwesomeNotificationsException)?.code, "INVALID_ARGUMENTS")
        XCTAssertEqual((answer as? AwesomeNotificationsException)?.detailedCode,
                       "arguments.required.permissionList")
    }
}
