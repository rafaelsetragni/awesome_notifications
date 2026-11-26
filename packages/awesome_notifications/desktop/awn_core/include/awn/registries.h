#pragma once

#include <functional>
#include <memory>
#include <mutex>
#include <string>
#include <vector>

#include "awn/export.h"
#include "awn/notification_builder.h"
#include "awn/value.h"

namespace awn {

/// Composes the notification-builder decorator chain. Decorators register a
/// factory with a priority; the composed builder is the base wrapped in
/// ascending priority order, so a higher priority ends up outermost and its
/// `build` runs first — regardless of registration order.
class AWN_API NotificationBuilderRegistry {
 public:
  using Factory =
      std::function<std::shared_ptr<NotificationBuilder>(std::shared_ptr<NotificationBuilder>)>;

  static NotificationBuilderRegistry& shared();

  void registerDecorator(int priority, Factory factory);
  std::shared_ptr<NotificationBuilder> makeBuilder() const;
  void clearForTest();

 private:
  struct Entry {
    int priority;
    Factory make;
  };
  mutable std::mutex mutex_;
  std::vector<Entry> entries_;
};

using MethodResult = std::function<void(const Value&)>;
/// Fails a method call: reaches Dart as a `PlatformException(code, message,
/// details)`.
using MethodError =
    std::function<void(const std::string& code, const std::string& message, const Value& details)>;

/// Decorator seam for the method channel: a handler answers channel methods the
/// core doesn't implement (e.g. the scheduling or localization methods).
class AWN_API AwesomeMethodHandler {
 public:
  virtual ~AwesomeMethodHandler() = default;
  /// If handled, calls `result` exactly once and returns true.
  virtual bool handle(const std::string& method, const Value& arguments,
                      MethodResult result) = 0;

  /// Same as `handle`, but the handler may fail the call with `error` instead
  /// (exactly one of the two is called). Defaults to `handle`, for handlers
  /// that never fail.
  virtual bool handle(const std::string& method, const Value& arguments, MethodResult result,
                      MethodError error) {
    (void)error;
    return handle(method, arguments, std::move(result));
  }
};

class AWN_API AwesomeMethodHandlerRegistry {
 public:
  static AwesomeMethodHandlerRegistry& shared();

  void registerHandler(std::shared_ptr<AwesomeMethodHandler> handler);
  void unregisterHandler(const std::shared_ptr<AwesomeMethodHandler>& handler);
  bool handle(const std::string& method, const Value& arguments, MethodResult result,
              MethodError error = nullptr);
  void clearForTest();

 private:
  std::mutex mutex_;
  std::vector<std::shared_ptr<AwesomeMethodHandler>> handlers_;
};

/// Broadcasts lifecycle events (created/displayed/action/dismissed) to the
/// platform bridge, which forwards them to Dart.
class AWN_API AwesomeEventsReceiver {
 public:
  using Listener = std::function<void(const std::string& event, const ValueMap& content)>;

  static AwesomeEventsReceiver& shared();

  /// Returns a token for `unsubscribe`.
  int subscribe(Listener listener);
  void unsubscribe(int token);
  void notify(const std::string& event, const ValueMap& content);

 private:
  std::mutex mutex_;
  int nextToken_ = 1;
  std::vector<std::pair<int, Listener>> listeners_;
};

}  // namespace awn
