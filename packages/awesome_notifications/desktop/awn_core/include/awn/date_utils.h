#pragma once

#include <chrono>
#include <optional>
#include <string>

#include "awn/export.h"

namespace awn {

using Clock = std::chrono::system_clock;
using TimePoint = std::chrono::time_point<Clock, std::chrono::seconds>;

/// Lifecycle dates travel as UTC "yyyy-MM-dd HH:mm:ss", like on every other
/// platform, so Dart's AwesomeDateUtils parses them back consistently.
class AWN_API DateUtils {
 public:
  static std::string formatUtc(TimePoint time);
  /// nullopt when `text` is not "yyyy-MM-dd HH:mm:ss".
  static std::optional<TimePoint> parseUtc(const std::string& text);
  static TimePoint now();
  static std::string nowUtc() { return formatUtc(now()); }

  /// Days since 1970-01-01 of a proleptic Gregorian civil date (and back).
  static int64_t daysFromCivil(int64_t y, unsigned m, unsigned d);
  static void civilFromDays(int64_t days, int64_t& y, unsigned& m, unsigned& d);
};

}  // namespace awn
