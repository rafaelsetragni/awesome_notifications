#pragma once

#include <optional>
#include <string>

#include "awn/date_utils.h"

namespace awesome_notifications {

/// IANA time zones through the ICU that ships with Windows 10 (icu.dll since
/// 1903, icuin.dll before). Loaded dynamically, so the plugin still loads where
/// it is missing (then callers fall back to UTC).
class IcuTimeZone {
 public:
  /// The device's IANA time zone id (e.g. "America/Sao_Paulo").
  static std::optional<std::string> DefaultZone();
  /// Offset from UTC in seconds of `zone` at `utc`, DST included.
  static std::optional<int64_t> Offset(const std::string& zone, awn::TimePoint utc);
};

}  // namespace awesome_notifications
