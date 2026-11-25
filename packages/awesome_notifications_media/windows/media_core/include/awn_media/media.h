#pragma once

// The platform-independent part of the Windows media session: model parsing,
// the builder rules, the control <-> system button mapping and the command
// routing. Plain C++17 on the desktop core (unit-tested off Windows); the
// SystemMediaTransportControls side is a MediaSurface.

#include <cstdint>
#include <functional>
#include <map>
#include <memory>
#include <optional>
#include <set>
#include <string>

#include "awn/awesome_notifications.h"
#include "awn/notification_builder.h"
#include "awn/registries.h"
#include "awn/value.h"

namespace awn_media {

/// Map keys and names shared with the Dart side (MediaKeys).
namespace keys {
inline constexpr const char* media = "media";
inline constexpr const char* sessionId = "sessionId";
inline constexpr const char* title = "title";
inline constexpr const char* artist = "artist";
inline constexpr const char* album = "album";
inline constexpr const char* artwork = "artwork";
inline constexpr const char* duration = "duration";
inline constexpr const char* position = "position";
inline constexpr const char* playbackSpeed = "playbackSpeed";
inline constexpr const char* state = "state";
inline constexpr const char* controls = "controls";
inline constexpr const char* skipInterval = "skipInterval";
inline constexpr const char* commandTarget = "commandTarget";
inline constexpr const char* control = "control";
inline constexpr const char* payloadSessionId = "mediaSessionId";
inline constexpr const char* commandPrefix = "awn.media.";
inline constexpr const char* layoutMediaPlayer = "MediaPlayer";
inline constexpr const char* methodStop = "mediaStop";
inline constexpr const char* methodUpdatePosition = "mediaUpdatePosition";
inline constexpr const char* methodCapabilities = "mediaCapabilities";
inline constexpr const char* commandsChannel = "awesome_notifications_media/commands";
}  // namespace keys

enum class CommandTarget { ActionEvent, Stream, Both };

/// The `media` block of a model.
struct MediaSession {
  std::string sessionId;
  std::string title;
  std::string artist;
  std::string album;
  std::string artwork;
  /// Absent: a live stream (no progress bar).
  std::optional<int64_t> duration;
  int64_t position = 0;
  double playbackSpeed = 0;
  /// NotificationPlayState name.
  std::string state;
  /// MediaControl names.
  std::set<std::string> controls;
  int64_t skipInterval = 15000;
  CommandTarget commandTarget = CommandTarget::ActionEvent;

  bool has(const std::string& control) const { return controls.count(control) > 0; }

  /// nullopt (with the reason in `error`) when the block is not a valid session.
  static std::optional<MediaSession> parse(const awn::Value& block, std::string* error = nullptr);
};

/// SystemMediaTransportControls' MediaPlaybackStatus.
enum class PlaybackStatus { Closed, Changing, Stopped, Playing, Paused };
PlaybackStatus playbackStatusOf(const std::string& state);

/// SystemMediaTransportControls' buttons that carry a media command.
enum class Button { Play, Pause, Stop, Next, Previous, FastForward, Rewind };

/// Which system buttons are enabled. The system has no interval-skip button:
/// skipForward / skipBackward use FastForward / Rewind when fastForward /
/// rewind are not controls themselves.
struct ButtonStates {
  bool play = false;
  bool pause = false;
  bool stop = false;
  bool next = false;
  bool previous = false;
  bool fastForward = false;
  bool rewind = false;
};
ButtonStates buttonStatesOf(const MediaSession& session);

/// The control a pressed system button stands for, or nullopt when the session
/// doesn't have it (a media key the session didn't enable).
std::optional<std::string> controlOf(Button button, const MediaSession& session);

/// The progress bar, in milliseconds. A live stream (no duration) has none.
struct Timeline {
  bool visible = false;
  int64_t start = 0;
  int64_t end = 0;
  int64_t position = 0;
  int64_t minSeek = 0;
  int64_t maxSeek = 0;
};
Timeline timelineOf(const MediaSession& session);

/// Where an artwork comes from on Windows.
struct ArtworkSource {
  enum class Kind { None, Remote, File, Asset };
  Kind kind = Kind::None;
  /// The URL (Remote), the local path (File) or the path inside the app's
  /// flutter_assets (Asset), UTF-8.
  std::string path;
};
/// https:// / http:// → Remote; file:// or an absolute path → File;
/// asset:// or a relative path → Asset; resource:// → None (no Windows
/// equivalent).
ArtworkSource artworkSourceOf(const std::string& source);
/// The cache file name of a downloaded artwork (hash of the URL + its image
/// extension, .png by default).
std::string artworkCacheName(const std::string& url);

/// The OS media controls (SystemMediaTransportControls on Windows). Called on
/// the platform thread.
class MediaSurface {
 public:
  virtual ~MediaSurface() = default;
  /// Shows `session`, replacing whatever was shown. False when the system
  /// controls are not available.
  virtual bool show(const MediaSession& session) = 0;
  /// Only the position of the shown session changed.
  virtual void updatePosition(const MediaSession& session) = 0;
  /// Removes the controls.
  virtual void clear() = 0;
};

/// The media session of the app window: one at a time, the last delivered
/// wins. Turns the user's commands into the core action event and / or the
/// commands stream. Platform thread only.
class MediaController {
 public:
  using StreamSink = std::function<void(const awn::ValueMap& event)>;

  MediaController(awn::AwesomeNotifications& core, std::shared_ptr<MediaSurface> surface);

  /// The commands stream while Dart listens; null otherwise.
  void setStreamSink(StreamSink sink);

  /// Shows a session built from `model` (the stamped notification model).
  bool deliver(const MediaSession& session, const awn::ValueMap& model);
  /// Releases a session: removes the controls when it is the shown one and
  /// cancels its notification.
  void stop(const std::string& sessionId);
  void updatePosition(const std::string& sessionId, int64_t position);

  /// A system button was pressed.
  void onButton(Button button);
  /// The user moved the progress bar.
  void onSeek(int64_t position);
  /// Delivers the command `control` of the shown session to its target(s).
  void command(const std::string& control, std::optional<int64_t> position = std::nullopt);

  const std::optional<MediaSession>& current() const { return current_; }

 private:
  awn::AwesomeNotifications& core_;
  std::shared_ptr<MediaSurface> surface_;
  StreamSink sink_;
  std::optional<MediaSession> current_;
  awn::ValueMap currentModel_;
  /// Notification id of every session delivered and not stopped.
  std::map<std::string, int64_t> ids_;
};

/// Builder decorator: takes over the MediaPlayer layout. Its models are shown
/// as the window's media controls instead of a toast.
class MediaBuilder : public awn::NotificationBuilder {
 public:
  MediaBuilder(std::shared_ptr<awn::NotificationBuilder> inner,
               std::shared_ptr<MediaController> controller);
  std::optional<awn::BuiltNotification> build(const awn::ValueMap& model) override;

 private:
  std::shared_ptr<MediaController> controller_;
};

/// mediaStop / mediaUpdatePosition / mediaCapabilities.
class MediaMethodHandler : public awn::AwesomeMethodHandler {
 public:
  explicit MediaMethodHandler(std::shared_ptr<MediaController> controller);
  bool handle(const std::string& method, const awn::Value& arguments,
              awn::MethodResult result) override;

 private:
  std::shared_ptr<MediaController> controller_;
};

/// What the Windows media controls show.
awn::ValueMap capabilities();

/// Below localization (it fills the title from the translated model), above
/// scheduling.
inline constexpr int kMediaPriority = 50;

/// Registers the decorator and the method handler in the core registries.
void RegisterMedia(std::shared_ptr<MediaController> controller);

}  // namespace awn_media
