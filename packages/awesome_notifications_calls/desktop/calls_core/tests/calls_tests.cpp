// Unit tests of the desktop call logic, on the desktop core's engine and
// harness, with a fake presenter and a manual timer. No Flutter, GLib or
// Windows.
#include <algorithm>
#include <memory>
#include <set>

#include "awn/awesome_notifications.h"
#include "awn/freedesktop.h"
#include "awn/method_router.h"
#include "awn/platform.h"
#include "awn/registries.h"
#include "awn/toast_xml.h"
#include "awn_calls/calls.h"
#include "awn_test.h"

using namespace awn;
using namespace awn_calls;

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

ValueList names(std::initializer_list<const char*> list) {
  ValueList out;
  for (auto name : list) out.push_back(Value(name));
  return out;
}

ValueMap callBlock(ValueMap extra = {}) {
  ValueMap call{{"callId", "c-1"},
                {"caller", ValueMap{{"key", "u-2"},
                                    {"name", "Ana"},
                                    {"avatar", "https://example.com/ana.png"},
                                    {"isBot", false},
                                    {"isImportant", false}}},
                {"video", false},
                {"state", "incoming"},
                {"ringTimeout", 30000},
                {"missedNotification", true},
                {"controls", names({"accept", "decline", "hangUp", "mute", "hold"})},
                {"commandTarget", "actionEvent"},
                {"systemCallUI", true},
                {"texts", ValueMap{{"incoming", "Incoming call"},
                                   {"incomingVideo", "Incoming video call"},
                                   {"outgoing", "Calling"},
                                   {"ongoing", "Ongoing call"},
                                   {"missed", "Missed call"},
                                   {"missedVideo", "Missed video call"},
                                   {"accept", "Accept"},
                                   {"decline", "Decline"},
                                   {"hangUp", "Hang up"}}}};
  for (auto& [k, v] : extra) call[k] = v;
  return call;
}

ValueMap model(int id, std::optional<ValueMap> call, ValueMap contentExtra = {}) {
  ValueMap content{{"id", id}, {"channelKey", "calls"}};
  for (auto& [k, v] : contentExtra) content[k] = v;
  ValueMap m{{"content", content}};
  if (call) m["call"] = *call;
  return m;
}

std::string str(const ValueMap& map, const char* key) { return getString(map, key).value_or(""); }

std::vector<std::string> buttonKeys(const ValueMap& m) {
  std::vector<std::string> keys;
  for (const auto& b : NotificationBuilder::actionButtons(m)) keys.push_back(str(b.map(), "key"));
  return keys;
}

CallModel parsed(ValueMap block) {
  auto call = CallModel::parse(Value(block));
  return call ? *call : CallModel{};
}

/// A fresh engine with the calls registered, on a manual clock and timer.
struct Harness {
  std::shared_ptr<FakePresenter> presenter = std::make_shared<FakePresenter>();
  std::shared_ptr<NotificationStore> store = std::make_shared<NotificationStore>();
  AwesomeNotifications engine;
  int64_t now = 1'800'000'000'000;
  std::vector<Timer> timers;
  std::shared_ptr<CallController> controller;
  std::vector<Event> events;
  std::vector<ValueMap> stream;
  int token;

  Harness() {
    NotificationBuilderRegistry::shared().clearForTest();
    AwesomeMethodHandlerRegistry::shared().clearForTest();
    engine.configure(presenter, std::make_shared<InlineDispatcher>(), store, false);
    CallHost host = engineHost(engine, [this](int64_t ms, std::function<void()> work) {
      timers.push_back({ms, std::move(work)});
    });
    host.now = [this] { return now; };
    controller = std::make_shared<CallController>(std::move(host));
    controller->setStreamSink([this](const ValueMap& event) { stream.push_back(event); });
    RegisterCalls(controller, desktopCapabilities(), engine);
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
  const Event* last(const std::string& name) const {
    for (auto it = events.rbegin(); it != events.rend(); ++it)
      if (it->name == name) return &*it;
    return nullptr;
  }
  std::string lastAction() const {
    auto action = last("defaultAction");
    return action ? str(action->content, "buttonKeyPressed") : "";
  }
  std::vector<ValueMap> calls() {
    std::vector<ValueMap> out;
    Value answer = call("callActiveCalls");
    for (const auto& entry : answer.list()) out.push_back(entry.map());
    return out;
  }
};

const std::string kInvalid = "INVALID_ARGUMENTS|arguments.invalid.notificationCall";

}  // namespace

// MARK: - Model

TEST(ParsesTheCallBlock) {
  auto call = parsed(callBlock({{"handle", "tel:+5511999"},
                                {"groupName", "Team"},
                                {"video", true},
                                {"startedAt", int64_t(1700000000000)},
                                {"commandTarget", "both"},
                                {"controls", names({"accept", "decline", "teleport"})}}));
  EXPECT_EQ(call.callId, std::string("c-1"));
  EXPECT_EQ(call.caller.key, std::string("u-2"));
  EXPECT_EQ(call.caller.name, std::string("Ana"));
  EXPECT_EQ(call.caller.avatar, std::string("https://example.com/ana.png"));
  EXPECT_EQ(call.handle, std::string("tel:+5511999"));
  EXPECT_EQ(call.groupName, std::string("Team"));
  EXPECT_EQ(call.displayName(), std::string("Team"));
  EXPECT_TRUE(call.video);
  EXPECT_TRUE(call.state == CallState::incoming);
  EXPECT_EQ(call.startedAt.value_or(0), int64_t(1700000000000));
  EXPECT_EQ(call.ringTimeoutMs, int64_t(30000));
  EXPECT_EQ(call.controls.size(), size_t(2));
  EXPECT_TRUE(call.toActionEvent());
  EXPECT_TRUE(call.toStream());
}

TEST(ParseDefaults) {
  auto call = CallModel::parse(Value(ValueMap{{"callId", "x"},
                                              {"caller", ValueMap{{"key", "k"}, {"name", "N"}}},
                                              {"state", "ongoing"}}));
  EXPECT_TRUE(call.has_value());
  EXPECT_EQ(call->handle, std::string("k"));  // the caller's key
  EXPECT_FALSE(call->video);
  EXPECT_EQ(call->ringTimeoutMs, int64_t(60000));
  EXPECT_TRUE(call->missedNotification);
  EXPECT_EQ(call->controls.size(), size_t(5));
  EXPECT_TRUE(call->target == CommandTarget::actionEvent);
  EXPECT_EQ(call->texts.accept, std::string("Accept"));
  EXPECT_EQ(call->texts.outgoing, std::string("Calling\xE2\x80\xA6"));
  EXPECT_EQ(call->displayName(), std::string("N"));
  EXPECT_FALSE(parsed(callBlock({{"commandTarget", "stream"}})).toActionEvent());
}

// NotificationCall.validate() rules, plus what Dart can't send but a push can.
TEST(ParseRejectsInvalidBlocks) {
  auto rejects = [](ValueMap block, const char* reason) {
    std::string error;
    bool rejected = !CallModel::parse(Value(block), &error).has_value();
    EXPECT_TRUE(rejected);
    EXPECT_CONTAINS(error, reason);
  };
  rejects(callBlock({{"callId", "  "}}), "callId");
  ValueMap noCaller = callBlock();
  noCaller.erase("caller");
  rejects(noCaller, "caller");
  rejects(callBlock({{"caller", ValueMap{{"key", ""}, {"name", "A"}}}}), "caller needs a non-empty key");
  rejects(callBlock({{"caller", ValueMap{{"key", "k"}, {"name", " "}}}}), "caller needs a non-empty name");
  rejects(callBlock({{"handle", ""}}), "handle");
  rejects(callBlock({{"groupName", " "}}), "groupName");
  rejects(callBlock({{"ringTimeout", 0}}), "ring timeout");
  rejects(callBlock({{"controls", names({"hangUp"})}}), "accept or the decline");
  rejects(callBlock({{"state", "ringing"}}), "Unknown call state");
  std::string error;
  EXPECT_FALSE(CallModel::parse(Value("x"), &error).has_value());
  // Only an incoming call needs accept / decline.
  EXPECT_TRUE(CallModel::parse(Value(callBlock({{"state", "ongoing"}, {"controls", ValueList{}}})))
                  .has_value());
}

TEST(MissedIdIsStableAndPositive) {
  EXPECT_EQ(missedId("c-1"), missedId("c-1"));
  EXPECT_FALSE(missedId("c-1") == missedId("c-2"));
  EXPECT_TRUE(missedId("c-1") >= 0);
  // Java String.hashCode() of "missed:" + callId over UTF-16 units, masked
  // positive: the same id as Android / Apple / Web.
  EXPECT_EQ(missedId("c-1"), int64_t(1927345128));
  EXPECT_EQ(missedId("c-\xC3\xA7\xF0\x9F\x98\x80"), int64_t(1049711233));
}

// MARK: - Builder

TEST(ScheduledCallIsRefused) {
  Harness h;
  ValueMap m = model(1, callBlock());
  m["schedule"] = ValueMap{{"interval", 60}};
  EXPECT_EQ(h.create(m), kInvalid + ".schedule");
  EXPECT_TRUE(h.presenter->presented.empty());
  EXPECT_TRUE(h.calls().empty());
}

TEST(MalformedCallIsRefused) {
  Harness h;
  EXPECT_EQ(h.create(model(1, callBlock({{"callId", ""}}))), kInvalid);
  EXPECT_EQ(h.create(model(1, callBlock({{"state", "bogus"}}))), kInvalid);
  EXPECT_TRUE(h.presenter->presented.empty());
}

TEST(NotificationWithoutCallIsUntouched) {
  Harness h;
  EXPECT_EQ(h.create(model(4, std::nullopt, {{"title", "Hi"}, {"category", "Call"}})),
            std::string("true"));
  const auto* shown = h.presenter->last(4);
  EXPECT_TRUE(shown != nullptr);
  EXPECT_FALSE(has(shown->model, "desktopPresentation"));
  EXPECT_FALSE(has(getMap(NotificationBuilder::content(shown->model), "payload"), "callId"));
  EXPECT_TRUE(h.timers.empty());
}

TEST(PushedCallRings) {
  Harness h;
  EXPECT_EQ(h.create(model(5, callBlock(), {{"createdSource", "Firebase"}})), std::string("true"));
  EXPECT_EQ(h.calls().size(), size_t(1));
}

TEST(IncomingCallIsTheStrongestNotification) {
  Harness h;
  EXPECT_EQ(h.create(model(7, callBlock(), {{"payload", ValueMap{{"k", "v"}}}})),
            std::string("true"));
  const auto* shown = h.presenter->last(7);
  EXPECT_TRUE(shown != nullptr);
  ValueMap content = NotificationBuilder::content(shown->model);
  EXPECT_EQ(str(content, "title"), std::string("Ana"));
  EXPECT_EQ(str(content, "body"), std::string("Incoming call"));
  EXPECT_EQ(str(content, "largeIcon"), std::string("https://example.com/ana.png"));
  EXPECT_TRUE(getBool(content, "roundedLargeIcon").value_or(false));
  EXPECT_EQ(str(getMap(content, "payload"), "callId"), std::string("c-1"));
  EXPECT_EQ(str(getMap(content, "payload"), "k"), std::string("v"));
  EXPECT_EQ(buttonKeys(shown->model),
            (std::vector<std::string>{"awn.call.accept", "awn.call.decline"}));

  // Linux: critical, resident, ringing, Accept / Decline.
  auto n = Freedesktop::render(shown->model, {}, false, "Default", {"actions", "body"});
  EXPECT_EQ(n.urgency, 2);
  EXPECT_TRUE(n.resident);
  EXPECT_EQ(n.soundName, std::string("phone-incoming-call"));
  EXPECT_EQ(n.actions.size(), size_t(3));  // default + Accept + Decline
  EXPECT_EQ(n.actions[1].second, std::string("Accept"));
  EXPECT_EQ(n.actions[2].second, std::string("Decline"));
  // Windows: incomingCall toast, looping ring, Accept (foreground) / Decline.
  auto xml = ToastXml::render(shown->model, {}, false);
  EXPECT_CONTAINS(xml, "scenario=\"incomingCall\"");
  EXPECT_CONTAINS(xml, "loop=\"true\"");
  EXPECT_CONTAINS(xml, "<action content=\"Accept\" arguments=\"awn&amp;id=7&amp;btn=awn.call.accept\" hint-buttonStyle=\"Success\"/>");
  EXPECT_CONTAINS(xml, "btn=awn.call.decline\" activationType=\"background\" hint-buttonStyle=\"Critical\"");

  // Created and displayed like any notification; the ring timer runs.
  EXPECT_EQ(h.count("notificationCreated"), 1);
  EXPECT_EQ(h.count("notificationDisplayed"), 1);
  EXPECT_EQ(h.timers.size(), size_t(1));
  EXPECT_EQ(h.timers[0].ms, int64_t(30000));
  auto calls = h.calls();
  EXPECT_EQ(str(calls[0], "callId"), std::string("c-1"));
  EXPECT_EQ(str(calls[0], "state"), std::string("incoming"));
}

TEST(GroupVideoCallAndAppTitle) {
  Harness h;
  h.create(model(8, callBlock({{"groupName", "Team"}, {"video", true}})));
  ValueMap content = NotificationBuilder::content(h.presenter->last(8)->model);
  EXPECT_EQ(str(content, "title"), std::string("Team"));
  EXPECT_EQ(str(content, "body"), std::string("Incoming video call"));
  h.create(model(9, callBlock({{"callId", "c-9"}}), {{"title", "Work line"}, {"largeIcon", "asset://me.png"}}));
  content = NotificationBuilder::content(h.presenter->last(9)->model);
  EXPECT_EQ(str(content, "title"), std::string("Work line"));
  EXPECT_EQ(str(content, "largeIcon"), std::string("asset://me.png"));
}

TEST(OutgoingAndOngoingAreQuietWithHangUp) {
  Harness h;
  h.create(model(10, callBlock({{"state", "outgoing"}})));
  const auto* shown = h.presenter->last(10);
  EXPECT_EQ(str(NotificationBuilder::content(shown->model), "body"), std::string("Calling"));
  EXPECT_EQ(buttonKeys(shown->model), std::vector<std::string>{"awn.call.hangUp"});
  auto n = Freedesktop::render(shown->model, {}, false, "Max", {"actions"});
  EXPECT_TRUE(n.resident);
  EXPECT_TRUE(n.suppressSound);
  EXPECT_EQ(n.urgency, 1);
  EXPECT_CONTAINS(ToastXml::render(shown->model, {}, false), "<audio silent=\"true\"/>");
  EXPECT_TRUE(h.timers.empty());  // only a ringing call times out

  h.create(model(10, callBlock({{"state", "held"}, {"controls", ValueList{}}})));
  shown = h.presenter->last(10);
  EXPECT_EQ(str(NotificationBuilder::content(shown->model), "body"), std::string("On hold"));
  EXPECT_TRUE(buttonKeys(shown->model).empty());
  EXPECT_EQ(str(h.calls()[0], "state"), std::string("held"));
}

TEST(AppButtonsFollowTheCallButtons) {
  Harness h;
  ValueMap m = model(11, callBlock());
  m["actionButtons"] = ValueList{ValueMap{{"key", "MSG"}, {"label", "Message"}}};
  h.create(m);
  EXPECT_EQ(buttonKeys(h.presenter->last(11)->model),
            (std::vector<std::string>{"awn.call.accept", "awn.call.decline", "MSG"}));
  // The app's own button is the core's: an ordinary action event.
  h.press(11, "MSG");
  EXPECT_EQ(h.lastAction(), std::string("MSG"));
  EXPECT_TRUE(h.stream.empty());
}

// MARK: - Commands

TEST(AcceptMakesTheCallOngoingThenEmits) {
  Harness h;
  h.create(model(20, callBlock()));
  auto type = h.press(20, "awn.call.accept");
  EXPECT_TRUE(type == ActionType::Default);  // the app comes forward

  // The notification is the ongoing call now: Hang up, quiet, timer base.
  const auto* shown = h.presenter->last(20);
  EXPECT_EQ(buttonKeys(shown->model), std::vector<std::string>{"awn.call.hangUp"});
  EXPECT_EQ(str(NotificationBuilder::content(shown->model), "body"), std::string("Ongoing call"));
  ValueMap block = getMap(shown->model, "call");
  EXPECT_EQ(str(block, "state"), std::string("ongoing"));
  EXPECT_EQ(getInt(block, "startedAt").value_or(0), h.now);
  EXPECT_TRUE(h.presenter->shows(20));
  EXPECT_EQ(str(getMap(*h.store->get(20), "call"), "state"), std::string("ongoing"));
  EXPECT_EQ(str(h.calls()[0], "state"), std::string("ongoing"));

  auto action = h.last("defaultAction");
  EXPECT_EQ(str(action->content, "buttonKeyPressed"), std::string("awn.call.accept"));
  EXPECT_EQ(str(getMap(action->content, "payload"), "callId"), std::string("c-1"));
  EXPECT_TRUE(h.stream.empty());  // actionEvent only

  // The ring stopped: no timeout, no missed call.
  h.fireTimers();
  EXPECT_EQ(h.count("defaultAction"), 1);
  EXPECT_FALSE(h.presenter->last(missedId("c-1")) != nullptr);

  // Hang up ends it.
  EXPECT_TRUE(h.press(20, "awn.call.hangUp") == ActionType::SilentAction);
  EXPECT_FALSE(h.presenter->shows(20));
  EXPECT_TRUE(h.calls().empty());
  EXPECT_EQ(h.lastAction(), std::string("awn.call.hangUp"));
}

TEST(AcceptKeepsAGivenStartedAt) {
  Harness h;
  h.create(model(21, callBlock({{"startedAt", int64_t(1234)}})));
  h.press(21, "awn.call.accept");
  EXPECT_EQ(getInt(getMap(h.presenter->last(21)->model, "call"), "startedAt").value_or(0),
            int64_t(1234));
}

TEST(DeclineEndsTheCallThenEmits) {
  Harness h;
  h.create(model(22, callBlock()));
  EXPECT_TRUE(h.press(22, "awn.call.decline") == ActionType::SilentAction);
  EXPECT_FALSE(h.presenter->shows(22));
  EXPECT_FALSE(h.store->get(22).has_value());
  EXPECT_TRUE(h.calls().empty());
  EXPECT_EQ(h.lastAction(), std::string("awn.call.decline"));
  EXPECT_EQ(str(h.last("defaultAction")->content, "actionType"), std::string("SilentAction"));
  h.fireTimers();  // the ring of an ended call does nothing
  EXPECT_EQ(h.count("defaultAction"), 1);
  EXPECT_FALSE(h.presenter->last(missedId("c-1")) != nullptr);
}

TEST(CommandTargetStreamSkipsTheActionEvent) {
  Harness h;
  h.create(model(23, callBlock({{"commandTarget", "stream"}})));
  h.press(23, "awn.call.decline");
  EXPECT_EQ(h.count("defaultAction"), 0);
  EXPECT_EQ(h.stream.size(), size_t(1));
  EXPECT_EQ(str(h.stream[0], "kind"), std::string("command"));
  EXPECT_EQ(str(h.stream[0], "action"), std::string("decline"));
  EXPECT_EQ(str(h.stream[0], "callId"), std::string("c-1"));
}

TEST(CommandTargetBothDeliversTwice) {
  Harness h;
  h.create(model(24, callBlock({{"commandTarget", "both"}})));
  h.press(24, "awn.call.accept");
  EXPECT_EQ(h.lastAction(), std::string("awn.call.accept"));
  EXPECT_EQ(h.stream.size(), size_t(1));
  EXPECT_EQ(str(h.stream[0], "action"), std::string("accept"));
}

TEST(TappingTheCallOpensTheAppAndKeepsIt) {
  Harness h;
  h.create(model(25, callBlock()));
  EXPECT_TRUE(h.press(25, "") == ActionType::Default);
  EXPECT_EQ(h.count("defaultAction"), 1);
  EXPECT_TRUE(h.presenter->shows(25));
  EXPECT_TRUE(h.store->get(25).has_value());
  EXPECT_EQ(h.calls().size(), size_t(1));
}

TEST(CommandAfterARestartStillWorks) {
  // A toast Accept / Decline can start the app (Windows): the call is only in
  // the stored model.
  Harness h;
  ValueMap stored = callNotification(model(26, callBlock()), parsed(callBlock()));
  h.store->put(26, stored);
  h.presenter->delivered.push_back(26);
  h.press(26, "awn.call.accept");
  EXPECT_EQ(h.lastAction(), std::string("awn.call.accept"));
  EXPECT_EQ(str(h.calls()[0], "state"), std::string("ongoing"));
  EXPECT_EQ(buttonKeys(h.presenter->last(26)->model),
            std::vector<std::string>{"awn.call.hangUp"});
}

// MARK: - Ring timer

TEST(RingTimeoutMissesTheCall) {
  Harness h;
  h.create(model(30, callBlock()));
  h.fireTimers();
  EXPECT_FALSE(h.presenter->shows(30));
  EXPECT_TRUE(h.calls().empty());
  // The missed call notification: same channel, its own stable id.
  const auto* missed = h.presenter->last(missedId("c-1"));
  EXPECT_TRUE(missed != nullptr);
  ValueMap content = NotificationBuilder::content(missed->model);
  EXPECT_EQ(str(content, "title"), std::string("Ana"));
  EXPECT_EQ(str(content, "body"), std::string("Missed call"));
  EXPECT_EQ(str(content, "channelKey"), std::string("calls"));
  EXPECT_EQ(str(content, "largeIcon"), std::string("https://example.com/ana.png"));
  EXPECT_EQ(str(getMap(content, "payload"), "callId"), std::string("c-1"));
  EXPECT_TRUE(NotificationBuilder::actionButtons(missed->model).empty());
  EXPECT_FALSE(has(missed->model, "desktopPresentation"));
  EXPECT_EQ(h.count("notificationCreated"), 2);  // the call's and the missed one
  // Then the timeout command.
  EXPECT_EQ(h.lastAction(), std::string("awn.call.timeout"));
  EXPECT_EQ(str(getMap(h.last("defaultAction")->content, "payload"), "callId"),
            std::string("c-1"));
}

TEST(RingTimeoutWithoutMissedNotification) {
  Harness h;
  h.create(model(31, callBlock({{"missedNotification", false},
                                {"commandTarget", "stream"},
                                {"video", true}})));
  h.fireTimers();
  EXPECT_FALSE(h.presenter->last(missedId("c-1")) != nullptr);
  EXPECT_EQ(h.count("defaultAction"), 0);
  EXPECT_EQ(str(h.stream.at(0), "action"), std::string("timeout"));
}

TEST(UpdatingARingingCallKeepsItsTimerAndId) {
  Harness h;
  h.create(model(32, callBlock()));
  h.create(model(32, callBlock({{"caller", ValueMap{{"key", "u-2"}, {"name", "Ana Maria"}}}})));
  EXPECT_EQ(h.timers.size(), size_t(1));  // not restarted
  EXPECT_EQ(str(NotificationBuilder::content(h.presenter->last(32)->model), "title"),
            std::string("Ana Maria"));
  EXPECT_EQ(h.calls().size(), size_t(1));
  h.fireTimers();
  EXPECT_EQ(h.lastAction(), std::string("awn.call.timeout"));
}

TEST(SameCallOnAnotherIdMovesIt) {
  Harness h;
  h.create(model(33, callBlock()));
  h.create(model(34, callBlock({{"state", "ongoing"}})));
  EXPECT_FALSE(h.presenter->shows(33));
  EXPECT_TRUE(h.presenter->shows(34));
  auto calls = h.calls();
  EXPECT_EQ(calls.size(), size_t(1));
  EXPECT_EQ(str(calls[0], "state"), std::string("ongoing"));
  h.fireTimers();  // ongoing now: the old ring does nothing
  EXPECT_EQ(h.count("defaultAction"), 0);
}

// MARK: - States from the app

TEST(EndedRemovesTheCallWithoutCommand) {
  Harness h;
  h.create(model(40, callBlock()));
  EXPECT_EQ(h.create(model(40, callBlock({{"state", "ended"}}))), std::string("true"));
  EXPECT_FALSE(h.presenter->shows(40));
  EXPECT_FALSE(h.store->get(40).has_value());
  EXPECT_TRUE(h.calls().empty());
  EXPECT_FALSE(h.presenter->last(missedId("c-1")) != nullptr);
  h.fireTimers();
  EXPECT_EQ(h.count("defaultAction"), 0);
  EXPECT_TRUE(h.stream.empty());
}

TEST(MissedShowsTheMissedNotification) {
  Harness h;
  h.create(model(41, callBlock()));
  h.create(model(41, callBlock({{"state", "missed"}, {"video", true}})));
  EXPECT_FALSE(h.presenter->shows(41));
  const auto* missed = h.presenter->last(missedId("c-1"));
  EXPECT_TRUE(missed != nullptr);
  EXPECT_EQ(str(NotificationBuilder::content(missed->model), "body"),
            std::string("Missed video call"));
  h.fireTimers();
  EXPECT_EQ(h.count("defaultAction"), 0);
  // Turned off: nothing.
  Harness quiet;
  quiet.create(model(42, callBlock({{"callId", "c-42"}, {"state", "missed"},
                                    {"missedNotification", false}})));
  EXPECT_FALSE(quiet.presenter->last(missedId("c-42")) != nullptr);
}

// MARK: - Removal / methods

TEST(CancellingTheNotificationEndsTheCall) {
  Harness h;
  h.create(model(50, callBlock()));
  h.call("cancelNotification", Value(50));
  EXPECT_TRUE(h.calls().empty());
  h.fireTimers();
  EXPECT_EQ(h.count("defaultAction"), 0);
  EXPECT_FALSE(h.presenter->last(missedId("c-1")) != nullptr);

  h.create(model(51, callBlock({{"callId", "c-51"}, {"state", "ongoing"}})));
  h.call("dismissAllNotifications");
  h.engine.dismissAll();
  EXPECT_TRUE(h.calls().empty());
  EXPECT_TRUE(h.stream.empty());
}

TEST(CallEndUnansweredShowsTheMissedCall) {
  Harness h;
  h.create(model(60, callBlock()));
  h.create(model(61, callBlock({{"callId", "c-61"}, {"state", "ongoing"}})));
  EXPECT_TRUE(h.call("callEnd", Value(ValueMap{{"callId", "c-1"}, {"reason", "unanswered"}})).isNull());
  EXPECT_FALSE(h.presenter->shows(60));
  EXPECT_TRUE(h.presenter->last(missedId("c-1")) != nullptr);
  h.call("callEnd", Value(ValueMap{{"callId", "c-61"}, {"reason", "remoteEnded"}}));
  EXPECT_FALSE(h.presenter->shows(61));
  EXPECT_FALSE(h.presenter->last(missedId("c-61")) != nullptr);
  EXPECT_TRUE(h.calls().empty());
  EXPECT_EQ(h.count("defaultAction"), 0);
  h.call("callEnd", Value(ValueMap{{"callId", "unknown"}}));  // nothing to end
}

TEST(DesktopMethods) {
  Harness h;
  EXPECT_TRUE(h.call("callVoipToken").isNull());
  EXPECT_TRUE(h.call("callCanUseFullScreenIntent") == Value(true));
  EXPECT_TRUE(h.call("callRequestFullScreenIntent") == Value(true));
  ValueMap caps = h.call("callCapabilities").map();
  for (auto key : {"systemCallUI", "lockScreen", "muteAndHold", "push"})
    EXPECT_TRUE(getBool(caps, key) == std::optional<bool>(false));
  EXPECT_TRUE(h.call("callActiveCalls").list().empty());
}

int main() { return awn_test::runAll(); }
