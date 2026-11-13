import XCTest
@testable import SchedulesLogic

/// getNextDate math (same interpretation as the delivery triggers) and the
/// handler's method routing. The UNUserNotificationCenter-backed methods are
/// exercised on device; here we only check they are claimed.
final class ScheduleMethodHandlerTests: XCTestCase {

    private let fixed = ScheduleDates.parse("2026-07-05 08:30:00")!  // UTC

    func testIntervalNextDateIsFixedPlusInterval() {
        let next = ScheduleDates.nextDate(of: ["interval": 90], after: fixed)
        XCTAssertEqual(next.map(ScheduleDates.format), "2026-07-05 08:31:30")
    }

    func testCalendarNextDateInTheScheduleTimeZone() {
        let schedule: [String: Any] = ["hour": 9, "minute": 0, "second": 0, "timeZone": "UTC"]
        XCTAssertEqual(
            ScheduleDates.nextDate(of: schedule, after: fixed).map(ScheduleDates.format),
            "2026-07-05 09:00:00")

        let later = ScheduleDates.parse("2026-07-05 09:30:00")!
        XCTAssertEqual(
            ScheduleDates.nextDate(of: schedule, after: later).map(ScheduleDates.format),
            "2026-07-06 09:00:00", "a passed time rolls over to the next day")
    }

    func testCalendarNextDateHonoursANonUtcTimeZone() {
        // 09:00 in São Paulo (UTC-3) is 12:00 UTC.
        let schedule: [String: Any] = [
            "hour": 9, "minute": 0, "second": 0, "timeZone": "America/Sao_Paulo"
        ]
        XCTAssertEqual(
            ScheduleDates.nextDate(of: schedule, after: fixed).map(ScheduleDates.format),
            "2026-07-05 12:00:00")
    }

    func testPastOneShotCalendarHasNoNextDate() {
        let schedule: [String: Any] = [
            "year": 2020, "month": 1, "day": 1, "hour": 0, "minute": 0, "second": 0,
            "timeZone": "UTC"
        ]
        XCTAssertNil(ScheduleDates.nextDate(of: schedule, after: fixed))
    }

    func testInvalidSchedulesHaveNoNextDate() {
        XCTAssertNil(ScheduleDates.nextDate(of: [:], after: fixed))
        XCTAssertNil(ScheduleDates.nextDate(of: ["interval": 30, "repeats": true], after: fixed))
    }

    func testGetNextDateMethodReturnsUtcString() {
        var value: Any?
        let handled = ScheduleMethodHandler().handle(
            method: "getNextDate",
            arguments: [
                "fixedDate": "2026-07-05 08:30:00",
                "schedule": ["interval": 60]
            ]
        ) { value = $0 }
        XCTAssertTrue(handled)
        XCTAssertEqual(value as? String, "2026-07-05 08:31:00")
    }

    func testUnknownMethodIsNotClaimed() {
        XCTAssertFalse(ScheduleMethodHandler().handle(method: "createNewNotification", arguments: nil) { _ in })
    }
}
