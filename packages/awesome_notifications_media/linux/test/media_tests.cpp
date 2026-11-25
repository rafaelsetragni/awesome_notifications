// Unit tests of the portable media logic, with the desktop core's harness.
#include <algorithm>
#include <memory>

#include "awn/awesome_notifications.h"
#include "awn/method_router.h"
#include "awn/registries.h"
#include "awn_test.h"
#include "media_model.h"

using namespace awn;
using namespace awn_media;
using namespace std::chrono_literals;

namespace {

class FakePresenter : public NotificationPresenter {
 public:
  std::vector<int64_t> presented;
  void present(const BuiltNotification& built, std::function<void(bool)> done) override {
    presented.push_back(built.id);
    done(true);
  }
  void removeDelivered(const std::vector<int64_t>&) override {}
  void removeAllDelivered() override {}
  void removePending(const std::vector<int64_t>&) override {}
  void removeAllPending() override {}
  std::vector<int64_t> deliveredIds() override { return presented; }
  std::vector<int64_t> pendingIds() override { return {}; }
  bool isAllowed() override { return true; }
  void requestPermission(std::function<void(bool)> done) override { done(true); }
  std::string localTimeZone() override { return "UTC"; }
  int64_t utcOffset(const std::string&, TimePoint) override { return 0; }
  std::string systemLanguage() override { return "en"; }
  std::filesystem::path dataDirectory() override { return {}; }
};

class InlineDispatcher : public Dispatcher {
 public:
  void post(std::function<void()> work) override { work(); }
};

class FakePlayer : public Player {
 public:
  std::vector<std::string> calls;
  std::vector<int64_t> seeks;
  const Session* shown = nullptr;
  void show(const Session& session) override {
    shown = &session;
    calls.push_back("show " + session.media.sessionId);
  }
  void seeked(const Session&, int64_t positionMs) override {
    seeks.push_back(positionMs);
    calls.push_back("seeked");
  }
  void clear() override {
    shown = nullptr;
    calls.push_back("clear");
  }
};

ValueMap mediaBlock(ValueMap extra = {}) {
  ValueMap media{{"sessionId", "main"},
                 {"title", "Song"},
                 {"artist", "Band"},
                 {"duration", int64_t(200000)},
                 {"position", int64_t(10000)},
                 {"playbackSpeed", 1.0},
                 {"state", "playing"},
                 {"controls", ValueList{"play", "pause", "skipNext", "seekTo"}},
                 {"skipInterval", int64_t(15000)},
                 {"commandTarget", "both"}};
  for (auto& [k, v] : extra) media[k] = v;
  return media;
}

ValueMap mediaModel(int id, ValueMap media, std::string layout = "MediaPlayer",
                    ValueMap content = {}) {
  ValueMap c{{"id", id}, {"channelKey", "media"}, {"notificationLayout", layout}};
  for (auto& [k, v] : content) c[k] = v;
  ValueMap m{{"content", c}};
  if (!media.empty()) m["media"] = media;
  return m;
}

MediaModel parsed(ValueMap extra = {}) { return *MediaModel::parse(Value(mediaBlock(extra))); }

/// A controller on a manual clock, recording what it sends.
struct ControllerHarness {
  std::shared_ptr<FakePlayer> player = std::make_shared<FakePlayer>();
  MediaClock::time_point now = MediaClock::time_point() + 1h;
  std::vector<std::pair<std::string, std::optional<std::string>>> actions;
  std::vector<ValueMap> buttons;
  std::vector<ValueMap> events;
  std::shared_ptr<MediaController> controller = std::make_shared<MediaController>(
      player,
      [this](const ValueMap&, const std::string& key, const std::optional<std::string>& input,
             const ValueMap& button) {
        actions.emplace_back(key, input);
        buttons.push_back(button);
      },
      [this](const ValueMap& event) { events.push_back(event); }, [this] { return now; });
};

/// A fresh engine with the media decorator registered.
struct EngineHarness {
  std::shared_ptr<FakePresenter> presenter = std::make_shared<FakePresenter>();
  std::shared_ptr<NotificationStore> store = std::make_shared<NotificationStore>();
  AwesomeNotifications engine;
  ControllerHarness media;
  std::vector<std::pair<std::string, ValueMap>> events;
  int token;

  EngineHarness() {
    NotificationBuilderRegistry::shared().clearForTest();
    AwesomeMethodHandlerRegistry::shared().clearForTest();
    engine.configure(presenter, std::make_shared<InlineDispatcher>(), store, false);
    RegisterMedia(media.controller);
    token = AwesomeEventsReceiver::shared().subscribe(
        [this](const std::string& name, const ValueMap& content) {
          events.emplace_back(name, content);
        });
  }
  ~EngineHarness() { AwesomeEventsReceiver::shared().unsubscribe(token); }

  /// "created" / "false" / "error <code> <details>".
  std::string create(const ValueMap& model) {
    std::string outcome;
    AwesomeMethodRouter router(engine);
    router.handle(
        "createNewNotification", Value(model),
        [&](const Value& v) { outcome = v.asBool().value_or(false) ? "created" : "false"; },
        [&](const std::string& code, const std::string&, const Value& details) {
          outcome = "error " + code + " " + details.asString().value_or("");
        });
    return outcome;
  }

  Value call(const std::string& method, const Value& arguments) {
    Value answer("unanswered");
    AwesomeMethodRouter router(engine);
    bool handled = router.handle(method, arguments, [&](const Value& v) { answer = v; });
    return handled ? answer : Value("not implemented");
  }
};

}  // namespace

// MARK: - Model

TEST(ParsesTheMediaBlock) {
  auto media = parsed({{"album", "Album"}, {"artwork", "asset://images/cover.png"}});
  EXPECT_EQ(media.sessionId, std::string("main"));
  EXPECT_EQ(media.title, std::string("Song"));
  EXPECT_EQ(media.artist, std::string("Band"));
  EXPECT_EQ(media.album, std::string("Album"));
  EXPECT_EQ(media.artwork, std::string("asset://images/cover.png"));
  EXPECT_EQ(media.durationMs.value_or(-1), int64_t(200000));
  EXPECT_EQ(media.positionMs, int64_t(10000));
  EXPECT_EQ(media.speed, 1.0);
  EXPECT_TRUE(media.has(Control::seekTo));
  EXPECT_FALSE(media.has(Control::stop));
  EXPECT_TRUE(media.toActionEvent());
  EXPECT_TRUE(media.toStream());
}

TEST(ParseRejectsInvalidBlocks) {
  std::string error;
  EXPECT_FALSE(MediaModel::parse(Value(mediaBlock({{"sessionId", " "}})), &error).has_value());
  EXPECT_CONTAINS(error, "sessionId");
  EXPECT_FALSE(MediaModel::parse(Value(mediaBlock({{"title", ""}})), &error).has_value());
  EXPECT_FALSE(
      MediaModel::parse(Value(mediaBlock({{"position", int64_t(300000)}})), &error).has_value());
  EXPECT_CONTAINS(error, "past its duration");
  EXPECT_FALSE(MediaModel::parse(Value("x"), &error).has_value());
}

TEST(LiveStreamAndTargetsAndUnknownControls) {
  ValueMap block = mediaBlock({{"commandTarget", "stream"},
                               {"controls", ValueList{"pause", "teleport"}}});
  block.erase("duration");
  auto media = *MediaModel::parse(Value(block));
  EXPECT_FALSE(media.durationMs.has_value());
  EXPECT_FALSE(media.toActionEvent());
  EXPECT_TRUE(media.toStream());
  EXPECT_EQ(media.controls.size(), size_t(1));
  EXPECT_FALSE(parsed({{"commandTarget", "actionEvent"}}).toStream());
}

TEST(StatesMapToPlaybackStatus) {
  EXPECT_EQ(std::string(playbackStatusName(parsed().status())), std::string("Playing"));
  for (const char* state : {"paused", "buffering", "connecting", "next"})
    EXPECT_EQ(std::string(playbackStatusName(parsed({{"state", state}}).status())),
              std::string("Paused"));
  for (const char* state : {"stopped", "none", "unknown", "error"})
    EXPECT_EQ(std::string(playbackStatusName(parsed({{"state", state}}).status())),
              std::string("Stopped"));
}

TEST(FillContentKeepsWhatIsThere) {
  ValueMap model = mediaModel(1, {}, "MediaPlayer", {{"payload", ValueMap{{"k", "v"}}}});
  auto filled = NotificationBuilder::content(fillContent(model, parsed()));
  EXPECT_EQ(getString(filled, "title").value_or(""), std::string("Song"));
  EXPECT_EQ(getString(filled, "body").value_or(""), std::string("Band"));
  auto payload = getMap(filled, "payload");
  EXPECT_EQ(getString(payload, "k").value_or(""), std::string("v"));
  EXPECT_EQ(getString(payload, "mediaSessionId").value_or(""), std::string("main"));

  ValueMap titled = mediaModel(1, {}, "MediaPlayer", {{"title", "Mine"}, {"body", "Text"}});
  auto kept = NotificationBuilder::content(fillContent(titled, parsed()));
  EXPECT_EQ(getString(kept, "title").value_or(""), std::string("Mine"));
  EXPECT_EQ(getString(kept, "body").value_or(""), std::string("Text"));
}

// MARK: - Builder through the core

TEST(MediaModelIsDeliveredToThePlayerNotTheNotificationServer) {
  EngineHarness h;
  EXPECT_EQ(h.create(mediaModel(7, mediaBlock())), std::string("created"));
  EXPECT_TRUE(h.presenter->presented.empty());
  EXPECT_EQ(h.media.player->calls, std::vector<std::string>{"show main"});
  auto active = h.media.controller->active();
  EXPECT_TRUE(active != nullptr);
  auto content = NotificationBuilder::content(active->model);
  EXPECT_EQ(getString(getMap(content, "payload"), "mediaSessionId").value_or(""),
            std::string("main"));
  EXPECT_FALSE(getString(content, "displayedDate").value_or("").empty());
  EXPECT_EQ(h.events.size(), size_t(2));  // created + displayed
}

TEST(LayoutAndMediaMustComeTogether) {
  EngineHarness h;
  EXPECT_EQ(h.create(mediaModel(1, {})),
            std::string("error INVALID_ARGUMENTS arguments.invalid.notificationMedia"));
  EXPECT_EQ(h.create(mediaModel(2, mediaBlock(), "Default")),
            std::string("error INVALID_ARGUMENTS arguments.invalid.notificationMedia.layout"));
  EXPECT_EQ(h.create(mediaModel(3, mediaBlock({{"sessionId", ""}}))),
            std::string("error INVALID_ARGUMENTS arguments.invalid.notificationMedia"));
  EXPECT_TRUE(h.media.player->calls.empty());

  // Neither: the next in the chain (the notification server).
  EXPECT_EQ(h.create(mediaModel(4, {}, "BigText")), std::string("created"));
  EXPECT_EQ(h.presenter->presented, std::vector<int64_t>{4});
}

TEST(ChannelMethods) {
  EngineHarness h;
  h.create(mediaModel(7, mediaBlock()));
  auto capabilities = h.call("mediaCapabilities", Value());
  EXPECT_EQ(capabilities.map().at("seekBar").asBool().value_or(false), true);
  EXPECT_EQ(capabilities.map().at("artwork").asBool().value_or(false), true);
  EXPECT_EQ(capabilities.map().at("customButtons").asBool().value_or(true), false);
  EXPECT_EQ(capabilities.map().at("lockScreen").asBool().value_or(true), false);

  h.media.now += 2s;
  EXPECT_TRUE(h.call("mediaUpdatePosition",
                     Value(ValueMap{{"sessionId", "main"}, {"position", int64_t(90000)}}))
                  .isNull());
  EXPECT_EQ(h.media.player->seeks, std::vector<int64_t>{90000});
  EXPECT_EQ(h.media.controller->position(), int64_t(90000));

  EXPECT_TRUE(h.call("mediaStop", Value("main")).isNull());
  EXPECT_EQ(h.media.player->calls.back(), std::string("clear"));
  EXPECT_TRUE(h.media.controller->active() == nullptr);
}

// MARK: - Position

TEST(PositionAdvancesWithSpeedWhilePlaying) {
  ControllerHarness h;
  h.controller->deliver(parsed({{"playbackSpeed", 2.0}}), {});
  h.now += 3s;
  EXPECT_EQ(h.controller->position(), int64_t(16000));
  h.now += 1000s;
  EXPECT_EQ(h.controller->position(), int64_t(200000));  // capped at the duration

  h.controller->deliver(parsed({{"state", "paused"}, {"playbackSpeed", 0.0}}), {});
  h.now += 5s;
  EXPECT_EQ(h.controller->position(), int64_t(10000));
}

TEST(OnlyJumpsAreSeeked) {
  ControllerHarness h;
  h.controller->deliver(parsed(), {});
  h.now += 1s;
  h.controller->updatePosition("main", 11050);  // the normal advance
  EXPECT_TRUE(h.player->seeks.empty());
  h.controller->updatePosition("main", 60000);
  EXPECT_EQ(h.player->seeks, std::vector<int64_t>{60000});
  // A model update that moves the position is a jump too.
  h.controller->deliver(parsed({{"position", int64_t(5000)}}), {});
  EXPECT_EQ(h.player->seeks, (std::vector<int64_t>{60000, 5000}));
  // Unknown session: nothing.
  h.controller->updatePosition("other", 1);
  EXPECT_EQ(h.player->seeks.size(), size_t(2));
}

TEST(LastUpdatedSessionOwnsThePlayer) {
  ControllerHarness h;
  h.controller->deliver(parsed(), {});
  h.controller->deliver(parsed({{"sessionId", "second"}}), {});
  EXPECT_EQ(h.controller->active()->media.sessionId, std::string("second"));
  h.controller->stop("main");  // not the active one: the player stays
  EXPECT_EQ(h.player->calls.back(), std::string("show second"));
  h.controller->stop("second");
  EXPECT_EQ(h.player->calls.back(), std::string("clear"));
  EXPECT_FALSE(h.controller->onPlayerMethod("Play"));
}

// MARK: - Commands

TEST(PlayerMethodsBecomeCommands) {
  ControllerHarness h;
  h.controller->deliver(parsed(), {});
  EXPECT_TRUE(h.controller->onPlayerMethod("Next"));
  EXPECT_TRUE(h.controller->onPlayerMethod("PlayPause"));  // playing -> pause
  EXPECT_FALSE(h.controller->onPlayerMethod("Previous"));  // no skipPrevious
  EXPECT_FALSE(h.controller->onPlayerMethod("Stop"));
  EXPECT_EQ(h.actions.size(), size_t(2));
  EXPECT_EQ(h.actions[0].first, std::string("awn.media.skipNext"));
  EXPECT_FALSE(h.actions[0].second.has_value());
  EXPECT_EQ(h.actions[1].first, std::string("awn.media.pause"));
  EXPECT_EQ(getString(h.buttons[0], "actionType").value_or(""), std::string("SilentAction"));
  EXPECT_EQ(getBool(h.buttons[0], "autoDismissible").value_or(true), false);
  EXPECT_EQ(getString(h.buttons[0], "key").value_or(""), std::string("awn.media.skipNext"));
  EXPECT_EQ(h.events.size(), size_t(2));
  EXPECT_EQ(getString(h.events[0], "control").value_or(""), std::string("skipNext"));
  EXPECT_EQ(getString(h.events[0], "sessionId").value_or(""), std::string("main"));
  EXPECT_FALSE(has(h.events[0], "position"));

  h.controller->deliver(parsed({{"state", "paused"}}), {});
  EXPECT_TRUE(h.controller->onPlayerMethod("PlayPause"));
  EXPECT_EQ(h.actions.back().first, std::string("awn.media.play"));
}

TEST(SeekAndSetPositionBecomeSeekTo) {
  ControllerHarness h;
  h.controller->deliver(parsed(), {});
  h.now += 2s;  // at 12 s
  EXPECT_TRUE(h.controller->onPlayerMethod("Seek", 5000000));
  EXPECT_EQ(h.actions.back().first, std::string("awn.media.seekTo"));
  EXPECT_EQ(h.actions.back().second.value_or(""), std::string("17000"));
  EXPECT_EQ(getInt(h.events.back(), "position").value_or(-1), int64_t(17000));

  EXPECT_TRUE(h.controller->onPlayerMethod("Seek", -60000000));  // clamped at 0
  EXPECT_EQ(h.actions.back().second.value_or(""), std::string("0"));

  std::string track = trackIdFor("main");
  EXPECT_TRUE(h.controller->onPlayerMethod("SetPosition", 0, track, 42000000));
  EXPECT_EQ(h.actions.back().second.value_or(""), std::string("42000"));
  EXPECT_FALSE(h.controller->onPlayerMethod("SetPosition", 0, trackIdFor("x"), 42000000));
  EXPECT_FALSE(h.controller->onPlayerMethod("SetPosition", 0, track, 999000000));
  EXPECT_FALSE(h.controller->onPlayerMethod("Seek", 0));
}

TEST(SeekFallsBackToSkipControls) {
  ControllerHarness h;
  h.controller->deliver(parsed({{"controls", ValueList{"skipForward", "skipBackward"}},
                                {"commandTarget", "actionEvent"}}),
                        {});
  EXPECT_TRUE(capabilitiesOf(h.controller->active()->media).canSeek);
  EXPECT_TRUE(h.controller->onPlayerMethod("Seek", 10000000));
  EXPECT_TRUE(h.controller->onPlayerMethod("Seek", -10000000));
  EXPECT_FALSE(h.controller->onPlayerMethod("SetPosition", 0, trackIdFor("main"), 1000));
  EXPECT_EQ(h.actions.size(), size_t(2));
  EXPECT_EQ(h.actions[0].first, std::string("awn.media.skipForward"));
  EXPECT_EQ(h.actions[1].first, std::string("awn.media.skipBackward"));
  EXPECT_FALSE(h.actions[0].second.has_value());
  EXPECT_TRUE(h.events.empty());  // actionEvent only
}

TEST(StreamOnlyTargetSkipsTheActionEvent) {
  ControllerHarness h;
  h.controller->deliver(parsed({{"commandTarget", "stream"}}), {});
  EXPECT_TRUE(h.controller->onPlayerMethod("Pause"));
  EXPECT_TRUE(h.actions.empty());
  EXPECT_EQ(h.events.size(), size_t(1));
}

TEST(CapabilitiesFollowTheControls) {
  auto can = capabilitiesOf(parsed());
  EXPECT_TRUE(can.canPlay);
  EXPECT_TRUE(can.canPause);
  EXPECT_TRUE(can.canGoNext);
  EXPECT_FALSE(can.canGoPrevious);
  EXPECT_TRUE(can.canSeek);
  EXPECT_FALSE(capabilitiesOf(parsed({{"controls", ValueList{"play"}}})).canSeek);
}

// MARK: - Names

TEST(TrackIdsAndBusNames) {
  EXPECT_EQ(trackIdFor("a-1"), std::string("/me/carda/awesome_notifications/media/session_612d31"));
  EXPECT_EQ(busNameFor("com.example.my_app", 42),
            std::string("org.mpris.MediaPlayer2.com.example.my_app.instance42"));
  EXPECT_EQ(busNameFor("1app..x y", 7), std::string("org.mpris.MediaPlayer2._1app.x_y.instance7"));
  EXPECT_EQ(busNameFor("", 7), std::string("org.mpris.MediaPlayer2.flutter_app.instance7"));
}

TEST(ControlNamesRoundTrip) {
  for (const char* name : {"play", "pause", "stop", "skipNext", "skipPrevious", "skipForward",
                           "skipBackward", "seekTo", "fastForward", "rewind"}) {
    auto control = controlFrom(name);
    EXPECT_TRUE(control.has_value());
    if (control) EXPECT_EQ(buttonKeyOf(*control), std::string("awn.media.") + name);
  }
  EXPECT_FALSE(controlFrom("Play").has_value());
}

int main() { return awn_test::runAll(); }
