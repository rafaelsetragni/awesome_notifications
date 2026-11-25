#pragma once

#include <functional>
#include <optional>
#include <string>
#include <vector>

#include "awn/date_utils.h"
#include "awn/value.h"

namespace awn_schedules {

/// Keys of the `schedule` block (the Dart NotificationInterval /
/// NotificationCalendar `toMap()`), shared with the Apple and Android decorators.
namespace keys {
inline constexpr const char* SCHEDULE = "schedule";
inline constexpr const char* INTERVAL = "interval";
inline constexpr const char* REPEATS = "repeats";
inline constexpr const char* ALLOW_WHILE_IDLE = "allowWhileIdle";
inline constexpr const char* PRECISE_ALARM = "preciseAlarm";
inline constexpr const char* DELAY_TOLERANCE = "delayTolerance";
inline constexpr const char* CREATED_DATE = "createdDate";
inline constexpr const char* TIME_ZONE = "timeZone";
inline constexpr const char* ERA = "era";
inline constexpr const char* YEAR = "year";
inline constexpr const char* MONTH = "month";
inline constexpr const char* DAY = "day";
inline constexpr const char* HOUR = "hour";
inline constexpr const char* MINUTE = "minute";
inline constexpr const char* SECOND = "second";
inline constexpr const char* MILLISECOND = "millisecond";
inline constexpr const char* WEEKDAY = "weekday";
inline constexpr const char* WEEK_OF_MONTH = "weekOfMonth";
inline constexpr const char* WEEK_OF_YEAR = "weekOfYear";
inline constexpr const char* CRONTAB_EXPRESSION = "crontabExpression";
inline constexpr const char* PRECISE_SCHEDULES = "preciseSchedules";
inline constexpr const char* EXPIRATION_DATE_TIME = "expirationDateTime";
}  // namespace keys

/// UTC offset (seconds east of UTC) of time zone `zone` at instant `utc`.
using OffsetProvider = std::function<int64_t(const std::string& zone, awn::TimePoint utc)>;
/// Whether the platform knows the IANA time zone `zone`.
using ZoneValidator = std::function<bool(const std::string& zone)>;

/// The time-zone services the math needs, from the platform presenter.
struct Zones {
  std::string local;          // the device zone (default of a schedule)
  OffsetProvider offsets;
  ZoneValidator isKnown;      // null: every zone is known
};

/// Next-fire-date math of the desktop scheduling decorator: a port of the 0.12
/// Android `NotificationScheduleModel` (the reference Windows and Linux
/// follow), quirks included:
///  - the KEYS present decide the type (a Dart calendar sends every component
///    key, null ones too): crontab keys, else calendar keys, else interval;
///  - validation rules and messages are 0.12's;
///  - a calendar is a Quartz cron "<sec|*> <min|*> <hour|*> <day|*|?> <month|*>
///    <weekday|?> <year|*>": every missing component is free (a free second
///    matches one second after the reference), the day of the month is ignored
///    when a weekday is given, and era / millisecond / weekOfMonth /
///    weekOfYear are ignored. The next date is strictly after the reference;
///  - an interval is reference + interval.
class ScheduleMath {
 public:
  enum class Kind { None, Interval, Calendar, Crontab };

  static Kind kindOf(const awn::ValueMap& schedule);

  /// Throws `awn::AwesomeNotificationsException` like 0.12's validate().
  static void validate(const awn::ValueMap& schedule, const Zones& zones);

  /// 0.12 `getNextValidDate(fixed)`: not validated first (an out-of-range
  /// component just never matches). Throws for a missing interval or an
  /// unknown time zone, like 0.12.
  static std::optional<awn::TimePoint> nextDate(const awn::ValueMap& schedule,
                                                awn::TimePoint fixed, const Zones& zones);

  /// Up to `limit` successive fire dates after `fixed` (one for a non-repeating
  /// schedule), all before `horizon`.
  static std::vector<awn::TimePoint> nextDates(const awn::ValueMap& schedule,
                                               awn::TimePoint fixed, size_t limit,
                                               awn::TimePoint horizon, const Zones& zones);

  /// 0.12 `calendarToString`: "yyyy-MM-dd HH:mm:ss <zone>" in the zone of the
  /// resulting calendar (the schedule's for a calendar, UTC for an interval).
  static std::string describe(const awn::ValueMap& schedule, awn::TimePoint date,
                              const Zones& zones);

  /// 0.12 `toMap()` of the parsed schedule: what is stored and listed.
  static awn::ValueMap normalized(const awn::ValueMap& schedule, const Zones& zones);

  static bool repeats(const awn::ValueMap& schedule);
  /// The schedule's time zone (the device zone when absent).
  static std::string zoneOf(const awn::ValueMap& schedule, const Zones& zones);
};

}  // namespace awn_schedules
