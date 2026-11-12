#ifndef FLUTTER_PLUGIN_AWESOME_NOTIFICATIONS_SCHEDULES_PLUGIN_H_
#define FLUTTER_PLUGIN_AWESOME_NOTIFICATIONS_SCHEDULES_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace awesome_notifications_schedules {

class AwesomeNotificationsSchedulesPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  AwesomeNotificationsSchedulesPlugin();

  virtual ~AwesomeNotificationsSchedulesPlugin();

  // Disallow copy and assign.
  AwesomeNotificationsSchedulesPlugin(const AwesomeNotificationsSchedulesPlugin&) = delete;
  AwesomeNotificationsSchedulesPlugin& operator=(const AwesomeNotificationsSchedulesPlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace awesome_notifications_schedules

#endif  // FLUTTER_PLUGIN_AWESOME_NOTIFICATIONS_SCHEDULES_PLUGIN_H_
