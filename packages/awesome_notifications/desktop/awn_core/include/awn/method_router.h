#pragma once

#include <string>

#include "awn/awesome_notifications.h"
#include "awn/export.h"
#include "awn/registries.h"
#include "awn/value.h"

namespace awn {

/// Routes the `awesome_notifications` method-channel protocol to the engine —
/// the desktop twin of the Apple core's AwesomeMethodRouter. Flutter-free: the
/// bridge converts the codec values, answers platform-only methods and reports
/// "not implemented" when this returns false. Unknown methods fall through to
/// the decorators registered in AwesomeMethodHandlerRegistry.
class AWN_API AwesomeMethodRouter {
 public:
  explicit AwesomeMethodRouter(AwesomeNotifications& core = AwesomeNotifications::shared());

  /// Calls `result` exactly once and returns true, or returns false (without
  /// calling `result`) when nobody implements `method`.
  bool handle(const std::string& method, const Value& arguments, MethodResult result);
  /// Same, but a failing call (e.g. a decorator rejecting a notification)
  /// answers `error` instead; without one it answers a null result.
  bool handle(const std::string& method, const Value& arguments, MethodResult result,
              MethodError error);

 private:
  AwesomeNotifications& core_;
};

}  // namespace awn
