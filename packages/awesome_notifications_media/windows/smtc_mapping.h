#pragma once

// How the shared media logic maps to the SystemMediaTransportControls
// (portable: no Windows headers, so the shared test suite covers it on any
// OS). Used by SmtcSurface.

#include <cstdint>
#include <optional>

#include "awn_media/media.h"

namespace awn_media {

/// SystemMediaTransportControls' MediaPlaybackStatus.
enum class SmtcStatus { Closed, Changing, Stopped, Playing, Paused };
/// Stopped (not Closed) for a stopped player: Closed would drop the session
/// from the system flyout while the app still shows it.
SmtcStatus smtcStatusOf(PlaybackState state);

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
ButtonStates buttonStatesOf(const MediaModel& media);

/// The control a pressed system button stands for, or nullopt when the session
/// doesn't have it (a media key the session didn't enable).
std::optional<Control> controlOf(Button button, const MediaModel& media);

/// The progress bar, in milliseconds. A live stream (no duration) has none.
struct Timeline {
  bool visible = false;
  int64_t start = 0;
  int64_t end = 0;
  int64_t position = 0;
  int64_t minSeek = 0;
  int64_t maxSeek = 0;
};
Timeline timelineOf(const MediaModel& media);

/// Sends the command of a pressed system button on the active session.
/// Returns whether it became a command.
bool onButton(MediaController& controller, Button button);
/// The user moved the progress bar to `positionMs`: seekTo (clamped to the
/// track) when the active session has it.
bool onSeek(MediaController& controller, int64_t positionMs);

/// What the media controls can do on Windows (mediaCapabilities).
ValueMap smtcCapabilities();

}  // namespace awn_media
