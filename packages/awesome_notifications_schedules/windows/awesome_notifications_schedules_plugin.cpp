#include "awesome_notifications_schedules_plugin.h"

#include <memory>

#include "awn_schedules/schedules.h"

namespace awesome_notifications_schedules {

// static
void AwesomeNotificationsSchedulesPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows* registrar) {
  // Plugins register alphabetically, so the core plugin already configured the
  // engine: this also tops up the pre-armed occurrences of repeating schedules.
  awn_schedules::RegisterSchedules();
  registrar->AddPlugin(std::make_unique<AwesomeNotificationsSchedulesPlugin>());
}

}  // namespace awesome_notifications_schedules
