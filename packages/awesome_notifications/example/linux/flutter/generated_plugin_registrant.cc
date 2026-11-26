//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <awesome_notifications/awesome_notifications_plugin.h>
#include <awesome_notifications_schedules/awesome_notifications_schedules_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) awesome_notifications_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "AwesomeNotificationsPlugin");
  awesome_notifications_plugin_register_with_registrar(awesome_notifications_registrar);
  g_autoptr(FlPluginRegistrar) awesome_notifications_schedules_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "AwesomeNotificationsSchedulesPlugin");
  awesome_notifications_schedules_plugin_register_with_registrar(awesome_notifications_schedules_registrar);
}
