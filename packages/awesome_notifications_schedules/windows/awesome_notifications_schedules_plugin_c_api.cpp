#include "include/awesome_notifications_schedules/awesome_notifications_schedules_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "awesome_notifications_schedules_plugin.h"

void AwesomeNotificationsSchedulesPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  awesome_notifications_schedules::AwesomeNotificationsSchedulesPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
