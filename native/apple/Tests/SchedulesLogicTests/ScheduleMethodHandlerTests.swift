import XCTest
import IosAwnCore
@testable import SchedulesLogic

/// getNextDate exactly as 0.12 answered it on Apple, from Sunday
/// 2026-07-05 08:30:00 UTC with the device in São Paulo (UTC-3). The answer is
/// the wall clock of the schedule's time zone (the device's for "UTC") plus
/// that zone's identifier. These are the compat suite's iOS references.
final class ScheduleMethodHandlerTests: XCTestCase {

    private var savedTimeZone: TimeZone!

    override func setUp() {
        savedTimeZone = NSTimeZone.default
        NSTimeZone.default = TimeZone(identifier: "America/Sao_Paulo")!
    }

    override func tearDown() {
        NSTimeZone.default = savedTimeZone
    }

    private func next(_ schedule: [String: Any]) -> String? {
        var schedule = schedule
        schedule["repeats"] = schedule["repeats"] ?? false
        return ScheduleMethodHandler.nextDate([
            "fixedDate": "2026-07-05 08:30:00",
            "schedule": schedule
        ])
    }

    func testIntervalIsAnsweredInTheDeviceZone() {
        XCTAssertEqual(next(["interval": 90, "timeZone": "UTC"]),
                       "2026-07-05 05:31:30 America/Sao_Paulo")
        XCTAssertEqual(next(["interval": 90, "timeZone": "UTC", "repeats": true]),
                       "2026-07-05 05:31:30 America/Sao_Paulo")
        XCTAssertEqual(next(["interval": 90, "timeZone": "America/Sao_Paulo"]),
                       "2026-07-05 05:31:30 America/Sao_Paulo")
    }

    func testCalendarUtcIsComputedInTheDeviceZone() {
        XCTAssertEqual(next(["hour": 9, "minute": 0, "second": 0, "timeZone": "UTC"]),
                       "2026-07-05 09:00:00 America/Sao_Paulo")
        XCTAssertEqual(next(["minute": 30, "timeZone": "UTC"]),
                       "2026-07-05 06:30:00 America/Sao_Paulo")
        XCTAssertEqual(next(["second": 15, "timeZone": "UTC"]),
                       "2026-07-05 05:30:15 America/Sao_Paulo")
        XCTAssertEqual(next(["hour": 8, "minute": 30, "second": 0, "timeZone": "UTC"]),
                       "2026-07-05 08:30:00 America/Sao_Paulo")
    }

    func testCalendarInAValidZoneAnswersThatZonesWallClock() {
        XCTAssertEqual(
            next(["hour": 9, "minute": 0, "second": 0, "timeZone": "America/New_York"]),
            "2026-07-05 09:00:00 America/New_York")
    }

    func testIsoWeekdays() {
        XCTAssertEqual(next(["weekday": 1, "hour": 10, "timeZone": "UTC"]),
                       "2026-07-06 10:00:00 America/Sao_Paulo")
        XCTAssertEqual(next(["weekday": 7, "hour": 10, "timeZone": "UTC"]),
                       "2026-07-05 10:00:00 America/Sao_Paulo")
        XCTAssertEqual(next(["weekOfYear": 28, "weekday": 3, "timeZone": "UTC"]),
                       "2026-07-08 00:00:00 America/Sao_Paulo")
    }

    func testFoundationEdgeCases() {
        XCTAssertEqual(next(["month": 2, "day": 29, "hour": 12, "timeZone": "UTC"]),
                       "2027-03-01 00:00:00 America/Sao_Paulo")
        XCTAssertNil(next(["year": 2020, "month": 1, "day": 1, "hour": 0, "timeZone": "UTC"]))
    }

    func testMissingArgumentsAnswerNil() {
        XCTAssertNil(ScheduleMethodHandler.nextDate(["schedule": ["interval": 60]]))
        XCTAssertNil(ScheduleMethodHandler.nextDate(["fixedDate": "2026-07-05 08:30:00"]))
        XCTAssertNil(ScheduleMethodHandler.nextDate([
            "fixedDate": "2026-07-05 08:30:00", "schedule": [String: Any]()]))
    }

    func testGetNextDateMethod() {
        var value: Any?
        let handled = ScheduleMethodHandler().handle(
            method: "getNextDate",
            arguments: [
                "fixedDate": "2026-07-05 08:30:00",
                "schedule": ["interval": 60, "timeZone": "America/New_York", "repeats": false]
            ]
        ) { value = $0 }
        XCTAssertTrue(handled)
        XCTAssertEqual(value as? String, "2026-07-05 04:31:00 America/New_York")
    }

    func testCancelScheduleRejectsAnInvalidId() {
        var value: Any?
        XCTAssertTrue(ScheduleMethodHandler().handle(method: "cancelSchedule", arguments: -1) {
            value = $0
        })
        XCTAssertEqual((value as? AwesomeNotificationsException)?.message, "Invalid id value")
    }

    func testUnknownMethodIsNotClaimed() {
        XCTAssertFalse(ScheduleMethodHandler().handle(method: "createNewNotification", arguments: nil) { _ in })
    }
}
