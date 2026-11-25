#include "awn_schedules/schedule_math.h"

#include <algorithm>
#include <array>
#include <cctype>
#include <cstdio>

#include "awn/definitions.h"
#include "awn/exception.h"

namespace awn_schedules {

using awn::AwesomeNotificationsException;
using awn::DateUtils;
using awn::TimePoint;
using awn::Value;
using awn::ValueMap;
namespace code = awn::exception_code;

namespace {

constexpr int64_t kDay = 86400;
/// How far ahead a calendar search looks (8 years + slack covers Feb 29).
constexpr int64_t kSearchDays = 366 * 9;

constexpr std::array<const char*, 3> kCrontabKeys{
    {keys::CRONTAB_EXPRESSION, keys::PRECISE_SCHEDULES, keys::EXPIRATION_DATE_TIME}};
constexpr std::array<const char*, 11> kCalendarKeys{
    {keys::SECOND, keys::MINUTE, keys::HOUR, keys::DAY, keys::MONTH, keys::YEAR, keys::ERA,
     keys::MILLISECOND, keys::WEEKDAY, keys::WEEK_OF_MONTH, keys::WEEK_OF_YEAR}};

/// A key is present even with a null value (0.12 decided the type by keys).
bool present(const ValueMap& map, const char* key) { return map.find(key) != map.end(); }

/// 0.12 getValueOrDefault for an Int: a number, else absent.
std::optional<int64_t> integer(const ValueMap& map, const char* key) {
  auto it = map.find(key);
  if (it == map.end()) return std::nullopt;
  const Value& value = it->second;
  if (value.isInt()) return value.asInt();
  if (value.isDouble()) return static_cast<int64_t>(*value.asDouble());
  return std::nullopt;
}

AwesomeNotificationsException invalid(const std::string& message, const std::string& detail) {
  return AwesomeNotificationsException(code::INVALID_ARGUMENTS, message,
                                       std::string(code::DETAILED_INVALID_ARGUMENTS) + detail);
}

bool between(const std::optional<int64_t>& value, int64_t min, int64_t max) {
  return !value || (*value >= min && *value <= max);
}

/// A fixed-offset zone as 0.12 accepted it ("+03:00", "-03", "05"), in
/// seconds east of UTC; nullopt for a named zone.
std::optional<int64_t> fixedOffset(const std::string& zone) {
  size_t i = 0;
  int sign = 1;
  if (i < zone.size() && (zone[i] == '+' || zone[i] == '-')) sign = zone[i++] == '-' ? -1 : 1;
  auto twoDigits = [&](size_t at) {
    return at + 2 <= zone.size() && std::isdigit(static_cast<unsigned char>(zone[at])) &&
           std::isdigit(static_cast<unsigned char>(zone[at + 1]));
  };
  if (!twoDigits(i)) return std::nullopt;
  int hours = (zone[i] - '0') * 10 + (zone[i + 1] - '0');
  i += 2;
  int minutes = 0;
  if (i < zone.size()) {
    if (zone[i] != ':' || !twoDigits(i + 1) || i + 3 != zone.size()) return std::nullopt;
    minutes = (zone[i + 1] - '0') * 10 + (zone[i + 2] - '0');
  }
  return sign * (hours * 3600 + minutes * 60);
}

/// Java's id of a fixed-offset zone ("GMT+03:00").
std::string fixedOffsetId(int64_t offset) {
  char buffer[16];
  int64_t total = offset < 0 ? -offset : offset;
  std::snprintf(buffer, sizeof(buffer), "GMT%c%02d:%02d", offset < 0 ? '-' : '+',
                static_cast<int>(total / 3600), static_cast<int>(total % 3600 / 60));
  return buffer;
}

/// The schedule's zone as 0.12 parsed it: the device zone when absent; an
/// unknown named zone throws when used (0.12 "Invalid time zone").
struct Zone {
  std::string id;
  std::optional<int64_t> fixed;

  int64_t offsetAt(TimePoint utc, const Zones& zones) const {
    if (fixed) return *fixed;
    if (id == awn::defs::UTC_TIMEZONE || !zones.offsets) return 0;
    return zones.offsets(id, utc);
  }
};

Zone zoneFor(const ValueMap& schedule, const Zones& zones, const char* detail) {
  std::string name = ScheduleMath::zoneOf(schedule, zones);
  Zone zone{name, fixedOffset(name)};
  if (zone.fixed) {
    zone.id = fixedOffsetId(*zone.fixed);
  } else if (name != awn::defs::UTC_TIMEZONE && zones.isKnown && !zones.isKnown(name)) {
    throw invalid("Invalid time zone", detail);
  }
  return zone;
}

/// Dart / ISO weekday of a day count since 1970-01-01 (a Thursday): 1 = Monday.
int weekdayOf(int64_t days) {
  int64_t mod = ((days % 7) + 7) % 7;  // 0 = Thursday
  return static_cast<int>((mod + 3) % 7) + 1;
}

std::string wallClock(TimePoint utc, int64_t offset) {
  return DateUtils::formatUtc(utc + std::chrono::seconds(offset));
}

std::optional<TimePoint> nextCalendarDate(const ValueMap& schedule, TimePoint fixed,
                                          const Zones& zones) {
  Zone zone = zoneFor(schedule, zones, ".notificationCalendar.timeZone");

  auto year = integer(schedule, keys::YEAR);
  auto month = integer(schedule, keys::MONTH);
  auto day = integer(schedule, keys::DAY);
  auto hour = integer(schedule, keys::HOUR);
  auto minute = integer(schedule, keys::MINUTE);
  auto second = integer(schedule, keys::SECOND);
  auto weekday = integer(schedule, keys::WEEKDAY);
  // Quartz: one of day-of-month / day-of-week is "?" — the weekday wins.
  if (weekday) day.reset();

  // An out-of-range field makes the cron invalid: no date (not an error).
  if (!between(month, 1, 12) || !between(day, 1, 31) || !between(hour, 0, 23) ||
      !between(minute, 0, 59) || !between(second, 0, 59) || !between(weekday, 1, 7))
    return std::nullopt;

  // Quartz years run from 1970 to 100 years ahead.
  int64_t thisYear;
  unsigned m0, d0;
  DateUtils::civilFromDays(fixed.time_since_epoch().count() / kDay, thisYear, m0, d0);
  if (year && (*year < 1970 || *year > thisYear + 100)) return std::nullopt;

  auto values = [](const std::optional<int64_t>& given, int max) {
    std::vector<int> list;
    if (given) {
      list.push_back(static_cast<int>(*given));
    } else {
      for (int v = 0; v <= max; ++v) list.push_back(v);
    }
    return list;
  };
  const auto hours = values(hour, 23);
  const auto minutes = values(minute, 59);
  const auto seconds = values(second, 59);

  auto toUtc = [&](int64_t localSeconds) {
    TimePoint asUtc{std::chrono::seconds(localSeconds)};
    int64_t guessOffset = zone.offsetAt(asUtc, zones);
    TimePoint guess{std::chrono::seconds(localSeconds - guessOffset)};
    int64_t realOffset = zone.offsetAt(guess, zones);
    return realOffset == guessOffset ? guess
                                     : TimePoint{std::chrono::seconds(localSeconds - realOffset)};
  };

  // Quartz getNextValidTimeAfter: strictly after, at second resolution.
  TimePoint start = fixed + std::chrono::seconds(1);
  int64_t local = start.time_since_epoch().count() + zone.offsetAt(start, zones);
  int64_t startDay = local >= 0 ? local / kDay : (local - kDay + 1) / kDay;
  if (year) {
    if (DateUtils::daysFromCivil(*year + 1, 1, 1) <= startDay) return std::nullopt;
    startDay = std::max(startDay, DateUtils::daysFromCivil(*year, 1, 1));
  }

  for (int64_t days = startDay; days <= startDay + kSearchDays; ++days) {
    int64_t y;
    unsigned m, d;
    DateUtils::civilFromDays(days, y, m, d);
    if (year && y != *year) {
      if (y > *year) return std::nullopt;
      continue;
    }
    if (month && static_cast<int64_t>(m) != *month) continue;
    if (day && static_cast<int64_t>(d) != *day) continue;
    if (weekday && weekdayOf(days) != *weekday) continue;

    for (int h : hours)
      for (int mi : minutes)
        for (int s : seconds) {
          TimePoint candidate = toUtc(days * kDay + h * 3600 + mi * 60 + s);
          if (candidate >= start) return candidate;
        }
  }
  return std::nullopt;
}

}  // namespace

ScheduleMath::Kind ScheduleMath::kindOf(const ValueMap& schedule) {
  if (schedule.empty()) return Kind::None;
  for (const char* key : kCrontabKeys)
    if (present(schedule, key)) return Kind::Crontab;
  for (const char* key : kCalendarKeys)
    if (present(schedule, key)) return Kind::Calendar;
  if (present(schedule, keys::INTERVAL)) return Kind::Interval;
  return Kind::None;
}

bool ScheduleMath::repeats(const ValueMap& schedule) {
  return awn::getBool(schedule, keys::REPEATS).value_or(false);
}

std::string ScheduleMath::zoneOf(const ValueMap& schedule, const Zones& zones) {
  auto zone = awn::getString(schedule, keys::TIME_ZONE);
  return zone && !zone->empty() ? *zone : zones.local;
}

void ScheduleMath::validate(const ValueMap& schedule, const Zones&) {
  switch (kindOf(schedule)) {
    case Kind::Calendar: {
      auto era = integer(schedule, keys::ERA), year = integer(schedule, keys::YEAR),
           month = integer(schedule, keys::MONTH), day = integer(schedule, keys::DAY),
           hour = integer(schedule, keys::HOUR), minute = integer(schedule, keys::MINUTE),
           second = integer(schedule, keys::SECOND),
           millisecond = integer(schedule, keys::MILLISECOND),
           weekday = integer(schedule, keys::WEEKDAY),
           weekOfMonth = integer(schedule, keys::WEEK_OF_MONTH),
           weekOfYear = integer(schedule, keys::WEEK_OF_YEAR);
      if (!era && !year && !month && !day && !hour && !minute && !second && !millisecond &&
          !weekday && !weekOfMonth && !weekOfYear)
        throw invalid("At least one time condition is required", ".notificationCalendar");
      if (!between(era, 0, INT32_MAX) || !between(year, 0, INT32_MAX) ||
          !between(month, 1, 12) || !between(day, 1, 31) || !between(hour, 0, 23) ||
          !between(minute, 0, 59) || !between(second, 0, 59) ||
          !between(millisecond, 0, 999) || !between(weekday, 1, 7) ||
          !between(weekOfMonth, 1, 6) || !between(weekOfYear, 1, 53))
        throw invalid("The time conditions are invalid", ".notificationCalendar");
      return;
    }
    case Kind::Interval: {
      auto interval = integer(schedule, keys::INTERVAL);
      if (!interval || *interval < 5)
        throw invalid("Interval is required and must be greater than 5",
                      ".notificationInterval.interval");
      if (repeats(schedule) && *interval < 60)
        throw invalid("time interval must be at least 60 if repeating",
                      ".notificationInterval.interval");
      return;
    }
    case Kind::Crontab:
      if (!awn::has(schedule, keys::CRONTAB_EXPRESSION) &&
          awn::getList(schedule, keys::PRECISE_SCHEDULES).empty())
        throw AwesomeNotificationsException(code::INVALID_ARGUMENTS,
                                            "At least one schedule parameter is required",
                                            code::DETAILED_REQUIRED_ARGUMENTS);
      return;
    case Kind::None:
      return;
  }
}

std::optional<TimePoint> ScheduleMath::nextDate(const ValueMap& schedule, TimePoint fixed,
                                                const Zones& zones) {
  switch (kindOf(schedule)) {
    case Kind::Interval: {
      auto interval = integer(schedule, keys::INTERVAL);
      if (!interval)
        throw invalid("Interval is required and must be greater than 5",
                      ".notificationInterval.interval");
      TimePoint next = fixed + std::chrono::seconds(*interval);
      if (next < fixed) return std::nullopt;
      return next;
    }
    case Kind::Calendar:
      return nextCalendarDate(schedule, fixed, zones);
    case Kind::Crontab:  // not supported on desktop: never fires
    case Kind::None:
      return std::nullopt;
  }
  return std::nullopt;
}

std::vector<TimePoint> ScheduleMath::nextDates(const ValueMap& schedule, TimePoint fixed,
                                               size_t limit, TimePoint horizon,
                                               const Zones& zones) {
  std::vector<TimePoint> dates;
  TimePoint from = fixed;
  while (dates.size() < limit) {
    auto next = nextDate(schedule, from, zones);
    if (!next || *next > horizon) break;
    dates.push_back(*next);
    if (!repeats(schedule)) break;
    // A zero interval would repeat the same instant forever.
    if (*next <= from) break;
    from = *next;
  }
  return dates;
}

std::string ScheduleMath::describe(const ValueMap& schedule, TimePoint date, const Zones& zones) {
  if (kindOf(schedule) != Kind::Calendar)
    return DateUtils::formatUtc(date) + " " + awn::defs::UTC_TIMEZONE;
  Zone zone = zoneFor(schedule, zones, ".notificationCalendar.timeZone");
  return wallClock(date, zone.offsetAt(date, zones)) + " " + zone.id;
}

ValueMap ScheduleMath::normalized(const ValueMap& schedule, const Zones& zones) {
  ValueMap out;
  Kind kind = kindOf(schedule);
  if (kind == Kind::None) return out;

  std::string zone = zoneOf(schedule, zones);
  auto offset = fixedOffset(zone);
  out[keys::TIME_ZONE] = offset ? fixedOffsetId(*offset) : zone;
  if (auto created = awn::getString(schedule, keys::CREATED_DATE))
    out[keys::CREATED_DATE] = *created;
  out[keys::REPEATS] = repeats(schedule);
  out[keys::ALLOW_WHILE_IDLE] = awn::getBool(schedule, keys::ALLOW_WHILE_IDLE).value_or(false);
  out[keys::PRECISE_ALARM] = awn::getBool(schedule, keys::PRECISE_ALARM).value_or(false);
  out[keys::DELAY_TOLERANCE] = integer(schedule, keys::DELAY_TOLERANCE).value_or(0);

  if (kind == Kind::Calendar) {
    for (const char* key : kCalendarKeys)
      if (auto value = integer(schedule, key)) out[key] = *value;
  } else if (kind == Kind::Interval) {
    if (auto interval = integer(schedule, keys::INTERVAL)) out[keys::INTERVAL] = *interval;
  } else {
    for (const char* key : kCrontabKeys)
      if (awn::has(schedule, key)) out[key] = schedule.at(key);
  }
  return out;
}

}  // namespace awn_schedules
