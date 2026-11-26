#ifndef FLUTTER_PLUGIN_AWESOME_NOTIFICATIONS_LIVE_ACTIVITIES_PLUGIN_H_
#define FLUTTER_PLUGIN_AWESOME_NOTIFICATIONS_LIVE_ACTIVITIES_PLUGIN_H_

#include <windows.h>

#include <flutter/encodable_value.h>
#include <flutter/event_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <deque>
#include <functional>
#include <map>
#include <memory>
#include <mutex>
#include <optional>
#include <string>

#include <winrt/Windows.UI.Notifications.h>

#include "awn_live/live.h"

namespace awesome_notifications_live_activities {

/// Windows side of awesome_notifications_live_activities. Windows has no live
/// activity surface for desktop apps: an activity is a toast with a data-bound
/// progress bar (desktop/live_core builds it), shown once and then updated in
/// place through its NotificationData (tag + group, an increasing sequence
/// number), so an update doesn't pop again unless it alerts. This plugin shows
/// these toasts itself (the core's presenter has no data binding), as the
/// core's app identity with the core's tag (the id) and group, so the core's
/// cancel / dismiss / history reach them as any other toast. The Dart side
/// talks through the core `awesome_notifications` channel (the methods are a
/// handler in the core's registry); state changes go to the
/// `awesome_notifications_live_activities/events` event channel.
class AwesomeNotificationsLiveActivitiesPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);

  explicit AwesomeNotificationsLiveActivitiesPlugin(flutter::PluginRegistrarWindows* registrar);
  virtual ~AwesomeNotificationsLiveActivitiesPlugin();

  AwesomeNotificationsLiveActivitiesPlugin(const AwesomeNotificationsLiveActivitiesPlugin&) =
      delete;
  AwesomeNotificationsLiveActivitiesPlugin& operator=(
      const AwesomeNotificationsLiveActivitiesPlugin&) = delete;

  /// Runs `work` once on the platform thread after `ms` (a thread timer of
  /// the platform thread: its message loop runs the callback).
  static void After(int64_t ms, std::function<void()> work);

 private:
  /// Runs work on the platform thread: posts a private message to the app's
  /// top-level window, drained by this plugin's window-proc delegate. Shared
  /// with the toast event handlers (WinRT threads), which may outlive the
  /// plugin.
  struct Dispatch {
    std::mutex mutex;
    std::deque<std::function<void()>> queue;
    HWND window = nullptr;
    UINT message = 0;
    /// Thread-safe; dropped after Detach.
    void Post(std::function<void()> work);
    void Drain();
    void Detach();
  };

  /// Shows or updates the toast of an activity (LiveHost::present).
  void Present(const awn::BuiltNotification& built, std::function<void(bool)> done);
  winrt::Windows::UI::Notifications::ToastNotifier Notifier();
  HWND RootWindow() const;

  flutter::PluginRegistrarWindows* registrar_;
  int windowProcId_ = 0;
  std::shared_ptr<Dispatch> dispatch_;

  bool packaged_ = false;
  std::wstring aumid_;
  winrt::Windows::UI::Notifications::ToastNotifier notifier_{nullptr};
  /// Shown toasts are kept alive so their events keep arriving.
  std::map<int64_t, winrt::Windows::UI::Notifications::ToastNotification> shown_;

  std::shared_ptr<awn_live::LiveController> controller_;
  std::unique_ptr<flutter::EventChannel<flutter::EncodableValue>> events_;
};

}  // namespace awesome_notifications_live_activities

#endif  // FLUTTER_PLUGIN_AWESOME_NOTIFICATIONS_LIVE_ACTIVITIES_PLUGIN_H_
