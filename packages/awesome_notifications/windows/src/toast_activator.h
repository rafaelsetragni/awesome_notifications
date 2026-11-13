#pragma once

#include <windows.h>

#include <functional>

#include "awn/platform.h"

namespace awesome_notifications {

/// Registers the COM class Windows calls (INotificationActivationCallback) when
/// the user activates one of the app's toasts or toast buttons. If the app is
/// not running, Windows starts it with `-ToastActivated` and calls in as soon as
/// the class is registered here — the "launched by a notification" path.
class ToastActivator {
 public:
  using Callback = std::function<void(const awn::Activation&)>;

  /// Registers the class object for `clsid`; `callback` runs on the thread COM
  /// calls in on (the bridge re-posts it to the platform thread).
  static bool Register(const GUID& clsid, Callback callback);
  static void Unregister();
};

}  // namespace awesome_notifications
