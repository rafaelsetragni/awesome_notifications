#include "media_model.h"

#include <algorithm>
#include <cctype>
#include <cstdlib>
#include <cmath>
#include <cstdio>

#include "awn/definitions.h"
#include "awn/exception.h"

namespace awn_media {

namespace {

constexpr Control kControls[] = {Control::play,        Control::pause,      Control::stop,
                                 Control::skipNext,    Control::skipPrevious,
                                 Control::skipForward, Control::skipBackward, Control::seekTo,
                                 Control::fastForward, Control::rewind};

/// A position update this close to the expected one is the normal advance.
constexpr int64_t kJumpToleranceMs = 1000;

std::string text(const ValueMap& map, const char* key) {
  return awn::getString(map, key).value_or("");
}

bool blank(const std::string& value) {
  return std::all_of(value.begin(), value.end(),
                     [](unsigned char c) { return std::isspace(c) != 0; });
}

[[noreturn]] void invalid(const std::string& message, const std::string& detail) {
  throw awn::AwesomeNotificationsException(
      awn::exception_code::INVALID_ARGUMENTS, message,
      std::string(awn::exception_code::DETAILED_INVALID_ARGUMENTS) + detail);
}

}  // namespace

// MARK: - Enums

const char* controlName(Control control) {
  switch (control) {
    case Control::play: return "play";
    case Control::pause: return "pause";
    case Control::stop: return "stop";
    case Control::skipNext: return "skipNext";
    case Control::skipPrevious: return "skipPrevious";
    case Control::skipForward: return "skipForward";
    case Control::skipBackward: return "skipBackward";
    case Control::seekTo: return "seekTo";
    case Control::fastForward: return "fastForward";
    case Control::rewind: return "rewind";
  }
  return "play";
}

std::optional<Control> controlFrom(const std::string& name) {
  for (auto control : kControls)
    if (name == controlName(control)) return control;
  return std::nullopt;
}

const char* playbackStatusName(PlaybackStatus status) {
  switch (status) {
    case PlaybackStatus::Playing: return "Playing";
    case PlaybackStatus::Paused: return "Paused";
    case PlaybackStatus::Stopped: return "Stopped";
  }
  return "Stopped";
}

// MARK: - Model

std::optional<MediaModel> MediaModel::parse(const Value& block, std::string* error) {
  auto fail = [error](const char* message) -> std::optional<MediaModel> {
    if (error) *error = message;
    return std::nullopt;
  };
  if (!block.isMap()) return fail("The media block must be a map");
  const ValueMap& map = block.map();

  MediaModel media;
  media.sessionId = text(map, keys::SESSION_ID);
  media.title = text(map, keys::TITLE);
  if (blank(media.sessionId)) return fail("The media session needs a non-empty sessionId");
  if (blank(media.title)) return fail("The media needs a non-empty title");
  media.artist = text(map, keys::ARTIST);
  media.album = text(map, keys::ALBUM);
  media.artwork = text(map, keys::ARTWORK);

  if (auto duration = awn::getInt(map, keys::DURATION)) {
    if (*duration <= 0) return fail("The media duration must be positive");
    media.durationMs = *duration;
  }
  media.positionMs = awn::getInt(map, keys::POSITION).value_or(0);
  if (media.positionMs < 0) return fail("The media position can't be negative");
  if (media.durationMs && media.positionMs > *media.durationMs)
    return fail("The media position is past its duration");

  media.state = text(map, keys::STATE);
  if (media.state.empty()) media.state = "none";
  auto speed = map.count(keys::PLAYBACK_SPEED) ? map.at(keys::PLAYBACK_SPEED).asDouble()
                                               : std::nullopt;
  media.speed = speed.value_or(media.state == "playing" ? 1.0 : 0.0);
  if (media.speed < 0) return fail("The playback speed can't be negative");

  for (const auto& entry : awn::getList(map, keys::CONTROLS)) {
    if (auto control = controlFrom(entry.asString().value_or(""))) media.controls.insert(*control);
  }
  media.skipIntervalMs = awn::getInt(map, keys::SKIP_INTERVAL).value_or(15000);
  if (media.skipIntervalMs <= 0) return fail("The skip interval must be positive");

  std::string target = text(map, keys::COMMAND_TARGET);
  media.target = target == "stream" ? CommandTarget::stream
                 : target == "both" ? CommandTarget::both
                                    : CommandTarget::actionEvent;
  return media;
}

PlaybackStatus MediaModel::status() const {
  if (state == "playing" || state == "forwarding" || state == "rewinding")
    return PlaybackStatus::Playing;
  if (state == "stopped" || state == "none" || state == "unknown" || state == "error")
    return PlaybackStatus::Stopped;
  // paused, buffering, connecting and the transitions (previous, next,
  // skippingToQueueItem): the position doesn't advance.
  return PlaybackStatus::Paused;
}

ValueMap fillContent(const ValueMap& model, const MediaModel& media) {
  ValueMap result = model;
  ValueMap content = awn::NotificationBuilder::content(model);
  if (text(content, awn::defs::NOTIFICATION_TITLE).empty())
    content[awn::defs::NOTIFICATION_TITLE] = media.title;
  if (text(content, awn::defs::NOTIFICATION_BODY).empty() && !media.artist.empty())
    content[awn::defs::NOTIFICATION_BODY] = media.artist;
  ValueMap payload = awn::getMap(content, awn::defs::NOTIFICATION_PAYLOAD);
  payload[keys::PAYLOAD_SESSION_ID] = media.sessionId;
  content[awn::defs::NOTIFICATION_PAYLOAD] = std::move(payload);
  result[awn::defs::NOTIFICATION_CONTENT] = std::move(content);
  return result;
}

// MARK: - Builder

MediaBuilder::MediaBuilder(std::shared_ptr<awn::NotificationBuilder> inner, Deliver deliver)
    : awn::NotificationBuilder(std::move(inner)), deliver_(std::move(deliver)) {}

std::optional<awn::BuiltNotification> MediaBuilder::build(const ValueMap& model) {
  ValueMap content = awn::NotificationBuilder::content(model);
  bool isMediaPlayer = text(content, awn::defs::NOTIFICATION_LAYOUT) == keys::LAYOUT_MEDIA_PLAYER;
  auto block = model.find(keys::MEDIA);
  bool hasMedia = block != model.end() && !block->second.isNull();

  if (!hasMedia) {
    if (isMediaPlayer)
      invalid("The MediaPlayer layout requires a NotificationMedia", ".notificationMedia");
    return next(model);
  }
  if (!isMediaPlayer)
    invalid("A NotificationMedia requires the MediaPlayer layout", ".notificationMedia.layout");

  std::string error;
  auto media = MediaModel::parse(block->second, &error);
  if (!media) invalid(error, ".notificationMedia");

  auto built = next(fillContent(model, *media));
  if (!built) return built;
  auto deliver = deliver_;
  MediaModel parsed = *media;
  built->deliver = [deliver, parsed](const awn::BuiltNotification& final,
                                     std::function<void(bool)> done) {
    deliver(parsed, final, std::move(done));
  };
  return built;
}

// MARK: - Sessions

int64_t positionAt(const Session& session, MediaClock::time_point now) {
  const MediaModel& media = session.media;
  int64_t position = media.positionMs;
  if (media.status() == PlaybackStatus::Playing && media.speed > 0) {
    auto elapsed =
        std::chrono::duration_cast<std::chrono::milliseconds>(now - session.updatedAt).count();
    if (elapsed > 0) position += static_cast<int64_t>(std::llround(elapsed * media.speed));
  }
  if (media.durationMs) position = std::min(position, *media.durationMs);
  return std::max<int64_t>(position, 0);
}

bool isJump(int64_t expectedMs, int64_t actualMs) {
  return std::llabs(actualMs - expectedMs) > kJumpToleranceMs;
}

std::string trackIdFor(const std::string& sessionId) {
  // Object path elements only take [A-Za-z0-9_]: hex keeps every id distinct.
  std::string path = "/me/carda/awesome_notifications/media/session_";
  char hex[3];
  for (unsigned char c : sessionId) {
    std::snprintf(hex, sizeof(hex), "%02x", c);
    path += hex;
  }
  return path;
}

std::string busNameFor(const std::string& appId, long pid) {
  // Bus name elements: [A-Za-z0-9_-], not starting with a digit, not empty.
  std::string name = "org.mpris.MediaPlayer2";
  std::string element;
  auto flush = [&] {
    if (element.empty()) return;
    if (std::isdigit(static_cast<unsigned char>(element[0]))) element.insert(0, "_");
    name += "." + element;
    element.clear();
  };
  for (char c : appId) {
    if (c == '.') {
      flush();
    } else {
      bool ok = std::isalnum(static_cast<unsigned char>(c)) || c == '_' || c == '-';
      element += ok ? c : '_';
    }
  }
  flush();
  if (name == "org.mpris.MediaPlayer2") name += ".flutter_app";
  return name + ".instance" + std::to_string(pid);
}

Session& Sessions::update(const MediaModel& media, const ValueMap& model,
                          MediaClock::time_point now) {
  Session& session = sessions_[media.sessionId];
  session.media = media;
  session.model = model;
  session.updatedAt = now;
  session.trackId = trackIdFor(media.sessionId);
  active_ = media.sessionId;
  return session;
}

bool Sessions::updatePosition(const std::string& sessionId, int64_t positionMs,
                              MediaClock::time_point now) {
  Session* session = find(sessionId);
  if (!session) return false;
  int64_t position = std::max<int64_t>(positionMs, 0);
  if (session->media.durationMs) position = std::min(position, *session->media.durationMs);
  session->media.positionMs = position;
  session->updatedAt = now;
  return true;
}

bool Sessions::stop(const std::string& sessionId) {
  bool wasActive = sessionId == active_ && sessions_.count(sessionId) > 0;
  sessions_.erase(sessionId);
  if (wasActive) active_.clear();
  return wasActive;
}

Session* Sessions::find(const std::string& sessionId) {
  auto it = sessions_.find(sessionId);
  return it == sessions_.end() ? nullptr : &it->second;
}

Session* Sessions::active() { return active_.empty() ? nullptr : find(active_); }

// MARK: - Commands

PlayerCapabilities capabilitiesOf(const MediaModel& media) {
  PlayerCapabilities can;
  can.canPlay = media.has(Control::play);
  can.canPause = media.has(Control::pause);
  can.canGoNext = media.has(Control::skipNext);
  can.canGoPrevious = media.has(Control::skipPrevious);
  can.canSeek = media.has(Control::seekTo) || media.has(Control::skipForward) ||
                media.has(Control::skipBackward);
  return can;
}

std::optional<Command> commandFor(const std::string& method, const Session& session,
                                  MediaClock::time_point now, int64_t offsetUs,
                                  const std::string& trackId, int64_t positionUs) {
  const MediaModel& media = session.media;
  auto ifHas = [&](Control control) -> std::optional<Command> {
    if (!media.has(control)) return std::nullopt;
    return Command{control, std::nullopt};
  };
  auto seekTo = [&](int64_t targetMs) -> std::optional<Command> {
    targetMs = std::max<int64_t>(targetMs, 0);
    if (media.durationMs) targetMs = std::min(targetMs, *media.durationMs);
    return Command{Control::seekTo, targetMs};
  };

  if (method == "Play") return ifHas(Control::play);
  if (method == "Pause") return ifHas(Control::pause);
  if (method == "PlayPause")
    return ifHas(media.status() == PlaybackStatus::Playing ? Control::pause : Control::play);
  if (method == "Stop") return ifHas(Control::stop);
  if (method == "Next") return ifHas(Control::skipNext);
  if (method == "Previous") return ifHas(Control::skipPrevious);
  if (method == "Seek") {
    if (offsetUs == 0) return std::nullopt;
    if (media.has(Control::seekTo)) return seekTo(positionAt(session, now) + offsetUs / 1000);
    return ifHas(offsetUs > 0 ? Control::skipForward : Control::skipBackward);
  }
  if (method == "SetPosition") {
    // MPRIS: ignored for another track or a position out of the track.
    if (!media.has(Control::seekTo) || trackId != session.trackId || positionUs < 0)
      return std::nullopt;
    if (media.durationMs && positionUs / 1000 > *media.durationMs) return std::nullopt;
    return seekTo(positionUs / 1000);
  }
  return std::nullopt;
}

std::string buttonKeyOf(Control control) {
  return std::string(keys::COMMAND_PREFIX) + controlName(control);
}

ValueMap syntheticButton(Control control) {
  return ValueMap{{awn::defs::NOTIFICATION_BUTTON_KEY, buttonKeyOf(control)},
                  {awn::defs::NOTIFICATION_ACTION_TYPE, "SilentAction"},
                  {awn::defs::NOTIFICATION_AUTO_DISMISSIBLE, false}};
}

ValueMap streamEvent(const Command& command, const std::string& sessionId) {
  ValueMap event{{keys::CONTROL, controlName(command.control)}, {keys::SESSION_ID, sessionId}};
  if (command.positionMs) event[keys::POSITION] = *command.positionMs;
  return event;
}

ValueMap capabilitiesMap() {
  return ValueMap{
      {"seekBar", true}, {"artwork", true}, {"customButtons", false}, {"lockScreen", false}};
}

// MARK: - Controller

MediaController::MediaController(std::shared_ptr<Player> player, ActionSink action,
                                 StreamSink stream, Now now)
    : player_(std::move(player)),
      action_(std::move(action)),
      stream_(std::move(stream)),
      now_(std::move(now)) {}

void MediaController::deliver(const MediaModel& media, const ValueMap& model) {
  auto now = now_();
  Session* previous = sessions_.find(media.sessionId);
  bool wasActive = previous && previous == sessions_.active();
  std::optional<int64_t> expected;
  if (wasActive) expected = positionAt(*previous, now);

  Session& session = sessions_.update(media, model, now);
  player_->show(session);
  if (expected && isJump(*expected, media.positionMs)) player_->seeked(session, media.positionMs);
}

void MediaController::stop(const std::string& sessionId) {
  if (sessions_.stop(sessionId)) player_->clear();
}

void MediaController::updatePosition(const std::string& sessionId, int64_t positionMs) {
  auto now = now_();
  Session* session = sessions_.find(sessionId);
  if (!session) return;
  int64_t expected = positionAt(*session, now);
  sessions_.updatePosition(sessionId, positionMs, now);
  if (session != sessions_.active()) return;
  // Position isn't signaled by PropertiesChanged (clients poll it): only a
  // jump is announced.
  if (isJump(expected, session->media.positionMs))
    player_->seeked(*session, session->media.positionMs);
}

int64_t MediaController::position() {
  const Session* session = sessions_.active();
  return session ? positionAt(*session, now_()) : 0;
}

bool MediaController::onPlayerMethod(const std::string& method, int64_t offsetUs,
                                     const std::string& trackId, int64_t positionUs) {
  const Session* session = sessions_.active();
  if (!session) return false;
  auto command = commandFor(method, *session, now_(), offsetUs, trackId, positionUs);
  if (!command) return false;
  send(*session, *command);
  return true;
}

void MediaController::send(const Session& session, const Command& command) {
  // Copies: a sink may update the sessions (e.g. Dart answering synchronously).
  ValueMap model = session.model;
  MediaModel media = session.media;
  if (media.toActionEvent() && action_) {
    std::optional<std::string> input;
    if (command.positionMs) input = std::to_string(*command.positionMs);
    action_(model, buttonKeyOf(command.control), input, syntheticButton(command.control));
  }
  if (media.toStream() && stream_) stream_(streamEvent(command, media.sessionId));
}

// MARK: - Channel

MediaMethodHandler::MediaMethodHandler(std::shared_ptr<MediaController> controller)
    : controller_(std::move(controller)) {}

bool MediaMethodHandler::handle(const std::string& method, const Value& arguments,
                                awn::MethodResult result) {
  if (method == keys::METHOD_STOP) {
    if (auto sessionId = arguments.asString()) controller_->stop(*sessionId);
    result(Value());
    return true;
  }
  if (method == keys::METHOD_UPDATE_POSITION) {
    const ValueMap& map = arguments.map();
    auto sessionId = awn::getString(map, keys::SESSION_ID);
    auto position = awn::getInt(map, keys::POSITION);
    if (sessionId && position) controller_->updatePosition(*sessionId, *position);
    result(Value());
    return true;
  }
  if (method == keys::METHOD_CAPABILITIES) {
    result(Value(capabilitiesMap()));
    return true;
  }
  return false;
}

void RegisterMedia(std::shared_ptr<MediaController> controller) {
  awn::NotificationBuilderRegistry::shared().registerDecorator(
      kMediaPriority, [controller](std::shared_ptr<awn::NotificationBuilder> inner) {
        return std::make_shared<MediaBuilder>(
            std::move(inner), [controller](const MediaModel& media,
                                           const awn::BuiltNotification& built,
                                           std::function<void(bool)> done) {
              controller->deliver(media, built.model);
              done(true);
            });
      });
  awn::AwesomeMethodHandlerRegistry::shared().registerHandler(
      std::make_shared<MediaMethodHandler>(controller));
}

}  // namespace awn_media
