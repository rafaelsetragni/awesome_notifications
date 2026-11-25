#include <algorithm>
#include <memory>

#include "awn/awesome_notifications.h"
#include "awn/date_utils.h"
#include "awn/method_router.h"
#include "awn/registries.h"
#include "awn_media/media.h"
#include "awn_test.h"

using namespace awn;
using namespace awn_media;

namespace {

class FakePresenter : public NotificationPresenter {
 public:
  std::vector<BuiltNotification> presented;
  std::vector<int64_t> delivered, pending, removed;

  void present(const BuiltNotification& built, std::function<void(bool)> done) override {
    presented.push_back(built);
    (built.fireDate ? pending : delivered).push_back(built.id);
    done(true);
  }
  void removeDelivered(const std::vector<int64_t>& ids) override {
    removed.insert(removed.end(), ids.begin(), ids.end());
  }
  void removeAllDelivered() override {}
  void removePending(const std::vector<int64_t>&) override {}
  void removeAllPending() override {}
  std::vector<int64_t> deliveredIds() override { return delivered; }
  std::vector<int64_t> pendingIds() override { return pending; }
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

class FakeSurface : public MediaSurface {
 public:
  std::vector<MediaSession> shown;
  std::vector<int64_t> positions;
  int clears = 0;
  bool available = true;
  bool show(const MediaSession& session) override {
    if (available) shown.push_back(session);
    return available;
  }
  void updatePosition(const MediaSession& session) override {
    positions.push_back(session.position);
  }
  void clear() override { ++clears; }
};

/// Schedules every notification one hour ahead (a scheduling decorator).
class ScheduleEverything : public NotificationBuilder {
 public:
  using NotificationBuilder::NotificationBuilder;
  std::optional<BuiltNotification> build(const ValueMap& m) override {
    auto built = next(m);
    if (built) built->fireDate = DateUtils::now() + std::chrono::hours(1);
    return built;
  }
};

struct Event {
  std::string name;
  ValueMap content;
};

struct Harness {
  std::shared_ptr<FakePresenter> presenter = std::make_shared<FakePresenter>();
  std::shared_ptr<NotificationStore> store = std::make_shared<NotificationStore>();
  std::shared_ptr<FakeSurface> surface = std::make_shared<FakeSurface>();
  AwesomeNotifications engine;
  std::shared_ptr<MediaController> controller;
  std::vector<Event> events;
  std::vector<ValueMap> stream;
  int token;

  Harness() {
    NotificationBuilderRegistry::shared().clearForTest();
    AwesomeMethodHandlerRegistry::shared().clearForTest();
    engine.configure(presenter, std::make_shared<InlineDispatcher>(), store, false);
    controller = std::make_shared<MediaController>(engine, surface);
    controller->setStreamSink([this](const ValueMap& event) { stream.push_back(event); });
    RegisterMedia(controller);
    token = AwesomeEventsReceiver::shared().subscribe(
        [this](const std::string& name, const ValueMap& content) {
          events.push_back({name, content});
        });
  }
  ~Harness() { AwesomeEventsReceiver::shared().unsubscribe(token); }

  /// The create call's answer: "true" / "false" / the failure's detailed code.
  std::string create(const ValueMap& model) {
    std::string outcome;
    AwesomeMethodRouter router(engine);
    router.handle(
        "createNewNotification", Value(model),
        [&](const Value& value) { outcome = value.asBool().value_or(false) ? "true" : "false"; },
        [&](const std::string& code, const std::string&, const Value& details) {
          outcome = code + "|" + details.asString().value_or("");
        });
    return outcome;
  }

  Value call(const std::string& method, const Value& arguments, bool* handled = nullptr) {
    Value answer("unanswered");
    bool ok = AwesomeMethodRouter(engine).handle(method, arguments,
                                                 [&](const Value& value) { answer = value; });
    if (handled) *handled = ok;
    return answer;
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
};

ValueList names(std::initializer_list<const char*> list) {
  ValueList out;
  for (auto name : list) out.push_back(Value(name));
  return out;
}

ValueMap mediaBlock(const std::string& sessionId = "player", ValueMap extra = {}) {
  ValueMap media{{"sessionId", sessionId},
                 {"title", "Champagne Supernova"},
                 {"artist", "Bright Sharp"},
                 {"album", "Morning"},
                 {"duration", 261000},
                 {"position", 37000},
                 {"playbackSpeed", 1.0},
                 {"state", "playing"},
                 {"controls", names({"pause", "skipNext", "skipPrevious", "seekTo"})},
                 {"skipInterval", 15000},
                 {"commandTarget", "actionEvent"}};
  for (auto& [k, v] : extra) media[k] = v;
  return media;
}

ValueMap model(int id, std::optional<ValueMap> media, const std::string& layout = "MediaPlayer",
               ValueMap contentExtra = {}) {
  ValueMap content{{"id", id}, {"channelKey", "media"}, {"notificationLayout", layout}};
  for (auto& [k, v] : contentExtra) content[k] = v;
  ValueMap m{{"content", content}};
  if (media) m["media"] = *media;
  return m;
}

std::string str(const ValueMap& map, const char* key) { return getString(map, key).value_or(""); }

MediaSession parsed(ValueMap block) {
  auto session = MediaSession::parse(Value(block));
  return session ? *session : MediaSession{};
}

}  // namespace

// MARK: - Model

TEST(ParseReadsTheWholeBlock) {
  auto session = MediaSession::parse(Value(mediaBlock("s1", {{"artwork", "asset://a.png"},
                                                             {"commandTarget", "both"}})));
  EXPECT_TRUE(session.has_value());
  EXPECT_EQ(session->sessionId, std::string("s1"));
  EXPECT_EQ(session->title, std::string("Champagne Supernova"));
  EXPECT_EQ(session->artist, std::string("Bright Sharp"));
  EXPECT_EQ(session->album, std::string("Morning"));
  EXPECT_EQ(session->artwork, std::string("asset://a.png"));
  EXPECT_EQ(session->duration.value_or(0), int64_t(261000));
  EXPECT_EQ(session->position, int64_t(37000));
  EXPECT_EQ(session->playbackSpeed, 1.0);
  EXPECT_EQ(session->state, std::string("playing"));
  EXPECT_TRUE(session->has("seekTo"));
  EXPECT_FALSE(session->has("play"));
  EXPECT_EQ(session->skipInterval, int64_t(15000));
  EXPECT_TRUE(session->commandTarget == CommandTarget::Both);
}

TEST(ParseDefaults) {
  auto session = MediaSession::parse(Value(ValueMap{{"sessionId", "s"}, {"state", "paused"}}));
  EXPECT_TRUE(session.has_value());
  EXPECT_FALSE(session->duration.has_value());
  EXPECT_EQ(session->position, int64_t(0));
  EXPECT_EQ(session->playbackSpeed, 0.0);
  EXPECT_TRUE(session->controls.empty());
  EXPECT_EQ(session->skipInterval, int64_t(15000));
  EXPECT_TRUE(session->commandTarget == CommandTarget::ActionEvent);
  EXPECT_EQ(parsed({{"sessionId", "s"}, {"state", "playing"}}).playbackSpeed, 1.0);
  EXPECT_TRUE(parsed({{"sessionId", "s"}, {"commandTarget", "stream"}}).commandTarget ==
              CommandTarget::Stream);
}

TEST(ParseClampsPositionAndTreatsNonPositiveDurationAsLive) {
  EXPECT_EQ(parsed(mediaBlock("s", {{"position", 999999}})).position, int64_t(261000));
  EXPECT_EQ(parsed(mediaBlock("s", {{"position", -5}})).position, int64_t(0));
  EXPECT_FALSE(parsed(mediaBlock("s", {{"duration", 0}})).duration.has_value());
}

TEST(ParseRejectsAMissingOrBlankSessionId) {
  std::string error;
  EXPECT_FALSE(MediaSession::parse(Value(ValueMap{{"title", "x"}}), &error).has_value());
  EXPECT_CONTAINS(error, "sessionId");
  EXPECT_FALSE(MediaSession::parse(Value(ValueMap{{"sessionId", "  "}})).has_value());
  EXPECT_FALSE(MediaSession::parse(Value("not a map")).has_value());
}

// MARK: - System controls

TEST(PlaybackStatusOfEveryState) {
  EXPECT_TRUE(playbackStatusOf("playing") == PlaybackStatus::Playing);
  EXPECT_TRUE(playbackStatusOf("forwarding") == PlaybackStatus::Playing);
  EXPECT_TRUE(playbackStatusOf("rewinding") == PlaybackStatus::Playing);
  EXPECT_TRUE(playbackStatusOf("paused") == PlaybackStatus::Paused);
  for (auto state : {"buffering", "connecting", "previous", "next", "skippingToQueueItem"})
    EXPECT_TRUE(playbackStatusOf(state) == PlaybackStatus::Changing);
  for (auto state : {"stopped", "none", "unknown", "error", "bogus"})
    EXPECT_TRUE(playbackStatusOf(state) == PlaybackStatus::Stopped);
}

TEST(ButtonsFollowTheControls) {
  auto states = buttonStatesOf(parsed(mediaBlock()));
  EXPECT_FALSE(states.play);
  EXPECT_TRUE(states.pause);
  EXPECT_FALSE(states.stop);
  EXPECT_TRUE(states.next);
  EXPECT_TRUE(states.previous);
  EXPECT_FALSE(states.fastForward);
  EXPECT_FALSE(states.rewind);

  auto all = buttonStatesOf(parsed(mediaBlock(
      "s", {{"controls", names({"play", "stop", "fastForward", "rewind"})}})));
  EXPECT_TRUE(all.play && all.stop && all.fastForward && all.rewind);
}

TEST(SkipIntervalControlsUseFastForwardAndRewindWhenFree) {
  auto skips = parsed(mediaBlock("s", {{"controls", names({"skipForward", "skipBackward"})}}));
  EXPECT_TRUE(buttonStatesOf(skips).fastForward);
  EXPECT_TRUE(buttonStatesOf(skips).rewind);
  EXPECT_EQ(controlOf(Button::FastForward, skips).value_or(""), std::string("skipForward"));
  EXPECT_EQ(controlOf(Button::Rewind, skips).value_or(""), std::string("skipBackward"));

  // fastForward / rewind win: the interval skips are then not shown.
  auto both = parsed(mediaBlock(
      "s", {{"controls", names({"skipForward", "fastForward", "skipBackward", "rewind"})}}));
  EXPECT_EQ(controlOf(Button::FastForward, both).value_or(""), std::string("fastForward"));
  EXPECT_EQ(controlOf(Button::Rewind, both).value_or(""), std::string("rewind"));
}

TEST(ControlOfMapsEveryButtonAndIgnoresDisabledOnes) {
  auto session = parsed(mediaBlock(
      "s", {{"controls", names({"play", "pause", "stop", "skipNext", "skipPrevious"})}}));
  EXPECT_EQ(controlOf(Button::Play, session).value_or(""), std::string("play"));
  EXPECT_EQ(controlOf(Button::Pause, session).value_or(""), std::string("pause"));
  EXPECT_EQ(controlOf(Button::Stop, session).value_or(""), std::string("stop"));
  EXPECT_EQ(controlOf(Button::Next, session).value_or(""), std::string("skipNext"));
  EXPECT_EQ(controlOf(Button::Previous, session).value_or(""), std::string("skipPrevious"));
  EXPECT_FALSE(controlOf(Button::FastForward, session).has_value());
  EXPECT_FALSE(controlOf(Button::Play, parsed(mediaBlock())).has_value());
}

TEST(TimelineOfSeekableTrackLiveStreamAndFixedTrack) {
  auto seekable = timelineOf(parsed(mediaBlock()));
  EXPECT_TRUE(seekable.visible);
  EXPECT_EQ(seekable.start, int64_t(0));
  EXPECT_EQ(seekable.end, int64_t(261000));
  EXPECT_EQ(seekable.position, int64_t(37000));
  EXPECT_EQ(seekable.minSeek, int64_t(0));
  EXPECT_EQ(seekable.maxSeek, int64_t(261000));

  auto fixed = timelineOf(parsed(mediaBlock("s", {{"controls", names({"pause"})}})));
  EXPECT_TRUE(fixed.visible);
  EXPECT_EQ(fixed.maxSeek, int64_t(0));

  ValueMap live = mediaBlock();
  live.erase("duration");
  EXPECT_FALSE(timelineOf(parsed(live)).visible);
}

TEST(ArtworkSources) {
  using Kind = ArtworkSource::Kind;
  auto remote = artworkSourceOf("https://x.com/a.jpg");
  EXPECT_TRUE(remote.kind == Kind::Remote);
  EXPECT_EQ(remote.path, std::string("https://x.com/a.jpg"));
  EXPECT_TRUE(artworkSourceOf("http://x.com/a").kind == Kind::Remote);

  auto file = artworkSourceOf("file:///C:/Music/My%20Cover.png");
  EXPECT_TRUE(file.kind == Kind::File);
  EXPECT_EQ(file.path, std::string("C:/Music/My Cover.png"));
  EXPECT_EQ(artworkSourceOf("file:///home/u/a.png").path, std::string("/home/u/a.png"));
  EXPECT_TRUE(artworkSourceOf("C:\\covers\\a.png").kind == Kind::File);

  auto asset = artworkSourceOf("asset://assets/cover.png");
  EXPECT_TRUE(asset.kind == Kind::Asset);
  EXPECT_EQ(asset.path, std::string("assets/cover.png"));
  EXPECT_TRUE(artworkSourceOf("assets/cover.png").kind == Kind::Asset);

  EXPECT_TRUE(artworkSourceOf("resource://drawable/cover").kind == Kind::None);
  EXPECT_TRUE(artworkSourceOf("").kind == Kind::None);
}

TEST(ArtworkCacheNameKeepsTheImageExtension) {
  std::string jpg = artworkCacheName("https://x.com/Cover.JPG?size=3");
  EXPECT_EQ(jpg.size(), size_t(20));
  EXPECT_EQ(jpg.substr(16), std::string(".jpg"));
  EXPECT_EQ(artworkCacheName("https://x.com/cover").substr(16), std::string(".png"));
  EXPECT_EQ(artworkCacheName("https://x.com/a.gif"), artworkCacheName("https://x.com/a.gif"));
  EXPECT_TRUE(artworkCacheName("https://x.com/a.gif") != artworkCacheName("https://x.com/b.gif"));
}

// MARK: - Builder rules

TEST(MediaPlayerWithoutMediaFails) {
  Harness h;
  EXPECT_EQ(h.create(model(1, std::nullopt)),
            std::string("INVALID_ARGUMENTS|arguments.invalid.notificationMedia"));
  EXPECT_TRUE(h.presenter->presented.empty());
  EXPECT_TRUE(h.surface->shown.empty());
}

TEST(MediaWithAnotherLayoutFails) {
  Harness h;
  EXPECT_EQ(h.create(model(2, mediaBlock(), "BigPicture")),
            std::string("INVALID_ARGUMENTS|arguments.invalid.notificationMedia.layout"));
  EXPECT_TRUE(h.surface->shown.empty());
}

TEST(InvalidMediaBlockFails) {
  Harness h;
  EXPECT_EQ(h.create(model(3, ValueMap{{"title", "x"}})),
            std::string("INVALID_ARGUMENTS|arguments.invalid.notificationMedia"));
}

TEST(OtherModelsAreUntouched) {
  Harness h;
  EXPECT_EQ(h.create(model(4, std::nullopt, "Default", {{"title", "Plain"}})),
            std::string("true"));
  EXPECT_EQ(h.presenter->presented.size(), size_t(1));
  EXPECT_TRUE(h.surface->shown.empty());
  auto content = NotificationBuilder::content(h.presenter->presented[0].model);
  EXPECT_FALSE(has(getMap(content, "payload"), "mediaSessionId"));
}

TEST(MediaModelShowsTheControlsInsteadOfAToast) {
  Harness h;
  EXPECT_EQ(h.create(model(5, mediaBlock(), "MediaPlayer", {{"payload", ValueMap{{"k", "v"}}}})),
            std::string("true"));
  EXPECT_TRUE(h.presenter->presented.empty());
  EXPECT_EQ(h.surface->shown.size(), size_t(1));
  EXPECT_EQ(h.surface->shown[0].sessionId, std::string("player"));
  EXPECT_EQ(h.count("notificationCreated"), 1);
  EXPECT_EQ(h.count("notificationDisplayed"), 1);

  auto created = h.last("notificationCreated");
  EXPECT_EQ(str(created->content, "title"), std::string("Champagne Supernova"));
  EXPECT_EQ(str(created->content, "body"), std::string("Bright Sharp"));
  auto payload = getMap(created->content, "payload");
  EXPECT_EQ(str(payload, "mediaSessionId"), std::string("player"));
  EXPECT_EQ(str(payload, "k"), std::string("v"));
  EXPECT_TRUE(h.store->get(5).has_value());
}

TEST(TheModelTitleAndBodyWin) {
  Harness h;
  h.create(model(6, mediaBlock(), "MediaPlayer", {{"title", "Mine"}, {"body", "Body"}}));
  auto created = h.last("notificationCreated");
  EXPECT_EQ(str(created->content, "title"), std::string("Mine"));
  EXPECT_EQ(str(created->content, "body"), std::string("Body"));
}

TEST(AScheduledMediaModelStaysAToast) {
  Harness h;
  NotificationBuilderRegistry::shared().registerDecorator(
      10, [](auto inner) { return std::make_shared<ScheduleEverything>(inner); });
  EXPECT_EQ(h.create(model(7, mediaBlock())), std::string("true"));
  EXPECT_EQ(h.presenter->presented.size(), size_t(1));
  EXPECT_TRUE(h.surface->shown.empty());
}

TEST(UnavailableControlsAnswerNotCreated) {
  Harness h;
  h.surface->available = false;
  EXPECT_EQ(h.create(model(8, mediaBlock())), std::string("false"));
  EXPECT_EQ(h.count("notificationCreated"), 0);
  EXPECT_FALSE(h.store->get(8).has_value());
  EXPECT_FALSE(h.controller->current().has_value());
}

// MARK: - Commands

TEST(ActionEventTargetEmitsTheCoreActionEvent) {
  Harness h;
  h.create(model(10, mediaBlock()));
  h.controller->onButton(Button::Pause);
  auto action = h.last("defaultAction");
  EXPECT_TRUE(action != nullptr);
  EXPECT_EQ(str(action->content, "buttonKeyPressed"), std::string("awn.media.pause"));
  EXPECT_FALSE(has(action->content, "buttonKeyInput"));
  EXPECT_EQ(str(action->content, "actionType"), std::string("SilentAction"));
  EXPECT_EQ(getInt(action->content, "id").value_or(0), int64_t(10));
  EXPECT_EQ(str(getMap(action->content, "payload"), "mediaSessionId"), std::string("player"));
  EXPECT_TRUE(h.stream.empty());
  // The notification stays.
  EXPECT_TRUE(h.presenter->removed.empty());
  EXPECT_TRUE(h.store->get(10).has_value());
}

TEST(StreamTargetSendsOnlyTheStreamEvent) {
  Harness h;
  h.create(model(11, mediaBlock("s", {{"commandTarget", "stream"}})));
  h.controller->onButton(Button::Next);
  EXPECT_EQ(h.count("defaultAction"), 0);
  EXPECT_EQ(h.stream.size(), size_t(1));
  EXPECT_EQ(str(h.stream[0], "control"), std::string("skipNext"));
  EXPECT_EQ(str(h.stream[0], "sessionId"), std::string("s"));
  EXPECT_FALSE(has(h.stream[0], "position"));
}

TEST(BothTargetsAndSeekCarryThePosition) {
  Harness h;
  h.create(model(12, mediaBlock("s", {{"commandTarget", "both"}})));
  h.controller->onSeek(120000);
  auto action = h.last("defaultAction");
  EXPECT_TRUE(action != nullptr);
  EXPECT_EQ(str(action->content, "buttonKeyPressed"), std::string("awn.media.seekTo"));
  EXPECT_EQ(str(action->content, "buttonKeyInput"), std::string("120000"));
  EXPECT_EQ(h.stream.size(), size_t(1));
  EXPECT_EQ(str(h.stream[0], "control"), std::string("seekTo"));
  EXPECT_EQ(getInt(h.stream[0], "position").value_or(0), int64_t(120000));

  h.controller->onSeek(999999999);  // past the end
  EXPECT_EQ(getInt(h.stream[1], "position").value_or(0), int64_t(261000));
}

TEST(DisabledControlsSendNothing) {
  Harness h;
  h.create(model(13, mediaBlock("s", {{"commandTarget", "both"},
                                      {"controls", names({"pause"})}})));
  h.controller->onButton(Button::Play);       // a media key the session didn't enable
  h.controller->onButton(Button::FastForward);
  h.controller->onSeek(1000);                 // no seekTo
  EXPECT_EQ(h.count("defaultAction"), 0);
  EXPECT_TRUE(h.stream.empty());
}

TEST(SkipForwardComesFromTheFastForwardButton) {
  Harness h;
  h.create(model(14, mediaBlock("s", {{"controls", names({"skipForward", "skipBackward"})}})));
  h.controller->onButton(Button::FastForward);
  EXPECT_EQ(str(h.last("defaultAction")->content, "buttonKeyPressed"),
            std::string("awn.media.skipForward"));
  h.controller->onButton(Button::Rewind);
  EXPECT_EQ(str(h.last("defaultAction")->content, "buttonKeyPressed"),
            std::string("awn.media.skipBackward"));
}

TEST(NoListenerNoStreamEvent) {
  Harness h;
  h.controller->setStreamSink(nullptr);
  h.create(model(15, mediaBlock("s", {{"commandTarget", "stream"}})));
  h.controller->onButton(Button::Pause);
  EXPECT_TRUE(h.stream.empty());
  EXPECT_EQ(h.count("defaultAction"), 0);
}

TEST(NoSessionNoCommand) {
  Harness h;
  h.controller->onButton(Button::Pause);
  h.controller->onSeek(10);
  EXPECT_TRUE(h.events.empty());
}

TEST(TheLastSessionWins) {
  Harness h;
  h.create(model(20, mediaBlock("a")));
  h.create(model(21, mediaBlock("b")));
  EXPECT_EQ(h.surface->shown.size(), size_t(2));
  EXPECT_EQ(h.controller->current()->sessionId, std::string("b"));
  h.controller->onButton(Button::Pause);
  auto action = h.last("defaultAction");
  EXPECT_EQ(getInt(action->content, "id").value_or(0), int64_t(21));
  EXPECT_EQ(str(getMap(action->content, "payload"), "mediaSessionId"), std::string("b"));

  // Stopping the replaced session leaves the shown one alone.
  h.call("mediaStop", Value("a"));
  EXPECT_EQ(h.surface->clears, 0);
  EXPECT_FALSE(h.store->get(20).has_value());
  EXPECT_TRUE(h.store->get(21).has_value());
}

// MARK: - Channel methods

TEST(MediaStopClearsTheControlsAndCancelsTheNotification) {
  Harness h;
  h.create(model(30, mediaBlock()));
  bool handled = false;
  EXPECT_TRUE(h.call("mediaStop", Value("player"), &handled).isNull());
  EXPECT_TRUE(handled);
  EXPECT_EQ(h.surface->clears, 1);
  EXPECT_FALSE(h.controller->current().has_value());
  EXPECT_FALSE(h.store->get(30).has_value());
  h.controller->onButton(Button::Pause);
  EXPECT_EQ(h.count("defaultAction"), 0);

  // Unknown session: answered, nothing happens.
  EXPECT_TRUE(h.call("mediaStop", Value("nope")).isNull());
  EXPECT_EQ(h.surface->clears, 1);
}

TEST(MediaUpdatePositionMovesOnlyThePosition) {
  Harness h;
  h.create(model(31, mediaBlock()));
  EXPECT_TRUE(h.call("mediaUpdatePosition",
                     Value(ValueMap{{"sessionId", "player"}, {"position", 90000}}))
                  .isNull());
  EXPECT_EQ(h.surface->positions, std::vector<int64_t>{90000});
  EXPECT_EQ(h.controller->current()->position, int64_t(90000));
  EXPECT_EQ(h.controller->current()->state, std::string("playing"));
  EXPECT_EQ(h.controller->current()->playbackSpeed, 1.0);
  EXPECT_EQ(h.surface->shown.size(), size_t(1));

  h.call("mediaUpdatePosition", Value(ValueMap{{"sessionId", "player"}, {"position", 999999}}));
  EXPECT_EQ(h.controller->current()->position, int64_t(261000));
  // Another session: ignored.
  h.call("mediaUpdatePosition", Value(ValueMap{{"sessionId", "other"}, {"position", 1}}));
  EXPECT_EQ(h.surface->positions.size(), size_t(2));
}

TEST(MediaCapabilitiesOfWindows) {
  Harness h;
  Value answer = h.call("mediaCapabilities", Value());
  EXPECT_EQ(answer["seekBar"].asBool().value_or(false), true);
  EXPECT_EQ(answer["artwork"].asBool().value_or(false), true);
  EXPECT_EQ(answer["customButtons"].asBool().value_or(true), false);
  EXPECT_EQ(answer["lockScreen"].asBool().value_or(false), true);
}

TEST(OtherMethodsAreNotHandled) {
  Harness h;
  bool handled = true;
  h.call("mediaUnknown", Value(), &handled);
  EXPECT_FALSE(handled);
}

int main() { return awn_test::runAll(); }
