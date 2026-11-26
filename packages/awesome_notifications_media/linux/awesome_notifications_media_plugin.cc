#include "include/awesome_notifications_media/awesome_notifications_media_plugin.h"

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>

#include <memory>

#include "awn/awesome_notifications.h"
#include "awesome_notifications/awn_fl_value_codec.h"
#include "awn_media/media.h"
#include "src/mpris_mapping.h"
#include "src/mpris_player.h"

#define AWESOME_NOTIFICATIONS_MEDIA_PLUGIN(obj)                                     \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), awesome_notifications_media_plugin_get_type(), \
                              AwesomeNotificationsMediaPlugin))

struct _AwesomeNotificationsMediaPlugin {
  GObject parent_instance;
};

G_DEFINE_TYPE(AwesomeNotificationsMediaPlugin, awesome_notifications_media_plugin,
              g_object_get_type())

static void awesome_notifications_media_plugin_class_init(
    AwesomeNotificationsMediaPluginClass* klass) {}

static void awesome_notifications_media_plugin_init(AwesomeNotificationsMediaPlugin* self) {}

namespace {

/// The media side of the engine: lives as long as the app (one per process).
struct Media {
  /// The app's view (weak: cleared when it goes). The registrar itself is
  /// released right after registration, so it can't be kept.
  FlView* view = nullptr;
  FlEventChannel* commands = nullptr;
  bool listening = false;
  std::shared_ptr<awn_media::MprisPlayer> player;
  std::shared_ptr<awn_media::MediaController> controller;

  void Raise() const {
    if (view == nullptr) return;
    GtkWidget* toplevel = gtk_widget_get_toplevel(GTK_WIDGET(view));
    if (GTK_IS_WINDOW(toplevel)) gtk_window_present(GTK_WINDOW(toplevel));
  }
};

Media* media = nullptr;

/// The application id (GApplication) or, without one, the program name: the
/// same id the core uses.
std::string AppId() {
  GApplication* app = g_application_get_default();
  const char* id = app ? g_application_get_application_id(app) : nullptr;
  if (id && *id) return id;
  const char* name = g_get_prgname();
  return name && *name ? name : "flutter_app";
}

std::string Identity() {
  const char* name = g_get_application_name();
  return name && *name ? name : AppId();
}

FlMethodErrorResponse* OnListen(FlEventChannel*, FlValue*, gpointer) {
  if (media) media->listening = true;
  return nullptr;
}

FlMethodErrorResponse* OnCancel(FlEventChannel*, FlValue*, gpointer) {
  if (media) media->listening = false;
  return nullptr;
}

}  // namespace

void awesome_notifications_media_plugin_register_with_registrar(FlPluginRegistrar* registrar) {
  if (media != nullptr) return;
  media = new Media();
  media->view = fl_plugin_registrar_get_view(registrar);
  if (media->view)
    g_object_add_weak_pointer(G_OBJECT(media->view), reinterpret_cast<gpointer*>(&media->view));

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  media->commands = fl_event_channel_new(fl_plugin_registrar_get_messenger(registrar),
                                         awn_media::keys::COMMANDS_CHANNEL,
                                         FL_METHOD_CODEC(codec));
  fl_event_channel_set_stream_handlers(media->commands, OnListen, OnCancel, nullptr, nullptr);

  std::string appId = AppId();
  awn_media::MprisPlayer::Callbacks callbacks;
  callbacks.onMethod = [](const std::string& method, int64_t offsetUs,
                          const std::string& trackId, int64_t positionUs) {
    return awn_media::onPlayerMethod(*media->controller, method, offsetUs, trackId, positionUs);
  };
  callbacks.position = [] { return media->controller->position(); };
  callbacks.raise = [] { media->Raise(); };
  media->player = std::make_shared<awn_media::MprisPlayer>(
      appId, Identity(),
      std::filesystem::path(g_get_user_cache_dir()) / appId / "awesome_notifications_media",
      std::move(callbacks));

  media->controller = std::make_shared<awn_media::MediaController>(
      media->player,
      [](const awn::ValueMap& model, const std::string& buttonKey,
         const std::optional<std::string>& input, const awn::ValueMap& button) {
        awn::AwesomeNotifications::shared().dispatchAction(model, buttonKey, input, button);
      },
      [](int64_t id) {
        auto& core = awn::AwesomeNotifications::shared();
        if (core.isConfigured()) core.cancel(id);
      });
  media->controller->setStreamSink([](const awn::ValueMap& event) {
    if (!media->listening) return;
    g_autoptr(FlValue) value = awesome_notifications::ToFlValue(awn::Value(event));
    fl_event_channel_send(media->commands, value, nullptr, nullptr);
  });

  // Plugins register alphabetically: the core plugin already configured the
  // engine. The media builder replaces the freedesktop notification of a
  // MediaPlayer model with the MPRIS player.
  awn_media::RegisterMedia(media->controller, awn_media::mprisCapabilities(),
                           awn::AwesomeNotifications::shared());
}
