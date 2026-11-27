// Unit tests of the desktop live activity logic, on the desktop core's engine
// and harness, with a fake presenter and a manual timer. No Flutter, GLib or
// Windows.
#include <algorithm>
#include <memory>

#include "awn/awesome_notifications.h"
#include "awn/freedesktop.h"
#include "awn/method_router.h"
#include "awn/platform.h"
#include "awn/registries.h"
#include "awn_live/live.h"
#include "awn_test.h"

using namespace awn;
using namespace awn_live;

namespace {

class FakePresenter : public NotificationPresenter {
 public:
  std::vector<BuiltNotification> presented;
  std::vector<int64_t> delivered, removed;

  void present(const BuiltNotification& built, std::function<void(bool)> done) override {
    presented.push_back(built);
    if (std::find(delivered.begin(), delivered.end(), built.id) == delivered.end())
      delivered.push_back(built.id);
    done(true);
  }
  void removeDelivered(const std::vector<int64_t>& ids) override {
    for (auto id : ids) {
      removed.push_back(id);
      delivered.erase(std::remove(delivered.begin(), delivered.end(), id), delivered.end());
    }
  }
  void removeAllDelivered() override { delivered.clear(); }
  void removePending(const std::vector<int64_t>&) override {}
  void removeAllPending() override {}
  std::vector<int64_t> deliveredIds() override { return delivered; }
  std::vector<int64_t> pendingIds() override { return {}; }
  bool isAllowed() override { return true; }
  void requestPermission(std::function<void(bool)> done) override { done(true); }
  std::string localTimeZone() override { return "UTC"; }
  int64_t utcOffset(const std::string&, TimePoint) override { return 0; }
  std::string systemLanguage() override { return "en"; }
  std::filesystem::path dataDirectory() override { return {}; }

  const BuiltNotification* last(int64_t id) const {
    for (auto it = presented.rbegin(); it != presented.rend(); ++it)
      if (it->id == id) return &*it;
    return nullptr;
  }
  bool shows(int64_t id) const {
    return std::find(delivered.begin(), delivered.end(), id) != delivered.end();
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

struct Timer {
  int64_t ms;
  std::function<void()> work;
};

std::string str(const ValueMap& map, const char* key) { return getString(map, key).value_or(""); }

ValueMap model(int id, std::optional<ValueMap> live, ValueMap contentExtra = {}) {
  ValueMap content{{"id", id}, {"channelKey", "live"}, {"title", "Order"}, {"body", "On the way"}};
  for (auto& [k, v] : contentExtra) content[k] = v;
  ValueMap m{{"content", content}};
  if (live) m["liveActivity"] = *live;
  return m;
}

ValueMap block(ValueMap extra = {}) {
  ValueMap live{{"state", "active"}, {"metrics", ValueList{}}, {"alert", false},
                {"dismissal", "default"}};
  for (auto& [k, v] : extra) live[k] = v;
  return live;
}

ValueMap hintsOf(const BuiltNotification* built) {
  return built ? getMap(built->model, "desktopPresentation") : ValueMap{};
}
ValueMap contentOf(const BuiltNotification* built) {
  return built ? NotificationBuilder::content(built->model) : ValueMap{};
}

LiveModel parsed(ValueMap live, int64_t id = 7) {
  auto parsedModel = LiveModel::parse(Value(live), id);
  return parsedModel ? *parsedModel : LiveModel{};
}

std::string clockOf(int64_t ms) { return "T" + std::to_string(ms); }

/// A fresh engine with the live activities registered, on a manual clock and
/// timer.
struct Harness {
  std::shared_ptr<FakePresenter> presenter = std::make_shared<FakePresenter>();
  std::shared_ptr<NotificationStore> store = std::make_shared<NotificationStore>();
  AwesomeNotifications engine;
  int64_t now = 1'800'000'000'000;
  std::vector<Timer> timers;
  std::shared_ptr<LiveController> controller;
  std::vector<Event> events;
  std::vector<ValueMap> stream;
  int token;

  explicit Harness(Surface surface = Surface::freedesktop) {
    NotificationBuilderRegistry::shared().clearForTest();
    AwesomeMethodHandlerRegistry::shared().clearForTest();
    engine.configure(presenter, std::make_shared<InlineDispatcher>(), store, false);
    LiveHost host = engineHost(engine, [this](int64_t ms, std::function<void()> work) {
      timers.push_back({ms, std::move(work)});
    });
    host.now = [this] { return now; };
    host.clock = &clockOf;
    controller = std::make_shared<LiveController>(std::move(host), surface);
    controller->setStreamSink([this](const ValueMap& event) { stream.push_back(event); });
    RegisterLiveActivities(controller, desktopCapabilities(), engine);
    token = AwesomeEventsReceiver::shared().subscribe(
        [this](const std::string& name, const ValueMap& content) {
          events.push_back({name, content});
        });
  }
  ~Harness() { AwesomeEventsReceiver::shared().unsubscribe(token); }

  /// The create call's answer: "true" / "false" / "<code>|<detailed code>".
  std::string create(const ValueMap& m) {
    std::string outcome;
    AwesomeMethodRouter router(engine);
    router.handle(
        "createNewNotification", Value(m),
        [&](const Value& value) { outcome = value.asBool().value_or(false) ? "true" : "false"; },
        [&](const std::string& code, const std::string&, const Value& details) {
          outcome = code + "|" + details.asString().value_or("");
        });
    return outcome;
  }

  Value call(const std::string& method, const Value& arguments = Value()) {
    Value answer("unanswered");
    AwesomeMethodRouter(engine).handle(method, arguments,
                                       [&](const Value& value) { answer = value; });
    return answer;
  }

  std::optional<ActionType> press(int64_t id, const std::string& key) {
    return engine.onActivated({LaunchArgs::encode(id, key), {}});
  }

  /// Runs the timers armed so far.
  void fireTimers() {
    auto due = std::move(timers);
    timers.clear();
    for (auto& timer : due) timer.work();
  }

  int count(const std::string& name) const {
    return static_cast<int>(std::count_if(events.begin(), events.end(),
                                          [&](const Event& e) { return e.name == name; }));
  }
  /// The state events, as "activityId:state".
  std::vector<std::string> states() const {
    std::vector<std::string> out;
    for (const auto& event : stream)
      out.push_back(str(event, "activityId") + ":" + str(event, "state"));
    return out;
  }
  std::vector<std::string> list() {
    std::vector<std::string> out;
    Value answer = call("liveActivityList");
    for (const auto& entry : answer.list())
      out.push_back(str(entry.map(), "activityId") + ":" + str(entry.map(), "state"));
    return out;
  }
};

const std::string kInvalid = "INVALID_ARGUMENTS|arguments.invalid.notificationLiveActivity";
using Strings = std::vector<std::string>;

}  // namespace

// MARK: - Model

TEST(ParsesTheBlock) {
  auto live = parsed(block({{"activityId", "order-1"},
                            {"progress", ValueMap{{"segments", ValueList{ValueMap{{"length", 2}},
                                                                         ValueMap{{"length", 3}}}},
                                                  {"points", ValueList{ValueMap{{"position", 5}}}},
                                                  {"trackerIcon", "asset://car.png"}}},
                            {"timer", ValueMap{{"end", int64_t(2000)}, {"countDown", true}}},
                            {"metrics", ValueList{ValueMap{{"label", "Speed"},
                                                           {"value", "42"},
                                                           {"unit", "km/h"}}}},
                            {"shortText", "12 min"},
                            {"accentColor", int64_t(0xFF00FF00)},
                            {"staleAt", int64_t(5000)},
                            {"relevance", 0.5},
                            {"alert", true},
                            {"dismissal", int64_t(9000)},
                            {"pushChannel", "ch"}}));
  EXPECT_EQ(live.activityId, std::string("order-1"));
  EXPECT_TRUE(live.state == State::active);
  EXPECT_EQ(live.progress->segments.size(), size_t(2));
  EXPECT_EQ(live.progress->points.front().position, int64_t(5));
  EXPECT_EQ(live.progress->trackerIcon, std::string("asset://car.png"));
  EXPECT_TRUE(live.timer->countDown);
  EXPECT_EQ(live.timer->end.value_or(0), int64_t(2000));
  EXPECT_EQ(live.metrics.front().unit, std::string("km/h"));
  EXPECT_EQ(live.shortText, std::string("12 min"));
  EXPECT_EQ(live.accentColor.value_or(0), int64_t(0xFF00FF00));
  EXPECT_EQ(live.staleAt.value_or(0), int64_t(5000));
  EXPECT_EQ(live.relevance.value_or(0), 0.5);
  EXPECT_TRUE(live.alert);
  EXPECT_TRUE(live.dismissal.kind == Dismissal::Kind::at);
  EXPECT_EQ(live.dismissal.at, int64_t(9000));
  EXPECT_EQ(live.pushChannel, std::string("ch"));
}

TEST(ParseDefaults) {
  auto live = LiveModel::parse(Value(ValueMap{}), 42);
  EXPECT_TRUE(live.has_value());
  EXPECT_EQ(live->activityId, std::string("42"));  // the notification id
  EXPECT_TRUE(live->state == State::active);
  EXPECT_FALSE(live->alert);
  EXPECT_TRUE(live->dismissal.kind == Dismissal::Kind::system);
  EXPECT_FALSE(live->progress.has_value());
  EXPECT_TRUE(parsed(block({{"state", "ended"}, {"dismissal", "immediate"}})).dismissal.kind ==
              Dismissal::Kind::immediate);
}

// NotificationLiveActivity.validate() rules, plus what Dart can't send but a
// push can.
TEST(ParseRejectsInvalidBlocks) {
  auto rejects = [](ValueMap live, const char* reason) {
    std::string error;
    bool rejected = !LiveModel::parse(Value(live), 1, &error).has_value();
    if (!rejected) awn_test::fail(__FILE__, __LINE__, std::string("accepted: ") + reason);
    if (rejected && error.empty()) awn_test::fail(__FILE__, __LINE__, "no reason given");
  };
  rejects(block({{"activityId", " "}}), "blank activityId");
  rejects(block({{"state", "paused"}}), "unknown state");
  ValueList four;
  for (int i = 0; i < 4; ++i) four.push_back(ValueMap{{"label", "m"}, {"value", "1"}});
  rejects(block({{"metrics", four}}), "4 metrics");
  rejects(block({{"metrics", ValueList{ValueMap{{"label", " "}, {"value", "1"}}}}}),
          "blank metric label");
  rejects(block({{"shortText", ""}}), "empty shortText");
  rejects(block({{"pushChannel", ""}}), "empty pushChannel");
  rejects(block({{"progress", ValueMap{{"segments", ValueList{ValueMap{{"length", 0}}}}}}}),
          "zero segment");
  rejects(block({{"progress", ValueMap{{"points", ValueList{ValueMap{{"position", 101}}}}}}}),
          "point past 100");
  rejects(block({{"progress", ValueMap{{"segments", ValueList{ValueMap{{"length", 3}}}},
                                       {"points", ValueList{ValueMap{{"position", 4}}}}}}}),
          "point past the segments");
  rejects(block({{"timer", ValueMap{{"start", int64_t(10)}, {"end", int64_t(10)}}}}),
          "countdown ending at its start");
  rejects(block({{"timer", ValueMap{{"countDown", true}}}}), "countdown without end");
  rejects(block({{"timer", ValueMap{{"countDown", false}}}}), "elapsed without start");
  rejects(block({{"dismissal", "later"}}), "unknown dismissal");
  rejects(ValueMap{{"progress", "60"}}, "progress not a map");
  std::string error;
  EXPECT_FALSE(LiveModel::parse(Value("x"), 1, &error).has_value());
}

// MARK: - Text (the web's webLiveBodyOf)

TEST(BodyFoldsLikeTheWeb) {
  ValueMap content{{"body", "On the way"}, {"progress", 60}};
  auto live = parsed(block({{"shortText", "12 min"},
                            {"timer", ValueMap{{"end", int64_t(2000)}, {"countDown", true}}},
                            {"metrics", ValueList{ValueMap{{"label", "Speed"},
                                                           {"value", "42"},
                                                           {"unit", "km/h"}},
                                                  ValueMap{{"label", "Stops"}, {"value", "2"}}}}}));
  EXPECT_EQ(liveBody(content, live, true, &clockOf),
            std::string("On the way\n"
                        "\xE2\x96\xB0\xE2\x96\xB0\xE2\x96\xB0\xE2\x96\xB0\xE2\x96\xB0\xE2\x96\xB0"
                        "\xE2\x96\xB1\xE2\x96\xB1\xE2\x96\xB1\xE2\x96\xB1 60% \xC2\xB7 12 min\n"
                        "Ends at T2000\n"
                        "Speed 42 km/h \xC2\xB7 Stops 2"));
  // Without the bar (Windows draws its own), indeterminate, elapsed timer.
  EXPECT_EQ(liveBody(content, live, false, &clockOf).find("60%"), std::string::npos);
  auto elapsed = parsed(block({{"timer", ValueMap{{"start", int64_t(1000)}, {"countDown", false}}}}));
  EXPECT_EQ(liveBody(ValueMap{}, elapsed, true, &clockOf), std::string("Started at T1000"));
  auto shortOnly = parsed(block({{"shortText", "soon"}}));
  EXPECT_EQ(barText(ValueMap{}, shortOnly, true), std::string("soon"));
}

TEST(BarRoundsAndClamps) {
  LiveModel live;
  auto cells = [&](double progress) {
    std::string text = barText(ValueMap{{"progress", progress}}, live, true);
    int filled = 0;
    for (size_t i = 0; (i = text.find("\xE2\x96\xB0", i)) != std::string::npos; i += 3) ++filled;
    return filled;
  };
  EXPECT_EQ(cells(0), 0);
  EXPECT_EQ(cells(4), 0);
  EXPECT_EQ(cells(5), 1);
  EXPECT_EQ(cells(64.6), 7);  // 65% -> round(6.5) = 7, as the web
  EXPECT_EQ(cells(100), 10);
  EXPECT_EQ(cells(150), 10);
  EXPECT_EQ(barText(ValueMap{{"progress", -3}}, live, true).find("0%") != std::string::npos, true);
  EXPECT_EQ(progressValue(ValueMap{{"progress", 250}}).value_or(0), 100.0);
  EXPECT_FALSE(progressValue(ValueMap{}).has_value());
}

// MARK: - Refusals

TEST(ScheduledActivityIsRefused) {
  Harness h;
  ValueMap m = model(1, block());
  m["schedule"] = ValueMap{{"interval", 60}};
  EXPECT_EQ(h.create(m), kInvalid + ".schedule");
  EXPECT_TRUE(h.presenter->presented.empty());
}

TEST(MalformedActivityIsRefused) {
  Harness h;
  EXPECT_EQ(h.create(model(1, block({{"state", "nope"}}))), kInvalid);
  EXPECT_TRUE(h.presenter->presented.empty());
}

TEST(NotificationWithoutBlockIsUntouched) {
  Harness h;
  EXPECT_EQ(h.create(model(3, std::nullopt)), std::string("true"));
  auto content = contentOf(h.presenter->last(3));
  EXPECT_EQ(str(content, "body"), std::string("On the way"));
  EXPECT_FALSE(has(h.presenter->last(3)->model, "desktopPresentation"));
  EXPECT_TRUE(h.list().empty());
}

// MARK: - Linux (freedesktop)

TEST(FirstPostAlertsThenUpdatesAreSilentInPlace) {
  Harness h;
  EXPECT_EQ(h.create(model(10, block(), {{"progress", 30}})), std::string("true"));
  auto first = h.presenter->last(10);
  EXPECT_TRUE(getBool(hintsOf(first), "silent") == std::optional<bool>(false));
  EXPECT_TRUE(getBool(hintsOf(first), "resident") == std::optional<bool>(true));
  EXPECT_EQ(str(getMap(contentOf(first), "payload"), "activityId"), std::string("10"));
  EXPECT_CONTAINS(str(contentOf(first), "body"), "30%");
  EXPECT_EQ(h.count("notificationCreated"), 1);
  EXPECT_EQ(h.count("notificationDisplayed"), 1);

  EXPECT_EQ(h.create(model(10, block(), {{"progress", 60}})), std::string("true"));
  auto update = h.presenter->last(10);
  EXPECT_TRUE(getBool(hintsOf(update), "silent") == std::optional<bool>(true));
  EXPECT_CONTAINS(str(contentOf(update), "body"), "60%");
  EXPECT_EQ(h.presenter->delivered.size(), size_t(1));  // the same notification
  EXPECT_EQ(h.count("notificationCreated"), 2);          // events as any notification
  EXPECT_EQ(h.list(), Strings{"10:active"});

  // `alert` makes an update alert again.
  h.create(model(10, block({{"alert", true}}), {{"progress", 70}}));
  EXPECT_TRUE(getBool(hintsOf(h.presenter->last(10)), "silent") == std::optional<bool>(false));
}

TEST(FreedesktopRendersTheFoldedBody) {
  Harness h;
  h.create(model(11, block({{"metrics", ValueList{ValueMap{{"label", "Stops"}, {"value", "2"}}}}}),
                 {{"progress", 50}}));
  auto rendered = Freedesktop::render(h.presenter->last(11)->model, {}, false, "Default",
                                      {"actions", "body-markup"});
  EXPECT_CONTAINS(rendered.body, "On the way\n");
  EXPECT_CONTAINS(rendered.body, "50%");
  EXPECT_CONTAINS(rendered.body, "Stops 2");
  EXPECT_TRUE(rendered.resident);
  EXPECT_FALSE(rendered.suppressSound);
  h.create(model(11, block(), {{"progress", 55}}));
  EXPECT_TRUE(Freedesktop::render(h.presenter->last(11)->model, {}, false, "Default", {})
                  .suppressSound);
}

TEST(EndedShowsTheFinalContentNotResident) {
  Harness h;
  h.create(model(12, block()));
  h.create(model(12, block({{"state", "ended"}})));
  auto ended = h.presenter->last(12);
  EXPECT_TRUE(getBool(hintsOf(ended), "resident") == std::optional<bool>(false));
  EXPECT_TRUE(getBool(hintsOf(ended), "silent") == std::optional<bool>(true));
  EXPECT_TRUE(h.presenter->shows(12));  // default dismissal: stays
  EXPECT_EQ(h.states(), Strings{"12:ended"});
  EXPECT_EQ(h.list(), Strings{"12:ended"});
  EXPECT_TRUE(h.timers.empty());
  // Ending again doesn't report it again.
  h.create(model(12, block({{"state", "ended"}})));
  EXPECT_EQ(h.states(), Strings{"12:ended"});
}

TEST(EndedImmediateRemovesIt) {
  Harness h;
  h.create(model(13, block()));
  EXPECT_EQ(h.create(model(13, block({{"state", "ended"}, {"dismissal", "immediate"}}))),
            std::string("true"));
  EXPECT_FALSE(h.presenter->shows(13));
  EXPECT_EQ(h.states(), (Strings{"13:ended", "13:dismissed"}));
  EXPECT_TRUE(h.list().empty());
}

TEST(EndedAtATimeRemovesItThen) {
  Harness h;
  h.create(model(14, block()));
  h.create(model(14, block({{"state", "ended"}, {"dismissal", h.now + 5000}})));
  EXPECT_EQ(h.timers.size(), size_t(1));
  EXPECT_EQ(h.timers.front().ms, int64_t(5000));
  h.now += 5000;
  h.fireTimers();
  EXPECT_FALSE(h.presenter->shows(14));
  EXPECT_EQ(h.states(), (Strings{"14:ended", "14:dismissed"}));
  EXPECT_TRUE(h.list().empty());
}

TEST(StaleAtRemovesItUnlessUpdated) {
  Harness h;
  h.create(model(15, block({{"staleAt", h.now + 1000}})));
  // An update with a later staleAt re-arms; the first timer is then a no-op.
  h.create(model(15, block({{"staleAt", h.now + 3000}})));
  EXPECT_EQ(h.timers.size(), size_t(2));
  h.now += 1000;
  auto first = std::move(h.timers.front());
  h.timers.erase(h.timers.begin());
  first.work();
  EXPECT_TRUE(h.presenter->shows(15));
  h.now += 2000;
  h.fireTimers();
  EXPECT_FALSE(h.presenter->shows(15));
  EXPECT_EQ(h.states(), Strings{"15:dismissed"});
}

TEST(FarDeadlineWaitsAgain) {
  Harness h;
  h.create(model(16, block({{"staleAt", h.now + kMaxTimerMs * 2}})));
  EXPECT_EQ(h.timers.front().ms, kMaxTimerMs);
  h.now += kMaxTimerMs;
  h.fireTimers();
  EXPECT_TRUE(h.presenter->shows(16));
  EXPECT_EQ(h.timers.size(), size_t(1));
  h.now += kMaxTimerMs;
  h.fireTimers();
  EXPECT_FALSE(h.presenter->shows(16));
}

TEST(CoreCancelAndDismissEndIt) {
  Harness h;
  h.create(model(17, block({{"activityId", "a"}})));
  h.create(model(18, block({{"activityId", "b"}})));
  h.create(model(19, block({{"activityId", "c"}, {"state", "ended"}})));
  h.call("cancelNotification", Value(17));
  h.call("dismissNotification", Value(18));
  h.call("cancelAllNotifications");
  EXPECT_EQ(h.states(), (Strings{"c:ended", "a:ended", "a:dismissed", "b:ended", "b:dismissed",
                                 "c:dismissed"}));
  EXPECT_TRUE(h.list().empty());
}

TEST(UserDismissalIsReported) {
  Harness h;
  h.create(model(20, block()));
  h.engine.onDismissed(20);
  EXPECT_EQ(h.states(), Strings{"20:dismissed"});
  EXPECT_TRUE(h.list().empty());
  // Posted again: a new activity, which alerts.
  h.create(model(20, block()));
  EXPECT_TRUE(getBool(hintsOf(h.presenter->last(20)), "silent") == std::optional<bool>(false));
}

TEST(TapOpensTheAppAndKeepsIt) {
  Harness h;
  h.create(model(21, block()));
  auto type = h.press(21, "");
  EXPECT_TRUE(type == std::optional<ActionType>(ActionType::Default));
  EXPECT_EQ(h.count("defaultAction"), 1);
  EXPECT_TRUE(h.presenter->shows(21));
  EXPECT_EQ(h.list(), Strings{"21:active"});
}

TEST(AutoDismissingButtonEndsIt) {
  Harness h;
  ValueMap m = model(22, block());
  m["actionButtons"] = ValueList{ValueMap{{"key", "stay"}, {"label", "Stay"}, {"autoDismissible", false}},
                                 ValueMap{{"key", "done"}, {"label", "Done"}}};
  h.create(m);
  h.press(22, "stay");
  EXPECT_EQ(h.count("defaultAction"), 1);
  EXPECT_TRUE(h.presenter->shows(22));
  EXPECT_TRUE(h.states().empty());
  h.press(22, "stay");  // the model stays for the next press
  EXPECT_EQ(h.count("defaultAction"), 2);
  h.press(22, "done");
  EXPECT_EQ(h.count("defaultAction"), 3);
  EXPECT_FALSE(h.presenter->shows(22));
  EXPECT_EQ(h.states(), (Strings{"22:ended", "22:dismissed"}));
  auto action = h.events.back().content;
  EXPECT_EQ(str(getMap(action, "payload"), "activityId"), std::string("22"));
}

TEST(SameActivityOnAnotherIdMovesIt) {
  Harness h;
  h.create(model(23, block({{"activityId", "trip"}})));
  h.create(model(24, block({{"activityId", "trip"}})));
  EXPECT_FALSE(h.presenter->shows(23));
  EXPECT_TRUE(h.presenter->shows(24));
  EXPECT_TRUE(h.states().empty());
  EXPECT_EQ(h.list(), Strings{"trip:active"});
}

// MARK: - Methods

TEST(EndMethodShowsTheLastContentEnded) {
  Harness h;
  h.create(model(30, block({{"activityId", "x"}}), {{"progress", 80}}));
  size_t before = h.presenter->presented.size();
  int created = h.count("notificationCreated");
  EXPECT_TRUE(h.call("liveActivityEnd", Value(ValueMap{{"activityId", "x"}, {"dismissal", "default"}}))
                  .isNull());
  EXPECT_EQ(h.presenter->presented.size(), before + 1);
  EXPECT_EQ(h.count("notificationCreated"), created);  // no new events
  auto ended = h.presenter->last(30);
  EXPECT_TRUE(getBool(hintsOf(ended), "resident") == std::optional<bool>(false));
  EXPECT_EQ(str(contentOf(ended), "body").find("On the way\n"), size_t(0));
  EXPECT_CONTAINS(str(contentOf(ended), "body"), "80%");
  // The stored model is the ended one (an activation after it sees it ended).
  EXPECT_EQ(str(getMap(*h.store->get(30), "liveActivity"), "state"), std::string("ended"));
  EXPECT_EQ(h.list(), Strings{"x:ended"});
  EXPECT_EQ(h.states(), Strings{"x:ended"});

  h.call("liveActivityEnd", Value(ValueMap{{"activityId", "x"}, {"dismissal", "immediate"}}));
  EXPECT_FALSE(h.presenter->shows(30));
  EXPECT_EQ(h.states(), (Strings{"x:ended", "x:dismissed"}));
  h.call("liveActivityEnd", Value(ValueMap{{"activityId", "unknown"}}));  // nothing to end
}

TEST(EndMethodAtATime) {
  Harness h;
  h.create(model(31, block()));
  h.call("liveActivityEnd", Value(ValueMap{{"activityId", "31"}, {"dismissal", h.now + 10}}));
  EXPECT_EQ(h.timers.size(), size_t(1));
  h.now += 10;
  h.fireTimers();
  EXPECT_FALSE(h.presenter->shows(31));
  EXPECT_EQ(h.states(), (Strings{"31:ended", "31:dismissed"}));
}

TEST(DesktopMethods) {
  Harness h;
  EXPECT_TRUE(h.call("liveActivityAreEnabled") == Value(true));
  EXPECT_TRUE(h.call("liveActivityRequestPermission") == Value(true));
  EXPECT_TRUE(h.call("liveActivityPushToStartToken").isNull());
  EXPECT_TRUE(h.call("liveActivityPushToken", Value(ValueMap{{"activityId", "a"}})).isNull());
  ValueMap caps = h.call("liveActivityCapabilities").map();
  for (auto key : {"systemSurface", "progressSegments", "metrics", "push"})
    EXPECT_TRUE(getBool(caps, key) == std::optional<bool>(false));
  EXPECT_TRUE(getBool(caps, "buttons") == std::optional<bool>(true));
  EXPECT_TRUE(h.call("liveActivityList").list().empty());
}

// MARK: - Windows (toast)

TEST(ToastFirstPostThenDataUpdates) {
  Harness h(Surface::toast);
  h.create(model(40, block({{"shortText", "12 min"},
                            {"timer", ValueMap{{"end", int64_t(2000)}, {"countDown", true}}}}),
                 {{"progress", 60}}));
  auto first = toastPostOf(h.presenter->last(40)->model, false);
  EXPECT_FALSE(first.update);
  EXPECT_FALSE(first.suppressPopup);
  EXPECT_EQ(first.tag, std::string("40"));
  EXPECT_CONTAINS(first.xml, "<text>{title}</text><text>{body}</text>");
  EXPECT_CONTAINS(first.xml,
                  "<progress title=\"{progressTitle}\" value=\"{progressValue}\" "
                  "valueStringOverride=\"{progressValueString}\" status=\"{progressStatus}\"/>"
                  "</binding>");
  EXPECT_FALSE(first.xml.find("<audio silent") != std::string::npos);
  EXPECT_EQ(first.data["title"], std::string("Order"));
  EXPECT_EQ(first.data["body"], std::string("On the way\nEnds at T2000"));  // no text bar
  EXPECT_EQ(first.data["progressValue"], std::string("0.6"));
  EXPECT_EQ(first.data["progressValueString"], std::string("60%"));
  EXPECT_EQ(first.data["progressStatus"], std::string("12 min"));

  h.create(model(40, block({{"shortText", "8 min"}}), {{"progress", 75}}));
  auto update = toastPostOf(h.presenter->last(40)->model, false);
  EXPECT_TRUE(update.update);
  EXPECT_TRUE(update.suppressPopup);
  EXPECT_TRUE(update.sequence > first.sequence);
  EXPECT_EQ(update.data["progressValue"], std::string("0.75"));
  EXPECT_EQ(update.data["progressStatus"], std::string("8 min"));
  EXPECT_CONTAINS(update.xml, "<audio silent=\"true\"/>");

  // `alert`: shown again, with its popup and sound.
  h.create(model(40, block({{"alert", true}}), {{"progress", 80}}));
  auto alert = toastPostOf(h.presenter->last(40)->model, false);
  EXPECT_FALSE(alert.update);
  EXPECT_FALSE(alert.suppressPopup);
}

TEST(ToastIndeterminateAndNoBar) {
  Harness h(Surface::toast);
  h.create(model(41, block({{"progress", ValueMap{}}, {"shortText", "soon"}})));
  auto post = toastPostOf(h.presenter->last(41)->model, false);
  EXPECT_EQ(post.data["progressValue"], std::string("indeterminate"));
  EXPECT_EQ(post.data["progressValueString"], std::string(""));
  EXPECT_CONTAINS(post.xml, "<progress");

  h.create(model(42, block({{"shortText", "soon"}})));
  auto plain = toastPostOf(h.presenter->last(42)->model, false);
  EXPECT_EQ(plain.xml.find("<progress"), std::string::npos);
  EXPECT_EQ(plain.data["body"], std::string("On the way\nsoon"));  // shortText in the text
}

TEST(ToastNewLayoutIsShownAgainQuietly) {
  Harness h(Surface::toast);
  h.create(model(43, block()));
  ValueMap withButton = model(43, block());
  withButton["actionButtons"] = ValueList{ValueMap{{"key", "stop"}, {"label", "Stop"}}};
  h.create(withButton);
  auto post = toastPostOf(h.presenter->last(43)->model, true);
  EXPECT_FALSE(post.update);         // a new layout can't be a data update
  EXPECT_TRUE(post.suppressPopup);   // but it doesn't pop again
  EXPECT_CONTAINS(post.xml, "content=\"Stop\"");
  EXPECT_CONTAINS(post.xml, "<audio silent=\"true\"/>");
}

TEST(ToastEndMethodUpdatesInPlace) {
  Harness h(Surface::toast);
  h.create(model(44, block(), {{"progress", 10}}));
  h.call("liveActivityEnd", Value(ValueMap{{"activityId", "44"}}));
  auto post = toastPostOf(h.presenter->last(44)->model, false);
  EXPECT_TRUE(post.update);
  EXPECT_EQ(post.data["progressValue"], std::string("0.1"));
}

TEST(ToastLocalImagesOnly) {
  EXPECT_EQ(localImagePath("file:///C:/img/a.png"), std::string("C:/img/a.png"));
  EXPECT_EQ(localImagePath("C:\\img\\a.png"), std::string("C:\\img\\a.png"));
  EXPECT_EQ(localImagePath("https://example.com/a.png"), std::string());
  EXPECT_EQ(localImagePath("asset://images/a.png"), std::string());
}

TEST(SilentChannel) {
  EXPECT_FALSE(silentChannel(std::nullopt));
  EXPECT_FALSE(silentChannel(ValueMap{{"channelKey", "x"}}));
  EXPECT_TRUE(silentChannel(ValueMap{{"playSound", false}}));
}

TEST(UnpackagedAumidMatchesTheCore) {
  // Same derivation as the core's AppIdentity::Resolve (FNV-1a 64 of the
  // lowercase path, low 32 bits).
  std::wstring path = L"C:\\Apps\\My App.exe";
  std::wstring lower = L"c:\\apps\\my app.exe";
  uint64_t hash = 14695981039346656037ULL;
  for (wchar_t c : lower) {
    hash ^= static_cast<uint64_t>(c);
    hash *= 1099511628211ULL;
  }
  wchar_t hex[17];
  std::swprintf(hex, 17, L"%08llx", static_cast<unsigned long long>(hash & 0xFFFFFFFFULL));
  EXPECT_TRUE(unpackagedAumid(path) == std::wstring(L"AwesomeNotifications.MyApp.") + hex);
  EXPECT_TRUE(unpackagedAumid(L"C:\\x\\+++.exe").rfind(L"AwesomeNotifications.App.", 0) == 0);
}

int main() { return awn_test::runAll(); }
