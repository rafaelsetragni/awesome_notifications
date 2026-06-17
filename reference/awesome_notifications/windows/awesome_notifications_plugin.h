#ifndef FLUTTER_PLUGIN_AWESOME_NOTIFICATIONS_PLUGIN_H_
#define FLUTTER_PLUGIN_AWESOME_NOTIFICATIONS_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace awesome_notifications {

class AwesomeNotificationsPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  AwesomeNotificationsPlugin();

  virtual ~AwesomeNotificationsPlugin();

  // Disallow copy and assign.
  AwesomeNotificationsPlugin(const AwesomeNotificationsPlugin&) = delete;
  AwesomeNotificationsPlugin& operator=(const AwesomeNotificationsPlugin&) = delete;

 private:
  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace awesome_notifications

#endif  // FLUTTER_PLUGIN_AWESOME_NOTIFICATIONS_PLUGIN_H_
