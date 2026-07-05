import XCTest
import UserNotifications
@testable import SchedulesLogic

/// The scheduling decorator's pure trigger-building logic (interval vs calendar,
/// and the repeating-interval minimum).
final class ScheduleBuilderTriggerTests: XCTestCase {

    func testIntervalTrigger() {
        let trigger = ScheduleBuilder.trigger(
            for: [ScheduleKeys.schedule: [ScheduleKeys.interval: 60]])
        let interval = trigger as? UNTimeIntervalNotificationTrigger
        XCTAssertNotNil(interval)
        XCTAssertEqual(interval?.timeInterval, 60)
        XCTAssertEqual(interval?.repeats, false)
    }

    func testRepeatingIntervalUnder60IsRejected() {
        let trigger = ScheduleBuilder.trigger(
            for: [ScheduleKeys.schedule: [
                ScheduleKeys.interval: 30, ScheduleKeys.repeats: true]])
        XCTAssertNil(trigger)
    }

    func testCalendarTrigger() {
        let trigger = ScheduleBuilder.trigger(
            for: [ScheduleKeys.schedule: [ScheduleKeys.hour: 8, ScheduleKeys.minute: 0]])
        XCTAssertTrue(trigger is UNCalendarNotificationTrigger)
    }

    func testNoScheduleReturnsNil() {
        XCTAssertNil(ScheduleBuilder.trigger(for: [:]))
    }

    func testEmptyScheduleReturnsNil() {
        XCTAssertNil(
            ScheduleBuilder.trigger(for: [ScheduleKeys.schedule: [:] as [String: Any]]))
    }
}
