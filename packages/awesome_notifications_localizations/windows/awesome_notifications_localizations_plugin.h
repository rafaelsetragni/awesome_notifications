#ifndef FLUTTER_PLUGIN_AWESOME_NOTIFICATIONS_LOCALIZATIONS_PLUGIN_H_
#define FLUTTER_PLUGIN_AWESOME_NOTIFICATIONS_LOCALIZATIONS_PLUGIN_H_

#include <flutter/plugin_registrar_windows.h>

namespace awesome_notifications_localizations {

/// Windows side of the localization decorator. It has no channel of its own: the
/// Dart side talks through the core `awesome_notifications` channel, so this
/// only registers the localization builder decorator and method handler in the
/// core's registries (shared through the core plugin's DLL).
class AwesomeNotificationsLocalizationsPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);

  AwesomeNotificationsLocalizationsPlugin() = default;
  virtual ~AwesomeNotificationsLocalizationsPlugin() = default;

  AwesomeNotificationsLocalizationsPlugin(const AwesomeNotificationsLocalizationsPlugin&) = delete;
  AwesomeNotificationsLocalizationsPlugin& operator=(const AwesomeNotificationsLocalizationsPlugin&) =
      delete;
};

}  // namespace awesome_notifications_localizations

#endif  // FLUTTER_PLUGIN_AWESOME_NOTIFICATIONS_LOCALIZATIONS_PLUGIN_H_
