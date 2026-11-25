#pragma once

#include <memory>
#include <string>

#include "awn/awesome_notifications.h"
#include "awn/notification_builder.h"
#include "awn/registries.h"
#include "awn_schedules/schedule_math.h"

namespace awn_schedules {

/// How many occurrences of a repeating schedule are pre-armed at once, and how
/// far ahead. Desktop systems can't run plugin code while the app is closed, so
/// a repeating schedule keeps firing until these run out; they are topped up
/// whenever the app runs.
inline constexpr size_t kMaxArmedOccurrences = 64;
inline constexpr int kArmHorizonDays = 366;

/// Builder decorator: gives a notification carrying a `schedule` its fire date
/// (and the pre-armed later occurrences of a repeating one), and stamps its
/// created source as Schedule. Without a schedule it just delegates.
///
/// It answers the create call like 0.12 on Android (the desktop reference):
/// false once scheduled (or when the schedule has no next date, then not
/// stored); an error for an invalid schedule, a missing / disabled channel or
/// notifications not allowed.
class ScheduleBuilder : public awn::NotificationBuilder {
 public:
  ScheduleBuilder(std::shared_ptr<awn::NotificationBuilder> inner, awn::AwesomeNotifications& core);

  std::optional<awn::BuiltNotification> build(const awn::ValueMap& model) override;

 private:
  awn::AwesomeNotifications& core_;
};

/// Answers the schedule-only channel methods of AwesomeNotificationsSchedules.
/// A schedule is a pending (not yet delivered) notification: cancelling one
/// leaves an already-delivered notification with the same id on screen.
class ScheduleMethodHandler : public awn::AwesomeMethodHandler {
 public:
  explicit ScheduleMethodHandler(awn::AwesomeNotifications& core);

  bool handle(const std::string& method, const awn::Value& arguments,
              awn::MethodResult result) override;
  bool handle(const std::string& method, const awn::Value& arguments, awn::MethodResult result,
              awn::MethodError error) override;

 private:
  awn::AwesomeNotifications& core_;
};

/// The time-zone services of the platform presenter, as ScheduleMath needs them.
Zones ZonesOf(awn::AwesomeNotifications& core);

/// Registers the decorator + method handler in the core registries and tops up
/// the pre-armed occurrences of the repeating schedules. Call once, after the
/// core plugin configured the engine.
void RegisterSchedules(awn::AwesomeNotifications& core = awn::AwesomeNotifications::shared());

/// Re-arms every repeating schedule that is running low on pre-armed
/// occurrences. Returns how many were re-armed.
size_t TopUpRepeatingSchedules(awn::AwesomeNotifications& core);

}  // namespace awn_schedules
