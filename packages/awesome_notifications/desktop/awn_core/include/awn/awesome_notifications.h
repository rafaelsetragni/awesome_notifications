#pragma once

#include <functional>
#include <map>
#include <memory>
#include <optional>
#include <string>
#include <vector>

#include "awn/displayed_tracker.h"
#include "awn/exception.h"
#include "awn/export.h"
#include "awn/notification_store.h"
#include "awn/platform.h"
#include "awn/value.h"

namespace awn {

/// Flutter-free notification engine for the desktop platforms (Windows, Linux),
/// with the same behavior as the Apple core's `AwesomeNotifications`: it runs
/// the decorator chain, persists the models, stamps and broadcasts the lifecycle
/// events and settles the launch action. The OS side is a `NotificationPresenter`.
///
/// Every public method runs on the platform thread (the bridge posts OS
/// callbacks there through the `Dispatcher` before calling in).
class AWN_API AwesomeNotifications {
 public:
  using LifeCycleProvider = std::function<LifeCycle()>;

  /// The engine the plugin bridge configures; decorators reach it here.
  static AwesomeNotifications& shared();

  AwesomeNotifications();

  /// `launchedByNotification`: the process was started by a notification
  /// activation (the bridge reads it from the command line), so the launch must
  /// wait for that activation before answering getInitialAction.
  void configure(std::shared_ptr<NotificationPresenter> presenter,
                 std::shared_ptr<Dispatcher> dispatcher,
                 std::shared_ptr<NotificationStore> store, bool launchedByNotification,
                 LifeCycleProvider lifeCycle = nullptr);
  bool isConfigured() const { return presenter_ != nullptr; }

  // Setup
  void initialize(const ValueList& channels);
  void setChannel(const ValueMap& channel);
  std::optional<ValueMap> channel(const std::string& key) const;

  // Permissions
  void isNotificationAllowed(std::function<void(bool)> done);
  void requestPermission(std::function<void(bool)> done);
  std::string localTimeZone();

  // Launch / initial action
  void finishLaunching();
  void getInitialAction(bool removeFromEvents, std::function<void(const Value&)> done);

  // Create
  /// `done` answers the created flag; `fail` (when given) receives a
  /// decorator's rejection, otherwise reported as created = false.
  void createNotification(
      const ValueMap& model, std::function<void(bool)> done,
      std::function<void(const AwesomeNotificationsException&)> fail = nullptr);

  // OS callbacks (posted to the platform thread by the bridge)
  /// Returns the action type of what was activated (the bridge brings the app
  /// window forward unless it is a silent/dismiss action), or nullopt when the
  /// activation is not one of ours.
  std::optional<ActionType> onActivated(const Activation& activation);
  void onDismissed(int64_t id);
  /// Emits the action event of `model` as if `button` (keyed `buttonKey`, with
  /// the typed `input`) was pressed, for a control that is not one of the
  /// model's buttons (e.g. a media control). Leaves the notification and its
  /// stored model alone.
  void dispatchAction(const ValueMap& model, const std::string& buttonKey,
                      const std::optional<std::string>& input, const ValueMap& button);
  /// A scheduled notification fired while the app was running.
  void onDisplayed(int64_t id);

  // Dismiss (remove from screen, keep schedule) / cancel (both)
  void dismiss(int64_t id);
  void cancel(int64_t id);
  void dismissByChannelKey(const std::string& key);
  void cancelByChannelKey(const std::string& key);
  void dismissByGroupKey(const std::string& key);
  void cancelByGroupKey(const std::string& key);
  void dismissAll();
  void cancelAll();

  // Schedule management (for the scheduling decorator)
  /// Re-runs the builder chain on a stored model and re-presents it without
  /// emitting events (tops up the pre-armed occurrences of a repeating schedule).
  bool rearm(const ValueMap& model);
  /// Models of the scheduled notifications (one per id).
  std::vector<ValueMap> pendingModels();
  void cancelSchedules(const std::vector<int64_t>& ids);
  void cancelAllSchedules();
  std::vector<int64_t> pendingIdsWhereContent(const std::string& key, const std::string& value);

  NotificationPresenter* presenter() const { return presenter_.get(); }
  NotificationStore* store() const { return store_.get(); }

 private:
  void emit(const char* event, const ValueMap& content);
  LifeCycle currentLifeCycle() const;
  /// Drops the stored model of a notification that left the screen, unless it is
  /// still scheduled (a repeating schedule re-arms with the same id).
  void forgetIfGone(int64_t id);
  void dismissIds(const std::vector<int64_t>& ids);
  void cancelIds(const std::vector<int64_t>& ids);
  /// Through the decorator's own delivery when it set one, else the presenter.
  void deliver(const BuiltNotification& built, std::function<void(bool)> done);

  std::shared_ptr<NotificationPresenter> presenter_;
  std::shared_ptr<Dispatcher> dispatcher_;
  std::shared_ptr<NotificationStore> store_;
  LifeCycleProvider lifeCycle_;
  DisplayedLifecycleTracker tracker_;
  std::map<std::string, ValueMap> channels_;

  bool launchedByNotification_ = false;
  bool didFinishLaunch_ = false;
  Value initialAction_;
  bool removeInitialActionFromEvents_ = false;
  std::function<void(const Value&)> pendingInitialAction_;
};

}  // namespace awn
