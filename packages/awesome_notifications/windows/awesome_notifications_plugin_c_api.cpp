#include "include/awesome_notifications/awesome_notifications_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "awesome_notifications_plugin.h"

void AwesomeNotificationsPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  awesome_notifications::AwesomeNotificationsPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
