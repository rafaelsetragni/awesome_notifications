#pragma once

#include <glib.h>

#include <chrono>
#include <functional>

#include "awn/platform.h"

namespace awesome_notifications {

/// Runs work on the GLib main loop (the GTK / Flutter platform thread). `post`
/// is safe from any thread.
class GlibDispatcher : public awn::Dispatcher {
 public:
  void post(std::function<void()> work) override;

  /// Runs `work` on the main loop after `delay`; returns a handle for
  /// CancelDelayed (0 never names a timer).
  guint PostDelayed(std::chrono::milliseconds delay, std::function<void()> work);
  void CancelDelayed(guint handle);
};

}  // namespace awesome_notifications
