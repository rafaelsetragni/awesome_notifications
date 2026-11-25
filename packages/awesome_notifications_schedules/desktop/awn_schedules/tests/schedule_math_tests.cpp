#include "awn/exception.h"
#include "awn_schedules/schedule_math.h"
#include "awn_test.h"

using namespace awn;
using namespace awn_schedules;

namespace {

/// Fixed offsets: UTC, São Paulo (UTC-3), New York in summer (UTC-4) and a
/// zone that leaves DST (-2h → -3h) at 2026-11-01 05:00 UTC.
int64_t offsetOf(const std::string& zone, TimePoint utc) {
  if (zone == "America/Sao_Paulo") return -3 * 3600;
  if (zone == "America/New_York") return -4 * 3600;
  if (zone == "Test/Dst") {
    return utc < *DateUtils::parseUtc("2026-11-01 05:00:00") ? -2 * 3600 : -3 * 3600;
  }
  return 0;
}

Zones zones(const std::string& local = "UTC") {
  return Zones{local, offsetOf, [](const std::string& zone) { return zone != "Nowhere/City"; }};
}

const TimePoint kFixed = *DateUtils::parseUtc("2026-07-05 08:30:00");  // a Sunday

ValueMap utc(ValueMap schedule) {
  if (!schedule.count("timeZone")) schedule["timeZone"] = "UTC";
  return schedule;
}

/// The next date as getNextDate answers it (wall clock + zone), or "null".
std::string next(const ValueMap& schedule, TimePoint from = kFixed) {
  auto date = ScheduleMath::nextDate(schedule, from, zones());
  return date ? ScheduleMath::describe(schedule, *date, zones()) : "null";
}

std::string validation(const ValueMap& schedule) {
  try {
    ScheduleMath::validate(schedule, zones());
    return "ok";
  } catch (const AwesomeNotificationsException& e) {
    return e.code() + ": " + e.what() + " (" + e.details() + ")";
  }
}

}  // namespace

// MARK: - Type, by the keys present (0.12 getScheduleModelFromMap)

TEST(KindIsDecidedByTheKeysPresent) {
  EXPECT_TRUE(ScheduleMath::kindOf({}) == ScheduleMath::Kind::None);
  EXPECT_TRUE(ScheduleMath::kindOf({{"timeZone", "UTC"}}) == ScheduleMath::Kind::None);
  EXPECT_TRUE(ScheduleMath::kindOf({{"interval", 60}}) == ScheduleMath::Kind::Interval);
  // A Dart calendar sends every component key, null ones too.
  EXPECT_TRUE(ScheduleMath::kindOf({{"hour", nullptr}}) == ScheduleMath::Kind::Calendar);
  EXPECT_TRUE(ScheduleMath::kindOf({{"crontabExpression", "* * * * * ? *"}}) ==
              ScheduleMath::Kind::Crontab);
}

// MARK: - Validation (0.12 rules and messages)

TEST(CalendarValidation) {
  EXPECT_EQ(validation({{"hour", nullptr}, {"minute", nullptr}}),
            std::string("INVALID_ARGUMENTS: At least one time condition is required "
                        "(arguments.invalid.notificationCalendar)"));
  EXPECT_EQ(validation({{"hour", 24}}),
            std::string("INVALID_ARGUMENTS: The time conditions are invalid "
                        "(arguments.invalid.notificationCalendar)"));
  EXPECT_EQ(validation({{"weekday", 8}}),
            std::string("INVALID_ARGUMENTS: The time conditions are invalid "
                        "(arguments.invalid.notificationCalendar)"));
  EXPECT_EQ(validation({{"hour", 9}}), std::string("ok"));
}

TEST(IntervalValidation) {
  EXPECT_EQ(validation({{"interval", 0}}),
            std::string("INVALID_ARGUMENTS: Interval is required and must be greater than 5 "
                        "(arguments.invalid.notificationInterval.interval)"));
  EXPECT_EQ(validation({{"interval", 30}, {"repeats", true}}),
            std::string("INVALID_ARGUMENTS: time interval must be at least 60 if repeating "
                        "(arguments.invalid.notificationInterval.interval)"));
  EXPECT_EQ(validation({{"interval", 60}, {"repeats", true}}), std::string("ok"));
  EXPECT_EQ(validation({{"interval", 5}}), std::string("ok"));
}

// MARK: - Next date (the compat suite's 0.12 Android table)

TEST(IntervalIsTheReferencePlusTheInterval) {
  EXPECT_EQ(next(utc({{"interval", 90}})), std::string("2026-07-05 08:31:30 UTC"));
  // Answered in UTC whatever the schedule's zone (0.12 kept the reference's).
  EXPECT_EQ(next({{"interval", 90}, {"timeZone", "America/Sao_Paulo"}}),
            std::string("2026-07-05 08:31:30 UTC"));
}

TEST(CalendarAnswersTheWallClockOfItsZone) {
  EXPECT_EQ(next(utc({{"hour", 9}, {"minute", 0}, {"second", 0}})),
            std::string("2026-07-05 09:00:00 UTC"));
  EXPECT_EQ(next({{"hour", 9}, {"minute", 0}, {"second", 0}, {"timeZone", "America/Sao_Paulo"}}),
            std::string("2026-07-05 09:00:00 America/Sao_Paulo"));
  EXPECT_EQ(next({{"hour", 9}, {"minute", 0}, {"second", 0}, {"timeZone", "America/New_York"}}),
            std::string("2026-07-05 09:00:00 America/New_York"));
}

TEST(FreeComponentsAreCronWildcards) {
  EXPECT_EQ(next(utc({{"hour", 9}})), std::string("2026-07-05 09:00:00 UTC"));
  // A free second still matches one second after the reference.
  EXPECT_EQ(next(utc({{"minute", 30}})), std::string("2026-07-05 08:30:01 UTC"));
  EXPECT_EQ(next(utc({{"second", 15}})), std::string("2026-07-05 08:30:15 UTC"));
  EXPECT_EQ(next(utc({{"day", 10}})), std::string("2026-07-10 00:00:00 UTC"));
  EXPECT_EQ(next(utc({{"month", 9}})), std::string("2026-09-01 00:00:00 UTC"));
  EXPECT_EQ(next(utc({{"hour", 9}, {"minute", 15}})), std::string("2026-07-05 09:15:00 UTC"));
}

TEST(NextDateIsStrictlyAfterTheReference) {
  EXPECT_EQ(next(utc({{"hour", 8}, {"minute", 30}, {"second", 0}})),
            std::string("2026-07-06 08:30:00 UTC"));
}

TEST(WeekdayIsIsoAndWinsOverTheDay) {
  EXPECT_EQ(next(utc({{"weekday", 1}, {"hour", 10}})), std::string("2026-07-06 10:00:00 UTC"));
  EXPECT_EQ(next(utc({{"weekday", 7}, {"hour", 10}})), std::string("2026-07-05 10:00:00 UTC"));
  // weekOfYear is ignored, like 0.12 (only the weekday counts).
  EXPECT_EQ(next(utc({{"weekOfYear", 28}, {"weekday", 3}})),
            std::string("2026-07-08 00:00:00 UTC"));
  // The day of the month is "?" when a weekday is given.
  EXPECT_EQ(next(utc({{"day", 20}, {"weekday", 1}, {"hour", 10}})),
            std::string("2026-07-06 10:00:00 UTC"));
}

TEST(PastAndFutureDates) {
  EXPECT_EQ(next(utc({{"year", 2020}, {"month", 1}, {"day", 1}, {"hour", 0}})),
            std::string("null"));
  EXPECT_EQ(next(utc({{"year", 2027}, {"month", 2}, {"day", 1}, {"hour", 8}})),
            std::string("2027-02-01 08:00:00 UTC"));
  EXPECT_EQ(next(utc({{"month", 2}, {"day", 29}, {"hour", 12}})),
            std::string("2028-02-29 12:00:00 UTC"));
}

TEST(OutOfRangeComponentsNeverMatch) {
  EXPECT_EQ(next(utc({{"hour", 24}})), std::string("null"));
}

TEST(UnknownZoneFailsLike012) {
  try {
    ScheduleMath::nextDate({{"hour", 9}, {"timeZone", "Nowhere/City"}}, kFixed, zones());
    EXPECT_TRUE(false);
  } catch (const AwesomeNotificationsException& e) {
    EXPECT_EQ(e.details(), std::string("arguments.invalid.notificationCalendar.timeZone"));
  }
}

TEST(FixedOffsetZones) {
  EXPECT_EQ(next({{"hour", 9}, {"minute", 0}, {"second", 0}, {"timeZone", "-03:00"}}),
            std::string("2026-07-05 09:00:00 GMT-03:00"));
}

TEST(CalendarFollowsDstChanges) {
  ValueMap nine{{"hour", 9}, {"minute", 0}, {"second", 0}, {"timeZone", "Test/Dst"}};
  auto a = ScheduleMath::nextDate(nine, *DateUtils::parseUtc("2026-10-31 12:00:00"), zones());
  EXPECT_EQ(DateUtils::formatUtc(*a), std::string("2026-11-01 12:00:00"));  // -3h by then
  auto b = ScheduleMath::nextDate(nine, *DateUtils::parseUtc("2026-10-30 12:00:00"), zones());
  EXPECT_EQ(DateUtils::formatUtc(*b), std::string("2026-10-31 11:00:00"));  // still -2h
}

TEST(DefaultZoneAppliesWithoutTimeZone) {
  auto date = ScheduleMath::nextDate({{"hour", 9}, {"minute", 0}, {"second", 0}}, kFixed,
                                     zones("America/Sao_Paulo"));
  EXPECT_EQ(DateUtils::formatUtc(*date), std::string("2026-07-05 12:00:00"));
}

TEST(NextDatesListsRepeatsUpToLimitAndHorizon) {
  ValueMap daily = utc({{"hour", 9}, {"minute", 0}, {"second", 0}, {"repeats", true}});
  auto dates = ScheduleMath::nextDates(daily, kFixed, 3, kFixed + std::chrono::hours(24 * 30),
                                       zones());
  EXPECT_EQ(dates.size(), size_t(3));
  EXPECT_EQ(DateUtils::formatUtc(dates[2]), std::string("2026-07-07 09:00:00"));

  auto capped = ScheduleMath::nextDates(daily, kFixed, 10, kFixed + std::chrono::hours(30),
                                        zones());
  EXPECT_EQ(capped.size(), size_t(2));

  auto once = ScheduleMath::nextDates(utc({{"interval", 60}}), kFixed, 10,
                                      kFixed + std::chrono::hours(1), zones());
  EXPECT_EQ(once.size(), size_t(1));
}

TEST(NormalizedIsThe012StoredShape) {
  ValueMap calendar{{"hour", 9}, {"minute", nullptr}, {"weekday", 1}, {"repeats", true}};
  ValueMap stored = ScheduleMath::normalized(calendar, zones("America/Sao_Paulo"));
  EXPECT_EQ(getString(stored, "timeZone").value_or(""), std::string("America/Sao_Paulo"));
  EXPECT_EQ(getInt(stored, "hour").value_or(-1), 9);
  EXPECT_EQ(getInt(stored, "weekday").value_or(-1), 1);
  EXPECT_FALSE(stored.count("minute") > 0);
  EXPECT_EQ(getBool(stored, "repeats").value_or(false), true);
  EXPECT_EQ(getBool(stored, "allowWhileIdle").value_or(true), false);
  EXPECT_EQ(getInt(stored, "delayTolerance").value_or(-1), 0);
}

int main() { return awn_test::runAll(); }
