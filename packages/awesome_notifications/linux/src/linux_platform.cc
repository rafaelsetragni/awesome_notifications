#include "linux_platform.h"

#include <gio/gio.h>
#include <glib.h>
#include <unistd.h>

#include <cctype>
#include <fstream>
#include <system_error>

#include "awn/definitions.h"

namespace awesome_notifications {
namespace linux_platform {

namespace {

std::string Trim(std::string text) {
  while (!text.empty() && std::isspace(static_cast<unsigned char>(text.back()))) text.pop_back();
  size_t start = 0;
  while (start < text.size() && std::isspace(static_cast<unsigned char>(text[start]))) ++start;
  return text.substr(start);
}

bool IsKnownZone(const std::string& zone) {
  if (zone.empty() || zone.find("..") != std::string::npos) return false;
  std::error_code ec;
  return std::filesystem::is_regular_file(std::filesystem::path("/usr/share/zoneinfo") / zone, ec);
}

}  // namespace

bool IsKnownTimeZone(const std::string& zone) { return zone == "UTC" || IsKnownZone(zone); }

std::string AppId() {
  GApplication* app = g_application_get_default();
  const char* id = app ? g_application_get_application_id(app) : nullptr;
  if (id && *id) return id;
  const char* name = g_get_prgname();
  return name && *name ? name : "flutter_app";
}

std::filesystem::path DataDirectory() {
  return std::filesystem::path(g_get_user_data_dir()) / AppId() / "awesome_notifications";
}

std::filesystem::path ExecutableDirectory() {
  std::error_code ec;
  auto exe = std::filesystem::read_symlink("/proc/self/exe", ec);
  return ec ? std::filesystem::current_path(ec) : exe.parent_path();
}

std::string LocalTimeZone() {
  if (const char* tz = g_getenv("TZ")) {
    std::string zone = tz;
    if (!zone.empty() && zone[0] == ':') zone.erase(0, 1);
    if (IsKnownZone(zone)) return zone;
  }
  std::ifstream file("/etc/timezone");
  std::string zone;
  if (file && std::getline(file, zone) && IsKnownZone(Trim(zone))) return Trim(zone);

  std::error_code ec;
  auto target = std::filesystem::read_symlink("/etc/localtime", ec).string();
  auto marker = target.find("zoneinfo/");
  if (!ec && marker != std::string::npos) {
    zone = target.substr(marker + 9);
    if (IsKnownZone(zone)) return zone;
  }
  return awn::defs::UTC_TIMEZONE;
}

int64_t UtcOffset(const std::string& zone, awn::TimePoint utc) {
#if GLIB_CHECK_VERSION(2, 68, 0)
  GTimeZone* tz = g_time_zone_new_identifier(zone.c_str());
#else
  GTimeZone* tz = g_time_zone_new(zone.c_str());
#endif
  if (tz == nullptr) return 0;
  gint64 seconds = utc.time_since_epoch().count();
  gint interval = g_time_zone_find_interval(tz, G_TIME_TYPE_UNIVERSAL, seconds);
  int64_t offset = interval < 0 ? 0 : g_time_zone_get_offset(tz, interval);
  g_time_zone_unref(tz);
  return offset;
}

std::string SystemLanguage() {
  const gchar* const* names = g_get_language_names();
  std::string tag = names && names[0] ? names[0] : "C";
  tag = tag.substr(0, tag.find_first_of(".@"));
  if (tag.empty() || tag == "C" || tag == "POSIX") return "en";
  for (auto& c : tag) {
    c = c == '_' ? '-' : static_cast<char>(std::tolower(static_cast<unsigned char>(c)));
  }
  return tag;
}

}  // namespace linux_platform
}  // namespace awesome_notifications
