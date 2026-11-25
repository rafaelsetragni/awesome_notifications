#include "awn/method_router.h"

#include "awn/definitions.h"

namespace awn {

AwesomeMethodRouter::AwesomeMethodRouter(AwesomeNotifications& core) : core_(core) {}

bool AwesomeMethodRouter::handle(const std::string& method, const Value& arguments,
                                 MethodResult result) {
  return handle(method, arguments, std::move(result), nullptr);
}

bool AwesomeMethodRouter::handle(const std::string& method, const Value& arguments,
                                 MethodResult result, MethodError error) {
  if (method == "initialize") {
    core_.initialize(getList(arguments.map(), defs::INITIALIZE_CHANNELS));
    result(Value(true));
  } else if (method == "getLocalTimeZoneIdentifier") {
    result(Value(core_.localTimeZone()));
  } else if (method == "getUtcTimeZoneIdentifier") {
    result(Value(defs::UTC_TIMEZONE));
  } else if (method == "setEventHandles") {
    // Background isolate handles; events are delivered live through the
    // channel, so just acknowledge.
    result(Value(true));
  } else if (method == "getInitialAction") {
    bool removeFromEvents = arguments.asBool().value_or(false);
    core_.getInitialAction(removeFromEvents, [result](const Value& action) { result(action); });
  } else if (method == "isNotificationAllowed") {
    core_.isNotificationAllowed([result](bool allowed) { result(Value(allowed)); });
  } else if (method == "requestNotifications") {
    // Dart expects back the permissions still MISSING after the request.
    ValueList requested = getList(arguments.map(), defs::NOTIFICATION_PERMISSIONS);
    core_.requestPermission([result, requested](bool granted) {
      result(granted ? Value(ValueList{}) : Value(requested));
    });
  } else if (method == "setNotificationChannel") {
    if (arguments.isMap()) core_.setChannel(arguments.map());
    result(Value(true));
  } else if (method == "createNewNotification") {
    if (!arguments.isMap()) {
      result(Value(false));
    } else {
      core_.createNotification(
          arguments.map(), [result](bool created) { result(Value(created)); },
          [result, error](const AwesomeNotificationsException& exception) {
            if (error)
              error(exception.code(), exception.what(), Value(exception.details()));
            else
              result(Value());
          });
    }
  } else if (method == "dismissNotification") {
    if (auto id = arguments.asInt()) core_.dismiss(*id);
    result(Value(true));
  } else if (method == "cancelNotification") {
    if (auto id = arguments.asInt()) core_.cancel(*id);
    result(Value(true));
  } else if (method == "dismissNotificationsByChannelKey") {
    if (auto key = arguments.asString()) core_.dismissByChannelKey(*key);
    result(Value(true));
  } else if (method == "cancelNotificationsByChannelKey") {
    if (auto key = arguments.asString()) core_.cancelByChannelKey(*key);
    result(Value(true));
  } else if (method == "dismissNotificationsByGroupKey") {
    if (auto key = arguments.asString()) core_.dismissByGroupKey(*key);
    result(Value(true));
  } else if (method == "cancelNotificationsByGroupKey") {
    if (auto key = arguments.asString()) core_.cancelByGroupKey(*key);
    result(Value(true));
  } else if (method == "dismissAllNotifications") {
    core_.dismissAll();
    result(Value(true));
  } else if (method == "cancelAllNotifications") {
    core_.cancelAll();
    result(Value(true));
  } else {
    // Let registered decorators (scheduling, localization, …) answer.
    return AwesomeMethodHandlerRegistry::shared().handle(method, arguments, std::move(result),
                                                         std::move(error));
  }
  return true;
}

}  // namespace awn
