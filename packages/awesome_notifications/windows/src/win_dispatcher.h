#pragma once

#include <windows.h>

#include <chrono>
#include <deque>
#include <functional>
#include <map>
#include <mutex>
#include <optional>

#include "awn/platform.h"

namespace awesome_notifications {

/// Runs work on the Flutter platform thread by posting a private message to the
/// app's top-level window; the plugin's window-proc delegate drains it. Also
/// runs delayed work through window timers (used to report a scheduled
/// notification as displayed when it fires while the app is running).
class WinDispatcher : public awn::Dispatcher {
 public:
  explicit WinDispatcher(HWND window);

  /// Thread-safe.
  void post(std::function<void()> work) override;

  /// Platform thread only. Returns a handle for CancelDelayed.
  UINT_PTR PostDelayed(std::chrono::milliseconds delay, std::function<void()> work);
  void CancelDelayed(UINT_PTR handle);

  /// Feed from the top-level window proc; returns a result when it handled the
  /// message.
  std::optional<LRESULT> HandleMessage(UINT message, WPARAM wparam, LPARAM lparam);

  /// Stops posting (plugin teardown).
  void Detach();

 private:
  void Drain();

  HWND window_;
  UINT message_;
  std::mutex mutex_;
  std::deque<std::function<void()>> queue_;
  std::map<UINT_PTR, std::function<void()>> timers_;
  UINT_PTR nextTimer_;
};

}  // namespace awesome_notifications
