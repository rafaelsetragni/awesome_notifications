#include "awesome_notifications_localizations_plugin.h"

#include <windows.h>

#include <filesystem>
#include <memory>

#include "awn_localizations/localizations.h"

namespace awesome_notifications_localizations {

namespace {

/// The app's loc-key strings: `data/flutter_assets/<kAssetFolder>` next to the
/// executable (where Flutter bundles the app's assets on Windows).
std::filesystem::path StringsFolder() {
  std::wstring path(MAX_PATH, L'\0');
  DWORD length = 0;
  while ((length = ::GetModuleFileNameW(nullptr, path.data(),
                                        static_cast<DWORD>(path.size()))) == path.size()) {
    path.resize(path.size() * 2);
  }
  if (length == 0) return {};
  path.resize(length);
  return std::filesystem::path(path).parent_path() / "data" / "flutter_assets" /
         awn_localizations::LocalizedStrings::kAssetFolder;
}

}  // namespace

// static
void AwesomeNotificationsLocalizationsPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows* registrar) {
  // Translates notifications before the other decorators see them.
  awn_localizations::RegisterLocalizations(awn::AwesomeNotifications::shared(), StringsFolder());
  registrar->AddPlugin(std::make_unique<AwesomeNotificationsLocalizationsPlugin>());
}

}  // namespace awesome_notifications_localizations
