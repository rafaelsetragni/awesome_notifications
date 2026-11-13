#include "awn_schedules/schedule_math.h"

#include <array>

namespace awn_schedules {

using awn::DateUtils;
using awn::TimePoint;
using awn::ValueMap;

namespace {

constexpr int64_t kDay = 86400;
/// How far ahead a calendar search looks (8 years + slack covers Feb 29).
constexpr int64_t kSearchDays = 366 * 9;

struct Component {
  const char* key;
  int min;
  int max;
};

// Validation ranges of the calendar components.
constexpr std::array<Component, 9> kComponents{{
    {keys::YEAR, 1, 9999},
    {keys::MONTH, 1, 12},
    {keys::DAY, 1, 31},
    {keys::HOUR, 0, 23},
    {keys::MINUTE, 0, 59},
    {keys::SECOND, 0, 59},
    {keys::WEEKDAY, 1, 7},
    {keys::WEEK_OF_MONTH, 1, 6},
    {keys::WEEK_OF_YEAR, 1, 53},
}};

std::optional<int> component(const ValueMap& schedule, const char* key) {
  auto value = awn::getInt(schedule, key);
  if (!value) return std::nullopt;
  return static_cast<int>(*value);
}

/// Dart weekday of a day count since 1970-01-01 (a Thursday): 1 = Monday.
int weekdayOf(int64_t days) {
  int64_t mod = ((days % 7) + 7) % 7;  // 0 = Thursday
  return static_cast<int>((mod + 3) % 7) + 1;
}

int dayOfYear(int64_t days, int64_t year) {
  return static_cast<int>(days - DateUtils::daysFromCivil(year, 1, 1)) + 1;
}

/// ISO 8601 week number.
int isoWeekOfYear(int64_t days) {
  int64_t thursday = days + (4 - weekdayOf(days));
  int64_t y;
  unsigned m, d;
  DateUtils::civilFromDays(thursday, y, m, d);
  return (dayOfYear(thursday, y) - 1) / 7 + 1;
}

/// Week of the month, weeks starting on Monday (the 1st is in week 1).
int weekOfMonth(int64_t days, unsigned dayOfMonth) {
  int firstWeekday = weekdayOf(days - (dayOfMonth - 1));
  return static_cast<int>((dayOfMonth - 1 + static_cast<unsigned>(firstWeekday - 1)) / 7) + 1;
}

std::string zoneOf(const ValueMap& schedule, const std::string& defaultZone) {
  auto zone = awn::getString(schedule, keys::TIME_ZONE);
  return zone && !zone->empty() ? *zone : defaultZone;
}

std::optional<TimePoint> nextCalendarDate(const ValueMap& schedule, TimePoint fixed,
                                          const std::string& zone,
                                          const OffsetProvider& offsets) {
  for (const auto& c : kComponents) {
    auto value = component(schedule, c.key);
    if (value && (*value < c.min || *value > c.max)) return std::nullopt;
  }
  // era 0 (BC) can never match a future date.
  if (auto era = component(schedule, keys::ERA); era && *era == 0) return std::nullopt;

  auto year = component(schedule, keys::YEAR);
  auto month = component(schedule, keys::MONTH);
  auto day = component(schedule, keys::DAY);
  auto hour = component(schedule, keys::HOUR);
  auto minute = component(schedule, keys::MINUTE);
  auto second = component(schedule, keys::SECOND);
  auto weekday = component(schedule, keys::WEEKDAY);
  auto weekMonth = component(schedule, keys::WEEK_OF_MONTH);
  auto weekYear = component(schedule, keys::WEEK_OF_YEAR);

  // The finest given component; finer ones default to 0, coarser are free.
  int finest = 0;
  if (month) finest = 1;
  if (day || weekday || weekMonth || weekYear) finest = 2;
  if (hour) finest = 3;
  if (minute) finest = 4;
  if (second) finest = 5;

  auto range = [&](const std::optional<int>& given, int level, int max) {
    std::vector<int> values;
    if (given) {
      values.push_back(*given);
    } else if (finest < level) {
      values.push_back(0);
    } else {
      for (int v = 0; v <= max; ++v) values.push_back(v);
    }
    return values;
  };
  const auto hours = range(hour, 3, 23);
  const auto minutes = range(minute, 4, 59);
  const auto seconds = range(second, 5, 59);

  auto toUtc = [&](int64_t localSeconds) {
    TimePoint asUtc{std::chrono::seconds(localSeconds)};
    int64_t guessOffset = offsets(zone, asUtc);
    TimePoint guess{std::chrono::seconds(localSeconds - guessOffset)};
    int64_t realOffset = offsets(zone, guess);
    return realOffset == guessOffset ? guess
                                     : TimePoint{std::chrono::seconds(localSeconds - realOffset)};
  };

  int64_t fixedSeconds = fixed.time_since_epoch().count();
  int64_t localNow = fixedSeconds + offsets(zone, fixed);
  int64_t startDay = localNow >= 0 ? localNow / kDay : (localNow - kDay + 1) / kDay;
  if (year) {
    int64_t yearStart = DateUtils::daysFromCivil(*year, 1, 1);
    if (DateUtils::daysFromCivil(*year + 1, 1, 1) <= startDay) return std::nullopt;
    if (yearStart > startDay) startDay = yearStart;
  }

  for (int64_t days = startDay; days <= startDay + kSearchDays; ++days) {
    int64_t y;
    unsigned m, d;
    DateUtils::civilFromDays(days, y, m, d);
    if (year && y != *year) {
      if (y > *year) return std::nullopt;
      continue;
    }
    if (month && static_cast<int>(m) != *month) continue;
    if (day && static_cast<int>(d) != *day) continue;
    if (weekday && weekdayOf(days) != *weekday) continue;
    if (weekMonth && weekOfMonth(days, d) != *weekMonth) continue;
    if (weekYear && isoWeekOfYear(days) != *weekYear) continue;

    for (int h : hours)
      for (int mi : minutes)
        for (int s : seconds) {
          TimePoint candidate = toUtc(days * kDay + h * 3600 + mi * 60 + s);
          if (candidate > fixed) return candidate;
        }
  }
  return std::nullopt;
}

}  // namespace

bool ScheduleMath::repeats(const ValueMap& schedule) {
  return awn::getBool(schedule, keys::REPEATS).value_or(false);
}

std::optional<int64_t> ScheduleMath::validInterval(const ValueMap& schedule) {
  auto interval = awn::getInt(schedule, keys::INTERVAL);
  if (!interval || *interval <= 0) return std::nullopt;
  if (repeats(schedule) && *interval < 60) return std::nullopt;
  return interval;
}

bool ScheduleMath::isCalendar(const ValueMap& schedule) {
  if (awn::has(schedule, keys::INTERVAL)) return false;
  for (const char* key : {keys::ERA, keys::YEAR, keys::MONTH, keys::DAY, keys::HOUR, keys::MINUTE,
                          keys::SECOND, keys::WEEKDAY, keys::WEEK_OF_MONTH, keys::WEEK_OF_YEAR}) {
    if (awn::has(schedule, key)) return true;
  }
  return false;
}

std::optional<TimePoint> ScheduleMath::nextDate(const ValueMap& schedule, TimePoint fixed,
                                                const std::string& defaultZone,
                                                const OffsetProvider& offsets) {
  if (auto interval = validInterval(schedule))
    return fixed + std::chrono::seconds(*interval);
  if (!isCalendar(schedule)) return std::nullopt;
  return nextCalendarDate(schedule, fixed, zoneOf(schedule, defaultZone), offsets);
}

std::vector<TimePoint> ScheduleMath::nextDates(const ValueMap& schedule, TimePoint fixed,
                                               size_t limit, TimePoint horizon,
                                               const std::string& defaultZone,
                                               const OffsetProvider& offsets) {
  std::vector<TimePoint> dates;
  TimePoint from = fixed;
  while (dates.size() < limit) {
    auto next = nextDate(schedule, from, defaultZone, offsets);
    if (!next || *next > horizon) break;
    dates.push_back(*next);
    if (!repeats(schedule)) break;
    from = *next;
  }
  return dates;
}

}  // namespace awn_schedules
