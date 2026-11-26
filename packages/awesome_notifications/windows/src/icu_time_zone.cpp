#include "icu_time_zone.h"

#include <windows.h>

#include "win_utils.h"

namespace awesome_notifications {

namespace {

// The few ICU C entry points we use (ucal.h); UChar is UTF-16 like wchar_t.
using UCalendar = void;
using GetDefaultTimeZoneFn = int32_t(__cdecl*)(wchar_t*, int32_t, int*);
using OpenFn = UCalendar*(__cdecl*)(const wchar_t*, int32_t, const char*, int, int*);
using SetMillisFn = void(__cdecl*)(UCalendar*, double, int*);
using GetFn = int32_t(__cdecl*)(const UCalendar*, int, int*);
using CloseFn = void(__cdecl*)(UCalendar*);

constexpr int kGregorian = 1;     // UCAL_GREGORIAN
constexpr int kZoneOffset = 15;   // UCAL_ZONE_OFFSET
constexpr int kDstOffset = 16;    // UCAL_DST_OFFSET

bool Succeeded(int status) { return status <= 0; }  // U_SUCCESS

struct Icu {
  GetDefaultTimeZoneFn getDefaultTimeZone = nullptr;
  OpenFn open = nullptr;
  SetMillisFn setMillis = nullptr;
  GetFn get = nullptr;
  CloseFn close = nullptr;

  bool ready() const { return open && setMillis && get && close; }

  static const Icu& Instance() {
    static const Icu icu = Load();
    return icu;
  }

 private:
  template <typename Fn>
  static Fn Find(HMODULE module, const char* name) {
    return reinterpret_cast<Fn>(reinterpret_cast<void*>(::GetProcAddress(module, name)));
  }

  static Icu Load() {
    Icu icu;
    // Kept loaded for the life of the process.
    for (const wchar_t* dll : {L"icu.dll", L"icuin.dll"}) {
      HMODULE module = ::LoadLibraryExW(dll, nullptr, LOAD_LIBRARY_SEARCH_SYSTEM32);
      if (!module) continue;
      icu.getDefaultTimeZone = Find<GetDefaultTimeZoneFn>(module, "ucal_getDefaultTimeZone");
      icu.open = Find<OpenFn>(module, "ucal_open");
      icu.setMillis = Find<SetMillisFn>(module, "ucal_setMillis");
      icu.get = Find<GetFn>(module, "ucal_get");
      icu.close = Find<CloseFn>(module, "ucal_close");
      if (icu.ready()) return icu;
      ::FreeLibrary(module);
      icu = Icu();
    }
    return icu;
  }
};

}  // namespace

std::optional<std::string> IcuTimeZone::DefaultZone() {
  const Icu& icu = Icu::Instance();
  if (!icu.getDefaultTimeZone) return std::nullopt;
  wchar_t buffer[128] = {};
  int status = 0;
  int32_t length = icu.getDefaultTimeZone(buffer, 128, &status);
  if (!Succeeded(status) || length <= 0 || length >= 128) return std::nullopt;
  return WideToUtf8(std::wstring(buffer, static_cast<size_t>(length)));
}

std::optional<int64_t> IcuTimeZone::Offset(const std::string& zone, awn::TimePoint utc) {
  const Icu& icu = Icu::Instance();
  if (!icu.ready()) return std::nullopt;
  std::wstring id = Utf8ToWide(zone);
  int status = 0;
  UCalendar* calendar =
      icu.open(id.c_str(), static_cast<int32_t>(id.size()), "en_US", kGregorian, &status);
  if (!calendar || !Succeeded(status)) {
    if (calendar) icu.close(calendar);
    return std::nullopt;
  }
  icu.setMillis(calendar, static_cast<double>(utc.time_since_epoch().count()) * 1000.0, &status);
  int32_t zoneMs = icu.get(calendar, kZoneOffset, &status);
  int32_t dstMs = icu.get(calendar, kDstOffset, &status);
  icu.close(calendar);
  if (!Succeeded(status)) return std::nullopt;
  return (static_cast<int64_t>(zoneMs) + dstMs) / 1000;
}

}  // namespace awesome_notifications
