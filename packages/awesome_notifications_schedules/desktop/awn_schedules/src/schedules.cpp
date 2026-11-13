#include "awn_schedules/schedules.h"

#include <map>

#include "awn/definitions.h"

namespace awn_schedules {

using awn::AwesomeNotifications;
using awn::DateUtils;
using awn::Value;
using awn::ValueList;
using awn::ValueMap;

namespace {

namespace method {
constexpr const char* CANCEL_SCHEDULE = "cancelSchedule";
constexpr const char* CANCEL_BY_CHANNEL = "cancelSchedulesByChannelKey";
constexpr const char* CANCEL_BY_GROUP = "cancelSchedulesByGroupKey";
constexpr const char* CANCEL_ALL = "cancelAllSchedules";
constexpr const char* LIST_ALL = "listAllSchedules";
constexpr const char* GET_NEXT_DATE = "getNextDate";
}  // namespace method

constexpr const char* kFixedDate = "fixedDate";

}  // namespace

OffsetProvider OffsetsOf(AwesomeNotifications& core) {
  return [&core](const std::string& zone, awn::TimePoint utc) -> int64_t {
    if (zone == awn::defs::UTC_TIMEZONE || !core.presenter()) return 0;
    return core.presenter()->utcOffset(zone, utc);
  };
}

std::string LocalZoneOf(AwesomeNotifications& core) {
  return core.presenter() ? core.presenter()->localTimeZone() : awn::defs::UTC_TIMEZONE;
}

// MARK: - Builder

ScheduleBuilder::ScheduleBuilder(std::shared_ptr<awn::NotificationBuilder> inner,
                                 AwesomeNotifications& core)
    : awn::NotificationBuilder(std::move(inner)), core_(core) {}

std::optional<awn::BuiltNotification> ScheduleBuilder::build(const ValueMap& model) {
  ValueMap schedule = awn::getMap(model, keys::SCHEDULE);
  if (schedule.empty()) return next(model);

  auto now = DateUtils::now();
  auto dates = ScheduleMath::nextDates(schedule, now, kMaxArmedOccurrences,
                                       now + std::chrono::hours(24 * kArmHorizonDays),
                                       LocalZoneOf(core_), OffsetsOf(core_));
  // A schedule that never fires again (a past date, an invalid rule) is
  // rejected rather than delivered right away.
  if (dates.empty()) return std::nullopt;

  // Stamp the Schedule source before the base stamps its default (Local); the
  // base's stamp is a no-op once the created date is set.
  auto built = next(stampCreatedLifecycle(model, awn::LifeCycle::Foreground,
                                          awn::source::SCHEDULE));
  if (!built) return std::nullopt;
  built->fireDate = dates.front();
  built->repeatDates.assign(dates.begin() + 1, dates.end());
  built->trigger = Value(schedule);
  return built;
}

// MARK: - Method handler

ScheduleMethodHandler::ScheduleMethodHandler(AwesomeNotifications& core) : core_(core) {}

bool ScheduleMethodHandler::handle(const std::string& name, const Value& arguments,
                                   awn::MethodResult result) {
  if (name == method::CANCEL_SCHEDULE) {
    if (auto id = arguments.asInt()) core_.cancelSchedules({*id});
    result(Value(true));
  } else if (name == method::CANCEL_BY_CHANNEL) {
    if (auto key = arguments.asString())
      core_.cancelSchedules(
          core_.pendingIdsWhereContent(awn::defs::NOTIFICATION_CHANNEL_KEY, *key));
    result(Value(true));
  } else if (name == method::CANCEL_BY_GROUP) {
    if (auto key = arguments.asString())
      core_.cancelSchedules(core_.pendingIdsWhereContent(awn::defs::NOTIFICATION_GROUP_KEY, *key));
    result(Value(true));
  } else if (name == method::CANCEL_ALL) {
    core_.cancelAllSchedules();
    result(Value(true));
  } else if (name == method::LIST_ALL) {
    ValueList models;
    for (const auto& model : core_.pendingModels()) models.push_back(Value(model));
    result(Value(std::move(models)));
  } else if (name == method::GET_NEXT_DATE) {
    const ValueMap& args = arguments.map();
    std::optional<awn::TimePoint> fixed;
    if (auto text = awn::getString(args, kFixedDate)) fixed = DateUtils::parseUtc(*text);
    auto date = ScheduleMath::nextDate(awn::getMap(args, keys::SCHEDULE),
                                       fixed.value_or(DateUtils::now()), LocalZoneOf(core_),
                                       OffsetsOf(core_));
    result(date ? Value(DateUtils::formatUtc(*date)) : Value());
  } else {
    return false;
  }
  return true;
}

// MARK: - Registration / top-up

size_t TopUpRepeatingSchedules(AwesomeNotifications& core) {
  if (!core.presenter()) return 0;
  std::map<int64_t, size_t> armed;
  for (auto id : core.presenter()->pendingIds()) ++armed[id];

  size_t rearmed = 0;
  for (const auto& model : core.pendingModels()) {
    ValueMap schedule = awn::getMap(model, keys::SCHEDULE);
    if (!ScheduleMath::repeats(schedule)) continue;
    auto id = awn::NotificationBuilder::readId(awn::NotificationBuilder::content(model));
    if (!id || armed[*id] > kMaxArmedOccurrences / 2) continue;
    if (core.rearm(model)) ++rearmed;
  }
  return rearmed;
}

void RegisterSchedules(AwesomeNotifications& core) {
  awn::NotificationBuilderRegistry::shared().registerDecorator(
      10, [&core](std::shared_ptr<awn::NotificationBuilder> inner) {
        return std::make_shared<ScheduleBuilder>(std::move(inner), core);
      });
  awn::AwesomeMethodHandlerRegistry::shared().registerHandler(
      std::make_shared<ScheduleMethodHandler>(core));
  if (core.isConfigured()) TopUpRepeatingSchedules(core);
}

}  // namespace awn_schedules
