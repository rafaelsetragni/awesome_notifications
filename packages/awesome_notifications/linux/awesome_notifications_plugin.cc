#include "include/awesome_notifications/awesome_notifications_plugin.h"

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>
#include <sys/utsname.h>

#include <cstring>
#include <memory>

#include "awesome_notifications_plugin_private.h"
#include "awn/awesome_notifications.h"
#include "awn/definitions.h"
#include "awn/method_router.h"
#include "awn/notification_builder.h"
#include "awn/registries.h"
#include "include/awesome_notifications/awn_fl_value_codec.h"
#include "src/freedesktop_presenter.h"
#include "src/glib_dispatcher.h"
#include "src/linux_platform.h"

#define AWESOME_NOTIFICATIONS_PLUGIN(obj)                                     \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), awesome_notifications_plugin_get_type(), \
                              AwesomeNotificationsPlugin))

namespace {

using awesome_notifications::FreedesktopPresenter;
using awesome_notifications::GlibDispatcher;

/// The C++ side of the plugin: the engine's presenter, dispatcher and router,
/// and the Flutter view whose window gives the app lifecycle.
struct Bridge {
  /// The app's view, taken at registration (the registrar is released right
  /// after it). Weak: cleared when the view goes.
  FlView* view = nullptr;
  FlMethodChannel* channel = nullptr;
  std::shared_ptr<GlibDispatcher> dispatcher;
  std::shared_ptr<FreedesktopPresenter> presenter;
  std::unique_ptr<awn::AwesomeMethodRouter> router;
  int eventsToken = 0;

  GtkWindow* Window() const {
    if (view == nullptr) return nullptr;
    GtkWidget* toplevel = gtk_widget_get_toplevel(GTK_WIDGET(view));
    return GTK_IS_WINDOW(toplevel) ? GTK_WINDOW(toplevel) : nullptr;
  }

  /// Foreground while the app's window is the active one and not minimized,
  /// as on Windows; otherwise background.
  awn::LifeCycle CurrentLifeCycle() const {
    GtkWindow* window = Window();
    if (window == nullptr || !gtk_window_is_active(window)) return awn::LifeCycle::Background;
    GdkWindow* gdk = gtk_widget_get_window(GTK_WIDGET(window));
    if (gdk && (gdk_window_get_state(gdk) & GDK_WINDOW_STATE_ICONIFIED))
      return awn::LifeCycle::Background;
    return awn::LifeCycle::Foreground;
  }

  void OnActivated(const awn::Activation& activation) const {
    auto type = awn::AwesomeNotifications::shared().onActivated(activation);
    if (!type) return;
    switch (*type) {
      case awn::ActionType::SilentAction:
      case awn::ActionType::SilentBackgroundAction:
      case awn::ActionType::DismissAction:
        return;
      default:
        if (GtkWindow* window = Window()) gtk_window_present(window);
    }
  }
};

}  // namespace

struct _AwesomeNotificationsPlugin {
  GObject parent_instance;
  Bridge* bridge;
};

G_DEFINE_TYPE(AwesomeNotificationsPlugin, awesome_notifications_plugin, g_object_get_type())

FlMethodResponse* get_platform_version() {
  struct utsname uname_data = {};
  uname(&uname_data);
  g_autofree gchar* version = g_strdup_printf("Linux %s", uname_data.version);
  g_autoptr(FlValue) result = fl_value_new_string(version);
  return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
}

static void awesome_notifications_plugin_handle_method_call(AwesomeNotificationsPlugin* self,
                                                            FlMethodCall* method_call) {
  const gchar* method = fl_method_call_get_name(method_call);
  if (strcmp(method, "getPlatformVersion") == 0) {
    g_autoptr(FlMethodResponse) response = get_platform_version();
    fl_method_call_respond(method_call, response, nullptr);
    return;
  }

  awn::Value arguments = awesome_notifications::ToAwnValue(fl_method_call_get_args(method_call));
  // The result may arrive later (async work): keep the call alive until then.
  g_object_ref(method_call);
  bool handled = self->bridge->router->handle(
      method, arguments,
      [method_call](const awn::Value& value) {
        g_autoptr(FlValue) result = awesome_notifications::ToFlValue(value);
        fl_method_call_respond_success(method_call, result, nullptr);
        g_object_unref(method_call);
      },
      [method_call](const std::string& code, const std::string& message,
                    const awn::Value& details) {
        g_autoptr(FlValue) value = awesome_notifications::ToFlValue(details);
        fl_method_call_respond_error(method_call, code.c_str(), message.c_str(), value, nullptr);
        g_object_unref(method_call);
      });
  if (!handled) {
    fl_method_call_respond_not_implemented(method_call, nullptr);
    g_object_unref(method_call);
  }
}

static void awesome_notifications_plugin_dispose(GObject* object) {
  AwesomeNotificationsPlugin* self = AWESOME_NOTIFICATIONS_PLUGIN(object);
  if (self->bridge != nullptr) {
    awn::AwesomeEventsReceiver::shared().unsubscribe(self->bridge->eventsToken);
    if (self->bridge->view != nullptr)
      g_object_remove_weak_pointer(G_OBJECT(self->bridge->view),
                                   reinterpret_cast<gpointer*>(&self->bridge->view));
    g_clear_object(&self->bridge->channel);
    delete self->bridge;
    self->bridge = nullptr;
  }
  G_OBJECT_CLASS(awesome_notifications_plugin_parent_class)->dispose(object);
}

static void awesome_notifications_plugin_class_init(AwesomeNotificationsPluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = awesome_notifications_plugin_dispose;
}

static void awesome_notifications_plugin_init(AwesomeNotificationsPlugin* self) {
  self->bridge = nullptr;
}

static void method_call_cb(FlMethodChannel* channel, FlMethodCall* method_call,
                           gpointer user_data) {
  awesome_notifications_plugin_handle_method_call(AWESOME_NOTIFICATIONS_PLUGIN(user_data),
                                                  method_call);
}

void awesome_notifications_plugin_register_with_registrar(FlPluginRegistrar* registrar) {
  AwesomeNotificationsPlugin* plugin = AWESOME_NOTIFICATIONS_PLUGIN(
      g_object_new(awesome_notifications_plugin_get_type(), nullptr));

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  FlMethodChannel* channel = fl_method_channel_new(fl_plugin_registrar_get_messenger(registrar),
                                                   "awesome_notifications",
                                                   FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(channel, method_call_cb, g_object_ref(plugin),
                                            g_object_unref);

  auto* bridge = new Bridge();
  bridge->view = fl_plugin_registrar_get_view(registrar);
  if (bridge->view != nullptr)
    g_object_add_weak_pointer(G_OBJECT(bridge->view), reinterpret_cast<gpointer*>(&bridge->view));
  bridge->channel = channel;
  bridge->dispatcher = std::make_shared<GlibDispatcher>();
  plugin->bridge = bridge;

  auto& core = awn::AwesomeNotifications::shared();

  FreedesktopPresenter::Callbacks callbacks;
  callbacks.onDismissed = [](int64_t id) { awn::AwesomeNotifications::shared().onDismissed(id); };
  callbacks.onDisplayed = [](int64_t id) { awn::AwesomeNotifications::shared().onDisplayed(id); };
  callbacks.onActivated = [bridge](const awn::Activation& activation) {
    bridge->OnActivated(activation);
  };
  auto channelOf = [](const awn::ValueMap& model) -> std::optional<awn::ValueMap> {
    auto key = awn::getString(awn::NotificationBuilder::content(model),
                              awn::defs::NOTIFICATION_CHANNEL_KEY);
    return key ? awn::AwesomeNotifications::shared().channel(*key) : std::nullopt;
  };
  callbacks.isSilent = [channelOf](const awn::ValueMap& model) {
    auto channelModel = channelOf(model);
    return channelModel &&
           !awn::getBool(*channelModel, awn::defs::NOTIFICATION_PLAY_SOUND).value_or(true);
  };
  callbacks.importance = [channelOf](const awn::ValueMap& model) {
    auto channelModel = channelOf(model);
    return channelModel
               ? awn::getString(*channelModel, awn::defs::NOTIFICATION_IMPORTANCE).value_or("Default")
               : std::string("Default");
  };

  auto dataDirectory = awesome_notifications::linux_platform::DataDirectory();
  bridge->presenter = std::make_shared<FreedesktopPresenter>(
      dataDirectory, awesome_notifications::linux_platform::AppId(), bridge->dispatcher,
      std::move(callbacks));

  // Phase 1: a notification never starts the app on Linux (no launch action
  // to wait for).
  core.configure(bridge->presenter, bridge->dispatcher,
                 std::make_shared<awn::NotificationStore>(dataDirectory / "notifications.json"),
                 /*launchedByNotification=*/false, [bridge] { return bridge->CurrentLifeCycle(); });
  bridge->router = std::make_unique<awn::AwesomeMethodRouter>(core);

  // Forward core lifecycle events (created/displayed/action/dismissed) to Dart.
  // The core emits them on the platform thread.
  bridge->eventsToken = awn::AwesomeEventsReceiver::shared().subscribe(
      [bridge](const std::string& event, const awn::ValueMap& content) {
        FlValue* arguments = awesome_notifications::ToFlValue(awn::Value(content));
        fl_method_channel_invoke_method(bridge->channel, event.c_str(), arguments, nullptr,
                                        nullptr, nullptr);
        fl_value_unref(arguments);
      });

  bridge->presenter->Start();

  // The plugin lives as long as the engine (the channel handler holds it).
  (void)plugin;
}
