#pragma once

// Portable (Flutter-, GLib- and D-Bus-free) logic of the media package on the
// desktop: the `media` model, the builder rules, the sessions and how an MPRIS
// call becomes a media command. Unit-tested with the core's harness (test/).

#include <chrono>
#include <cstdint>
#include <functional>
#include <map>
#include <memory>
#include <optional>
#include <set>
#include <string>
#include <vector>

#include "awn/notification_builder.h"
#include "awn/registries.h"
#include "awn/value.h"

namespace awn_media {

using awn::Value;
using awn::ValueList;
using awn::ValueMap;
using MediaClock = std::chrono::steady_clock;

namespace keys {
inline constexpr const char* MEDIA = "media";
inline constexpr const char* SESSION_ID = "sessionId";
inline constexpr const char* TITLE = "title";
inline constexpr const char* ARTIST = "artist";
inline constexpr const char* ALBUM = "album";
inline constexpr const char* ARTWORK = "artwork";
inline constexpr const char* DURATION = "duration";
inline constexpr const char* POSITION = "position";
inline constexpr const char* PLAYBACK_SPEED = "playbackSpeed";
inline constexpr const char* STATE = "state";
inline constexpr const char* CONTROLS = "controls";
inline constexpr const char* SKIP_INTERVAL = "skipInterval";
inline constexpr const char* COMMAND_TARGET = "commandTarget";
inline constexpr const char* CONTROL = "control";
inline constexpr const char* PAYLOAD_SESSION_ID = "mediaSessionId";
inline constexpr const char* COMMAND_PREFIX = "awn.media.";
inline constexpr const char* LAYOUT_MEDIA_PLAYER = "MediaPlayer";

inline constexpr const char* METHOD_STOP = "mediaStop";
inline constexpr const char* METHOD_UPDATE_POSITION = "mediaUpdatePosition";
inline constexpr const char* METHOD_CAPABILITIES = "mediaCapabilities";
inline constexpr const char* COMMANDS_CHANNEL = "awesome_notifications_media/commands";
}  // namespace keys

/// Order of the media builder in the desktop chain: inside the localization
/// decorator (100, so the media sees translated text), outside the schedules (10).
inline constexpr int kMediaPriority = 50;

/// `MediaControl` of the Dart side, by its name.
enum class Control {
  play,
  pause,
  stop,
  skipNext,
  skipPrevious,
  skipForward,
  skipBackward,
  seekTo,
  fastForward,
  rewind
};

const char* controlName(Control control);
std::optional<Control> controlFrom(const std::string& name);

/// `MediaCommandTarget` of the Dart side.
enum class CommandTarget { actionEvent, stream, both };

/// MPRIS PlaybackStatus.
enum class PlaybackStatus { Playing, Paused, Stopped };
const char* playbackStatusName(PlaybackStatus status);

/// The `media` block of a model (the Dart `NotificationMedia.toMap()`).
struct MediaModel {
  std::string sessionId;
  std::string title;
  std::string artist;
  std::string album;
  std::string artwork;
  /// Absent for a live stream.
  std::optional<int64_t> durationMs;
  int64_t positionMs = 0;
  double speed = 0.0;
  std::string state = "none";
  std::set<Control> controls;
  int64_t skipIntervalMs = 15000;
  CommandTarget target = CommandTarget::actionEvent;

  /// Parses the block; nullopt with `error` set when it is invalid.
  static std::optional<MediaModel> parse(const Value& block, std::string* error = nullptr);

  bool has(Control control) const { return controls.count(control) > 0; }
  PlaybackStatus status() const;
  bool toActionEvent() const { return target != CommandTarget::stream; }
  bool toStream() const { return target != CommandTarget::actionEvent; }
};

/// The model with the content filled for the media (empty title / body from
/// the media title / artist, `mediaSessionId` in the payload).
ValueMap fillContent(const ValueMap& model, const MediaModel& media);

/// Takes over the `MediaPlayer` layout: validates the pair (layout, `media`)
/// and hands the built notification to `deliver` instead of the OS
/// notification. A model with neither goes through untouched.
class MediaBuilder : public awn::NotificationBuilder {
 public:
  /// Delivers on the platform thread; `done` answers whether it was shown.
  using Deliver = std::function<void(const MediaModel& media, const awn::BuiltNotification& built,
                                     std::function<void(bool)> done)>;

  MediaBuilder(std::shared_ptr<awn::NotificationBuilder> inner, Deliver deliver);
  std::optional<awn::BuiltNotification> build(const ValueMap& model) override;

 private:
  Deliver deliver_;
};

/// One session of the app's player.
struct Session {
  MediaModel media;
  /// The notification model (for the action events).
  ValueMap model;
  /// When `media.positionMs` was true.
  MediaClock::time_point updatedAt;
  /// Object path of the session's track (MPRIS `mpris:trackid`).
  std::string trackId;
};

/// The position now, from the last update and the speed, kept in [0, duration].
int64_t positionAt(const Session& session, MediaClock::time_point now);

/// A position update that is not where the player was expected to be (more
/// than the tolerance away): MPRIS clients must be told (Seeked).
bool isJump(int64_t expectedMs, int64_t actualMs);

/// MPRIS `mpris:trackid` of a session: an object path that names it.
std::string trackIdFor(const std::string& sessionId);
/// MPRIS bus name of the app: org.mpris.MediaPlayer2.<app id>.instance<pid>.
std::string busNameFor(const std::string& appId, long pid);

/// The sessions of the app. The system shows one player per app: the last
/// updated session owns it.
class Sessions {
 public:
  /// Creates or replaces a session and makes it the active one.
  Session& update(const MediaModel& media, const ValueMap& model, MediaClock::time_point now);
  /// Updates a session's position only. Returns whether the session exists.
  bool updatePosition(const std::string& sessionId, int64_t positionMs, MediaClock::time_point now);
  /// Releases a session. Returns whether it was the active one.
  bool stop(const std::string& sessionId);

  Session* find(const std::string& sessionId);
  Session* active();

 private:
  std::map<std::string, Session> sessions_;
  std::string active_;
};

/// A command for Dart.
struct Command {
  Control control;
  /// The target position of a seekTo, in ms.
  std::optional<int64_t> positionMs;
};

/// MPRIS Player capabilities, from the session's controls.
struct PlayerCapabilities {
  bool canPlay = false;
  bool canPause = false;
  bool canGoNext = false;
  bool canGoPrevious = false;
  bool canSeek = false;
};
PlayerCapabilities capabilitiesOf(const MediaModel& media);

/// The command an MPRIS org.mpris.MediaPlayer2.Player method call becomes
/// (nullopt when the session has no control for it). `offsetUs` is Seek's
/// argument; `trackId` / `positionUs` are SetPosition's.
std::optional<Command> commandFor(const std::string& method, const Session& session,
                                  MediaClock::time_point now, int64_t offsetUs = 0,
                                  const std::string& trackId = "", int64_t positionUs = 0);

/// The `awn.media.<control>` button of a command, as a pressed button.
std::string buttonKeyOf(Control control);
ValueMap syntheticButton(Control control);
/// The EventChannel event of a command.
ValueMap streamEvent(const Command& command, const std::string& sessionId);

/// What the media controls can do on Linux.
ValueMap capabilitiesMap();

/// The system's player (MPRIS on Linux). Called on the platform thread.
class Player {
 public:
  virtual ~Player() = default;
  /// Shows the active session (metadata, status, capabilities).
  virtual void show(const Session& session) = 0;
  /// The active session's position jumped to `positionMs`.
  virtual void seeked(const Session& session, int64_t positionMs) = 0;
  /// Nothing to show: empty metadata, Stopped.
  virtual void clear() = 0;
};

/// The sessions and their commands, between the channel, the builder and the
/// system's player. Everything runs on the platform thread.
class MediaController {
 public:
  /// Emits the core's action event (awn::AwesomeNotifications::dispatchAction).
  using ActionSink = std::function<void(const ValueMap& model, const std::string& buttonKey,
                                        const std::optional<std::string>& input,
                                        const ValueMap& button)>;
  /// Sends an EventChannel event (dropped while Dart doesn't listen).
  using StreamSink = std::function<void(const ValueMap& event)>;
  using Now = std::function<MediaClock::time_point()>;

  MediaController(std::shared_ptr<Player> player, ActionSink action, StreamSink stream,
                  Now now = [] { return MediaClock::now(); });

  /// A media notification was created / updated.
  void deliver(const MediaModel& media, const ValueMap& model);
  void stop(const std::string& sessionId);
  void updatePosition(const std::string& sessionId, int64_t positionMs);

  /// An org.mpris.MediaPlayer2.Player method on the active session. Returns
  /// whether it became a command.
  bool onPlayerMethod(const std::string& method, int64_t offsetUs = 0,
                      const std::string& trackId = "", int64_t positionUs = 0);

  /// The active session (null when none).
  const Session* active() { return sessions_.active(); }
  /// The active session's position now, in ms (0 without one).
  int64_t position();

 private:
  void send(const Session& session, const Command& command);

  std::shared_ptr<Player> player_;
  ActionSink action_;
  StreamSink stream_;
  Now now_;
  Sessions sessions_;
};

/// Answers mediaStop / mediaUpdatePosition / mediaCapabilities.
class MediaMethodHandler : public awn::AwesomeMethodHandler {
 public:
  explicit MediaMethodHandler(std::shared_ptr<MediaController> controller);
  bool handle(const std::string& method, const Value& arguments,
              awn::MethodResult result) override;

 private:
  std::shared_ptr<MediaController> controller_;
};

/// Registers the media builder and method handler with the desktop core.
void RegisterMedia(std::shared_ptr<MediaController> controller);

}  // namespace awn_media
