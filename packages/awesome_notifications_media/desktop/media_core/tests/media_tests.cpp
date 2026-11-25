// Unit tests of the desktop media logic (shared library + the MPRIS and SMTC
// mappings), with the desktop core's harness. No Flutter, GLib or Windows.
#include <algorithm>
#include <memory>

#include "awn/awesome_notifications.h"
#include "awn/date_utils.h"
#include "awn/method_router.h"
#include "awn/registries.h"
#include "awn_media/media.h"
#include "awn_test.h"
#include "mpris_mapping.h"
#include "smtc_mapping.h"

using namespace awn;
using namespace awn_media;
using namespace std::chrono_literals;

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
  std::vector<std::string> calls;
  std::vector<Session> shown;
  /// Every position the app set on the shown session.
  std::vector<int64_t> positions;
  /// The ones that jumped.
  std::vector<int64_t> jumps;
  int clears = 0;
  bool available = true;

  bool show(const Session& session) override {
    if (!available) return false;
    shown.push_back(session);
    calls.push_back("show " + session.media.sessionId);
    return true;
  }
  void positionChanged(const Session& session, bool jump) override {
    positions.push_back(session.media.positionMs);
    if (jump) {
      jumps.push_back(session.media.positionMs);
      calls.push_back("seeked");
    }
  }
  void clear() override {
    ++clears;
    calls.push_back("clear");
  }
};

/// Schedules every notification one hour ahead without a schedule entry (a
/// decorator further down the chain).
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

ValueList names(std::initializer_list<const char*> list) {
  ValueList out;
  for (auto name : list) out.push_back(Value(name));
  return out;
}

/// A playing, seekable track; commands to both targets.
ValueMap mediaBlock(ValueMap extra = {}) {
  ValueMap media{{"sessionId", "main"},
                 {"title", "Song"},
                 {"artist", "Band"},
                 {"duration", int64_t(200000)},
                 {"position", int64_t(10000)},
                 {"playbackSpeed", 1.0},
                 {"state", "playing"},
                 {"controls", names({"play", "pause", "skipNext", "seekTo"})},
                 {"skipInterval", int64_t(15000)},
                 {"commandTarget", "both"}};
  for (auto& [k, v] : extra) media[k] = v;
  return media;
}

/// Another playing track, with previous / next; commands as action events.
ValueMap songBlock(const std::string& sessionId = "player", ValueMap extra = {}) {
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

MediaModel parsed(ValueMap block) {
  auto media = MediaModel::parse(Value(block));
  return media ? *media : MediaModel{};
}
MediaModel parsedMedia(ValueMap extra = {}) { return parsed(mediaBlock(std::move(extra))); }

/// A model for a controller used without the engine.
ValueMap modelOf(int id) { return model(id, std::nullopt); }

/// A controller alone, on a manual clock, recording what it sends.
struct ControllerHarness {
  std::shared_ptr<FakeSurface> surface = std::make_shared<FakeSurface>();
  MediaClock::time_point now = MediaClock::time_point() + 1h;
  std::vector<std::pair<std::string, std::optional<std::string>>> actions;
  std::vector<ValueMap> buttons;
  std::vector<ValueMap> events;
  std::vector<int64_t> cancelled;
  std::shared_ptr<MediaController> controller = std::make_shared<MediaController>(
      surface,
      [this](const ValueMap&, const std::string& key, const std::optional<std::string>& input,
             const ValueMap& button) {
        actions.emplace_back(key, input);
        buttons.push_back(button);
      },
      [this](int64_t id) { cancelled.push_back(id); }, [this] { return now; });

  ControllerHarness() {
    controller->setStreamSink([this](const ValueMap& event) { events.push_back(event); });
  }
  void deliver(const MediaModel& media, int id = 1) { controller->deliver(media, modelOf(id)); }
};

/// A fresh engine with the media decorator registered: the action events go
/// through the core, cancelling through the engine.
struct Harness {
  std::shared_ptr<FakePresenter> presenter = std::make_shared<FakePresenter>();
  std::shared_ptr<NotificationStore> store = std::make_shared<NotificationStore>();
  std::shared_ptr<FakeSurface> surface = std::make_shared<FakeSurface>();
  AwesomeNotifications engine;
  MediaClock::time_point now = MediaClock::time_point() + 1h;
  std::shared_ptr<MediaController> controller;
  std::vector<Event> events;
  std::vector<ValueMap> stream;
  int token;

  explicit Harness(ValueMap capabilities = smtcCapabilities()) {
    NotificationBuilderRegistry::shared().clearForTest();
    AwesomeMethodHandlerRegistry::shared().clearForTest();
    engine.configure(presenter, std::make_shared<InlineDispatcher>(), store, false);
    controller = std::make_shared<MediaController>(
        surface,
        [this](const ValueMap& m, const std::string& key, const std::optional<std::string>& input,
               const ValueMap& button) { engine.dispatchAction(m, key, input, button); },
        [this](int64_t id) { engine.cancel(id); }, [this] { return now; });
    controller->setStreamSink([this](const ValueMap& event) { stream.push_back(event); });
    RegisterMedia(controller, std::move(capabilities), engine);
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

const std::string kInvalid = "INVALID_ARGUMENTS|arguments.invalid.notificationMedia";

}  // namespace

// MARK: - Model

TEST(ParsesTheMediaBlock) {
  auto media = parsedMedia({{"album", "Album"}, {"artwork", "asset://images/cover.png"}});
  EXPECT_EQ(media.sessionId, std::string("main"));
  EXPECT_EQ(media.title, std::string("Song"));
  EXPECT_EQ(media.artist, std::string("Band"));
  EXPECT_EQ(media.album, std::string("Album"));
  EXPECT_EQ(media.artwork, std::string("asset://images/cover.png"));
  EXPECT_EQ(media.durationMs.value_or(-1), int64_t(200000));
  EXPECT_EQ(media.positionMs, int64_t(10000));
  EXPECT_EQ(media.speed, 1.0);
  EXPECT_EQ(media.state, std::string("playing"));
  EXPECT_TRUE(media.has(Control::seekTo));
  EXPECT_FALSE(media.has(Control::stop));
  EXPECT_EQ(media.skipIntervalMs, int64_t(15000));
  EXPECT_TRUE(media.target == CommandTarget::both);
  EXPECT_TRUE(media.toActionEvent());
  EXPECT_TRUE(media.toStream());
}

TEST(ParseDefaults) {
  auto media = MediaModel::parse(
      Value(ValueMap{{"sessionId", "s"}, {"title", "t"}, {"state", "paused"}}));
  EXPECT_TRUE(media.has_value());
  EXPECT_FALSE(media->durationMs.has_value());
  EXPECT_EQ(media->positionMs, int64_t(0));
  EXPECT_EQ(media->speed, 0.0);
  EXPECT_TRUE(media->controls.empty());
  EXPECT_EQ(media->skipIntervalMs, int64_t(15000));
  EXPECT_TRUE(media->target == CommandTarget::actionEvent);
  EXPECT_EQ(parsed({{"sessionId", "s"}, {"title", "t"}}).state, std::string("unknown"));
  EXPECT_EQ(parsed({{"sessionId", "s"}, {"title", "t"}, {"state", "playing"}}).speed, 1.0);
  EXPECT_TRUE(parsed({{"sessionId", "s"}, {"title", "t"}, {"commandTarget", "stream"}}).target ==
              CommandTarget::stream);
}

// NotificationMedia.validate() rules (the Dart side already enforces them).
TEST(ParseRejectsInvalidBlocks) {
  std::string error;
  EXPECT_FALSE(MediaModel::parse(Value(mediaBlock({{"sessionId", " "}})), &error).has_value());
  EXPECT_CONTAINS(error, "sessionId");
  EXPECT_FALSE(MediaModel::parse(Value(ValueMap{{"title", "x"}}), &error).has_value());
  EXPECT_CONTAINS(error, "sessionId");
  EXPECT_FALSE(MediaModel::parse(Value(mediaBlock({{"title", ""}})), &error).has_value());
  EXPECT_CONTAINS(error, "title");
  EXPECT_FALSE(MediaModel::parse(Value(ValueMap{{"sessionId", "s"}})).has_value());
  EXPECT_FALSE(
      MediaModel::parse(Value(mediaBlock({{"position", int64_t(300000)}})), &error).has_value());
  EXPECT_CONTAINS(error, "past its duration");
  EXPECT_FALSE(MediaModel::parse(Value(mediaBlock({{"position", -5}})), &error).has_value());
  EXPECT_CONTAINS(error, "negative");
  EXPECT_FALSE(MediaModel::parse(Value(mediaBlock({{"duration", 0}})), &error).has_value());
  EXPECT_CONTAINS(error, "duration");
  EXPECT_FALSE(MediaModel::parse(Value(mediaBlock({{"playbackSpeed", -1.0}}))).has_value());
  EXPECT_FALSE(MediaModel::parse(Value(mediaBlock({{"skipInterval", 0}}))).has_value());
  EXPECT_FALSE(MediaModel::parse(Value("x"), &error).has_value());
}

TEST(LiveStreamAndTargetsAndUnknownControls) {
  ValueMap block =
      mediaBlock({{"commandTarget", "stream"}, {"controls", names({"pause", "teleport"})}});
  block.erase("duration");
  auto media = *MediaModel::parse(Value(block));
  EXPECT_FALSE(media.durationMs.has_value());
  EXPECT_FALSE(media.toActionEvent());
  EXPECT_TRUE(media.toStream());
  EXPECT_EQ(media.controls.size(), size_t(1));
  EXPECT_FALSE(parsedMedia({{"commandTarget", "actionEvent"}}).toStream());
}

TEST(PlaybackStateOfEveryState) {
  for (auto state : {"playing", "forwarding", "rewinding"})
    EXPECT_TRUE(playbackStateOf(state) == PlaybackState::Playing);
  EXPECT_TRUE(playbackStateOf("paused") == PlaybackState::Paused);
  for (auto state : {"buffering", "connecting", "previous", "next", "skippingToQueueItem"})
    EXPECT_TRUE(playbackStateOf(state) == PlaybackState::Changing);
  for (auto state : {"stopped", "none", "unknown", "error", "bogus"})
    EXPECT_TRUE(playbackStateOf(state) == PlaybackState::Stopped);
}

TEST(FillContentKeepsWhatIsThere) {
  ValueMap m = model(1, std::nullopt, "MediaPlayer", {{"payload", ValueMap{{"k", "v"}}}});
  auto filled = NotificationBuilder::content(fillContent(m, parsedMedia()));
  EXPECT_EQ(str(filled, "title"), std::string("Song"));
  EXPECT_EQ(str(filled, "body"), std::string("Band"));
  auto payload = getMap(filled, "payload");
  EXPECT_EQ(str(payload, "k"), std::string("v"));
  EXPECT_EQ(str(payload, "mediaSessionId"), std::string("main"));

  ValueMap titled = model(1, std::nullopt, "MediaPlayer", {{"title", "Mine"}, {"body", "Text"}});
  auto kept = NotificationBuilder::content(fillContent(titled, parsedMedia()));
  EXPECT_EQ(str(kept, "title"), std::string("Mine"));
  EXPECT_EQ(str(kept, "body"), std::string("Text"));
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

// MARK: - Artwork

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
  EXPECT_TRUE(artworkSourceOf("/home/u/a.png").kind == Kind::File);

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
  EXPECT_EQ(artworkCacheName("https://x.com/a.webp").substr(16), std::string(".webp"));
  EXPECT_EQ(artworkCacheName("https://x.com/a.gif"), artworkCacheName("https://x.com/a.gif"));
  EXPECT_TRUE(artworkCacheName("https://x.com/a.gif") != artworkCacheName("https://x.com/b.gif"));
}

// MARK: - Builder rules (through the core)

TEST(MediaPlayerWithoutMediaFails) {
  Harness h;
  EXPECT_EQ(h.create(model(1, std::nullopt)), kInvalid);
  EXPECT_TRUE(h.presenter->presented.empty());
  EXPECT_TRUE(h.surface->shown.empty());
}

TEST(MediaWithAnotherLayoutFails) {
  Harness h;
  EXPECT_EQ(h.create(model(2, songBlock(), "BigPicture")), kInvalid + ".layout");
  EXPECT_EQ(h.create(model(2, mediaBlock(), "Default")), kInvalid + ".layout");
  EXPECT_TRUE(h.surface->shown.empty());
}

TEST(InvalidMediaBlockFails) {
  Harness h;
  EXPECT_EQ(h.create(model(3, ValueMap{{"title", "x"}})), kInvalid);
  EXPECT_EQ(h.create(model(3, mediaBlock({{"sessionId", ""}}))), kInvalid);
  EXPECT_TRUE(h.surface->shown.empty());
}

TEST(PushModelsAreRejected) {
  Harness h;
  for (const char* source : {"Firebase", "firebase", "FIREBASE"}) {
    EXPECT_EQ(h.create(model(4, songBlock(), "MediaPlayer", {{"createdSource", source}})),
              kInvalid + ".push");
  }
  // Either half of the pair is enough to be a media model.
  EXPECT_EQ(h.create(model(4, std::nullopt, "MediaPlayer", {{"createdSource", "Firebase"}})),
            kInvalid + ".push");
  EXPECT_EQ(h.create(model(4, songBlock(), "Default", {{"createdSource", "Firebase"}})),
            kInvalid + ".push");
  EXPECT_EQ(h.create(model(4, songBlock(), "MediaPlayer", {{"createdSource", "Local"}})),
            std::string("true"));
  // A push that is not a media model: untouched.
  EXPECT_EQ(h.create(model(5, std::nullopt, "Default", {{"createdSource", "Firebase"}})),
            std::string("true"));
  EXPECT_EQ(h.surface->shown.size(), size_t(1));
  EXPECT_EQ(h.presenter->presented.size(), size_t(1));
}

TEST(ScheduledModelsAreRejected) {
  Harness h;
  ValueMap scheduled = model(6, songBlock());
  scheduled["schedule"] = ValueMap{{"interval", 60}};
  EXPECT_EQ(h.create(scheduled), kInvalid + ".schedule");
  ValueMap layoutOnly = model(6, std::nullopt);
  layoutOnly["schedule"] = ValueMap{{"interval", 60}};
  EXPECT_EQ(h.create(layoutOnly), kInvalid + ".schedule");
  // A push wins over a schedule; a schedule over the layout rules.
  ValueMap both = model(6, std::nullopt, "MediaPlayer", {{"createdSource", "Firebase"}});
  both["schedule"] = ValueMap{{"interval", 60}};
  EXPECT_EQ(h.create(both), kInvalid + ".push");
  ValueMap wrongLayout = model(6, songBlock(), "Default");
  wrongLayout["schedule"] = ValueMap{{"interval", 60}};
  EXPECT_EQ(h.create(wrongLayout), kInvalid + ".schedule");
  // A null schedule is no schedule.
  ValueMap none = model(6, songBlock());
  none["schedule"] = Value();
  EXPECT_EQ(h.create(none), std::string("true"));
  // A schedule on another model: untouched.
  ValueMap plain = model(7, std::nullopt, "Default");
  plain["schedule"] = ValueMap{{"interval", 60}};
  EXPECT_EQ(h.create(plain), std::string("true"));
  EXPECT_EQ(h.surface->shown.size(), size_t(1));
}

TEST(OtherModelsAreUntouched) {
  Harness h;
  EXPECT_EQ(h.create(model(4, std::nullopt, "Default", {{"title", "Plain"}})),
            std::string("true"));
  EXPECT_EQ(h.create(model(5, std::nullopt, "BigText")), std::string("true"));
  EXPECT_EQ(h.presenter->delivered, (std::vector<int64_t>{4, 5}));
  EXPECT_TRUE(h.surface->shown.empty());
  auto content = NotificationBuilder::content(h.presenter->presented[0].model);
  EXPECT_FALSE(has(getMap(content, "payload"), "mediaSessionId"));
}

TEST(MediaModelShowsTheControlsInsteadOfANotification) {
  Harness h;
  EXPECT_EQ(h.create(model(5, songBlock(), "MediaPlayer", {{"payload", ValueMap{{"k", "v"}}}})),
            std::string("true"));
  EXPECT_TRUE(h.presenter->presented.empty());
  EXPECT_EQ(h.surface->calls, std::vector<std::string>{"show player"});
  EXPECT_EQ(h.count("notificationCreated"), 1);
  EXPECT_EQ(h.count("notificationDisplayed"), 1);

  auto created = h.last("notificationCreated");
  EXPECT_EQ(str(created->content, "title"), std::string("Champagne Supernova"));
  EXPECT_EQ(str(created->content, "body"), std::string("Bright Sharp"));
  auto payload = getMap(created->content, "payload");
  EXPECT_EQ(str(payload, "mediaSessionId"), std::string("player"));
  EXPECT_EQ(str(payload, "k"), std::string("v"));
  EXPECT_FALSE(str(h.last("notificationDisplayed")->content, "displayedDate").empty());
  EXPECT_TRUE(h.store->get(5).has_value());

  const Session* active = h.controller->active();
  EXPECT_TRUE(active != nullptr);
  EXPECT_EQ(active->notificationId, int64_t(5));
  auto content = NotificationBuilder::content(active->model);
  EXPECT_EQ(str(getMap(content, "payload"), "mediaSessionId"), std::string("player"));
  EXPECT_FALSE(str(content, "displayedDate").empty());
}

TEST(TheModelTitleAndBodyWin) {
  Harness h;
  h.create(model(6, songBlock(), "MediaPlayer", {{"title", "Mine"}, {"body", "Body"}}));
  auto created = h.last("notificationCreated");
  EXPECT_EQ(str(created->content, "title"), std::string("Mine"));
  EXPECT_EQ(str(created->content, "body"), std::string("Body"));
}

TEST(ADeliveryTimeSetDownTheChainStaysANotification) {
  Harness h;
  NotificationBuilderRegistry::shared().registerDecorator(
      10, [](auto inner) { return std::make_shared<ScheduleEverything>(inner); });
  EXPECT_EQ(h.create(model(7, songBlock())), std::string("true"));
  EXPECT_EQ(h.presenter->presented.size(), size_t(1));
  EXPECT_TRUE(h.surface->shown.empty());
}

TEST(UnavailableControlsAnswerNotCreated) {
  Harness h;
  h.surface->available = false;
  EXPECT_EQ(h.create(model(8, songBlock())), std::string("false"));
  EXPECT_EQ(h.count("notificationCreated"), 0);
  EXPECT_FALSE(h.store->get(8).has_value());
  EXPECT_TRUE(h.controller->active() == nullptr);
}

// MARK: - Sessions and position

TEST(PositionAdvancesWithSpeedWhilePlaying) {
  ControllerHarness h;
  h.deliver(parsedMedia({{"playbackSpeed", 2.0}}));
  h.now += 3s;
  EXPECT_EQ(h.controller->position(), int64_t(16000));
  h.now += 1000s;
  EXPECT_EQ(h.controller->position(), int64_t(200000));  // capped at the duration

  h.deliver(parsedMedia({{"state", "paused"}, {"playbackSpeed", 0.0}}));
  h.now += 5s;
  EXPECT_EQ(h.controller->position(), int64_t(10000));
  // About to move (buffering): the position holds.
  h.deliver(parsedMedia({{"state", "buffering"}, {"playbackSpeed", 1.0}}));
  h.now += 5s;
  EXPECT_EQ(h.controller->position(), int64_t(10000));
}

TEST(OnlyJumpsAreSeeked) {
  ControllerHarness h;
  h.deliver(parsedMedia());
  h.now += 1s;
  h.controller->updatePosition("main", 11050);  // the normal advance
  EXPECT_TRUE(h.surface->jumps.empty());
  EXPECT_EQ(h.surface->positions, std::vector<int64_t>{11050});
  h.controller->updatePosition("main", 60000);
  EXPECT_EQ(h.surface->jumps, std::vector<int64_t>{60000});
  // A model update that moves the position is a jump too.
  h.deliver(parsedMedia({{"position", int64_t(5000)}}));
  EXPECT_EQ(h.surface->jumps, (std::vector<int64_t>{60000, 5000}));
  // Unknown session: nothing.
  h.controller->updatePosition("other", 1);
  EXPECT_EQ(h.surface->positions.size(), size_t(3));
}

TEST(LastUpdatedSessionOwnsThePlayer) {
  ControllerHarness h;
  h.deliver(parsedMedia(), 1);
  h.deliver(parsedMedia({{"sessionId", "second"}}), 2);
  EXPECT_EQ(h.controller->active()->media.sessionId, std::string("second"));
  h.controller->stop("main");  // not the active one: the player stays
  EXPECT_EQ(h.surface->calls.back(), std::string("show second"));
  EXPECT_EQ(h.cancelled, std::vector<int64_t>{1});
  h.controller->stop("second");
  EXPECT_EQ(h.surface->calls.back(), std::string("clear"));
  EXPECT_EQ(h.cancelled, (std::vector<int64_t>{1, 2}));
  EXPECT_FALSE(onPlayerMethod(*h.controller, "Play"));
  // Unknown session: nothing.
  h.controller->stop("main");
  EXPECT_EQ(h.cancelled.size(), size_t(2));
}

TEST(StopKeepsANotificationAnotherSessionUses) {
  ControllerHarness h;
  h.deliver(parsedMedia(), 7);
  h.deliver(parsedMedia({{"sessionId", "second"}}), 7);
  h.controller->stop("main");
  EXPECT_TRUE(h.cancelled.empty());
  EXPECT_EQ(h.surface->clears, 0);
  h.controller->stop("second");
  EXPECT_EQ(h.cancelled, std::vector<int64_t>{7});
  EXPECT_EQ(h.surface->clears, 1);
}

TEST(UpdatePositionOfAHiddenSessionIsKeptQuietly) {
  ControllerHarness h;
  h.deliver(parsedMedia(), 1);
  h.deliver(parsedMedia({{"sessionId", "second"}}), 2);
  h.controller->updatePosition("main", 90000);
  EXPECT_TRUE(h.surface->positions.empty());
  EXPECT_EQ(h.controller->find("main")->media.positionMs, int64_t(90000));
}

// MARK: - Commands (MPRIS)

TEST(PlayerMethodsBecomeCommands) {
  ControllerHarness h;
  h.deliver(parsedMedia());
  EXPECT_TRUE(onPlayerMethod(*h.controller, "Next"));
  EXPECT_TRUE(onPlayerMethod(*h.controller, "PlayPause"));  // playing -> pause
  EXPECT_FALSE(onPlayerMethod(*h.controller, "Previous"));  // no skipPrevious
  EXPECT_FALSE(onPlayerMethod(*h.controller, "Stop"));
  EXPECT_FALSE(onPlayerMethod(*h.controller, "OpenUri"));
  EXPECT_EQ(h.actions.size(), size_t(2));
  EXPECT_EQ(h.actions[0].first, std::string("awn.media.skipNext"));
  EXPECT_FALSE(h.actions[0].second.has_value());
  EXPECT_EQ(h.actions[1].first, std::string("awn.media.pause"));
  EXPECT_EQ(str(h.buttons[0], "actionType"), std::string("SilentAction"));
  EXPECT_EQ(getBool(h.buttons[0], "autoDismissible").value_or(true), false);
  EXPECT_EQ(str(h.buttons[0], "key"), std::string("awn.media.skipNext"));
  EXPECT_EQ(h.events.size(), size_t(2));
  EXPECT_EQ(str(h.events[0], "control"), std::string("skipNext"));
  EXPECT_EQ(str(h.events[0], "sessionId"), std::string("main"));
  EXPECT_FALSE(has(h.events[0], "position"));

  h.deliver(parsedMedia({{"state", "paused"}}));
  EXPECT_TRUE(onPlayerMethod(*h.controller, "PlayPause"));
  EXPECT_EQ(h.actions.back().first, std::string("awn.media.play"));
}

TEST(SeekAndSetPositionBecomeSeekTo) {
  ControllerHarness h;
  h.deliver(parsedMedia());
  h.now += 2s;  // at 12 s
  EXPECT_TRUE(onPlayerMethod(*h.controller, "Seek", 5000000));
  EXPECT_EQ(h.actions.back().first, std::string("awn.media.seekTo"));
  EXPECT_EQ(h.actions.back().second.value_or(""), std::string("17000"));
  EXPECT_EQ(getInt(h.events.back(), "position").value_or(-1), int64_t(17000));

  EXPECT_TRUE(onPlayerMethod(*h.controller, "Seek", -60000000));  // clamped at 0
  EXPECT_EQ(h.actions.back().second.value_or(""), std::string("0"));

  std::string track = trackIdFor("main");
  EXPECT_TRUE(onPlayerMethod(*h.controller, "SetPosition", 0, track, 42000000));
  EXPECT_EQ(h.actions.back().second.value_or(""), std::string("42000"));
  EXPECT_FALSE(onPlayerMethod(*h.controller, "SetPosition", 0, trackIdFor("x"), 42000000));
  EXPECT_FALSE(onPlayerMethod(*h.controller, "SetPosition", 0, track, 999000000));
  EXPECT_FALSE(onPlayerMethod(*h.controller, "Seek", 0));
}

TEST(SeekFallsBackToSkipControls) {
  ControllerHarness h;
  h.deliver(parsedMedia(
      {{"controls", names({"skipForward", "skipBackward"})}, {"commandTarget", "actionEvent"}}));
  EXPECT_TRUE(capabilitiesOf(h.controller->active()->media).canSeek);
  EXPECT_TRUE(onPlayerMethod(*h.controller, "Seek", 10000000));
  EXPECT_TRUE(onPlayerMethod(*h.controller, "Seek", -10000000));
  EXPECT_FALSE(onPlayerMethod(*h.controller, "SetPosition", 0, trackIdFor("main"), 1000));
  EXPECT_EQ(h.actions.size(), size_t(2));
  EXPECT_EQ(h.actions[0].first, std::string("awn.media.skipForward"));
  EXPECT_EQ(h.actions[1].first, std::string("awn.media.skipBackward"));
  EXPECT_FALSE(h.actions[0].second.has_value());
  EXPECT_TRUE(h.events.empty());  // actionEvent only
}

TEST(StreamOnlyTargetSkipsTheActionEvent) {
  ControllerHarness h;
  h.deliver(parsedMedia({{"commandTarget", "stream"}}));
  EXPECT_TRUE(onPlayerMethod(*h.controller, "Pause"));
  EXPECT_TRUE(h.actions.empty());
  EXPECT_EQ(h.events.size(), size_t(1));
}

TEST(MprisCapabilitiesFollowTheControls) {
  auto can = capabilitiesOf(parsedMedia());
  EXPECT_TRUE(can.canPlay);
  EXPECT_TRUE(can.canPause);
  EXPECT_TRUE(can.canGoNext);
  EXPECT_FALSE(can.canGoPrevious);
  EXPECT_TRUE(can.canSeek);
  EXPECT_FALSE(capabilitiesOf(parsedMedia({{"controls", names({"play"})}})).canSeek);
}

TEST(MprisPlaybackStatusOfEveryState) {
  auto status = [](const char* state) {
    return std::string(mprisPlaybackStatus(playbackStateOf(state)));
  };
  for (auto state : {"playing", "forwarding", "rewinding"})
    EXPECT_EQ(status(state), std::string("Playing"));
  for (auto state : {"paused", "buffering", "connecting", "previous", "next",
                     "skippingToQueueItem"})
    EXPECT_EQ(status(state), std::string("Paused"));
  for (auto state : {"stopped", "none", "unknown", "error"})
    EXPECT_EQ(status(state), std::string("Stopped"));
}

TEST(TrackIdsAndBusNames) {
  EXPECT_EQ(trackIdFor("a-1"), std::string("/me/carda/awesome_notifications/media/session_612d31"));
  EXPECT_EQ(busNameFor("com.example.my_app", 42),
            std::string("org.mpris.MediaPlayer2.com.example.my_app.instance42"));
  EXPECT_EQ(busNameFor("1app..x y", 7), std::string("org.mpris.MediaPlayer2._1app.x_y.instance7"));
  EXPECT_EQ(busNameFor("", 7), std::string("org.mpris.MediaPlayer2.flutter_app.instance7"));
}

// MARK: - Commands (SMTC)

TEST(SmtcStatusOfEveryState) {
  for (auto state : {"playing", "forwarding", "rewinding"})
    EXPECT_TRUE(smtcStatusOf(playbackStateOf(state)) == SmtcStatus::Playing);
  EXPECT_TRUE(smtcStatusOf(playbackStateOf("paused")) == SmtcStatus::Paused);
  for (auto state : {"buffering", "connecting", "previous", "next", "skippingToQueueItem"})
    EXPECT_TRUE(smtcStatusOf(playbackStateOf(state)) == SmtcStatus::Changing);
  for (auto state : {"stopped", "none", "unknown", "error", "bogus"})
    EXPECT_TRUE(smtcStatusOf(playbackStateOf(state)) == SmtcStatus::Stopped);
}

TEST(ButtonsFollowTheControls) {
  auto states = buttonStatesOf(parsed(songBlock()));
  EXPECT_FALSE(states.play);
  EXPECT_TRUE(states.pause);
  EXPECT_FALSE(states.stop);
  EXPECT_TRUE(states.next);
  EXPECT_TRUE(states.previous);
  EXPECT_FALSE(states.fastForward);
  EXPECT_FALSE(states.rewind);

  auto all = buttonStatesOf(
      parsed(songBlock("s", {{"controls", names({"play", "stop", "fastForward", "rewind"})}})));
  EXPECT_TRUE(all.play && all.stop && all.fastForward && all.rewind);
}

TEST(SkipIntervalControlsUseFastForwardAndRewindWhenFree) {
  auto skips = parsed(songBlock("s", {{"controls", names({"skipForward", "skipBackward"})}}));
  EXPECT_TRUE(buttonStatesOf(skips).fastForward);
  EXPECT_TRUE(buttonStatesOf(skips).rewind);
  EXPECT_TRUE(controlOf(Button::FastForward, skips) == Control::skipForward);
  EXPECT_TRUE(controlOf(Button::Rewind, skips) == Control::skipBackward);

  // fastForward / rewind win: the interval skips are then not shown.
  auto both = parsed(songBlock(
      "s", {{"controls", names({"skipForward", "fastForward", "skipBackward", "rewind"})}}));
  EXPECT_TRUE(controlOf(Button::FastForward, both) == Control::fastForward);
  EXPECT_TRUE(controlOf(Button::Rewind, both) == Control::rewind);
}

TEST(ControlOfMapsEveryButtonAndIgnoresDisabledOnes) {
  auto media = parsed(
      songBlock("s", {{"controls", names({"play", "pause", "stop", "skipNext", "skipPrevious"})}}));
  EXPECT_TRUE(controlOf(Button::Play, media) == Control::play);
  EXPECT_TRUE(controlOf(Button::Pause, media) == Control::pause);
  EXPECT_TRUE(controlOf(Button::Stop, media) == Control::stop);
  EXPECT_TRUE(controlOf(Button::Next, media) == Control::skipNext);
  EXPECT_TRUE(controlOf(Button::Previous, media) == Control::skipPrevious);
  EXPECT_FALSE(controlOf(Button::FastForward, media).has_value());
  EXPECT_FALSE(controlOf(Button::Play, parsed(songBlock())).has_value());
}

TEST(TimelineOfSeekableTrackLiveStreamAndFixedTrack) {
  auto seekable = timelineOf(parsed(songBlock()));
  EXPECT_TRUE(seekable.visible);
  EXPECT_EQ(seekable.start, int64_t(0));
  EXPECT_EQ(seekable.end, int64_t(261000));
  EXPECT_EQ(seekable.position, int64_t(37000));
  EXPECT_EQ(seekable.minSeek, int64_t(0));
  EXPECT_EQ(seekable.maxSeek, int64_t(261000));

  auto fixed = timelineOf(parsed(songBlock("s", {{"controls", names({"pause"})}})));
  EXPECT_TRUE(fixed.visible);
  EXPECT_EQ(fixed.maxSeek, int64_t(0));

  ValueMap live = songBlock();
  live.erase("duration");
  EXPECT_FALSE(timelineOf(parsed(live)).visible);
}

TEST(ActionEventTargetEmitsTheCoreActionEvent) {
  Harness h;
  h.create(model(10, songBlock()));
  EXPECT_TRUE(onButton(*h.controller, Button::Pause));
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
  h.create(model(11, songBlock("s", {{"commandTarget", "stream"}})));
  onButton(*h.controller, Button::Next);
  EXPECT_EQ(h.count("defaultAction"), 0);
  EXPECT_EQ(h.stream.size(), size_t(1));
  EXPECT_EQ(str(h.stream[0], "control"), std::string("skipNext"));
  EXPECT_EQ(str(h.stream[0], "sessionId"), std::string("s"));
  EXPECT_FALSE(has(h.stream[0], "position"));
}

TEST(BothTargetsAndSeekCarryThePosition) {
  Harness h;
  h.create(model(12, songBlock("s", {{"commandTarget", "both"}})));
  EXPECT_TRUE(onSeek(*h.controller, 120000));
  auto action = h.last("defaultAction");
  EXPECT_TRUE(action != nullptr);
  EXPECT_EQ(str(action->content, "buttonKeyPressed"), std::string("awn.media.seekTo"));
  EXPECT_EQ(str(action->content, "buttonKeyInput"), std::string("120000"));
  EXPECT_EQ(h.stream.size(), size_t(1));
  EXPECT_EQ(str(h.stream[0], "control"), std::string("seekTo"));
  EXPECT_EQ(getInt(h.stream[0], "position").value_or(0), int64_t(120000));

  onSeek(*h.controller, 999999999);  // past the end
  EXPECT_EQ(getInt(h.stream[1], "position").value_or(0), int64_t(261000));
}

TEST(DisabledControlsSendNothing) {
  Harness h;
  h.create(model(13, songBlock("s", {{"commandTarget", "both"}, {"controls", names({"pause"})}})));
  EXPECT_FALSE(onButton(*h.controller, Button::Play));  // a media key the session didn't enable
  EXPECT_FALSE(onButton(*h.controller, Button::FastForward));
  EXPECT_FALSE(onSeek(*h.controller, 1000));  // no seekTo
  EXPECT_EQ(h.count("defaultAction"), 0);
  EXPECT_TRUE(h.stream.empty());
}

TEST(SkipForwardComesFromTheFastForwardButton) {
  Harness h;
  h.create(model(14, songBlock("s", {{"controls", names({"skipForward", "skipBackward"})}})));
  onButton(*h.controller, Button::FastForward);
  EXPECT_EQ(str(h.last("defaultAction")->content, "buttonKeyPressed"),
            std::string("awn.media.skipForward"));
  onButton(*h.controller, Button::Rewind);
  EXPECT_EQ(str(h.last("defaultAction")->content, "buttonKeyPressed"),
            std::string("awn.media.skipBackward"));
}

TEST(NoListenerNoStreamEvent) {
  Harness h;
  h.controller->setStreamSink(nullptr);
  h.create(model(15, songBlock("s", {{"commandTarget", "stream"}})));
  EXPECT_TRUE(onButton(*h.controller, Button::Pause));
  EXPECT_TRUE(h.stream.empty());
  EXPECT_EQ(h.count("defaultAction"), 0);
}

TEST(NoSessionNoCommand) {
  Harness h;
  EXPECT_FALSE(onButton(*h.controller, Button::Pause));
  EXPECT_FALSE(onSeek(*h.controller, 10));
  EXPECT_FALSE(onPlayerMethod(*h.controller, "Pause"));
  EXPECT_TRUE(h.events.empty());
}

TEST(TheLastSessionWins) {
  Harness h;
  h.create(model(20, songBlock("a")));
  h.create(model(21, songBlock("b")));
  EXPECT_EQ(h.surface->shown.size(), size_t(2));
  EXPECT_EQ(h.controller->active()->media.sessionId, std::string("b"));
  onButton(*h.controller, Button::Pause);
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
  h.create(model(30, songBlock()));
  bool handled = false;
  EXPECT_TRUE(h.call("mediaStop", Value("player"), &handled).isNull());
  EXPECT_TRUE(handled);
  EXPECT_EQ(h.surface->clears, 1);
  EXPECT_TRUE(h.controller->active() == nullptr);
  EXPECT_FALSE(h.store->get(30).has_value());
  EXPECT_FALSE(onButton(*h.controller, Button::Pause));
  EXPECT_EQ(h.count("defaultAction"), 0);

  // Unknown session: answered, nothing happens.
  EXPECT_TRUE(h.call("mediaStop", Value("nope")).isNull());
  EXPECT_EQ(h.surface->clears, 1);
  // The session id may come in a map too.
  h.create(model(31, songBlock("m")));
  EXPECT_TRUE(h.call("mediaStop", Value(ValueMap{{"sessionId", "m"}})).isNull());
  EXPECT_EQ(h.surface->clears, 2);
}

TEST(MediaUpdatePositionMovesOnlyThePosition) {
  Harness h;
  h.create(model(31, songBlock()));
  h.now += 2s;
  EXPECT_TRUE(
      h.call("mediaUpdatePosition", Value(ValueMap{{"sessionId", "player"}, {"position", 90000}}))
          .isNull());
  EXPECT_EQ(h.surface->positions, std::vector<int64_t>{90000});
  EXPECT_EQ(h.surface->jumps, std::vector<int64_t>{90000});
  EXPECT_EQ(h.controller->position(), int64_t(90000));
  const Session* active = h.controller->active();
  EXPECT_EQ(active->media.positionMs, int64_t(90000));
  EXPECT_EQ(active->media.state, std::string("playing"));
  EXPECT_EQ(active->media.speed, 1.0);
  EXPECT_EQ(h.surface->shown.size(), size_t(1));

  h.call("mediaUpdatePosition", Value(ValueMap{{"sessionId", "player"}, {"position", 999999}}));
  EXPECT_EQ(h.controller->active()->media.positionMs, int64_t(261000));
  // Another session: ignored.
  h.call("mediaUpdatePosition", Value(ValueMap{{"sessionId", "other"}, {"position", 1}}));
  EXPECT_EQ(h.surface->positions.size(), size_t(2));
}

TEST(MediaCapabilitiesOfEachPlatform) {
  {
    Harness h(smtcCapabilities());
    Value answer = h.call("mediaCapabilities", Value());
    EXPECT_EQ(answer["seekBar"].asBool().value_or(false), true);
    EXPECT_EQ(answer["artwork"].asBool().value_or(false), true);
    EXPECT_EQ(answer["customButtons"].asBool().value_or(true), false);
    EXPECT_EQ(answer["lockScreen"].asBool().value_or(false), true);
  }
  {
    Harness h(mprisCapabilities());
    Value answer = h.call("mediaCapabilities", Value());
    EXPECT_EQ(answer["seekBar"].asBool().value_or(false), true);
    EXPECT_EQ(answer["artwork"].asBool().value_or(false), true);
    EXPECT_EQ(answer["customButtons"].asBool().value_or(true), false);
    EXPECT_EQ(answer["lockScreen"].asBool().value_or(true), false);
  }
}

TEST(OtherMethodsAreNotHandled) {
  Harness h;
  bool handled = true;
  h.call("mediaUnknown", Value(), &handled);
  EXPECT_FALSE(handled);
}

// MARK: - Removing the notification ends the session

TEST(CancelAndDismissEndTheSession) {
  struct Case {
    const char* name;
    std::function<void(AwesomeNotifications&)> remove;
  };
  std::vector<Case> cases{
      {"cancel", [](AwesomeNotifications& e) { e.cancel(40); }},
      {"dismiss", [](AwesomeNotifications& e) { e.dismiss(40); }},
      {"cancelAll", [](AwesomeNotifications& e) { e.cancelAll(); }},
      {"dismissAll", [](AwesomeNotifications& e) { e.dismissAll(); }},
      {"cancelByChannelKey", [](AwesomeNotifications& e) { e.cancelByChannelKey("media"); }},
      {"dismissByChannelKey", [](AwesomeNotifications& e) { e.dismissByChannelKey("media"); }},
      {"cancelByGroupKey", [](AwesomeNotifications& e) { e.cancelByGroupKey("g"); }},
      {"dismissByGroupKey", [](AwesomeNotifications& e) { e.dismissByGroupKey("g"); }},
  };
  for (const auto& c : cases) {
    Harness h;
    // Playing included.
    h.create(model(40, songBlock(), "MediaPlayer", {{"groupKey", "g"}}));
    c.remove(h.engine);
    EXPECT_EQ(std::string(c.name) + " clears " + std::to_string(h.surface->clears),
              std::string(c.name) + " clears 1");
    EXPECT_TRUE(h.controller->active() == nullptr);
    EXPECT_TRUE(h.controller->find("player") == nullptr);
    EXPECT_FALSE(onButton(*h.controller, Button::Pause));
    EXPECT_FALSE(h.store->get(40).has_value());
  }
}

TEST(CancelThroughTheChannelEndsTheSession) {
  Harness h;
  h.create(model(41, songBlock()));
  bool handled = false;
  h.call("cancelNotification", Value(41), &handled);
  EXPECT_TRUE(handled);
  EXPECT_EQ(h.surface->clears, 1);
  EXPECT_TRUE(h.controller->active() == nullptr);
}

TEST(RemovingAnotherNotificationKeepsTheSession) {
  Harness h;
  h.create(model(42, songBlock("a")));
  h.create(model(43, songBlock("b")));
  h.create(model(44, std::nullopt, "Default", {{"channelKey", "other"}}));
  h.engine.cancel(44);
  h.engine.cancelByChannelKey("nothing");
  EXPECT_EQ(h.surface->clears, 0);
  // The hidden session ends quietly; the shown one stays.
  h.engine.cancel(42);
  EXPECT_EQ(h.surface->clears, 0);
  EXPECT_TRUE(h.controller->find("a") == nullptr);
  EXPECT_EQ(h.controller->active()->media.sessionId, std::string("b"));
  h.engine.dismiss(43);
  EXPECT_EQ(h.surface->clears, 1);
}

int main() { return awn_test::runAll(); }
