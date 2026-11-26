#pragma once

// The portable (Flutter- and OS-free, plain C++17) media logic of the desktop
// platforms, Linux and Windows: the `media` model, the builder rules, the
// sessions and the command routing, on the desktop core. The system side (MPRIS
// on Linux, SystemMediaTransportControls on Windows) is a MediaSurface; its own
// mappings live next to it, in linux/ and windows/. Unit-tested in tests/.

#include <chrono>
#include <cstdint>
#include <functional>
#include <map>
#include <memory>
#include <optional>
#include <set>
#include <string>
#include <vector>

#include "awn/awesome_notifications.h"
#include "awn/notification_builder.h"
#include "awn/registries.h"
#include "awn/value.h"

namespace awn_media {

using awn::Value;
using awn::ValueList;
using awn::ValueMap;
using MediaClock = std::chrono::steady_clock;

/// Map keys and names shared with the Dart side (MediaKeys).
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
/// decorator (100, so the media sees translated text), outside the schedules
/// (10, so a scheduled media model is rejected before it is scheduled).
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

/// How the player moves, whatever the system calls it (each surface maps it to
/// its own status names).
enum class PlaybackState {
  /// playing, forwarding, rewinding: the position advances.
  Playing,
  /// paused.
  Paused,
  /// buffering, connecting and the transitions (previous, next,
  /// skippingToQueueItem): about to move, the position holds.
  Changing,
  /// stopped, none, unknown, error (and any unknown name).
  Stopped
};
PlaybackState playbackStateOf(const std::string& state);

/// The `media` block of a model (the Dart `NotificationMedia.toMap()`). Parsed
/// with the rules of NotificationMedia.validate().
struct MediaModel {
  std::string sessionId;
  std::string title;
  std::string artist;
  std::string album;
  std::string artwork;
  /// Absent for a live stream (no progress bar).
  std::optional<int64_t> durationMs;
  int64_t positionMs = 0;
  double speed = 0.0;
  /// NotificationPlayState name.
  std::string state = "unknown";
  std::set<Control> controls;
  int64_t skipIntervalMs = 15000;
  CommandTarget target = CommandTarget::actionEvent;

  /// Parses the block; nullopt with the reason in `error` when it is invalid.
  static std::optional<MediaModel> parse(const Value& block, std::string* error = nullptr);

  bool has(Control control) const { return controls.count(control) > 0; }
  PlaybackState playback() const { return playbackStateOf(state); }
  bool toActionEvent() const { return target != CommandTarget::stream; }
  bool toStream() const { return target != CommandTarget::actionEvent; }
};

/// The model with the content filled for the media (empty title / body from
/// the media title / artist, `mediaSessionId` added to the payload).
ValueMap fillContent(const ValueMap& model, const MediaModel& media);

// MARK: - Artwork

/// Where an artwork comes from.
struct ArtworkSource {
  enum class Kind { None, Remote, File, Asset };
  Kind kind = Kind::None;
  /// The URL (Remote), the local path (File) or the path inside the app's
  /// flutter_assets (Asset), UTF-8.
  std::string path;
};
/// https:// / http:// → Remote; file:// (percent-decoded) or an absolute path →
/// File; asset:// or a relative path → Asset; resource:// → None (no desktop
/// equivalent).
ArtworkSource artworkSourceOf(const std::string& source);
/// The cache file name of a downloaded artwork (hash of the URL + its image
/// extension, .png by default).
std::string artworkCacheName(const std::string& url);

// MARK: - Sessions

/// One session of the app's player.
struct Session {
  MediaModel media;
  /// The stamped notification model (for the action events).
  ValueMap model;
  /// The id of the session's notification.
  int64_t notificationId = 0;
  /// When `media.positionMs` was true.
  MediaClock::time_point updatedAt;
};

/// The position now, from the last update and the speed, kept in [0, duration].
int64_t positionAt(const Session& session, MediaClock::time_point now);

/// A position update that is not where the player was expected to be (more
/// than the tolerance away).
bool isJump(int64_t expectedMs, int64_t actualMs);

/// A command for Dart.
struct Command {
  Control control;
  /// The target position of a seekTo, in ms.
  std::optional<int64_t> positionMs;
};

/// The `awn.media.<control>` button of a command, as a pressed button.
std::string buttonKeyOf(Control control);
ValueMap syntheticButton(Control control);
/// The EventChannel event of a command.
ValueMap streamEvent(const Command& command, const std::string& sessionId);

/// The system's media controls (MPRIS on Linux, SMTC on Windows). The system
/// shows one player per app. Called on the platform thread.
class MediaSurface {
 public:
  virtual ~MediaSurface() = default;
  /// Shows `session`, replacing whatever was shown. False when the system
  /// controls are not available.
  virtual bool show(const Session& session) = 0;
  /// The app set the shown session's position (mediaUpdatePosition, or an
  /// update of its model). `jump`: not where the clock had it.
  virtual void positionChanged(const Session& session, bool jump) = 0;
  /// Nothing to show: removes the controls.
  virtual void clear() = 0;
};

/// The app's sessions, between the channel, the builder and the system's
/// controls. The system shows one player per app: the last delivered session
/// owns it (the active one). Everything runs on the platform thread.
class MediaController {
 public:
  /// Emits the core's action event (awn::AwesomeNotifications::dispatchAction).
  using ActionSink = std::function<void(const ValueMap& model, const std::string& buttonKey,
                                        const std::optional<std::string>& input,
                                        const ValueMap& button)>;
  /// Sends an EventChannel event.
  using StreamSink = std::function<void(const ValueMap& event)>;
  /// Cancels a notification (awn::AwesomeNotifications::cancel).
  using CancelSink = std::function<void(int64_t id)>;
  using Now = std::function<MediaClock::time_point()>;

  MediaController(std::shared_ptr<MediaSurface> surface, ActionSink action, CancelSink cancel,
                  Now now = [] { return MediaClock::now(); });

  /// The commands stream while Dart listens; null otherwise.
  void setStreamSink(StreamSink sink) { stream_ = std::move(sink); }

  /// Shows a session built from `model` (the stamped notification model).
  /// False (nothing kept) when the system controls are not available.
  bool deliver(const MediaModel& media, const ValueMap& model);
  /// mediaStop: releases a session, removes the controls when it is the shown
  /// one and cancels its notification (unless another session still uses it).
  void stop(const std::string& sessionId);
  /// The core dismissed / cancelled these notifications: their sessions end,
  /// as with stop.
  void onRemoved(const std::vector<int64_t>& ids);
  void updatePosition(const std::string& sessionId, int64_t positionMs);

  /// Delivers a command of the active session to its target(s). False without
  /// an active session.
  bool send(const Command& command);

  /// The active session (null when none).
  const Session* active() const;
  const Session* find(const std::string& sessionId) const;
  /// The active session's position now, in ms (0 without one).
  int64_t position() const;

 private:
  /// Drops a session; clears the surface when it was the active one.
  void release(const std::string& sessionId);

  std::shared_ptr<MediaSurface> surface_;
  ActionSink action_;
  CancelSink cancel_;
  StreamSink stream_;
  Now now_;
  std::map<std::string, Session> sessions_;
  std::string active_;
};

/// Builder decorator: takes over the MediaPlayer layout. Its models are shown
/// as the system's media controls instead of an OS notification; a model with
/// neither the layout nor a `media` block goes through untouched.
class MediaBuilder : public awn::NotificationBuilder {
 public:
  MediaBuilder(std::shared_ptr<awn::NotificationBuilder> inner,
               std::shared_ptr<MediaController> controller);
  std::optional<awn::BuiltNotification> build(const ValueMap& model) override;

 private:
  std::shared_ptr<MediaController> controller_;
};

/// Answers mediaStop / mediaUpdatePosition / mediaCapabilities.
class MediaMethodHandler : public awn::AwesomeMethodHandler {
 public:
  /// `capabilities`: what the platform's media controls show.
  MediaMethodHandler(std::shared_ptr<MediaController> controller, ValueMap capabilities);
  bool handle(const std::string& method, const Value& arguments,
              awn::MethodResult result) override;

 private:
  std::shared_ptr<MediaController> controller_;
  ValueMap capabilities_;
};

/// Registers the media builder and method handler with the desktop core, and
/// ends a session when `core` dismisses / cancels its notification.
void RegisterMedia(std::shared_ptr<MediaController> controller, ValueMap capabilities,
                   awn::AwesomeNotifications& core);

}  // namespace awn_media
