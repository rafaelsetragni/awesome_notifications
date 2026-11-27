import XCTest
import IosAwnCore
@testable import FcmLogic

/// Silent (data-only) pushes, the APNs alert baseline and the persisted handles.
final class FcmSilentDataAndDefaultsTests: XCTestCase {

    private let parser = FcmMessageParser()

    private func content(_ model: [String: Any]) -> [String: Any] {
        model[Definitions.NOTIFICATION_CONTENT] as? [String: Any] ?? [:]
    }

    // MARK: - SilentDataModel

    func testTheEnvelopeIsPulledOutOfTheData() {
        let model = SilentDataModel().fromData([
            Definitions.NOTIFICATION_ID: "42",
            Definitions.NOTIFICATION_CREATED_DATE: "2026-01-02 03:04:05",
            Definitions.NOTIFICATION_CREATED_SOURCE: "Schedule",
            Definitions.NOTIFICATION_CREATED_LIFECYCLE: "Background",
            FcmDefinitions.SILENT_HANDLE: "123",
            FcmDefinitions.APS: ["content-available": 1],
            "orderId": "9",
            "nested": ["a": 1]
        ])
        XCTAssertEqual(model.id, 42)
        XCTAssertEqual(model.createdDate, "2026-01-02 03:04:05")
        XCTAssertEqual(model.createdSource, .schedule)
        XCTAssertEqual(model.createdLifeCycle, .background)
        XCTAssertEqual(Set(model.data.keys), ["orderId", "nested"])

        let map = model.toMap()
        XCTAssertEqual(map[Definitions.NOTIFICATION_ID] as? String, "42", "the id travels as a string")
        XCTAssertEqual(map[Definitions.NOTIFICATION_CREATED_DATE] as? String, "2026-01-02 03:04:05")
        XCTAssertEqual(map[Definitions.NOTIFICATION_CREATED_SOURCE] as? String, "Schedule")
        XCTAssertEqual(map[Definitions.NOTIFICATION_CREATED_LIFECYCLE] as? String, "Background")
        XCTAssertEqual(map["orderId"] as? String, "9")
        XCTAssertNil(map[FcmDefinitions.SILENT_HANDLE])
        XCTAssertNil(map[FcmDefinitions.APS])
    }

    func testDefaultsOfASilentPush() {
        let model = SilentDataModel().fromData([
            Definitions.NOTIFICATION_ID: 7,
            Definitions.NOTIFICATION_CREATED_SOURCE: "Nowhere",
            Definitions.NOTIFICATION_CREATED_LIFECYCLE: "Asleep"
        ])
        XCTAssertEqual(model.id, 7)
        XCTAssertEqual(model.createdSource, .firebase)
        XCTAssertEqual(model.createdLifeCycle, .terminated)
        // Stamped now, in the lifecycle date format.
        let date = try? XCTUnwrap(model.createdDate)
        XCTAssertNotNil(date)
        XCTAssertNotNil(date.flatMap { Self.utc.date(from: $0) }, date ?? "nil")

        let anonymous = SilentDataModel().fromData(["id": "not a number"]).toMap()
        XCTAssertNil(anonymous[Definitions.NOTIFICATION_ID] as? String)
        XCTAssertEqual(anonymous[Definitions.NOTIFICATION_CREATED_SOURCE] as? String, "Firebase")
        XCTAssertEqual(anonymous[Definitions.NOTIFICATION_CREATED_LIFECYCLE] as? String, "Terminated")
    }

    private static let utc: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }()

    // MARK: - APNs alert baseline

    func testTheApsAlertIsTheBaselineContent() {
        let model = parser.buildAwesomeMap(notificationId: 3, userInfo: [
            "aps": ["alert": ["title": "From APNs", "body": "Hello"]],
            "orderId": "9"
        ], lifeCycle: .background)
        let c = content(model)
        XCTAssertEqual(c[Definitions.NOTIFICATION_ID] as? Int, 3)
        XCTAssertEqual(c[Definitions.NOTIFICATION_TITLE] as? String, "From APNs")
        XCTAssertEqual(c[Definitions.NOTIFICATION_BODY] as? String, "Hello")
        XCTAssertEqual(c[Definitions.NOTIFICATION_PAYLOAD] as? [String: String], ["orderId": "9"])
        XCTAssertEqual(c[Definitions.NOTIFICATION_CREATED_SOURCE] as? String, "Firebase")
        XCTAssertEqual(c[Definitions.NOTIFICATION_CREATED_LIFECYCLE] as? String, "Background")

        let plain = content(parser.buildAwesomeMap(
            notificationId: 4, userInfo: ["aps": ["alert": "Just a body"]], lifeCycle: .foreground))
        XCTAssertNil(plain[Definitions.NOTIFICATION_TITLE])
        XCTAssertEqual(plain[Definitions.NOTIFICATION_BODY] as? String, "Just a body")
        XCTAssertNil(plain[Definitions.NOTIFICATION_PAYLOAD])

        let partial = content(parser.buildAwesomeMap(
            notificationId: 5, userInfo: ["aps": ["alert": ["subtitle": "only"]]], lifeCycle: .foreground))
        XCTAssertNil(partial[Definitions.NOTIFICATION_TITLE])
        XCTAssertNil(partial[Definitions.NOTIFICATION_BODY])
    }

    func testScheduleAndLocalizationsSections() {
        let model = parser.buildAwesomeMap(notificationId: 1, userInfo: [
            "content": "{\"id\":8,\"channelKey\":\"push\"}",
            "schedule": "{\"interval\":60,\"repeats\":true}",
            "localizations": "{\"pt-br\":{\"title\":\"Olá\"}}"
        ], lifeCycle: .foreground)
        let schedule = model[FcmDefinitions.MODEL_SCHEDULE] as? [String: Any]
        XCTAssertEqual(schedule?["interval"] as? Int, 60)
        XCTAssertEqual(schedule?["repeats"] as? Bool, true)
        let localizations = model[FcmDefinitions.MODEL_LOCALIZATIONS] as? [String: Any]
        XCTAssertEqual((localizations?["pt-br"] as? [String: Any])?["title"] as? String, "Olá")

        // Empty sections are left out.
        let empty = parser.buildAwesomeMap(notificationId: 1, userInfo: [
            "content": "{\"id\":8}", "schedule": "{}", "localizations": "{}"
        ], lifeCycle: .foreground)
        XCTAssertNil(empty[FcmDefinitions.MODEL_SCHEDULE])
        XCTAssertNil(empty[FcmDefinitions.MODEL_LOCALIZATIONS])
    }

    // MARK: - Persisted handles

    private let keys = ["awn_fcm_debug", "awn_fcm_dartBackgroundHandle",
                        "awn_fcm_silentCallbackHandle", "awn_fcm_lastToken"]

    override func setUp() {
        super.setUp()
        keys.forEach { UserDefaults.standard.removeObject(forKey: $0) }
    }

    override func tearDown() {
        keys.forEach { UserDefaults.standard.removeObject(forKey: $0) }
        super.tearDown()
    }

    func testHandlesAndTokenArePersisted() {
        XCTAssertEqual(FcmDefaultsManager.dartBackgroundHandle, 0)
        XCTAssertEqual(FcmDefaultsManager.silentCallbackHandle, 0)
        XCTAssertFalse(FcmDefaultsManager.isDebug)
        XCTAssertNil(FcmDefaultsManager.lastToken)

        FcmDefaultsManager.saveHandles(
            dartBackgroundHandle: 9_007_199_254_740_993, silentCallbackHandle: -5, debug: true)
        XCTAssertEqual(FcmDefaultsManager.dartBackgroundHandle, 9_007_199_254_740_993)
        XCTAssertEqual(FcmDefaultsManager.silentCallbackHandle, -5)
        XCTAssertTrue(FcmDefaultsManager.isDebug)

        // A missing handle keeps the stored one; the debug flag is always written.
        FcmDefaultsManager.saveHandles(dartBackgroundHandle: nil, silentCallbackHandle: 11, debug: false)
        XCTAssertEqual(FcmDefaultsManager.dartBackgroundHandle, 9_007_199_254_740_993)
        XCTAssertEqual(FcmDefaultsManager.silentCallbackHandle, 11)
        XCTAssertFalse(FcmDefaultsManager.isDebug)

        FcmDefaultsManager.lastToken = "token-1"
        XCTAssertEqual(FcmDefaultsManager.lastToken, "token-1")
        FcmDefaultsManager.lastToken = nil
        XCTAssertNil(FcmDefaultsManager.lastToken)
    }
}
