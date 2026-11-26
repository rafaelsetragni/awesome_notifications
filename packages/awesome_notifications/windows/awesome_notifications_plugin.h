#ifndef FLUTTER_PLUGIN_AWESOME_NOTIFICATIONS_PLUGIN_H_
#define FLUTTER_PLUGIN_AWESOME_NOTIFICATIONS_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>
#include <optional>

#include "awn/method_router.h"
#include "src/app_identity.h"
#include "src/toast_presenter.h"
#include "src/win_dispatcher.h"

namespace awesome_notifications {

/// Thin Flutter bridge for Windows: the portable desktop core (awn) does the
/// work; this adapts the method channel, the Win32 message loop (dispatcher),
/// the COM toast activator and the app window.
class AwesomeNotificationsPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);

  AwesomeNotificationsPlugin(flutter::PluginRegistrarWindows* registrar,
                             std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel);
  virtual ~AwesomeNotificationsPlugin();

  AwesomeNotificationsPlugin(const AwesomeNotificationsPlugin&) = delete;
  AwesomeNotificationsPlugin& operator=(const AwesomeNotificationsPlugin&) = delete;

  void HandleMethodCall(const flutter::MethodCall<flutter::EncodableValue>& method_call,
                        std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

 private:
  HWND RootWindow() const;
  awn::LifeCycle CurrentLifeCycle() const;
  void OnActivated(const awn::Activation& activation);
  void BringToFront() const;
  std::optional<LRESULT> HandleWindowProc(HWND hwnd, UINT message, WPARAM wparam, LPARAM lparam);

  flutter::PluginRegistrarWindows* registrar_;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;
  AppIdentity identity_;
  std::shared_ptr<WinDispatcher> dispatcher_;
  std::shared_ptr<ToastPresenter> presenter_;
  awn::AwesomeMethodRouter router_;
  int eventsToken_ = 0;
  int windowProcId_ = 0;
};

}  // namespace awesome_notifications

#endif  // FLUTTER_PLUGIN_AWESOME_NOTIFICATIONS_PLUGIN_H_
