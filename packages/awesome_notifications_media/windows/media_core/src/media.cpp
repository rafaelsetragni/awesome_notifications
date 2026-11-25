#include "awn_media/media.h"

#include <algorithm>
#include <cctype>
#include <cstdio>
#include <cstring>

#include "awn/definitions.h"
#include "awn/exception.h"

namespace awn_media {

using awn::Value;
using awn::ValueMap;

namespace {

bool startsWith(const std::string& text, const char* prefix) { return text.rfind(prefix, 0) == 0; }

std::string trim(const std::string& text) {
  auto begin = text.find_first_not_of(" \t\r\n");
  if (begin == std::string::npos) return {};
  auto end = text.find_last_not_of(" \t\r\n");
  return text.substr(begin, end - begin + 1);
}

int64_t clamp(int64_t value, int64_t low, int64_t high) {
  return std::max(low, std::min(value, high));
}

/// Decodes the %XX escapes of a file URI path.
std::string percentDecode(const std::string& text) {
  std::string out;
  for (size_t i = 0; i < text.size(); ++i) {
    if (text[i] == '%' && i + 2 < text.size() &&
        std::isxdigit(static_cast<unsigned char>(text[i + 1])) &&
        std::isxdigit(static_cast<unsigned char>(text[i + 2]))) {
      out += static_cast<char>(std::stoi(text.substr(i + 1, 2), nullptr, 16));
      i += 2;
    } else {
      out += text[i];
    }
  }
  return out;
}

bool isAbsolutePath(const std::string& path) {
  if (path.empty()) return false;
  if (path[0] == '/' || path[0] == '\\') return true;
  return path.size() > 1 && std::isalpha(static_cast<unsigned char>(path[0])) && path[1] == ':';
}

awn::AwesomeNotificationsException invalid(const std::string& message, const std::string& detail) {
  return awn::AwesomeNotificationsException(
      awn::exception_code::INVALID_ARGUMENTS, message,
      std::string(awn::exception_code::DETAILED_INVALID_ARGUMENTS) + ".notificationMedia" + detail);
}

}  // namespace

// MARK: - MediaSession

std::optional<MediaSession> MediaSession::parse(const Value& block, std::string* error) {
  auto fail = [error](const char* message) -> std::optional<MediaSession> {
    if (error) *error = message;
    return std::nullopt;
  };
  if (!block.isMap()) return fail("The media block must be a map");
  const ValueMap& map = block.map();

  MediaSession session;
  session.sessionId = awn::getString(map, keys::sessionId).value_or("");
  if (trim(session.sessionId).empty()) return fail("The media session needs a non-empty sessionId");
  session.title = awn::getString(map, keys::title).value_or("");
  session.artist = awn::getString(map, keys::artist).value_or("");
  session.album = awn::getString(map, keys::album).value_or("");
  session.artwork = awn::getString(map, keys::artwork).value_or("");
  session.state = awn::getString(map, keys::state).value_or("unknown");

  auto duration = awn::getInt(map, keys::duration);
  if (duration && *duration > 0) session.duration = *duration;
  session.position = std::max<int64_t>(0, awn::getInt(map, keys::position).value_or(0));
  if (session.duration) session.position = std::min(session.position, *session.duration);

  auto speed = map.count(keys::playbackSpeed) ? map.at(keys::playbackSpeed).asDouble() : std::nullopt;
  session.playbackSpeed = std::max(0.0, speed.value_or(session.state == "playing" ? 1.0 : 0.0));

  for (const auto& control : awn::getList(map, keys::controls)) {
    if (auto name = control.asString()) session.controls.insert(*name);
  }
  auto interval = awn::getInt(map, keys::skipInterval);
  if (interval && *interval > 0) session.skipInterval = *interval;

  std::string target = awn::getString(map, keys::commandTarget).value_or("");
  session.commandTarget = target == "stream" ? CommandTarget::Stream
                          : target == "both" ? CommandTarget::Both
                                             : CommandTarget::ActionEvent;
  return session;
}

// MARK: - System controls

PlaybackStatus playbackStatusOf(const std::string& state) {
  if (state == "playing" || state == "forwarding" || state == "rewinding")
    return PlaybackStatus::Playing;
  if (state == "paused") return PlaybackStatus::Paused;
  if (state == "buffering" || state == "connecting" || state == "previous" || state == "next" ||
      state == "skippingToQueueItem")
    return PlaybackStatus::Changing;
  // stopped, none, unknown, error: Closed would drop the session from the
  // system flyout while the app still shows it.
  return PlaybackStatus::Stopped;
}

ButtonStates buttonStatesOf(const MediaSession& session) {
  ButtonStates states;
  states.play = session.has("play");
  states.pause = session.has("pause");
  states.stop = session.has("stop");
  states.next = session.has("skipNext");
  states.previous = session.has("skipPrevious");
  states.fastForward = session.has("fastForward") || session.has("skipForward");
  states.rewind = session.has("rewind") || session.has("skipBackward");
  return states;
}

std::optional<std::string> controlOf(Button button, const MediaSession& session) {
  auto when = [&session](const char* control) -> std::optional<std::string> {
    if (session.has(control)) return std::string(control);
    return std::nullopt;
  };
  switch (button) {
    case Button::Play: return when("play");
    case Button::Pause: return when("pause");
    case Button::Stop: return when("stop");
    case Button::Next: return when("skipNext");
    case Button::Previous: return when("skipPrevious");
    case Button::FastForward:
      if (auto control = when("fastForward")) return control;
      return when("skipForward");
    case Button::Rewind:
      if (auto control = when("rewind")) return control;
      return when("skipBackward");
  }
  return std::nullopt;
}

Timeline timelineOf(const MediaSession& session) {
  Timeline timeline;
  if (!session.duration) return timeline;
  timeline.visible = true;
  timeline.end = *session.duration;
  timeline.position = clamp(session.position, 0, timeline.end);
  timeline.maxSeek = session.has("seekTo") ? timeline.end : 0;
  return timeline;
}

ArtworkSource artworkSourceOf(const std::string& source) {
  using Kind = ArtworkSource::Kind;
  if (source.empty() || startsWith(source, awn::media::RESOURCE)) return {};
  if (startsWith(source, "https://") || startsWith(source, "http://"))
    return {Kind::Remote, source};
  if (startsWith(source, "file://")) {
    std::string path = percentDecode(source.substr(std::strlen("file://")));
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
  std::string lower = url.substr(0, url.find_first_of("?#"));
  std::transform(lower.begin(), lower.end(), lower.begin(),
                 [](unsigned char c) { return static_cast<char>(std::tolower(c)); });
  std::string extension = ".png";
  for (const char* candidate : {".jpg", ".jpeg", ".gif", ".png", ".bmp"}) {
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

// MARK: - MediaController

MediaController::MediaController(awn::AwesomeNotifications& core,
                                 std::shared_ptr<MediaSurface> surface)
    : core_(core), surface_(std::move(surface)) {}

void MediaController::setStreamSink(StreamSink sink) { sink_ = std::move(sink); }

bool MediaController::deliver(const MediaSession& session, const ValueMap& model) {
  auto id = awn::NotificationBuilder::readId(awn::NotificationBuilder::content(model));
  if (!id) return false;
  if (!surface_->show(session)) return false;
  current_ = session;
  currentModel_ = model;
  ids_[session.sessionId] = *id;
  return true;
}

void MediaController::stop(const std::string& sessionId) {
  if (current_ && current_->sessionId == sessionId) {
    surface_->clear();
    current_.reset();
    currentModel_.clear();
  }
  auto it = ids_.find(sessionId);
  if (it == ids_.end()) return;
  int64_t id = it->second;
  ids_.erase(it);
  // Keep the notification when the shown session reuses its id.
  bool shownId = current_ && ids_.count(current_->sessionId) && ids_[current_->sessionId] == id;
  if (core_.isConfigured() && !shownId) core_.cancel(id);
}

void MediaController::updatePosition(const std::string& sessionId, int64_t position) {
  if (!current_ || current_->sessionId != sessionId) return;
  position = std::max<int64_t>(0, position);
  if (current_->duration) position = std::min(position, *current_->duration);
  current_->position = position;
  surface_->updatePosition(*current_);
}

void MediaController::onButton(Button button) {
  if (!current_) return;
  if (auto control = controlOf(button, *current_)) command(*control);
}

void MediaController::onSeek(int64_t position) {
  if (!current_ || !current_->has("seekTo") || !current_->duration) return;
  command("seekTo", clamp(position, 0, *current_->duration));
}

void MediaController::command(const std::string& control, std::optional<int64_t> position) {
  if (!current_) return;
  std::string key = std::string(keys::commandPrefix) + control;
  CommandTarget target = current_->commandTarget;

  if (target != CommandTarget::Stream) {
    ValueMap button{{awn::defs::NOTIFICATION_BUTTON_KEY, key},
                    {awn::defs::NOTIFICATION_ACTION_TYPE, "SilentAction"},
                    {awn::defs::NOTIFICATION_AUTO_DISMISSIBLE, false}};
    std::optional<std::string> input;
    if (position) input = std::to_string(*position);
    core_.dispatchAction(currentModel_, key, input, button);
  }
  if (target != CommandTarget::ActionEvent && sink_) {
    ValueMap event{{keys::control, control}, {keys::sessionId, current_->sessionId}};
    if (position) event[keys::position] = *position;
    sink_(event);
  }
}

// MARK: - MediaBuilder

MediaBuilder::MediaBuilder(std::shared_ptr<awn::NotificationBuilder> inner,
                           std::shared_ptr<MediaController> controller)
    : NotificationBuilder(std::move(inner)), controller_(std::move(controller)) {}

std::optional<awn::BuiltNotification> MediaBuilder::build(const ValueMap& model) {
  ValueMap content = NotificationBuilder::content(model);
  bool isMediaLayout = awn::getString(content, awn::defs::NOTIFICATION_LAYOUT).value_or("") ==
                       keys::layoutMediaPlayer;
  auto block = model.find(keys::media);
  if (block == model.end() || block->second.isNull()) {
    if (isMediaLayout) throw invalid("The MediaPlayer layout requires a NotificationMedia", "");
    return next(model);
  }
  if (!isMediaLayout)
    throw invalid("A NotificationMedia requires the MediaPlayer layout", ".layout");

  std::string error;
  auto session = MediaSession::parse(block->second, &error);
  if (!session) throw invalid(error, "");

  // What a toast would show, and the payload that tells commands which
  // session they came from.
  if (awn::getString(content, awn::defs::NOTIFICATION_TITLE).value_or("").empty())
    content[awn::defs::NOTIFICATION_TITLE] = session->title;
  if (awn::getString(content, awn::defs::NOTIFICATION_BODY).value_or("").empty() &&
      !session->artist.empty())
    content[awn::defs::NOTIFICATION_BODY] = session->artist;
  ValueMap payload = awn::getMap(content, awn::defs::NOTIFICATION_PAYLOAD);
  payload[keys::payloadSessionId] = session->sessionId;
  content[awn::defs::NOTIFICATION_PAYLOAD] = payload;

  ValueMap updated = model;
  updated[awn::defs::NOTIFICATION_CONTENT] = content;
  auto built = next(updated);
  // A scheduled media model stays a (scheduled) toast: the controls show what
  // plays now.
  if (!built || built->fireDate) return built;

  auto controller = controller_;
  MediaSession shown = *session;
  built->deliver = [controller, shown](const awn::BuiltNotification& delivered,
                                       std::function<void(bool)> done) {
    done(controller->deliver(shown, delivered.model));
  };
  return built;
}

// MARK: - MediaMethodHandler

MediaMethodHandler::MediaMethodHandler(std::shared_ptr<MediaController> controller)
    : controller_(std::move(controller)) {}

bool MediaMethodHandler::handle(const std::string& method, const Value& arguments,
                                awn::MethodResult result) {
  if (method == keys::methodStop) {
    auto sessionId = arguments.isMap() ? awn::getString(arguments.map(), keys::sessionId)
                                       : arguments.asString();
    if (sessionId) controller_->stop(*sessionId);
    result(Value());
    return true;
  }
  if (method == keys::methodUpdatePosition) {
    const ValueMap& map = arguments.map();
    auto sessionId = awn::getString(map, keys::sessionId);
    auto position = awn::getInt(map, keys::position);
    if (sessionId && position) controller_->updatePosition(*sessionId, *position);
    result(Value());
    return true;
  }
  if (method == keys::methodCapabilities) {
    result(Value(capabilities()));
    return true;
  }
  return false;
}

ValueMap capabilities() {
  return ValueMap{{"seekBar", true}, {"artwork", true}, {"customButtons", false},
                  {"lockScreen", true}};
}

void RegisterMedia(std::shared_ptr<MediaController> controller) {
  awn::NotificationBuilderRegistry::shared().registerDecorator(
      kMediaPriority, [controller](std::shared_ptr<awn::NotificationBuilder> inner) {
        return std::make_shared<MediaBuilder>(std::move(inner), controller);
      });
  awn::AwesomeMethodHandlerRegistry::shared().registerHandler(
      std::make_shared<MediaMethodHandler>(controller));
}

}  // namespace awn_media
