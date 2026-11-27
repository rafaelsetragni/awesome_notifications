#include "include/awesome_notifications_live_activities/awesome_notifications_live_activities_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "awesome_notifications_live_activities_plugin.h"

void AwesomeNotificationsLiveActivitiesPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  awesome_notifications_live_activities::AwesomeNotificationsLiveActivitiesPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
