#ifndef FLUTTER_PLUGIN_AWESOME_NOTIFICATIONS_CALLS_PLUGIN_H_
#define FLUTTER_PLUGIN_AWESOME_NOTIFICATIONS_CALLS_PLUGIN_H_

#include <windows.h>

#include <flutter/encodable_value.h>
#include <flutter/event_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <functional>
#include <memory>

#include "awn_calls/calls.h"

namespace awesome_notifications_calls {

/// Windows side of awesome_notifications_calls. Windows has no system call UI
/// for desktop apps: a call is a toast with scenario="incomingCall" (it stays
/// on screen and loops the ringing sound) with Accept / Decline, then an
/// ongoing toast with Hang up, drawn by the core's toast presenter from the
/// hints of the call builder (desktop/calls_core). The Dart side talks through
/// the core `awesome_notifications` channel (the call methods are a handler in
/// the core's registry); the commands also go to the
/// `awesome_notifications_calls/events` event channel.
class AwesomeNotificationsCallsPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);

  explicit AwesomeNotificationsCallsPlugin(flutter::PluginRegistrarWindows* registrar);
  virtual ~AwesomeNotificationsCallsPlugin();

  AwesomeNotificationsCallsPlugin(const AwesomeNotificationsCallsPlugin&) = delete;
  AwesomeNotificationsCallsPlugin& operator=(const AwesomeNotificationsCallsPlugin&) = delete;

  /// Runs `work` once on the platform thread after `ms` (a thread timer of
  /// the platform thread: its message loop runs the callback).
  static void After(int64_t ms, std::function<void()> work);

 private:
  std::shared_ptr<awn_calls::CallController> controller_;
  std::unique_ptr<flutter::EventChannel<flutter::EncodableValue>> events_;
};

}  // namespace awesome_notifications_calls

#endif  // FLUTTER_PLUGIN_AWESOME_NOTIFICATIONS_CALLS_PLUGIN_H_
