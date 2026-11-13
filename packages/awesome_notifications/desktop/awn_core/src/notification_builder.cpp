#include "awn/notification_builder.h"

namespace awn {

NotificationBuilder::NotificationBuilder(std::shared_ptr<NotificationBuilder> inner)
    : inner_(std::move(inner)) {}

NotificationBuilder::~NotificationBuilder() = default;

std::optional<BuiltNotification> NotificationBuilder::build(const ValueMap& model) {
  // Stamp the created lifecycle BEFORE storing, so it round-trips to the
  // displayed/action events (otherwise a tapped notification reports a null
  // createdDate).
  ValueMap stamped = stampCreatedLifecycle(model);
  auto id = readId(NotificationBuilder::content(stamped));
  if (!id) return std::nullopt;
  BuiltNotification built;
  built.id = *id;
  built.model = std::move(stamped);
  return built;
}

std::optional<BuiltNotification> NotificationBuilder::next(const ValueMap& model) {
  if (!inner_) return std::nullopt;
  return inner_->build(model);
}

ValueMap NotificationBuilder::content(const ValueMap& model) {
  return getMap(model, defs::NOTIFICATION_CONTENT);
}

std::optional<int64_t> NotificationBuilder::readId(const ValueMap& c) {
  return getInt(c, defs::NOTIFICATION_ID);
}

ValueList NotificationBuilder::actionButtons(const ValueMap& model) {
  return getList(model, defs::NOTIFICATION_BUTTONS);
}

std::optional<ValueMap> NotificationBuilder::findButton(const ValueMap& model,
                                                        const std::string& key) {
  if (key.empty()) return std::nullopt;
  for (const auto& button : actionButtons(model)) {
    if (getString(button.map(), defs::NOTIFICATION_BUTTON_KEY).value_or("") == key)
      return button.map();
  }
  return std::nullopt;
}

ValueMap NotificationBuilder::stampCreatedLifecycle(const ValueMap& model,
                                                    LifeCycle lifeCycle,
                                                    const std::string& source) {
  ValueMap result = model;
  ValueMap c = content(model);
  if (!has(c, defs::NOTIFICATION_CREATED_DATE)) {
    c[defs::NOTIFICATION_CREATED_DATE] = DateUtils::nowUtc();
    c[defs::NOTIFICATION_CREATED_LIFECYCLE] = toWire(lifeCycle);
    c[defs::NOTIFICATION_CREATED_SOURCE] = source;
  }
  result[defs::NOTIFICATION_CONTENT] = std::move(c);
  return result;
}

ValueMap NotificationBuilder::stampDisplayedLifecycle(const ValueMap& model,
                                                      const std::string& displayedDate,
                                                      LifeCycle lifeCycle) {
  ValueMap result = model;
  ValueMap c = content(model);
  c[defs::NOTIFICATION_DISPLAYED_DATE] = displayedDate;
  c[defs::NOTIFICATION_DISPLAYED_LIFECYCLE] = toWire(lifeCycle);
  result[defs::NOTIFICATION_CONTENT] = std::move(c);
  return result;
}

BuiltNotification NotificationBuilder::stampDisplayed(const BuiltNotification& built) {
  BuiltNotification result = built;
  if (built.fireDate) {
    result.model = stampDisplayedLifecycle(built.model, DateUtils::formatUtc(*built.fireDate),
                                           LifeCycle::Terminated);
  } else {
    auto created = getString(content(built.model), defs::NOTIFICATION_CREATED_DATE);
    result.model = stampDisplayedLifecycle(
        built.model, created.value_or(DateUtils::nowUtc()), LifeCycle::Foreground);
  }
  return result;
}

ValueMap NotificationBuilder::registerCreatedEvent(const ValueMap& eventContent,
                                                   LifeCycle lifeCycle) {
  // Preserve values already stamped (e.g. a scheduling decorator sets the source
  // to Schedule); only fill what's missing.
  ValueMap map = eventContent;
  if (!has(map, defs::NOTIFICATION_CREATED_DATE))
    map[defs::NOTIFICATION_CREATED_DATE] = DateUtils::nowUtc();
  if (!has(map, defs::NOTIFICATION_CREATED_LIFECYCLE))
    map[defs::NOTIFICATION_CREATED_LIFECYCLE] = toWire(lifeCycle);
  if (!has(map, defs::NOTIFICATION_CREATED_SOURCE))
    map[defs::NOTIFICATION_CREATED_SOURCE] = source::LOCAL;
  return map;
}

ValueMap NotificationBuilder::registerDisplayedEvent(const ValueMap& eventContent,
                                                     LifeCycle lifeCycle) {
  ValueMap map = eventContent;
  map[defs::NOTIFICATION_DISPLAYED_DATE] = DateUtils::nowUtc();
  map[defs::NOTIFICATION_DISPLAYED_LIFECYCLE] = toWire(lifeCycle);
  return map;
}

ValueMap NotificationBuilder::registerActionEvent(const ValueMap& eventContent,
                                                  LifeCycle lifeCycle,
                                                  ActionType actionType) {
  ValueMap map = eventContent;
  map[defs::NOTIFICATION_ACTION_DATE] = DateUtils::nowUtc();
  map[defs::NOTIFICATION_ACTION_LIFECYCLE] = toWire(lifeCycle);
  map[defs::NOTIFICATION_ACTION_TYPE] = toWire(actionType);
  return map;
}

ValueMap NotificationBuilder::registerDismissedEvent(const ValueMap& eventContent,
                                                     LifeCycle lifeCycle) {
  ValueMap map = eventContent;
  map[defs::NOTIFICATION_DISMISSED_DATE] = DateUtils::nowUtc();
  map[defs::NOTIFICATION_ACTION_LIFECYCLE] = toWire(lifeCycle);
  return map;
}

ActionType NotificationBuilder::buttonActionType(const std::optional<ValueMap>& button) {
  if (!button) return ActionType::Default;
  return actionTypeFrom(getString(*button, defs::NOTIFICATION_ACTION_TYPE).value_or(""));
}

bool NotificationBuilder::isDismissAction(const ValueMap& eventContent) {
  return actionTypeFrom(getString(eventContent, defs::NOTIFICATION_ACTION_TYPE).value_or("")) ==
         ActionType::DismissAction;
}

bool NotificationBuilder::shouldButtonAutoDismiss(const std::optional<ValueMap>& button) {
  switch (buttonActionType(button)) {
    case ActionType::DismissAction: return true;
    case ActionType::KeepOnTop: return false;
    default:
      return button ? getBool(*button, defs::NOTIFICATION_AUTO_DISMISSIBLE).value_or(true)
                    : true;
  }
}

}  // namespace awn
