import XCTest
import UserNotifications
import IosAwnCore
@testable import SchedulesLogic

/// The scheduling decorator's create-time behavior, which must match 0.12 on
/// Apple: invalid schedules throw, schedules without a next date are not
/// created, and the stored schedule carries the resolved (device) time zone.
final class ScheduleBuilderTests: XCTestCase {

    private var savedTimeZone: TimeZone!

    override func setUp() {
        savedTimeZone = NSTimeZone.default
        NSTimeZone.default = TimeZone(identifier: "America/Sao_Paulo")!
    }

    override func tearDown() {
        NSTimeZone.default = savedTimeZone
    }

    private func notification(_ schedule: [String: Any]?) -> [String: Any] {
        var model: [String: Any] = ["content": ["id": 1, "channelKey": "basic", "title": "Hi"]]
        if let schedule = schedule { model["schedule"] = schedule }
        return model
    }

    /// Runs extract + prepare like `ScheduleBuilder.build`.
    private func prepare(_ schedule: [String: Any]) throws -> (UNNotificationTrigger, [String: Any])? {
        let model = notification(schedule)
        let extracted = try XCTUnwrap(ScheduleModels.extract(fromNotification: model))
        return try ScheduleBuilder.prepare(model, extracted)
    }

    private func assertInvalid(_ schedule: [String: Any], file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertThrowsError(try prepare(schedule), file: file, line: line) { error in
            XCTAssertEqual((error as? AwesomeNotificationsException)?.code, "INVALID_ARGUMENTS",
                           file: file, line: line)
        }
    }

    func testNoScheduleIsNotScheduled() throws {
        XCTAssertNil(try ScheduleModels.extract(fromNotification: notification(nil)))
        XCTAssertNil(try ScheduleModels.extract(fromNotification: notification([:])))
    }

    func testIntervalTrigger() throws {
        let (trigger, _) = try XCTUnwrap(prepare(["interval": 3600, "repeats": false]))
        let interval = try XCTUnwrap(trigger as? UNTimeIntervalNotificationTrigger)
        XCTAssertEqual(interval.timeInterval, 3600)
        XCTAssertFalse(interval.repeats)
    }

    func testInvalidSchedulesThrow() {
        assertInvalid(["interval": 30, "repeats": true])   // repeating < 60 s
        assertInvalid(["interval": 0, "repeats": false])   // < 5 s
        assertInvalid(["hour": 24, "timeZone": "UTC"])
        assertInvalid(["timeZone": "UTC", "repeats": false])  // no time condition
    }

    func testCrontabSchedulesThrow() {
        XCTAssertThrowsError(try ScheduleModels.extract(
            fromNotification: notification(["crontabExpression": "0 0 * * * ?"])))
    }

    func testCalendarInThePastIsNotCreated() throws {
        XCTAssertNil(try prepare(["year": 2020, "month": 1, "day": 1, "hour": 0]))
    }

    func testStoredScheduleUsesTheDeviceTimeZoneForUtc() throws {
        let (trigger, model) = try XCTUnwrap(prepare([
            "hour": 9, "minute": 15, "second": 0, "timeZone": "UTC", "repeats": true,
            "allowWhileIdle": false
        ]))
        let schedule = try XCTUnwrap(model["schedule"] as? [String: Any])
        XCTAssertEqual(schedule["timeZone"] as? String, "America/Sao_Paulo")
        XCTAssertEqual(schedule["hour"] as? Int, 9)
        XCTAssertEqual(schedule["minute"] as? Int, 15)
        XCTAssertEqual(schedule["second"] as? Int, 0)
        XCTAssertEqual(schedule["repeats"] as? Bool, true)
        XCTAssertNotNil(schedule["createdDate"] as? String)
        XCTAssertNil(schedule["allowWhileIdle"], "0.12 stores only its own schedule fields")
        let calendar = try XCTUnwrap(trigger as? UNCalendarNotificationTrigger)
        XCTAssertEqual(calendar.dateComponents.timeZone?.identifier, "America/Sao_Paulo")
        XCTAssertTrue(calendar.repeats)
    }

    func testWeekdayIsIsoOnTheWireAndAppleInTheTrigger() throws {
        let (trigger, model) = try XCTUnwrap(prepare(["weekday": 1, "hour": 10, "timeZone": "UTC"]))
        let calendar = try XCTUnwrap(trigger as? UNCalendarNotificationTrigger)
        XCTAssertEqual(calendar.dateComponents.weekday, 2, "ISO Monday is Apple's 2")
        XCTAssertEqual((model["schedule"] as? [String: Any])?["weekday"] as? Int, 1)

        let (sunday, _) = try XCTUnwrap(prepare(["weekday": 7, "hour": 10]))
        XCTAssertEqual((sunday as? UNCalendarNotificationTrigger)?.dateComponents.weekday, 1)
    }

    func testBuildThrowsAndReturnsNilLikeThe012Core() throws {
        let builder = ScheduleBuilder(inner: NotificationBuilder())
        XCTAssertThrowsError(try builder.build(model: notification(["interval": 0])))
        XCTAssertNil(try builder.build(model: notification(["year": 2020, "month": 1, "day": 1])))
        let built = try XCTUnwrap(builder.build(model: notification(["interval": 60])))
        XCTAssertTrue(built.trigger is UNTimeIntervalNotificationTrigger)
        let content = built.model["content"] as? [String: Any]
        XCTAssertEqual(content?["createdSource"] as? String, NotificationSource.schedule.rawValue)
        let immediate = try XCTUnwrap(builder.build(model: notification(nil)))
        XCTAssertNil(immediate.trigger)
    }

    func testValidTimeZoneFollows012() {
        XCTAssertNil(ScheduleTimeZones.validTimeZone(fromTimeZoneId: "UTC"),
                     "Apple names UTC \"GMT\", so 0.12 rejected it")
        XCTAssertEqual(ScheduleTimeZones.validTimeZone(fromTimeZoneId: "GMT")?.identifier, "GMT")
        XCTAssertEqual(
            ScheduleTimeZones.validTimeZone(fromTimeZoneId: "America/New_York")?.identifier,
            "America/New_York")
        XCTAssertNil(ScheduleTimeZones.validTimeZone(fromTimeZoneId: "Not/AZone"))
        XCTAssertNil(ScheduleTimeZones.validTimeZone(fromTimeZoneId: nil))
    }
}
