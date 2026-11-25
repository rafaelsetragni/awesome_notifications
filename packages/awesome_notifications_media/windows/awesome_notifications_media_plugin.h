#ifndef FLUTTER_PLUGIN_AWESOME_NOTIFICATIONS_MEDIA_PLUGIN_H_
#define FLUTTER_PLUGIN_AWESOME_NOTIFICATIONS_MEDIA_PLUGIN_H_

#include <flutter/encodable_value.h>
#include <flutter/event_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <deque>
#include <functional>
#include <memory>
#include <mutex>
#include <optional>

#include "awn_media/media.h"
#include "smtc_surface.h"

namespace awesome_notifications_media {

/// Runs work on the platform thread: posts a private message to the app's
/// top-level window, drained by the plugin's window-proc delegate.
class PlatformThread {
 public:
  PlatformThread();
  /// Thread-safe. Dropped until a window is set.
  void Post(std::function<void()> work);
  /// Platform thread.
  void SetWindow(HWND window);
  std::optional<LRESULT> Handle(UINT message);
  void Detach();

 private:
  UINT message_;
  std::mutex mutex_;
  HWND window_ = nullptr;
  std::deque<std::function<void()>> queue_;
};

/// Windows side of awesome_notifications_media: shows MediaPlayer models as the
/// window's system media controls (SystemMediaTransportControls). The Dart side
/// talks through the core `awesome_notifications` channel (the media methods
/// are a handler in the core's registry); the commands also go to the
/// `awesome_notifications_media/commands` event channel.
class AwesomeNotificationsMediaPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);

  explicit AwesomeNotificationsMediaPlugin(flutter::PluginRegistrarWindows* registrar);
  virtual ~AwesomeNotificationsMediaPlugin();

  AwesomeNotificationsMediaPlugin(const AwesomeNotificationsMediaPlugin&) = delete;
  AwesomeNotificationsMediaPlugin& operator=(const AwesomeNotificationsMediaPlugin&) = delete;

 private:
  HWND RootWindow() const;

  flutter::PluginRegistrarWindows* registrar_;
  std::shared_ptr<PlatformThread> thread_;
  std::shared_ptr<SmtcSurface> surface_;
  std::shared_ptr<awn_media::MediaController> controller_;
  std::unique_ptr<flutter::EventChannel<flutter::EncodableValue>> commands_;
  int windowProcId_ = 0;
};

}  // namespace awesome_notifications_media

#endif  // FLUTTER_PLUGIN_AWESOME_NOTIFICATIONS_MEDIA_PLUGIN_H_
