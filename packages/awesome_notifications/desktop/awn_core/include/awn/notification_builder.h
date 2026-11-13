#pragma once

#include <memory>
#include <optional>
#include <string>
#include <vector>

#include "awn/date_utils.h"
#include "awn/definitions.h"
#include "awn/export.h"
#include "awn/value.h"

namespace awn {

/// The deliverable produced by the builder chain: the (possibly
/// decorator-transformed) model plus an optional delivery time contributed by a
/// scheduling decorator. The platform presenter renders it.
struct BuiltNotification {
  int64_t id = 0;
  ValueMap model;
  /// When to deliver; nullopt delivers immediately.
  std::optional<TimePoint> fireDate;
  /// Later occurrences of a repeating schedule, pre-armed with the same id
  /// (desktop systems only schedule one-shot notifications).
  std::vector<TimePoint> repeatDates;
  /// Decorator-owned delivery data (e.g. the repeat rule a scheduling decorator
  /// needs to re-arm a repeating schedule). Opaque to the core.
  Value trigger;
};

/// Builds notifications from a serialized `NotificationModel` (the map produced
/// by the Dart `NotificationModel.toMap()`) and stamps the lifecycle events.
///
/// Decorators subclass it, override `build`, do their work and delegate to the
/// wrapped builder through `next` — the same decorator chain as the Apple and
/// Android cores.
class AWN_API NotificationBuilder {
 public:
  explicit NotificationBuilder(std::shared_ptr<NotificationBuilder> inner = nullptr);
  virtual ~NotificationBuilder();

  /// Produces the deliverable for a model, or nullopt when it is invalid.
  virtual std::optional<BuiltNotification> build(const ValueMap& model);

  /// Delegates to the wrapped builder (called by decorators).
  std::optional<BuiltNotification> next(const ValueMap& model);

  // Model access
  static ValueMap content(const ValueMap& model);
  static std::optional<int64_t> readId(const ValueMap& content);
  static ValueList actionButtons(const ValueMap& model);
  static std::optional<ValueMap> findButton(const ValueMap& model, const std::string& key);

  // Lifecycle stamping, persisted into the model's content.
  static ValueMap stampCreatedLifecycle(const ValueMap& model,
                                        LifeCycle lifeCycle = LifeCycle::Foreground,
                                        const std::string& source = awn::source::LOCAL);
  static ValueMap stampDisplayedLifecycle(const ValueMap& model,
                                          const std::string& displayedDate,
                                          LifeCycle lifeCycle);
  /// Bakes the predicted displayed lifecycle: immediate → displayed == created
  /// (foreground); scheduled → the fire date, terminated (nobody knows the app
  /// state at fire time).
  static BuiltNotification stampDisplayed(const BuiltNotification& built);

  // Event stamping (returns the content map sent to Dart).
  static ValueMap registerCreatedEvent(const ValueMap& content, LifeCycle lifeCycle);
  static ValueMap registerDisplayedEvent(const ValueMap& content, LifeCycle lifeCycle);
  static ValueMap registerActionEvent(const ValueMap& content, LifeCycle lifeCycle,
                                      ActionType actionType = ActionType::Default);
  static ValueMap registerDismissedEvent(const ValueMap& content, LifeCycle lifeCycle);

  // Action concepts
  static ActionType buttonActionType(const std::optional<ValueMap>& button);
  /// A DismissAction notification behaves like a user dismissal.
  static bool isDismissAction(const ValueMap& content);
  /// DismissAction always dismisses; KeepOnTop never; otherwise the button's
  /// autoDismissible flag (default true).
  static bool shouldButtonAutoDismiss(const std::optional<ValueMap>& button);

 private:
  std::shared_ptr<NotificationBuilder> inner_;
};

}  // namespace awn
