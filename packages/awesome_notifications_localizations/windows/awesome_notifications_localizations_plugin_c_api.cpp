#include "include/awesome_notifications_localizations/awesome_notifications_localizations_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "awesome_notifications_localizations_plugin.h"

void AwesomeNotificationsLocalizationsPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  awesome_notifications_localizations::AwesomeNotificationsLocalizationsPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
