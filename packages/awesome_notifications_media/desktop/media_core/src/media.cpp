#include "awn_media/media.h"

#include <algorithm>
#include <cctype>
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <cstring>

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

bool startsWith(const std::string& value, const char* prefix) {
  return value.rfind(prefix, 0) == 0;
}

std::string lowercase(std::string value) {
  std::transform(value.begin(), value.end(), value.begin(),
                 [](unsigned char c) { return static_cast<char>(std::tolower(c)); });
  return value;
}

/// Decodes the %XX escapes of a file URI path.
std::string percentDecode(const std::string& value) {
  std::string out;
  for (size_t i = 0; i < value.size(); ++i) {
    if (value[i] == '%' && i + 2 < value.size() &&
        std::isxdigit(static_cast<unsigned char>(value[i + 1])) &&
        std::isxdigit(static_cast<unsigned char>(value[i + 2]))) {
      out += static_cast<char>(std::stoi(value.substr(i + 1, 2), nullptr, 16));
      i += 2;
    } else {
      out += value[i];
    }
  }
  return out;
}

bool isAbsolutePath(const std::string& path) {
  if (path.empty()) return false;
  if (path[0] == '/' || path[0] == '\\') return true;
  return path.size() > 1 && std::isalpha(static_cast<unsigned char>(path[0])) && path[1] == ':';
}

[[noreturn]] void invalid(const std::string& message, const std::string& detail) {
  throw awn::AwesomeNotificationsException(
      awn::exception_code::INVALID_ARGUMENTS, message,
      std::string(awn::exception_code::DETAILED_INVALID_ARGUMENTS) + ".notificationMedia" +
          detail);
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

PlaybackState playbackStateOf(const std::string& state) {
  if (state == "playing" || state == "forwarding" || state == "rewinding")
    return PlaybackState::Playing;
  if (state == "paused") return PlaybackState::Paused;
  if (state == "buffering" || state == "connecting" || state == "previous" || state == "next" ||
      state == "skippingToQueueItem")
    return PlaybackState::Changing;
  return PlaybackState::Stopped;
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
  if (media.state.empty()) media.state = "unknown";
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

// MARK: - Artwork

ArtworkSource artworkSourceOf(const std::string& source) {
  using Kind = ArtworkSource::Kind;
  if (source.empty() || startsWith(source, awn::media::RESOURCE)) return {};
  if (startsWith(source, awn::media::HTTPS) || startsWith(source, awn::media::HTTP))
    return {Kind::Remote, source};
  if (startsWith(source, awn::media::FILE)) {
    std::string path = percentDecode(source.substr(std::strlen(awn::media::FILE)));
    // file:///C:/x → C:/x
    if (path.size() > 2 && path[0] == '/' && path[2] == ':') path.erase(0, 1);
    return {Kind::File, path};
  }
  if (startsWith(source, awn::media::ASSET))
    return {Kind::Asset, source.substr(std::strlen(awn::media::ASSET))};
  return {isAbsolutePath(source) ? Kind::File : Kind::Asset, source};
}

std::string artworkCacheName(const std::string& url) {
  uint64_t hash = 14695981039346656037ULL;
  for (unsigned char c : url) {
    hash ^= c;
    hash *= 1099511628211ULL;
  }
  std::string lower = lowercase(url.substr(0, url.find_first_of("?#")));
  std::string extension = ".png";
  for (const char* candidate : {".jpg", ".jpeg", ".gif", ".png", ".bmp", ".webp"}) {
    size_t n = std::strlen(candidate);
    if (lower.size() >= n && lower.compare(lower.size() - n, n, candidate) == 0) {
      extension = candidate;
      break;
    }
  }
  char name[32];
  std::snprintf(name, sizeof(name), "%016llx", static_cast<unsigned long long>(hash));
  return std::string(name) + extension;
}

// MARK: - Sessions

int64_t positionAt(const Session& session, MediaClock::time_point now) {
  const MediaModel& media = session.media;
  int64_t position = media.positionMs;
  if (media.playback() == PlaybackState::Playing && media.speed > 0) {
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

// MARK: - Controller

MediaController::MediaController(std::shared_ptr<MediaSurface> surface, ActionSink action,
                                 CancelSink cancel, Now now)
    : surface_(std::move(surface)),
      action_(std::move(action)),
      cancel_(std::move(cancel)),
      now_(std::move(now)) {}

const Session* MediaController::find(const std::string& sessionId) const {
  auto it = sessions_.find(sessionId);
  return it == sessions_.end() ? nullptr : &it->second;
}

const Session* MediaController::active() const {
  return active_.empty() ? nullptr : find(active_);
}

int64_t MediaController::position() const {
  const Session* session = active();
  return session ? positionAt(*session, now_()) : 0;
}

bool MediaController::deliver(const MediaModel& media, const ValueMap& model) {
  auto id = awn::NotificationBuilder::readId(awn::NotificationBuilder::content(model));
  if (!id) return false;
  auto now = now_();
  const Session* previous = active();
  std::optional<int64_t> expected;
  if (previous && previous->media.sessionId == media.sessionId)
    expected = positionAt(*previous, now);

  Session session{media, model, *id, now};
  if (!surface_->show(session)) return false;
  Session& kept = sessions_[media.sessionId] = std::move(session);
  active_ = media.sessionId;
  if (expected && isJump(*expected, media.positionMs)) surface_->positionChanged(kept, true);
  return true;
}

void MediaController::release(const std::string& sessionId) {
  if (sessions_.erase(sessionId) == 0) return;
  if (sessionId != active_) return;
  active_.clear();
  surface_->clear();
}

void MediaController::stop(const std::string& sessionId) {
  const Session* session = find(sessionId);
  if (!session) return;
  int64_t id = session->notificationId;
  release(sessionId);
  // Keep the notification while another session uses its id. Cancelling it
  // comes back through onRemoved, with this session already gone.
  bool shared = std::any_of(sessions_.begin(), sessions_.end(),
                            [id](const auto& entry) { return entry.second.notificationId == id; });
  if (!shared && cancel_) cancel_(id);
}

void MediaController::onRemoved(const std::vector<int64_t>& ids) {
  std::vector<std::string> ended;
  for (const auto& [sessionId, session] : sessions_) {
    if (std::find(ids.begin(), ids.end(), session.notificationId) != ids.end())
      ended.push_back(sessionId);
  }
  for (const auto& sessionId : ended) release(sessionId);
}

void MediaController::updatePosition(const std::string& sessionId, int64_t positionMs) {
  auto it = sessions_.find(sessionId);
  if (it == sessions_.end()) return;
  Session& session = it->second;
  auto now = now_();
  int64_t expected = positionAt(session, now);
  int64_t position = std::max<int64_t>(positionMs, 0);
  if (session.media.durationMs) position = std::min(position, *session.media.durationMs);
  session.media.positionMs = position;
  session.updatedAt = now;
  if (sessionId == active_) surface_->positionChanged(session, isJump(expected, position));
}

bool MediaController::send(const Command& command) {
  const Session* session = active();
  if (!session) return false;
  // Copies: a sink may update the sessions (e.g. Dart answering synchronously).
  ValueMap model = session->model;
  MediaModel media = session->media;
  if (media.toActionEvent() && action_) {
    std::optional<std::string> input;
    if (command.positionMs) input = std::to_string(*command.positionMs);
    action_(model, buttonKeyOf(command.control), input, syntheticButton(command.control));
  }
  if (media.toStream() && stream_) stream_(streamEvent(command, media.sessionId));
  return true;
}

// MARK: - Builder

MediaBuilder::MediaBuilder(std::shared_ptr<awn::NotificationBuilder> inner,
                           std::shared_ptr<MediaController> controller)
    : awn::NotificationBuilder(std::move(inner)), controller_(std::move(controller)) {}

std::optional<awn::BuiltNotification> MediaBuilder::build(const ValueMap& model) {
  ValueMap content = awn::NotificationBuilder::content(model);
  bool isMediaPlayer = text(content, awn::defs::NOTIFICATION_LAYOUT) == keys::LAYOUT_MEDIA_PLAYER;
  auto block = model.find(keys::MEDIA);
  bool hasMedia = block != model.end() && !block->second.isNull();
  if (!isMediaPlayer && !hasMedia) return next(model);

  // The controls show what the app plays now: never from a push, never later.
  if (lowercase(text(content, awn::defs::NOTIFICATION_CREATED_SOURCE)) ==
      lowercase(awn::source::FIREBASE))
    invalid("A media notification can't come from a push", ".push");
  auto schedule = model.find(awn::defs::NOTIFICATION_SCHEDULE);
  if (schedule != model.end() && !schedule->second.isNull())
    invalid("A media notification can't be scheduled", ".schedule");

  if (!hasMedia) invalid("The MediaPlayer layout requires a NotificationMedia", "");
  if (!isMediaPlayer) invalid("A NotificationMedia requires the MediaPlayer layout", ".layout");

  std::string error;
  auto media = MediaModel::parse(block->second, &error);
  if (!media) invalid(error, "");

  auto built = next(fillContent(model, *media));
  // A delivery time set further down the chain without a schedule (none of
  // ours): left as an OS notification.
  if (!built || built->fireDate) return built;
  auto controller = controller_;
  MediaModel parsed = *media;
  built->deliver = [controller, parsed](const awn::BuiltNotification& final,
                                        std::function<void(bool)> done) {
    done(controller->deliver(parsed, final.model));
  };
  return built;
}

// MARK: - Channel

MediaMethodHandler::MediaMethodHandler(std::shared_ptr<MediaController> controller,
                                       ValueMap capabilities)
    : controller_(std::move(controller)), capabilities_(std::move(capabilities)) {}

bool MediaMethodHandler::handle(const std::string& method, const Value& arguments,
                                awn::MethodResult result) {
  if (method == keys::METHOD_STOP) {
    auto sessionId = arguments.isMap() ? awn::getString(arguments.map(), keys::SESSION_ID)
                                       : arguments.asString();
    if (sessionId) controller_->stop(*sessionId);
    result(Value());
    return true;
  }
  if (method == keys::METHOD_UPDATE_POSITION) {
    if (arguments.isMap()) {
      const ValueMap& map = arguments.map();
      auto sessionId = awn::getString(map, keys::SESSION_ID);
      auto position = awn::getInt(map, keys::POSITION);
      if (sessionId && position) controller_->updatePosition(*sessionId, *position);
    }
    result(Value());
    return true;
  }
  if (method == keys::METHOD_CAPABILITIES) {
    result(Value(capabilities_));
    return true;
  }
  return false;
}

void RegisterMedia(std::shared_ptr<MediaController> controller, ValueMap capabilities,
                   awn::AwesomeNotifications& core) {
  awn::NotificationBuilderRegistry::shared().registerDecorator(
      kMediaPriority, [controller](std::shared_ptr<awn::NotificationBuilder> inner) {
        return std::make_shared<MediaBuilder>(std::move(inner), controller);
      });
  awn::AwesomeMethodHandlerRegistry::shared().registerHandler(
      std::make_shared<MediaMethodHandler>(controller, std::move(capabilities)));
  std::weak_ptr<MediaController> weak = controller;
  core.addRemovalObserver([weak](const std::vector<int64_t>& ids) {
    if (auto alive = weak.lock()) alive->onRemoved(ids);
  });
}

}  // namespace awn_media
