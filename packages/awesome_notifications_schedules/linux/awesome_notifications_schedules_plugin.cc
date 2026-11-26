#include "include/awesome_notifications_schedules/awesome_notifications_schedules_plugin.h"

#include <flutter_linux/flutter_linux.h>

#include "awn/definitions.h"
#include "awn/registries.h"
#include "awn_schedules/schedules.h"

#define AWESOME_NOTIFICATIONS_SCHEDULES_PLUGIN(obj)                                     \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), awesome_notifications_schedules_plugin_get_type(), \
                              AwesomeNotificationsSchedulesPlugin))

struct _AwesomeNotificationsSchedulesPlugin {
  GObject parent_instance;
};

G_DEFINE_TYPE(AwesomeNotificationsSchedulesPlugin, awesome_notifications_schedules_plugin,
              g_object_get_type())

static void awesome_notifications_schedules_plugin_class_init(
    AwesomeNotificationsSchedulesPluginClass* klass) {}

static void awesome_notifications_schedules_plugin_init(AwesomeNotificationsSchedulesPlugin* self) {}

void awesome_notifications_schedules_plugin_register_with_registrar(FlPluginRegistrar* registrar) {
  // Plugins register alphabetically, so the core plugin already configured the
  // engine: this also tops up the pre-armed occurrences of repeating schedules.
  awn_schedules::RegisterSchedules();

  // Linux has no system scheduler: the app's own timer shows the occurrences,
  // so it keeps them topped up while it runs, after each one is displayed.
  awn::AwesomeEventsReceiver::shared().subscribe(
      [](const std::string& event, const awn::ValueMap&) {
        if (event == awn::defs::EVENT_NOTIFICATION_DISPLAYED)
          awn_schedules::TopUpRepeatingSchedules(awn::AwesomeNotifications::shared());
      });
}
