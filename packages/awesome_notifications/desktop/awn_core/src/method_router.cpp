#include "awn/method_router.h"

#include "awn/definitions.h"

namespace awn {

namespace {
// What a desktop notification server lets the user turn on or off: the
// notification itself and its sound. Everything else (badge, vibration,
// light, critical alerts, full-screen, …) has no desktop meaning.
bool isDesktopPermission(const std::string& name) {
  return name == "Alert" || name == "Sound";
}
}  // namespace

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
  } else if (method == "checkPermissions") {
    // The requested permissions that are granted now.
    ValueList requested = getList(arguments.map(), defs::NOTIFICATION_PERMISSIONS);
    core_.isNotificationAllowed([result, requested](bool allowed) {
      ValueList granted;
      if (allowed)
        for (const auto& permission : requested)
          if (isDesktopPermission(permission.asString().value_or(""))) granted.push_back(permission);
      result(Value(granted));
    });
  } else if (method == "getPermissionStatuses") {
    // 0.12.1 contract: permission name -> granted | denied | notSupported.
    ValueList requested = getList(arguments.map(), defs::NOTIFICATION_PERMISSIONS);
    core_.isNotificationAllowed([result, requested](bool allowed) {
      ValueMap statuses;
      for (const auto& permission : requested) {
        std::string name = permission.asString().value_or("");
        if (name.empty()) continue;
        statuses[name] = Value(!isDesktopPermission(name) ? "notSupported"
                               : allowed                  ? "granted"
                                                          : "denied");
      }
      result(Value(statuses));
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
