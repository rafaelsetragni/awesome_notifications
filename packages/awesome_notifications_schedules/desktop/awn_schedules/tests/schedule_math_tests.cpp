#include "awn_schedules/schedule_math.h"
#include "awn_test.h"

using namespace awn;
using namespace awn_schedules;

namespace {

/// Fixed offsets: UTC, São Paulo (UTC-3) and a zone that leaves DST (-2h → -3h)
/// at 2026-11-01 05:00 UTC.
int64_t offsetOf(const std::string& zone, TimePoint utc) {
  if (zone == "America/Sao_Paulo") return -3 * 3600;
  if (zone == "Test/Dst") {
    return utc < *DateUtils::parseUtc("2026-11-01 05:00:00") ? -2 * 3600 : -3 * 3600;
  }
  return 0;
}

const TimePoint kFixed = *DateUtils::parseUtc("2026-07-05 08:30:00");  // a Sunday

std::string next(const ValueMap& schedule, TimePoint from = kFixed) {
  auto date = ScheduleMath::nextDate(schedule, from, "UTC", offsetOf);
  return date ? DateUtils::formatUtc(*date) : "none";
}

}  // namespace

TEST(IntervalIsFixedPlusInterval) {
  EXPECT_EQ(next({{"interval", 90}}), std::string("2026-07-05 08:31:30"));
}

TEST(InvalidSchedulesHaveNoNextDate) {
  EXPECT_EQ(next({}), std::string("none"));
  EXPECT_EQ(next({{"interval", 30}, {"repeats", true}}), std::string("none"));
  EXPECT_EQ(next({{"interval", 0}}), std::string("none"));
  EXPECT_EQ(next({{"hour", 24}}), std::string("none"));
}

TEST(CalendarMatchesInTheScheduleTimeZone) {
  ValueMap nineUtc{{"hour", 9}, {"minute", 0}, {"second", 0}, {"timeZone", "UTC"}};
  EXPECT_EQ(next(nineUtc), std::string("2026-07-05 09:00:00"));
  EXPECT_EQ(next(nineUtc, *DateUtils::parseUtc("2026-07-05 09:30:00")),
            std::string("2026-07-06 09:00:00"));

  ValueMap nineSaoPaulo{{"hour", 9}, {"minute", 0}, {"second", 0},
                        {"timeZone", "America/Sao_Paulo"}};
  EXPECT_EQ(next(nineSaoPaulo), std::string("2026-07-05 12:00:00"));
}

TEST(FinerMissingComponentsDefaultToZero) {
  EXPECT_EQ(next({{"hour", 9}}), std::string("2026-07-05 09:00:00"));
  EXPECT_EQ(next({{"day", 10}}), std::string("2026-07-10 00:00:00"));
  // Coarser missing components are free: every hour at :30:00.
  EXPECT_EQ(next({{"minute", 30}}), std::string("2026-07-05 09:30:00"));
  EXPECT_EQ(next({{"second", 15}}), std::string("2026-07-05 08:30:15"));
}

TEST(WeekdayIsMondayBased) {
  EXPECT_EQ(next({{"weekday", 1}, {"hour", 10}}), std::string("2026-07-06 10:00:00"));
  EXPECT_EQ(next({{"weekday", 7}, {"hour", 10}}), std::string("2026-07-05 10:00:00"));
}

TEST(WeekOfYearIsIso) {
  EXPECT_EQ(next({{"weekOfYear", 28}, {"weekday", 3}}), std::string("2026-07-08 00:00:00"));
}

TEST(PastOneShotHasNoNextDate) {
  EXPECT_EQ(next({{"year", 2020}, {"month", 1}, {"day", 1}, {"hour", 0}}), std::string("none"));
  EXPECT_EQ(next({{"year", 2027}, {"month", 2}, {"day", 1}, {"hour", 8}}),
            std::string("2027-02-01 08:00:00"));
}

TEST(LeapDayIsFoundYearsAhead) {
  EXPECT_EQ(next({{"month", 2}, {"day", 29}, {"hour", 12}}), std::string("2028-02-29 12:00:00"));
}

TEST(CalendarFollowsDstChanges) {
  ValueMap nine{{"hour", 9}, {"timeZone", "Test/Dst"}};
  EXPECT_EQ(next(nine, *DateUtils::parseUtc("2026-10-31 12:00:00")),
            std::string("2026-11-01 12:00:00"));  // already -3h at 09:00 local
  EXPECT_EQ(next(nine, *DateUtils::parseUtc("2026-10-30 12:00:00")),
            std::string("2026-10-31 11:00:00"));  // still -2h
}

TEST(NextDatesListsRepeatsUpToLimitAndHorizon) {
  ValueMap daily{{"hour", 9}, {"repeats", true}};
  auto dates = ScheduleMath::nextDates(daily, kFixed, 3, kFixed + std::chrono::hours(24 * 30),
                                       "UTC", offsetOf);
  EXPECT_EQ(dates.size(), size_t(3));
  EXPECT_EQ(DateUtils::formatUtc(dates[2]), std::string("2026-07-07 09:00:00"));

  auto capped = ScheduleMath::nextDates(daily, kFixed, 10, kFixed + std::chrono::hours(30),
                                        "UTC", offsetOf);
  EXPECT_EQ(capped.size(), size_t(2));

  auto once = ScheduleMath::nextDates({{"interval", 60}}, kFixed, 10,
                                      kFixed + std::chrono::hours(1), "UTC", offsetOf);
  EXPECT_EQ(once.size(), size_t(1));
}

TEST(DefaultZoneAppliesWithoutTimeZone) {
  auto date = ScheduleMath::nextDate({{"hour", 9}}, kFixed, "America/Sao_Paulo", offsetOf);
  EXPECT_EQ(DateUtils::formatUtc(*date), std::string("2026-07-05 12:00:00"));
}

int main() { return awn_test::runAll(); }
