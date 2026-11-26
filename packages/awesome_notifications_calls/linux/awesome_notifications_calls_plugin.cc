#include "include/awesome_notifications_calls/awesome_notifications_calls_plugin.h"

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>

#include <functional>
#include <memory>

#include "awn/awesome_notifications.h"
#include "awesome_notifications/awn_fl_value_codec.h"
#include "awn_calls/calls.h"

#define AWESOME_NOTIFICATIONS_CALLS_PLUGIN(obj)                                     \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), awesome_notifications_calls_plugin_get_type(), \
                              AwesomeNotificationsCallsPlugin))

struct _AwesomeNotificationsCallsPlugin {
  GObject parent_instance;
};

G_DEFINE_TYPE(AwesomeNotificationsCallsPlugin, awesome_notifications_calls_plugin,
              g_object_get_type())

static void awesome_notifications_calls_plugin_class_init(
    AwesomeNotificationsCallsPluginClass* klass) {}

static void awesome_notifications_calls_plugin_init(AwesomeNotificationsCallsPlugin* self) {}

namespace {

/// The call side of the engine: lives as long as the app (one per process).
/// Linux has no system call UI: a call is a critical, resident freedesktop
/// notification with Accept / Decline (Hang up once answered), drawn by the
/// core's presenter from the hints of the call builder.
struct Calls {
  FlEventChannel* events = nullptr;
  bool listening = false;
  std::shared_ptr<awn_calls::CallController> controller;
};

Calls* calls = nullptr;

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
  if (calls) calls->listening = true;
  return nullptr;
}

FlMethodErrorResponse* OnCancel(FlEventChannel*, FlValue*, gpointer) {
  if (calls) calls->listening = false;
  return nullptr;
}

}  // namespace

void awesome_notifications_calls_plugin_register_with_registrar(FlPluginRegistrar* registrar) {
  if (calls != nullptr) return;
  calls = new Calls();

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  calls->events = fl_event_channel_new(fl_plugin_registrar_get_messenger(registrar),
                                       awn_calls::keys::EVENTS_CHANNEL, FL_METHOD_CODEC(codec));
  fl_event_channel_set_stream_handlers(calls->events, OnListen, OnCancel, nullptr, nullptr);

  auto& core = awn::AwesomeNotifications::shared();
  calls->controller = std::make_shared<awn_calls::CallController>(awn_calls::engineHost(core, After));
  calls->controller->setStreamSink([](const awn::ValueMap& event) {
    if (!calls->listening) return;
    g_autoptr(FlValue) value = awesome_notifications::ToFlValue(awn::Value(event));
    fl_event_channel_send(calls->events, value, nullptr, nullptr);
  });

  // Plugins register alphabetically: the core plugin already configured the
  // engine. The core's bridge brings the window forward for Accept (a
  // Default action) and leaves it for Decline / Hang up (silent).
  awn_calls::RegisterCalls(calls->controller, awn_calls::desktopCapabilities(), core);
}
