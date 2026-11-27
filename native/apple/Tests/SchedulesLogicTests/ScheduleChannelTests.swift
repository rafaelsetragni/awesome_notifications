import XCTest
import UserNotifications
@testable import IosAwnCore
@testable import SchedulesLogic

/// The schedule-only channel methods against a fake notification center: on
/// Apple a schedule is a pending request, so cancelling one never touches what
/// is already delivered.
final class ScheduleChannelTests: XCTestCase {

    private let handler = ScheduleMethodHandler()
    private var fake: FakeNotificationCenter { .shared }

    override func setUp() {
        super.setUp()
        FakeNotificationCenter.install()
        CriticalAlertUtils.setCache(false)
    }

    override func tearDown() {
        CriticalAlertUtils.clearCache()
        super.tearDown()
    }

    private func call(_ method: String, _ arguments: Any? = nil) -> (handled: Bool, value: Any?) {
        let done = XCTestExpectation(description: method)
        var value: Any?
        let handled = handler.handle(method: method, arguments: arguments) {
            value = $0
            done.fulfill()
        }
        if handled { wait(for: [done], timeout: 5) }
        return (handled, value)
    }

    private func detail(_ value: Any?) -> String? {
        (value as? AwesomeNotificationsException)?.detailedCode
    }

    private func seedPending() {
        fake.pending = [
            EngineFixtures.request(EngineFixtures.model(id: 1, channelKey: "news",
                content: [Definitions.NOTIFICATION_GROUP_KEY: "sports"])),
            EngineFixtures.request(EngineFixtures.model(id: 2, channelKey: "chat")),
            EngineFixtures.request(EngineFixtures.model(id: 3, channelKey: "news")),
            EngineFixtures.foreign(id: "not-ours").request
        ]
    }

    func testCancelScheduleRemovesOnlyThePendingRequest() {
        XCTAssertEqual(call("cancelSchedule", 7).value as? Bool, true)
        XCTAssertEqual(fake.read { $0.removedPending }, [["7"]])
        XCTAssertTrue(fake.read { $0.removedDelivered }.isEmpty)

        XCTAssertEqual(detail(call("cancelSchedule", -1).value), "arguments.invalid.dismiss.id")
        XCTAssertEqual(detail(call("cancelSchedule", "7").value), "arguments.invalid.dismiss.id")
        XCTAssertEqual(fake.read { $0.removedPending }.count, 1)
    }

    func testCancelSchedulesByChannelKey() {
        seedPending()
        XCTAssertEqual(call("cancelSchedulesByChannelKey", "news").value as? Bool, true)
        XCTAssertEqual(fake.read { $0.removedPending }, [["1", "3"]])

        // Nothing matches: nothing removed, still answered.
        XCTAssertEqual(call("cancelSchedulesByChannelKey", "nobody").value as? Bool, true)
        XCTAssertEqual(fake.read { $0.removedPending }.count, 1)

        XCTAssertEqual(detail(call("cancelSchedulesByChannelKey", 3).value),
                       "arguments.invalid.dismiss.channelKey")
        XCTAssertTrue(fake.read { $0.removedDelivered }.isEmpty)
    }

    func testCancelSchedulesByGroupKey() {
        seedPending()
        XCTAssertEqual(call("cancelSchedulesByGroupKey", "sports").value as? Bool, true)
        XCTAssertEqual(fake.read { $0.removedPending }, [["1"]])
        XCTAssertEqual(detail(call("cancelSchedulesByGroupKey", nil).value),
                       "arguments.invalid.dismiss.groupKey")
    }

    func testCancelAllSchedules() {
        XCTAssertEqual(call("cancelAllSchedules").value as? Bool, true)
        XCTAssertEqual(fake.read { $0.removedAllPending }, 1)
        XCTAssertEqual(fake.read { $0.removedAllDelivered }, 0)
    }

    func testListAllSchedulesAnswersTheStoredModels() {
        seedPending()
        let answer = call("listAllSchedules")
        XCTAssertTrue(answer.handled)
        let models = answer.value as? [[String: Any]]
        XCTAssertEqual(models?.count, 3, "the foreign request is not listed")
        let ids = models?.compactMap {
            ($0[Definitions.NOTIFICATION_CONTENT] as? [String: Any])?[Definitions.NOTIFICATION_ID] as? Int
        }
        XCTAssertEqual(ids, [1, 2, 3])

        fake.pending = []
        XCTAssertEqual((call("listAllSchedules").value as? [[String: Any]])?.count, 0)
    }

    func testUnknownMethodsAreNotHandled() {
        XCTAssertFalse(call("listScheduledNothing").handled)
    }
}

/// Date and time-zone parsing paths of the schedule models.
final class ScheduleParsingTests: XCTestCase {

    func testTheCreatedDateIsReadWithItsZone() {
        let zoned = ScheduleModels.from(scheduleMap: [
            "hour": 9, "createdDate": "2026-07-05 08:30:00 America/Sao_Paulo"])
        XCTAssertEqual(zoned?.createdDate?.description, "2026-07-05 08:30:00 America/Sao_Paulo")

        // Without a zone: UTC.
        let utc = ScheduleModels.from(scheduleMap: ["hour": 9, "createdDate": "2026-07-05 08:30:00"])
        XCTAssertEqual(utc?.createdDate?.timeZone, ScheduleDateTime.utcTimeZone)
        XCTAssertTrue(utc?.createdDate?.description.hasPrefix("2026-07-05 08:30:00") ?? false)

        // An unknown zone: the device's.
        let unknown = ScheduleModels.from(scheduleMap: [
            "interval": 60, "createdDate": "2026-07-05 08:30:00 Nowhere/Land"])
        XCTAssertEqual(unknown?.createdDate?.timeZone.identifier, TimeZone.current.identifier)

        // Not a date.
        XCTAssertNil(ScheduleModels.from(scheduleMap: ["hour": 9, "createdDate": "yesterday"])?.createdDate)
    }

    func testOffsetTimeZones() {
        // 0.12 accepted an offset only when the resolved identifier contains
        // it: Apple names "GMT-03:00" as "GMT-0300", so a minutes offset is
        // rejected while a bare hour offset passes (0.12 quirk).
        XCTAssertNil(ScheduleTimeZones.validTimeZone(fromTimeZoneId: "-03:00"))
        XCTAssertNil(ScheduleTimeZones.validTimeZone(fromTimeZoneId: "+05:30"))
        XCTAssertEqual(ScheduleTimeZones.validTimeZone(fromTimeZoneId: "+05")?.secondsFromGMT(), 5 * 3600)
        XCTAssertEqual(ScheduleTimeZones.validTimeZone(fromTimeZoneId: "-03")?.secondsFromGMT(), -3 * 3600)
        XCTAssertEqual(ScheduleTimeZones.validTimeZone(fromTimeZoneId: "05")?.secondsFromGMT(), 5 * 3600)
        XCTAssertEqual(ScheduleTimeZones.validTimeZone(fromTimeZoneId: "America/Sao_Paulo")?.identifier,
                       "America/Sao_Paulo")
        XCTAssertNil(ScheduleTimeZones.validTimeZone(fromTimeZoneId: "UTC"), "resolved as GMT")
        XCTAssertNil(ScheduleTimeZones.validTimeZone(fromTimeZoneId: nil))
    }

    func testAnInvalidFixedDateFallsBackToNow() {
        // An unreadable fixed date is "now" (UTC): the next date is still answered.
        let answer = ScheduleMethodHandler.nextDate([
            "fixedDate": "not a date",
            "schedule": ["interval": 60, "repeats": false, "timeZone": "America/Sao_Paulo"]
        ])
        XCTAssertNotNil(answer)
        XCTAssertTrue(answer?.hasSuffix("America/Sao_Paulo") ?? false, answer ?? "nil")
    }

    func testOnlyTimeTriggersHaveANextDate() {
        XCTAssertNil(ScheduleBuilder.nextTriggerDate(FakeNotificationCenter.pushTrigger()))
        XCTAssertNotNil(ScheduleBuilder.nextTriggerDate(
            UNTimeIntervalNotificationTrigger(timeInterval: 60, repeats: false)))
    }
}
