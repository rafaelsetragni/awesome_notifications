#include "include/awesome_notifications_localizations/awesome_notifications_localizations_plugin.h"

#include <flutter_linux/flutter_linux.h>

#include <filesystem>
#include <system_error>

#include "awn_localizations/localizations.h"

#define AWESOME_NOTIFICATIONS_LOCALIZATIONS_PLUGIN(obj)                                     \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), awesome_notifications_localizations_plugin_get_type(), \
                              AwesomeNotificationsLocalizationsPlugin))

struct _AwesomeNotificationsLocalizationsPlugin {
  GObject parent_instance;
};

G_DEFINE_TYPE(AwesomeNotificationsLocalizationsPlugin, awesome_notifications_localizations_plugin,
              g_object_get_type())

static void awesome_notifications_localizations_plugin_class_init(
    AwesomeNotificationsLocalizationsPluginClass* klass) {}

static void awesome_notifications_localizations_plugin_init(
    AwesomeNotificationsLocalizationsPlugin* self) {}

namespace {

/// The app's loc-key strings: `data/flutter_assets/<kAssetFolder>` next to the
/// executable (where Flutter bundles the app's assets on Linux).
std::filesystem::path StringsFolder() {
  std::error_code ec;
  auto exe = std::filesystem::read_symlink("/proc/self/exe", ec);
  if (ec) return {};
  return exe.parent_path() / "data" / "flutter_assets" /
         awn_localizations::LocalizedStrings::kAssetFolder;
}

}  // namespace

void awesome_notifications_localizations_plugin_register_with_registrar(
    FlPluginRegistrar* registrar) {
  // Translates notifications before the other decorators see them.
  awn_localizations::RegisterLocalizations(awn::AwesomeNotifications::shared(), StringsFolder());
}
