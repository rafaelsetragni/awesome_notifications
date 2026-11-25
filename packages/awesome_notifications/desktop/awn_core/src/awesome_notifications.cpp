#include "awn/awesome_notifications.h"

#include <algorithm>
#include <set>

#include "awn/definitions.h"
#include "awn/registries.h"

namespace awn {

namespace {
bool contains(const std::vector<int64_t>& ids, int64_t id) {
  return std::find(ids.begin(), ids.end(), id) != ids.end();
}
}  // namespace

AwesomeNotifications& AwesomeNotifications::shared() {
  static AwesomeNotifications instance;
  return instance;
}

AwesomeNotifications::AwesomeNotifications() = default;

void AwesomeNotifications::configure(std::shared_ptr<NotificationPresenter> presenter,
                                     std::shared_ptr<Dispatcher> dispatcher,
                                     std::shared_ptr<NotificationStore> store,
                                     bool launchedByNotification,
                                     LifeCycleProvider lifeCycle) {
  presenter_ = std::move(presenter);
  dispatcher_ = std::move(dispatcher);
  store_ = std::move(store);
  lifeCycle_ = std::move(lifeCycle);
  launchedByNotification_ = launchedByNotification;
  didFinishLaunch_ = false;
  initialAction_ = Value();
  pendingInitialAction_ = nullptr;
  // A normal launch has no launch action to wait for.
  if (!launchedByNotification_) didFinishLaunch_ = true;
}

// MARK: - Setup

void AwesomeNotifications::initialize(const ValueList& channels) {
  for (const auto& entry : channels) setChannel(entry.map());

  // Drop models of notifications the OS no longer has (cleared from the
  // notification center while the app was closed).
  auto delivered = presenter_->deliveredIds();
  auto pending = presenter_->pendingIds();
  store_->retainWhere([&](int64_t id) { return contains(delivered, id) || contains(pending, id); });
}

void AwesomeNotifications::setChannel(const ValueMap& channelModel) {
  auto key = getString(channelModel, defs::NOTIFICATION_CHANNEL_KEY);
  if (key) channels_[*key] = channelModel;
}

std::optional<ValueMap> AwesomeNotifications::channel(const std::string& key) const {
  auto it = channels_.find(key);
  if (it == channels_.end()) return std::nullopt;
  return it->second;
}

// MARK: - Permissions

void AwesomeNotifications::isNotificationAllowed(std::function<void(bool)> done) {
  done(presenter_->isAllowed());
}

void AwesomeNotifications::requestPermission(std::function<void(bool)> done) {
  auto dispatcher = dispatcher_;
  presenter_->requestPermission([dispatcher, done](bool granted) {
    dispatcher->post([done, granted] { done(granted); });
  });
}

std::string AwesomeNotifications::localTimeZone() { return presenter_->localTimeZone(); }

// MARK: - Launch / initial action

void AwesomeNotifications::finishLaunching() {
  if (didFinishLaunch_) return;
  didFinishLaunch_ = true;
  if (pendingInitialAction_) {
    Value action = initialAction_;
    if (removeInitialActionFromEvents_) initialAction_ = Value();
    auto done = std::move(pendingInitialAction_);
    pendingInitialAction_ = nullptr;
    done(action);
  }
}

void AwesomeNotifications::getInitialAction(bool removeFromEvents,
                                            std::function<void(const Value&)> done) {
  if (didFinishLaunch_) {
    Value action = initialAction_;
    if (removeFromEvents) initialAction_ = Value();
    done(action);
    return;
  }
  removeInitialActionFromEvents_ = removeFromEvents;
  pendingInitialAction_ = std::move(done);
}

// MARK: - Create

void AwesomeNotifications::createNotification(
    const ValueMap& model, std::function<void(bool)> done,
    std::function<void(const AwesomeNotificationsException&)> fail) {
  // Build through the decorator chain (localization, scheduling, …).
  auto builder = NotificationBuilderRegistry::shared().makeBuilder();
  std::optional<BuiltNotification> chained;
  try {
    chained = builder->build(model);
  } catch (const AwesomeNotificationsException& exception) {
    if (fail)
      fail(exception);
    else
      done(false);
    return;
  }
  if (!chained) {
    done(false);
    return;
  }
  BuiltNotification built = NotificationBuilder::stampDisplayed(*chained);

  // A new notification reusing an id starts with no display record.
  tracker_.forget(built.id);
  store_->put(built.id, built.model);

  auto dispatcher = dispatcher_;
  presenter_->present(built, [this, dispatcher, built, done](bool presented) {
    dispatcher->post([this, built, done, presented] {
      if (!presented) {
        store_->remove(built.id);
        done(false);
        return;
      }
      ValueMap content = NotificationBuilder::content(built.model);
      emit(defs::EVENT_NOTIFICATION_CREATED,
           NotificationBuilder::registerCreatedEvent(content, LifeCycle::Foreground));
      if (!built.fireDate) onDisplayed(built.id);
      done(built.answer.value_or(true));
    });
  });
}

// MARK: - OS callbacks

void AwesomeNotifications::onDisplayed(int64_t id) {
  auto model = store_->get(id);
  if (!model) return;
  LifeCycle lifeCycle = currentLifeCycle();
  ValueMap displayed =
      NotificationBuilder::registerDisplayedEvent(NotificationBuilder::content(*model), lifeCycle);
  if (lifeCycle == LifeCycle::Foreground) {
    tracker_.recordForegroundDisplay(
        id, getString(displayed, defs::NOTIFICATION_DISPLAYED_DATE).value_or(""));
  }
  emit(defs::EVENT_NOTIFICATION_DISPLAYED, displayed);
}

std::optional<ActionType> AwesomeNotifications::onActivated(const Activation& activation) {
  auto args = LaunchArgs::decode(activation.arguments);
  if (!args) return std::nullopt;
  auto model = store_->get(args->id);
  if (!model) {
    // Not ours anymore (store pruned) — still settle a pending launch.
    finishLaunching();
    return std::nullopt;
  }

  // The stored content carries the displayed lifecycle predicted at creation;
  // correct it if the notification was shown while the app was running.
  ValueMap content = tracker_.resolve(NotificationBuilder::content(*model), args->id);
  const std::string& buttonKey = args->buttonKey;
  auto pressedButton = NotificationBuilder::findButton(*model, buttonKey);
  ActionType actionType = NotificationBuilder::buttonActionType(pressedButton);

  if (!buttonKey.empty()) {
    content[defs::NOTIFICATION_BUTTON_KEY_PRESSED] = buttonKey;
    auto input = activation.userInputs.find(buttonKey);
    if (input != activation.userInputs.end())
      content[defs::NOTIFICATION_BUTTON_KEY_INPUT] = input->second;
  }

  bool isDismiss = (buttonKey.empty() && NotificationBuilder::isDismissAction(content)) ||
                   actionType == ActionType::DismissAction;

  if (isDismiss) {
    presenter_->removeDelivered({args->id});
    emit(defs::EVENT_NOTIFICATION_DISMISSED,
         NotificationBuilder::registerDismissedEvent(content, LifeCycle::Foreground));
    forgetIfGone(args->id);
    finishLaunching();
    return ActionType::DismissAction;
  }

  // An activated toast leaves the screen; honor KeepOnTop / autoDismissible=false
  // as far as the OS lets us (the toast is already gone on Windows).
  if (buttonKey.empty() || NotificationBuilder::shouldButtonAutoDismiss(pressedButton)) {
    presenter_->removeDelivered({args->id});
  }

  // Before the launch settles, this activation is the one that started the app.
  bool launchAction = !didFinishLaunch_;
  ValueMap actionMap = NotificationBuilder::registerActionEvent(
      content, launchAction ? LifeCycle::Terminated : currentLifeCycle(), actionType);
  if (launchAction) {
    initialAction_ = actionMap;
    finishLaunching();
  }
  emit(defs::EVENT_DEFAULT_ACTION, actionMap);
  forgetIfGone(args->id);
  return actionType;
}

void AwesomeNotifications::onDismissed(int64_t id) {
  auto model = store_->get(id);
  if (!model) return;
  ValueMap content = tracker_.resolve(NotificationBuilder::content(*model), id);
  emit(defs::EVENT_NOTIFICATION_DISMISSED,
       NotificationBuilder::registerDismissedEvent(content, currentLifeCycle()));
  forgetIfGone(id);
}

// MARK: - Dismiss / cancel

void AwesomeNotifications::dismissIds(const std::vector<int64_t>& ids) {
  if (ids.empty()) return;
  presenter_->removeDelivered(ids);
  for (auto id : ids) {
    tracker_.forget(id);
    forgetIfGone(id);
  }
}

void AwesomeNotifications::cancelIds(const std::vector<int64_t>& ids) {
  if (ids.empty()) return;
  presenter_->removePending(ids);
  presenter_->removeDelivered(ids);
  for (auto id : ids) tracker_.forget(id);
  store_->remove(ids);
}

void AwesomeNotifications::dismiss(int64_t id) { dismissIds({id}); }

void AwesomeNotifications::cancel(int64_t id) { cancelIds({id}); }

void AwesomeNotifications::dismissByChannelKey(const std::string& key) {
  dismissIds(store_->idsWhereContent(defs::NOTIFICATION_CHANNEL_KEY, key));
}

void AwesomeNotifications::cancelByChannelKey(const std::string& key) {
  cancelIds(store_->idsWhereContent(defs::NOTIFICATION_CHANNEL_KEY, key));
}

void AwesomeNotifications::dismissByGroupKey(const std::string& key) {
  dismissIds(store_->idsWhereContent(defs::NOTIFICATION_GROUP_KEY, key));
}

void AwesomeNotifications::cancelByGroupKey(const std::string& key) {
  cancelIds(store_->idsWhereContent(defs::NOTIFICATION_GROUP_KEY, key));
}

void AwesomeNotifications::dismissAll() {
  presenter_->removeAllDelivered();
  tracker_.forgetAll();
  auto pending = presenter_->pendingIds();
  store_->retainWhere([&](int64_t id) { return contains(pending, id); });
}

void AwesomeNotifications::cancelAll() {
  presenter_->removeAllPending();
  presenter_->removeAllDelivered();
  tracker_.forgetAll();
  store_->removeAll();
}

// MARK: - Schedules

bool AwesomeNotifications::rearm(const ValueMap& model) {
  auto chained = NotificationBuilderRegistry::shared().makeBuilder()->build(model);
  if (!chained || !chained->fireDate) return false;
  BuiltNotification built = NotificationBuilder::stampDisplayed(*chained);
  store_->put(built.id, built.model);
  presenter_->present(built, [](bool) {});
  return true;
}

std::vector<ValueMap> AwesomeNotifications::pendingModels() {
  std::vector<ValueMap> models;
  std::set<int64_t> seen;
  for (auto id : presenter_->pendingIds()) {
    if (!seen.insert(id).second) continue;  // one entry per pre-armed occurrence
    if (auto model = store_->get(id)) models.push_back(*model);
  }
  return models;
}

void AwesomeNotifications::cancelSchedules(const std::vector<int64_t>& ids) {
  if (ids.empty()) return;
  presenter_->removePending(ids);
  // Keep the model of a schedule whose notification is still on screen.
  auto delivered = presenter_->deliveredIds();
  for (auto id : ids) {
    if (!contains(delivered, id)) store_->remove(id);
  }
}

void AwesomeNotifications::cancelAllSchedules() {
  auto pending = presenter_->pendingIds();
  std::set<int64_t> unique(pending.begin(), pending.end());
  cancelSchedules(std::vector<int64_t>(unique.begin(), unique.end()));
}

std::vector<int64_t> AwesomeNotifications::pendingIdsWhereContent(const std::string& key,
                                                                   const std::string& value) {
  auto pending = presenter_->pendingIds();
  std::vector<int64_t> result;
  for (auto id : store_->idsWhereContent(key, value)) {  // store ids are unique
    if (contains(pending, id)) result.push_back(id);
  }
  return result;
}

// MARK: - Helpers

void AwesomeNotifications::emit(const char* event, const ValueMap& content) {
  AwesomeEventsReceiver::shared().notify(event, content);
}

LifeCycle AwesomeNotifications::currentLifeCycle() const {
  return lifeCycle_ ? lifeCycle_() : LifeCycle::Foreground;
}

void AwesomeNotifications::forgetIfGone(int64_t id) {
  if (!contains(presenter_->pendingIds(), id)) store_->remove(id);
}

}  // namespace awn
