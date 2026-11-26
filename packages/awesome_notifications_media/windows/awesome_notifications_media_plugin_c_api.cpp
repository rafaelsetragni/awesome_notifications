#include "include/awesome_notifications_media/awesome_notifications_media_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "awesome_notifications_media_plugin.h"

void AwesomeNotificationsMediaPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  awesome_notifications_media::AwesomeNotificationsMediaPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
