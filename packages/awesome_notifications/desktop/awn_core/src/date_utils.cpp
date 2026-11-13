#include "awn/date_utils.h"

#include <cstdio>

namespace awn {

// Howard Hinnant's civil-date algorithms (public domain): exact and free of any
// time-zone database, so they behave identically on every platform.
int64_t DateUtils::daysFromCivil(int64_t y, unsigned m, unsigned d) {
  y -= m <= 2;
  const int64_t era = (y >= 0 ? y : y - 399) / 400;
  const unsigned yoe = static_cast<unsigned>(y - era * 400);
  const unsigned doy = (153 * (m > 2 ? m - 3 : m + 9) + 2) / 5 + d - 1;
  const unsigned doe = yoe * 365 + yoe / 4 - yoe / 100 + doy;
  return era * 146097 + static_cast<int64_t>(doe) - 719468;
}

void DateUtils::civilFromDays(int64_t z, int64_t& y, unsigned& m, unsigned& d) {
  z += 719468;
  const int64_t era = (z >= 0 ? z : z - 146096) / 146097;
  const unsigned doe = static_cast<unsigned>(z - era * 146097);
  const unsigned yoe = (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365;
  y = static_cast<int64_t>(yoe) + era * 400;
  const unsigned doy = doe - (365 * yoe + yoe / 4 - yoe / 100);
  const unsigned mp = (5 * doy + 2) / 153;
  d = doy - (153 * mp + 2) / 5 + 1;
  m = mp < 10 ? mp + 3 : mp - 9;
  y += m <= 2;
}

std::string DateUtils::formatUtc(TimePoint time) {
  int64_t secs = time.time_since_epoch().count();
  int64_t days = secs / 86400;
  int64_t rem = secs % 86400;
  if (rem < 0) {
    rem += 86400;
    --days;
  }
  int64_t y;
  unsigned m, d;
  civilFromDays(days, y, m, d);
  char buf[32];
  std::snprintf(buf, sizeof(buf), "%04lld-%02u-%02u %02d:%02d:%02d",
                static_cast<long long>(y), m, d, static_cast<int>(rem / 3600),
                static_cast<int>((rem % 3600) / 60), static_cast<int>(rem % 60));
  return buf;
}

std::optional<TimePoint> DateUtils::parseUtc(const std::string& text) {
  int y, mo, d, h, mi, s;
  char tail;
  if (std::sscanf(text.c_str(), "%4d-%2d-%2d %2d:%2d:%2d%c", &y, &mo, &d, &h, &mi, &s,
                  &tail) != 6)
    return std::nullopt;
  if (mo < 1 || mo > 12 || d < 1 || d > 31 || h < 0 || h > 23 || mi < 0 || mi > 59 ||
      s < 0 || s > 60)
    return std::nullopt;
  int64_t days = daysFromCivil(y, static_cast<unsigned>(mo), static_cast<unsigned>(d));
  return TimePoint(std::chrono::seconds(days * 86400 + h * 3600 + mi * 60 + s));
}

TimePoint DateUtils::now() {
  return std::chrono::time_point_cast<std::chrono::seconds>(Clock::now());
}

}  // namespace awn
