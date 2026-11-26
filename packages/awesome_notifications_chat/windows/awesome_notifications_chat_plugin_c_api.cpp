#include "include/awesome_notifications_chat/awesome_notifications_chat_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "awesome_notifications_chat_plugin.h"

void AwesomeNotificationsChatPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  awesome_notifications_chat::AwesomeNotificationsChatPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
