#pragma once

#include <functional>
#include <map>
#include <optional>
#include <string>
#include <vector>

#include "awn/export.h"
#include "awn/notification_builder.h"

namespace awn {

/// Runs work on the platform (UI) thread — the only thread allowed to talk to
/// the Flutter channel. Results and events always reach the bridge through it.
class AWN_API Dispatcher {
 public:
  virtual ~Dispatcher() = default;
  virtual void post(std::function<void()> work) = 0;
};

/// The OS notification system, as the portable engine needs it. Windows
/// implements it with WinRT toasts; Linux with freedesktop notifications.
class AWN_API NotificationPresenter {
 public:
  virtual ~NotificationPresenter() = default;

  /// Shows (or schedules, when `built.fireDate` is set) a notification. May run
  /// asynchronously; `done` may be called on any thread.
  virtual void present(const BuiltNotification& built, std::function<void(bool)> done) = 0;

  virtual void removeDelivered(const std::vector<int64_t>& ids) = 0;
  virtual void removeAllDelivered() = 0;
  virtual void removePending(const std::vector<int64_t>& ids) = 0;
  virtual void removeAllPending() = 0;
  /// Ids currently shown by the OS (Action Center on Windows).
  virtual std::vector<int64_t> deliveredIds() = 0;
  /// Ids scheduled for a future delivery.
  virtual std::vector<int64_t> pendingIds() = 0;

  virtual bool isAllowed() = 0;
  /// Desktop systems don't prompt: an implementation may open the OS settings
  /// page and report the state after it.
  virtual void requestPermission(std::function<void(bool)> done) = 0;

  /// IANA identifier of the local time zone (e.g. "America/Sao_Paulo").
  virtual std::string localTimeZone() = 0;
};

/// A notification (or one of its buttons) activated by the user.
struct Activation {
  std::string arguments;
  /// Text typed into the notification's input fields, by input id (button key).
  std::map<std::string, std::string> userInputs;
};

/// The activation string a notification carries back: which notification and,
/// for a button, which key. Encoded as "awn&id=<id>[&btn=<percent-encoded key>]".
struct LaunchArgs {
  int64_t id = 0;
  std::string buttonKey;

  AWN_API static std::string encode(int64_t id, const std::string& buttonKey = "");
  AWN_API static std::optional<LaunchArgs> decode(const std::string& arguments);
};

}  // namespace awn
