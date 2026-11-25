#pragma once

#include <filesystem>
#include <string>

#include "awn/date_utils.h"

namespace awesome_notifications {

/// Linux facts the presenter needs (no Flutter, no GTK).
namespace linux_platform {

/// The application id (GApplication) or, without one, the program name.
std::string AppId();
/// Per-app folder of the plugin: $XDG_DATA_HOME/<app id>/awesome_notifications.
std::filesystem::path DataDirectory();
/// Folder of the running executable (the Flutter bundle root).
std::filesystem::path ExecutableDirectory();

/// IANA id of the local zone: $TZ, /etc/timezone, or the /etc/localtime link.
std::string LocalTimeZone();
/// Whether the system has the IANA zone `zone` (its tzdata file).
bool IsKnownTimeZone(const std::string& zone);
/// Offset from UTC, in seconds, of `zone` at `utc` (DST included); 0 when the
/// zone is unknown.
int64_t UtcOffset(const std::string& zone, awn::TimePoint utc);
/// The user's language as a lowercase BCP 47 tag ("pt_BR.UTF-8" -> "pt-br").
std::string SystemLanguage();

}  // namespace linux_platform

}  // namespace awesome_notifications
