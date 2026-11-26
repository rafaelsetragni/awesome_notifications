#include "awn_schedules/schedules.h"

#include <map>

#include "awn/definitions.h"
#include "awn/exception.h"

namespace awn_schedules {

using awn::AwesomeNotifications;
using awn::AwesomeNotificationsException;
using awn::DateUtils;
using awn::Value;
using awn::ValueList;
using awn::ValueMap;
namespace code = awn::exception_code;

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

/// 0.12 ChannelManager.isChannelEnabled: the channel exists and is not off.
bool isChannelEnabled(AwesomeNotifications& core, const std::string& key) {
  auto channel = core.channel(key);
  return channel &&
         awn::getString(*channel, awn::defs::NOTIFICATION_IMPORTANCE).value_or("Default") != "None";
}

AwesomeNotificationsException invalidArguments(const std::string& message,
                                               const std::string& detail) {
  return AwesomeNotificationsException(code::INVALID_ARGUMENTS, message,
                                       std::string(code::DETAILED_INVALID_ARGUMENTS) + detail);
}

}  // namespace

Zones ZonesOf(AwesomeNotifications& core) {
  Zones zones;
  auto* presenter = core.presenter();
  zones.local = presenter ? presenter->localTimeZone() : awn::defs::UTC_TIMEZONE;
  zones.offsets = [&core](const std::string& zone, awn::TimePoint utc) -> int64_t {
    if (zone == awn::defs::UTC_TIMEZONE || !core.presenter()) return 0;
    return core.presenter()->utcOffset(zone, utc);
  };
  zones.isKnown = [&core](const std::string& zone) {
    return !core.presenter() || core.presenter()->isKnownTimeZone(zone);
  };
  return zones;
}

// MARK: - Builder

ScheduleBuilder::ScheduleBuilder(std::shared_ptr<awn::NotificationBuilder> inner,
                                 AwesomeNotifications& core)
    : awn::NotificationBuilder(std::move(inner)), core_(core) {}

std::optional<awn::BuiltNotification> ScheduleBuilder::build(const ValueMap& model) {
  ValueMap schedule = awn::getMap(model, keys::SCHEDULE);
  // 0.12: an empty / unrecognized schedule block parsed to no schedule, so the
  // notification was delivered immediately.
  if (ScheduleMath::kindOf(schedule) == ScheduleMath::Kind::None) return next(model);

  // 0.12 createNotification: global permission first.
  if (core_.presenter() && !core_.presenter()->isAllowed())
    throw AwesomeNotificationsException(
        code::INSUFFICIENT_PERMISSIONS, "Notifications are disabled",
        std::string(code::DETAILED_INSUFFICIENT_PERMISSIONS) + ".global");

  Zones zones = ZonesOf(core_);
  ScheduleMath::validate(schedule, zones);

  ValueMap content = awn::NotificationBuilder::content(model);
  std::string channelKey = awn::getString(content, awn::defs::NOTIFICATION_CHANNEL_KEY).value_or("");
  if (!isChannelEnabled(core_, channelKey))
    throw AwesomeNotificationsException(
        code::INVALID_ARGUMENTS, "Channel '" + channelKey + "' do not exist or is disabled",
        std::string(code::DETAILED_INSUFFICIENT_PERMISSIONS) + ".channel." + channelKey);

  auto now = DateUtils::now();
  auto dates = ScheduleMath::nextDates(schedule, now, kMaxArmedOccurrences,
                                       now + std::chrono::hours(24 * kArmHorizonDays), zones);
  // No future date: 0.12 dropped any stored schedule with this id and answered
  // false without storing it.
  if (dates.empty()) {
    if (auto id = readId(content)) core_.cancelSchedules({*id});
    return std::nullopt;
  }

  // The stored (and listed) schedule is the parsed one, as 0.12 kept it.
  ValueMap stored = model;
  stored[keys::SCHEDULE] = ScheduleMath::normalized(schedule, zones);
  // Stamp the Schedule source before the base stamps its default (Local); the
  // base's stamp is a no-op once the created date is set.
  auto built = next(stampCreatedLifecycle(stored, awn::LifeCycle::Foreground,
                                          awn::source::SCHEDULE));
  if (!built) return std::nullopt;
  built->fireDate = dates.front();
  built->repeatDates.assign(dates.begin() + 1, dates.end());
  built->trigger = Value(schedule);
  // 0.12 Android answered false for a notification it did schedule.
  built->answer = false;
  return built;
}

// MARK: - Method handler

ScheduleMethodHandler::ScheduleMethodHandler(AwesomeNotifications& core) : core_(core) {}

bool ScheduleMethodHandler::handle(const std::string& name, const Value& arguments,
                                   awn::MethodResult result) {
  return handle(name, arguments, result,
                [result](const std::string&, const std::string&, const Value&) { result(Value()); });
}

bool ScheduleMethodHandler::handle(const std::string& name, const Value& arguments,
                                   awn::MethodResult result, awn::MethodError error) {
  try {
    if (name == method::CANCEL_SCHEDULE) {
      auto id = arguments.isInt() ? arguments.asInt() : std::nullopt;
      if (!id || *id < 0) throw invalidArguments("Invalid id value", ".dismiss.id");
      core_.cancelSchedules({*id});
      result(Value(true));
    } else if (name == method::CANCEL_BY_CHANNEL) {
      auto key = arguments.isString() ? arguments.asString() : std::nullopt;
      if (!key || key->empty())
        throw invalidArguments("Invalid channel Key value", ".dismiss.channelKey");
      core_.cancelSchedules(core_.pendingIdsWhereContent(awn::defs::NOTIFICATION_CHANNEL_KEY, *key));
      result(Value(true));
    } else if (name == method::CANCEL_BY_GROUP) {
      auto key = arguments.isString() ? arguments.asString() : std::nullopt;
      if (!key || key->empty())
        throw invalidArguments("Invalid groupKey value", ".dismiss.groupKey");
      core_.cancelSchedules(core_.pendingIdsWhereContent(awn::defs::NOTIFICATION_GROUP_KEY, *key));
      result(Value(true));
    } else if (name == method::CANCEL_ALL) {
      core_.cancelAllSchedules();
      result(Value(true));
    } else if (name == method::LIST_ALL) {
      Zones zones = ZonesOf(core_);
      ValueList models;
      for (auto model : core_.pendingModels()) {
        ValueMap schedule = awn::getMap(model, keys::SCHEDULE);
        if (ScheduleMath::kindOf(schedule) == ScheduleMath::Kind::None)
          model.erase(keys::SCHEDULE);
        else
          model[keys::SCHEDULE] = ScheduleMath::normalized(schedule, zones);
        models.push_back(Value(model));
      }
      result(Value(std::move(models)));
    } else if (name == method::GET_NEXT_DATE) {
      // 0.12 channelMethodGetNextDate: not validated first; the reply is the
      // wall clock of the resulting calendar's zone ("... <zone>").
      const ValueMap& args = arguments.map();
      ValueMap schedule = awn::getMap(args, keys::SCHEDULE);
      if (ScheduleMath::kindOf(schedule) == ScheduleMath::Kind::None)
        throw invalidArguments("Schedule data is invalid", ".schedule.data");
      std::optional<awn::TimePoint> fixed;
      if (auto text = awn::getString(args, kFixedDate)) fixed = DateUtils::parseUtc(*text);
      Zones zones = ZonesOf(core_);
      auto date = ScheduleMath::nextDate(schedule, fixed.value_or(DateUtils::now()), zones);
      result(date ? Value(ScheduleMath::describe(schedule, *date, zones)) : Value());
    } else {
      return false;
    }
  } catch (const AwesomeNotificationsException& exception) {
    error(exception.code(), exception.what(), Value(exception.details()));
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
    try {
      if (core.rearm(model)) ++rearmed;
    } catch (const AwesomeNotificationsException&) {
      // A schedule that can no longer be armed (e.g. its channel is gone)
      // keeps its remaining occurrences.
    }
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
