#ifndef FLUTTER_PLUGIN_AWESOME_NOTIFICATIONS_SCHEDULES_PLUGIN_H_
#define FLUTTER_PLUGIN_AWESOME_NOTIFICATIONS_SCHEDULES_PLUGIN_H_

#include <flutter/plugin_registrar_windows.h>

namespace awesome_notifications_schedules {

/// Windows side of the scheduling decorator. It has no channel of its own: the
/// Dart side talks through the core `awesome_notifications` channel, so this
/// only registers the schedule builder decorator and method handler in the
/// core's registries (shared through the core plugin's DLL).
class AwesomeNotificationsSchedulesPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);

  AwesomeNotificationsSchedulesPlugin() = default;
  virtual ~AwesomeNotificationsSchedulesPlugin() = default;

  AwesomeNotificationsSchedulesPlugin(const AwesomeNotificationsSchedulesPlugin&) = delete;
  AwesomeNotificationsSchedulesPlugin& operator=(const AwesomeNotificationsSchedulesPlugin&) =
      delete;
};

}  // namespace awesome_notifications_schedules

#endif  // FLUTTER_PLUGIN_AWESOME_NOTIFICATIONS_SCHEDULES_PLUGIN_H_
