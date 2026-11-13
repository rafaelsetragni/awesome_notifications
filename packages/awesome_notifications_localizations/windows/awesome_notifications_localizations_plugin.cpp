#include "awesome_notifications_localizations_plugin.h"

#include <memory>

#include "awn_localizations/localizations.h"

namespace awesome_notifications_localizations {

// static
void AwesomeNotificationsLocalizationsPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows* registrar) {
  // Translates notifications before the other decorators see them.
  awn_localizations::RegisterLocalizations();
  registrar->AddPlugin(std::make_unique<AwesomeNotificationsLocalizationsPlugin>());
}

}  // namespace awesome_notifications_localizations
