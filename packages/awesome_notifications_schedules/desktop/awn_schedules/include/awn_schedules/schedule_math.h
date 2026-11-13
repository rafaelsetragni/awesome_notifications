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
inline constexpr const char* TIME_ZONE = "timeZone";
inline constexpr const char* ERA = "era";
inline constexpr const char* YEAR = "year";
inline constexpr const char* MONTH = "month";
inline constexpr const char* DAY = "day";
inline constexpr const char* HOUR = "hour";
inline constexpr const char* MINUTE = "minute";
inline constexpr const char* SECOND = "second";
inline constexpr const char* WEEKDAY = "weekday";
inline constexpr const char* WEEK_OF_MONTH = "weekOfMonth";
inline constexpr const char* WEEK_OF_YEAR = "weekOfYear";
}  // namespace keys

/// UTC offset (seconds east of UTC) of time zone `zone` at instant `utc`.
/// Windows answers through ICU; tests use fixed offsets.
using OffsetProvider = std::function<int64_t(const std::string& zone, awn::TimePoint utc)>;

/// Next-fire-date math of the desktop scheduling decorator, with the semantics
/// documented by the Dart models:
///  - interval: `fixed + interval` (a repeating interval must be >= 60 s);
///  - calendar: the first instant after `fixed` whose wall-clock time in the
///    schedule's time zone matches every given component. Components finer than
///    the finest given one default to their minimum ({hour: 9} → 09:00:00);
///    coarser missing ones are free. weekday: 1 = Monday … 7 = Sunday.
class ScheduleMath {
 public:
  static std::optional<awn::TimePoint> nextDate(const awn::ValueMap& schedule,
                                                awn::TimePoint fixed,
                                                const std::string& defaultZone,
                                                const OffsetProvider& offsets);

  /// Up to `limit` successive fire dates after `fixed` (one for a non-repeating
  /// schedule), all before `horizon`.
  static std::vector<awn::TimePoint> nextDates(const awn::ValueMap& schedule,
                                               awn::TimePoint fixed, size_t limit,
                                               awn::TimePoint horizon,
                                               const std::string& defaultZone,
                                               const OffsetProvider& offsets);

  static bool repeats(const awn::ValueMap& schedule);
  /// The interval in seconds, or nullopt when it is not a (valid) interval.
  static std::optional<int64_t> validInterval(const awn::ValueMap& schedule);
  static bool isCalendar(const awn::ValueMap& schedule);
};

}  // namespace awn_schedules
