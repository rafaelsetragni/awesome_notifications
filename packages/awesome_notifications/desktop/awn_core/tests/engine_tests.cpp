#include <algorithm>
#include <memory>

#include "awn/awesome_notifications.h"
#include "awn/method_router.h"
#include "awn/registries.h"
#include "awn_test.h"

using namespace awn;

namespace {

/// Records what the engine asks of the OS; `present` succeeds synchronously.
class FakePresenter : public NotificationPresenter {
 public:
  std::vector<BuiltNotification> presented;
  std::vector<int64_t> delivered, pending;
  bool allowed = true;
  bool presentSucceeds = true;

  void present(const BuiltNotification& built, std::function<void(bool)> done) override {
    if (presentSucceeds) {
      presented.push_back(built);
      (built.fireDate ? pending : delivered).push_back(built.id);
    }
    done(presentSucceeds);
  }
  void removeDelivered(const std::vector<int64_t>& ids) override { erase(delivered, ids); }
  void removeAllDelivered() override { delivered.clear(); }
  void removePending(const std::vector<int64_t>& ids) override { erase(pending, ids); }
  void removeAllPending() override { pending.clear(); }
  std::vector<int64_t> deliveredIds() override { return delivered; }
  std::vector<int64_t> pendingIds() override { return pending; }
  bool isAllowed() override { return allowed; }
  void requestPermission(std::function<void(bool)> done) override { done(allowed); }
  std::string localTimeZone() override { return "America/Sao_Paulo"; }
  int64_t utcOffset(const std::string& zone, TimePoint) override {
    return zone == "America/Sao_Paulo" ? -3 * 3600 : 0;
  }
  std::string systemLanguage() override { return "pt-br"; }
  std::filesystem::path dataDirectory() override { return {}; }

 private:
  static void erase(std::vector<int64_t>& from, const std::vector<int64_t>& ids) {
    from.erase(std::remove_if(from.begin(), from.end(),
                              [&](int64_t id) {
                                return std::find(ids.begin(), ids.end(), id) != ids.end();
                              }),
               from.end());
  }
};

class InlineDispatcher : public Dispatcher {
 public:
  void post(std::function<void()> work) override { work(); }
};

struct Event {
  std::string name;
  ValueMap content;
};

/// A fresh engine wired to fakes, recording the events it broadcasts.
struct Harness {
  std::shared_ptr<FakePresenter> presenter = std::make_shared<FakePresenter>();
  std::shared_ptr<NotificationStore> store = std::make_shared<NotificationStore>();
  AwesomeNotifications engine;
  std::vector<Event> events;
  int token;
  LifeCycle lifeCycle = LifeCycle::Foreground;

  explicit Harness(bool launchedByNotification = false) {
    NotificationBuilderRegistry::shared().clearForTest();
    AwesomeMethodHandlerRegistry::shared().clearForTest();
    engine.configure(presenter, std::make_shared<InlineDispatcher>(), store,
                     launchedByNotification, [this] { return lifeCycle; });
    token = AwesomeEventsReceiver::shared().subscribe(
        [this](const std::string& name, const ValueMap& content) {
          events.push_back({name, content});
        });
  }
  ~Harness() { AwesomeEventsReceiver::shared().unsubscribe(token); }

  bool create(ValueMap model) {
    bool created = false;
    engine.createNotification(model, [&](bool ok) { created = ok; });
    return created;
  }

  const Event* last(const std::string& name) const {
    for (auto it = events.rbegin(); it != events.rend(); ++it)
      if (it->name == name) return &*it;
    return nullptr;
  }
};

ValueMap model(int id, ValueMap extra = {}, ValueList buttons = {}) {
  ValueMap content{{"id", id}, {"title", "T"}, {"channelKey", "basic"}};
  for (auto& [k, v] : extra) content[k] = v;
  ValueMap m{{"content", content}};
  if (!buttons.empty()) m["actionButtons"] = buttons;
  return m;
}

std::string str(const ValueMap& map, const char* key) { return getString(map, key).value_or(""); }

/// A decorator that schedules every notification one hour ahead.
class ScheduleEverything : public NotificationBuilder {
 public:
  using NotificationBuilder::NotificationBuilder;
  std::optional<BuiltNotification> build(const ValueMap& m) override {
    auto built = next(m);
    if (built) built->fireDate = DateUtils::now() + std::chrono::hours(1);
    return built;
  }
};

}  // namespace

TEST(CreateEmitsCreatedAndDisplayedAndStoresModel) {
  Harness h;
  EXPECT_TRUE(h.create(model(1)));
  EXPECT_EQ(h.presenter->presented.size(), size_t(1));
  EXPECT_TRUE(h.store->get(1).has_value());
  auto created = h.last("notificationCreated");
  EXPECT_TRUE(created != nullptr);
  EXPECT_EQ(str(created->content, "createdSource"), std::string("Local"));
  EXPECT_FALSE(str(created->content, "createdDate").empty());
  auto displayed = h.last("notificationDisplayed");
  EXPECT_TRUE(displayed != nullptr);
  EXPECT_EQ(str(displayed->content, "displayedLifeCycle"), std::string("Foreground"));
}

TEST(CreateWithoutIdFails) {
  Harness h;
  EXPECT_FALSE(h.create(ValueMap{{"content", ValueMap{{"title", "no id"}}}}));
  EXPECT_TRUE(h.events.empty());
}

TEST(FailedPresentDropsTheModel) {
  Harness h;
  h.presenter->presentSucceeds = false;
  EXPECT_FALSE(h.create(model(1)));
  EXPECT_FALSE(h.store->get(1).has_value());
  EXPECT_TRUE(h.events.empty());
}

TEST(TapEmitsActionAndForgetsTheModel) {
  Harness h;
  h.create(model(3, {{"payload", ValueMap{{"k", "v"}}}}));
  auto type = h.engine.onActivated({LaunchArgs::encode(3), {}});
  EXPECT_TRUE(type == ActionType::Default);
  auto action = h.last("defaultAction");
  EXPECT_TRUE(action != nullptr);
  EXPECT_EQ(str(action->content, "actionLifeCycle"), std::string("Foreground"));
  EXPECT_EQ(str(action->content, "actionType"), std::string("Default"));
  EXPECT_FALSE(str(action->content, "createdDate").empty());
  EXPECT_EQ(getString(getMap(action->content, "payload"), "k").value_or(""), std::string("v"));
  EXPECT_FALSE(h.store->get(3).has_value());
}

TEST(ButtonActivationCarriesKeyAndTypedText) {
  Harness h;
  h.create(model(4, {}, ValueList{ValueMap{{"key", "REPLY"}, {"requireInputText", true}}}));
  h.engine.onActivated({LaunchArgs::encode(4, "REPLY"), {{"REPLY", "hello"}}});
  auto action = h.last("defaultAction");
  EXPECT_EQ(str(action->content, "buttonKeyPressed"), std::string("REPLY"));
  EXPECT_EQ(str(action->content, "buttonKeyInput"), std::string("hello"));
}

TEST(DismissActionButtonEmitsDismissed) {
  Harness h;
  h.create(model(5, {}, ValueList{ValueMap{{"key", "X"}, {"actionType", "DismissAction"}}}));
  auto type = h.engine.onActivated({LaunchArgs::encode(5, "X"), {}});
  EXPECT_TRUE(type == ActionType::DismissAction);
  EXPECT_TRUE(h.last("notificationDismissed") != nullptr);
  EXPECT_TRUE(h.last("defaultAction") == nullptr);
}

TEST(ForeignActivationIsIgnored) {
  Harness h;
  EXPECT_FALSE(h.engine.onActivated({"something-else", {}}).has_value());
  EXPECT_FALSE(h.engine.onActivated({LaunchArgs::encode(99), {}}).has_value());
  EXPECT_TRUE(h.events.empty());
}

TEST(LaunchActivationBecomesTheInitialAction) {
  Harness h(/*launchedByNotification=*/true);
  h.store->put(8, model(8));  // created by a previous process

  Value initial;
  bool answered = false;
  h.engine.getInitialAction(false, [&](const Value& v) {
    initial = v;
    answered = true;
  });
  EXPECT_FALSE(answered);  // parked until the activation arrives

  h.engine.onActivated({LaunchArgs::encode(8), {}});
  EXPECT_TRUE(answered);
  EXPECT_EQ(initial["actionLifeCycle"].asString().value_or(""), std::string("Terminated"));
  EXPECT_EQ(initial["id"].asInt().value_or(0), int64_t(8));
}

TEST(NormalLaunchHasNoInitialAction) {
  Harness h;
  bool answered = false;
  h.engine.getInitialAction(false, [&](const Value& v) {
    answered = true;
    EXPECT_TRUE(v.isNull());
  });
  EXPECT_TRUE(answered);
}

TEST(LaunchTimeoutSettlesWithNull) {
  Harness h(true);
  bool answered = false;
  h.engine.getInitialAction(false, [&](const Value& v) {
    answered = true;
    EXPECT_TRUE(v.isNull());
  });
  h.engine.finishLaunching();  // the bridge's timeout
  EXPECT_TRUE(answered);
}

TEST(ScheduledNotificationIsPendingAndPredictedTerminated) {
  Harness h;
  NotificationBuilderRegistry::shared().registerDecorator(
      10, [](auto inner) { return std::make_shared<ScheduleEverything>(inner); });
  h.create(model(6));
  EXPECT_EQ(h.presenter->pending, (std::vector<int64_t>{6}));
  EXPECT_TRUE(h.last("notificationDisplayed") == nullptr);
  auto stored = NotificationBuilder::content(*h.store->get(6));
  EXPECT_EQ(str(stored, "displayedLifeCycle"), std::string("Terminated"));

  // It fires while the app runs: the tap reports the real displayed lifecycle.
  h.engine.onDisplayed(6);
  h.engine.onActivated({LaunchArgs::encode(6), {}});
  EXPECT_EQ(str(h.last("defaultAction")->content, "displayedLifeCycle"),
            std::string("Foreground"));
  // Still pending (a repeating schedule re-arms with the same id): model kept.
  EXPECT_TRUE(h.store->get(6).has_value());
}

TEST(DismissKeepsScheduleCancelRemovesAll) {
  Harness h;
  h.create(model(1));
  h.presenter->pending.push_back(1);  // also re-armed as a schedule
  h.engine.dismiss(1);
  EXPECT_TRUE(h.presenter->delivered.empty());
  EXPECT_TRUE(h.store->get(1).has_value());
  h.engine.cancel(1);
  EXPECT_TRUE(h.presenter->pending.empty());
  EXPECT_FALSE(h.store->get(1).has_value());
}

TEST(ChannelAndGroupFilters) {
  Harness h;
  h.create(model(1, {{"channelKey", "a"}, {"groupKey", "g"}}));
  h.create(model(2, {{"channelKey", "b"}, {"groupKey", "g"}}));
  h.create(model(3, {{"channelKey", "a"}}));
  h.engine.dismissByChannelKey("a");
  EXPECT_EQ(h.presenter->delivered, (std::vector<int64_t>{2}));
  h.engine.cancelByGroupKey("g");
  EXPECT_TRUE(h.presenter->delivered.empty());
  EXPECT_TRUE(h.store->ids().empty());
}

TEST(InitializePrunesModelsTheOsNoLongerHas) {
  Harness h;
  h.store->put(1, model(1));
  h.store->put(2, model(2));
  h.presenter->delivered = {2};
  h.engine.initialize(ValueList{ValueMap{{"channelKey", "basic"}, {"playSound", false}}});
  EXPECT_EQ(h.store->ids(), (std::vector<int64_t>{2}));
  EXPECT_EQ(getBool(*h.engine.channel("basic"), "playSound").value_or(true), false);
}

TEST(SystemDismissEmitsDismissed) {
  Harness h;
  h.create(model(9));
  h.lifeCycle = LifeCycle::Background;
  h.engine.onDismissed(9);
  auto dismissed = h.last("notificationDismissed");
  EXPECT_TRUE(dismissed != nullptr);
  EXPECT_EQ(str(dismissed->content, "actionLifeCycle"), std::string("Background"));
  EXPECT_FALSE(h.store->get(9).has_value());
}

// MARK: - Router

namespace {
class EchoHandler : public AwesomeMethodHandler {
 public:
  bool handle(const std::string& method, const Value& arguments, MethodResult result) override {
    if (method != "echo") return false;
    result(arguments);
    return true;
  }
};
}  // namespace

TEST(RouterAnswersCoreMethods) {
  Harness h;
  AwesomeMethodRouter router(h.engine);
  Value answer;
  EXPECT_TRUE(router.handle("getUtcTimeZoneIdentifier", Value(), [&](const Value& v) { answer = v; }));
  EXPECT_EQ(answer.asString().value_or(""), std::string("UTC"));
  router.handle("getLocalTimeZoneIdentifier", Value(), [&](const Value& v) { answer = v; });
  EXPECT_EQ(answer.asString().value_or(""), std::string("America/Sao_Paulo"));
  router.handle("createNewNotification", Value(model(1)), [&](const Value& v) { answer = v; });
  EXPECT_EQ(answer.asBool().value_or(false), true);
  router.handle("cancelNotification", Value(1), [&](const Value& v) { answer = v; });
  EXPECT_TRUE(h.store->ids().empty());
}

TEST(RouterReportsMissingPermissions) {
  Harness h;
  AwesomeMethodRouter router(h.engine);
  Value answer;
  ValueMap args{{"permissions", ValueList{Value("Alert"), Value("Sound")}}};
  h.presenter->allowed = false;
  router.handle("requestNotifications", Value(args), [&](const Value& v) { answer = v; });
  EXPECT_EQ(answer.list().size(), size_t(2));
  h.presenter->allowed = true;
  router.handle("requestNotifications", Value(args), [&](const Value& v) { answer = v; });
  EXPECT_TRUE(answer.list().empty());
}

TEST(RouterFallsThroughToDecorators) {
  Harness h;
  AwesomeMethodRouter router(h.engine);
  EXPECT_FALSE(router.handle("echo", Value(1), [](const Value&) {}));
  AwesomeMethodHandlerRegistry::shared().registerHandler(std::make_shared<EchoHandler>());
  Value answer;
  EXPECT_TRUE(router.handle("echo", Value(5), [&](const Value& v) { answer = v; }));
  EXPECT_EQ(answer.asInt().value_or(0), int64_t(5));
  AwesomeMethodHandlerRegistry::shared().clearForTest();
}

TEST(RegistryOrdersDecoratorsByPriority) {
  NotificationBuilderRegistry::shared().clearForTest();
  std::vector<int> order;
  struct Tracing : NotificationBuilder {
    int tag;
    std::vector<int>* order;
    Tracing(std::shared_ptr<NotificationBuilder> inner, int tag, std::vector<int>* order)
        : NotificationBuilder(inner), tag(tag), order(order) {}
    std::optional<BuiltNotification> build(const ValueMap& m) override {
      order->push_back(tag);
      return next(m);
    }
  };
  auto& registry = NotificationBuilderRegistry::shared();
  registry.registerDecorator(1, [&](auto inner) { return std::make_shared<Tracing>(inner, 1, &order); });
  registry.registerDecorator(10, [&](auto inner) { return std::make_shared<Tracing>(inner, 10, &order); });
  registry.makeBuilder()->build(model(1));
  EXPECT_EQ(order, (std::vector<int>{10, 1}));
  registry.clearForTest();
}

int main() { return awn_test::runAll(); }

// MARK: - Decorator answers / failures

namespace {

/// Answers the create call itself, like 0.12 Android's scheduler (false).
class AnswerFalse : public NotificationBuilder {
 public:
  using NotificationBuilder::NotificationBuilder;
  std::optional<BuiltNotification> build(const ValueMap& m) override {
    auto built = next(m);
    if (built) built->answer = false;
    return built;
  }
};

class RejectEverything : public NotificationBuilder {
 public:
  using NotificationBuilder::NotificationBuilder;
  std::optional<BuiltNotification> build(const ValueMap&) override {
    throw AwesomeNotificationsException("INVALID_ARGUMENTS", "Nope", "arguments.invalid.test");
  }
};

}  // namespace

TEST(DecoratorAnswerIsWhatTheCallReturns) {
  Harness h;
  NotificationBuilderRegistry::shared().registerDecorator(
      1, [](auto inner) { return std::make_shared<AnswerFalse>(inner); });
  EXPECT_FALSE(h.create(model(30)));
  // Still presented and reported as created.
  EXPECT_EQ(h.presenter->presented.size(), static_cast<size_t>(1));
  EXPECT_TRUE(h.last(defs::EVENT_NOTIFICATION_CREATED) != nullptr);
}

TEST(DecoratorFailureReachesTheErrorCallback) {
  Harness h;
  NotificationBuilderRegistry::shared().registerDecorator(
      1, [](auto inner) { return std::make_shared<RejectEverything>(inner); });
  std::string code, message, details;
  bool answered = false;
  AwesomeMethodRouter router(h.engine);
  router.handle(
      "createNewNotification", Value(model(31)), [&](const Value&) { answered = true; },
      [&](const std::string& c, const std::string& m, const Value& d) {
        code = c;
        message = m;
        details = d.asString().value_or("");
      });
  EXPECT_FALSE(answered);
  EXPECT_EQ(code, std::string("INVALID_ARGUMENTS"));
  EXPECT_EQ(message, std::string("Nope"));
  EXPECT_EQ(details, std::string("arguments.invalid.test"));
  EXPECT_TRUE(h.presenter->presented.empty());

  // Without an error callback the rejection answers created = false.
  EXPECT_FALSE(h.create(model(32)));
}

namespace {
/// A decorator that delivers every notification itself (like a media session).
class DeliverItself : public NotificationBuilder {
 public:
  DeliverItself(std::shared_ptr<NotificationBuilder> inner, std::vector<int64_t>* delivered)
      : NotificationBuilder(std::move(inner)), delivered_(delivered) {}
  std::optional<BuiltNotification> build(const ValueMap& m) override {
    auto built = next(m);
    auto* delivered = delivered_;
    if (built) built->deliver = [delivered](const BuiltNotification& b, auto done) {
      delivered->push_back(b.id);
      done(true);
    };
    return built;
  }

 private:
  std::vector<int64_t>* delivered_;
};
}  // namespace

TEST(DecoratorDeliveryReplacesThePresenter) {
  Harness h;
  std::vector<int64_t> delivered;
  NotificationBuilderRegistry::shared().registerDecorator(
      1, [&](auto inner) { return std::make_shared<DeliverItself>(inner, &delivered); });
  EXPECT_TRUE(h.create(model(41)));
  EXPECT_EQ(delivered, std::vector<int64_t>{41});
  EXPECT_TRUE(h.presenter->presented.empty());
  EXPECT_TRUE(h.store->get(41).has_value());
  EXPECT_TRUE(h.last("notificationCreated") != nullptr);
  EXPECT_TRUE(h.last("notificationDisplayed") != nullptr);
}

TEST(DispatchActionEmitsTheActionAndKeepsTheModel) {
  Harness h;
  EXPECT_TRUE(h.create(model(42, {{"payload", ValueMap{{"k", "v"}}}})));
  auto stored = h.store->get(42);
  EXPECT_TRUE(stored.has_value());
  ValueMap button{{"key", "awn.media.seekTo"}, {"actionType", "SilentAction"},
                  {"autoDismissible", false}};
  h.engine.dispatchAction(*stored, "awn.media.seekTo", std::string("12000"), button);
  auto action = h.last("defaultAction");
  EXPECT_TRUE(action != nullptr);
  EXPECT_EQ(str(action->content, "buttonKeyPressed"), std::string("awn.media.seekTo"));
  EXPECT_EQ(str(action->content, "buttonKeyInput"), std::string("12000"));
  EXPECT_EQ(str(action->content, "actionType"), std::string("SilentAction"));
  EXPECT_EQ(str(action->content, "actionLifeCycle"), std::string("Foreground"));
  EXPECT_EQ(str(getMap(action->content, "payload"), "k"), std::string("v"));
  EXPECT_EQ(h.presenter->delivered, std::vector<int64_t>{42});
  EXPECT_TRUE(h.store->get(42).has_value());

  h.engine.dispatchAction(*stored, "awn.media.pause", std::nullopt, button);
  EXPECT_FALSE(has(h.last("defaultAction")->content, "buttonKeyInput"));
}

TEST(RemovalObserversSeeEveryDismissAndCancel) {
  Harness h;
  std::vector<std::vector<int64_t>> removed;
  int token = h.engine.addRemovalObserver(
      [&](const std::vector<int64_t>& ids) { removed.push_back(ids); });
  h.create(model(1, {{"channelKey", "a"}, {"groupKey", "g"}}));
  h.create(model(2, {{"channelKey", "b"}, {"groupKey", "g"}}));
  h.create(model(3, {{"channelKey", "a"}}));

  h.engine.dismiss(1);
  h.engine.cancel(2);
  h.engine.dismissByChannelKey("a");  // 3 (1 is gone)
  EXPECT_EQ(removed, (std::vector<std::vector<int64_t>>{{1}, {2}, {3}}));
  h.engine.cancelByChannelKey("nothing");  // no ids: not notified
  EXPECT_EQ(removed.size(), size_t(3));

  h.create(model(4, {{"groupKey", "g"}}));
  h.engine.cancelByGroupKey("g");
  h.create(model(5, {{"groupKey", "g"}}));
  h.engine.dismissByGroupKey("g");
  EXPECT_EQ(removed[3], std::vector<int64_t>{4});
  EXPECT_EQ(removed[4], std::vector<int64_t>{5});

  h.create(model(6));
  h.create(model(7));
  h.engine.dismissAll();
  EXPECT_EQ(removed[5], (std::vector<int64_t>{6, 7}));
  h.create(model(8));
  h.engine.cancelAll();
  EXPECT_EQ(removed[6], std::vector<int64_t>{8});
  h.engine.cancelAll();  // nothing left
  EXPECT_EQ(removed.size(), size_t(7));

  h.engine.removeRemovalObserver(token);
  h.create(model(9));
  h.engine.cancel(9);
  EXPECT_EQ(removed.size(), size_t(7));
}

TEST(RemovalObserverMayCancelMore) {
  Harness h;
  std::vector<int64_t> removed;
  h.engine.addRemovalObserver([&](const std::vector<int64_t>& ids) {
    removed.insert(removed.end(), ids.begin(), ids.end());
    if (ids == std::vector<int64_t>{1}) h.engine.cancel(2);
  });
  h.create(model(1));
  h.create(model(2));
  h.engine.cancel(1);
  EXPECT_EQ(removed, (std::vector<int64_t>{1, 2}));
  EXPECT_TRUE(h.store->ids().empty());
}
