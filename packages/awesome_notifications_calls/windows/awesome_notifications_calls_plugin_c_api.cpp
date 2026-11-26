#include "include/awesome_notifications_calls/awesome_notifications_calls_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "awesome_notifications_calls_plugin.h"

void AwesomeNotificationsCallsPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  awesome_notifications_calls::AwesomeNotificationsCallsPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
