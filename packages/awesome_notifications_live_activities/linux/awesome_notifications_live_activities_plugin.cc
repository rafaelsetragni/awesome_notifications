#include "include/awesome_notifications_live_activities/awesome_notifications_live_activities_plugin.h"

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>

#include <functional>
#include <memory>

#include "awn/awesome_notifications.h"
#include "awesome_notifications/awn_fl_value_codec.h"
#include "awn_live/live.h"

#define AWESOME_NOTIFICATIONS_LIVE_ACTIVITIES_PLUGIN(obj)                          \
  (G_TYPE_CHECK_INSTANCE_CAST((obj),                                               \
                              awesome_notifications_live_activities_plugin_get_type(), \
                              AwesomeNotificationsLiveActivitiesPlugin))

struct _AwesomeNotificationsLiveActivitiesPlugin {
  GObject parent_instance;
};

G_DEFINE_TYPE(AwesomeNotificationsLiveActivitiesPlugin,
              awesome_notifications_live_activities_plugin, g_object_get_type())

static void awesome_notifications_live_activities_plugin_class_init(
    AwesomeNotificationsLiveActivitiesPluginClass* klass) {}

static void awesome_notifications_live_activities_plugin_init(
    AwesomeNotificationsLiveActivitiesPlugin* self) {}

namespace {

/// The live activity side of the engine: lives as long as the app (one per
/// process). Linux has no live activity surface: an activity is a resident
/// freedesktop notification, replaced in place (the core's presenter keeps its
/// replaces_id), silent after the first post, its progress drawn as a text bar.
struct LiveActivities {
  FlEventChannel* events = nullptr;
  bool listening = false;
  std::shared_ptr<awn_live::LiveController> controller;
};

LiveActivities* live = nullptr;

/// Runs `work` once on the GLib main loop (the platform thread) after `ms`.
void After(int64_t ms, std::function<void()> work) {
  auto* boxed = new std::function<void()>(std::move(work));
  g_timeout_add_full(
      G_PRIORITY_DEFAULT, static_cast<guint>(ms < 0 ? 0 : ms),
      [](gpointer data) -> gboolean {
        (*static_cast<std::function<void()>*>(data))();
        return G_SOURCE_REMOVE;
      },
      boxed, [](gpointer data) { delete static_cast<std::function<void()>*>(data); });
}

FlMethodErrorResponse* OnListen(FlEventChannel*, FlValue*, gpointer) {
  if (live) live->listening = true;
  return nullptr;
}

FlMethodErrorResponse* OnCancel(FlEventChannel*, FlValue*, gpointer) {
  if (live) live->listening = false;
  return nullptr;
}

}  // namespace

void awesome_notifications_live_activities_plugin_register_with_registrar(
    FlPluginRegistrar* registrar) {
  if (live != nullptr) return;
  live = new LiveActivities();

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  live->events = fl_event_channel_new(fl_plugin_registrar_get_messenger(registrar),
                                      awn_live::keys::EVENTS_CHANNEL, FL_METHOD_CODEC(codec));
  fl_event_channel_set_stream_handlers(live->events, OnListen, OnCancel, nullptr, nullptr);

  auto& core = awn::AwesomeNotifications::shared();
  live->controller = std::make_shared<awn_live::LiveController>(
      awn_live::engineHost(core, After), awn_live::Surface::freedesktop);
  live->controller->setStreamSink([](const awn::ValueMap& event) {
    if (!live->listening) return;
    g_autoptr(FlValue) value = awesome_notifications::ToFlValue(awn::Value(event));
    fl_event_channel_send(live->events, value, nullptr, nullptr);
  });

  // Plugins register alphabetically: the core plugin already configured the
  // engine.
  awn_live::RegisterLiveActivities(live->controller, awn_live::desktopCapabilities(), core);
}
