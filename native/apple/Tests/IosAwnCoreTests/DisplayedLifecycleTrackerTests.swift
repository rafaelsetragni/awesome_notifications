import XCTest
@testable import IosAwnCore

/// A scheduled notification is stored with a predicted displayed lifecycle of
/// terminated; when it fires with the app open, the action event must report
/// foreground (and the real displayed date).
final class DisplayedLifecycleTrackerTests: XCTestCase {

    private let predicted: [String: Any] = [
        Definitions.NOTIFICATION_ID: 7,
        Definitions.NOTIFICATION_DISPLAYED_DATE: "2026-01-01 10:00:00",
        Definitions.NOTIFICATION_DISPLAYED_LIFECYCLE: NotificationLifeCycle.terminated.rawValue
    ]

    func testForegroundDisplayOverridesThePrediction() {
        let tracker = DisplayedLifecycleTracker()
        tracker.recordForegroundDisplay(id: 7, date: "2026-01-01 10:00:05")

        let resolved = tracker.resolve(predicted, id: 7)
        XCTAssertEqual(
            resolved[Definitions.NOTIFICATION_DISPLAYED_LIFECYCLE] as? String,
            NotificationLifeCycle.foreground.rawValue)
        XCTAssertEqual(
            resolved[Definitions.NOTIFICATION_DISPLAYED_DATE] as? String, "2026-01-01 10:00:05")
    }

    func testWithoutARecordThePredictionStands() {
        let resolved = DisplayedLifecycleTracker().resolve(predicted, id: 7)
        XCTAssertEqual(
            resolved[Definitions.NOTIFICATION_DISPLAYED_LIFECYCLE] as? String,
            NotificationLifeCycle.terminated.rawValue)
    }

    func testRecordIsConsumedAndScopedToItsId() {
        let tracker = DisplayedLifecycleTracker()
        tracker.recordForegroundDisplay(id: 7, date: "d")

        XCTAssertEqual(
            tracker.resolve(predicted, id: 8)[Definitions.NOTIFICATION_DISPLAYED_LIFECYCLE] as? String,
            NotificationLifeCycle.terminated.rawValue)
        _ = tracker.resolve(predicted, id: 7)
        XCTAssertEqual(
            tracker.resolve(predicted, id: 7)[Definitions.NOTIFICATION_DISPLAYED_LIFECYCLE] as? String,
            NotificationLifeCycle.terminated.rawValue, "a record is used once")
    }

    func testForgetDropsRecords() {
        let tracker = DisplayedLifecycleTracker()
        tracker.recordForegroundDisplay(id: 7, date: "d")
        tracker.recordForegroundDisplay(id: 8, date: "d")
        tracker.forget(id: 7)
        XCTAssertEqual(
            tracker.resolve(predicted, id: 7)[Definitions.NOTIFICATION_DISPLAYED_LIFECYCLE] as? String,
            NotificationLifeCycle.terminated.rawValue)
        tracker.forgetAll()
        XCTAssertEqual(
            tracker.resolve(predicted, id: 8)[Definitions.NOTIFICATION_DISPLAYED_LIFECYCLE] as? String,
            NotificationLifeCycle.terminated.rawValue)
    }

    func testNilIdLeavesContentUntouched() {
        let tracker = DisplayedLifecycleTracker()
        tracker.recordForegroundDisplay(id: 7, date: "d")
        XCTAssertEqual(
            tracker.resolve(predicted, id: nil)[Definitions.NOTIFICATION_DISPLAYED_LIFECYCLE] as? String,
            NotificationLifeCycle.terminated.rawValue)
    }
}
