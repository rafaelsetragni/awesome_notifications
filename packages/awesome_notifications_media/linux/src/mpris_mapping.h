#pragma once

// How the shared media logic maps to MPRIS 2 (portable: no GLib, no D-Bus, so
// the shared test suite covers it on any OS). Used by MprisPlayer.

#include <cstdint>
#include <optional>
#include <string>

#include "awn_media/media.h"

namespace awn_media {

/// MPRIS PlaybackStatus: Playing, Paused or Stopped (MPRIS has no
/// "changing": a player about to move is Paused).
const char* mprisPlaybackStatus(PlaybackState state);

/// MPRIS Player capabilities, from the session's controls.
struct PlayerCapabilities {
  bool canPlay = false;
  bool canPause = false;
  bool canGoNext = false;
  bool canGoPrevious = false;
  bool canSeek = false;
};
PlayerCapabilities capabilitiesOf(const MediaModel& media);

/// The command an org.mpris.MediaPlayer2.Player method call becomes (nullopt
/// when the session has no control for it). `positionMs` is the session's
/// position now; `offsetUs` is Seek's argument; `trackId` / `positionUs` are
/// SetPosition's.
std::optional<Command> commandFor(const std::string& method, const Session& session,
                                  int64_t positionMs, int64_t offsetUs = 0,
                                  const std::string& trackId = "", int64_t positionUs = 0);

/// Sends the command of a Player method call on the active session. Returns
/// whether it became a command.
bool onPlayerMethod(MediaController& controller, const std::string& method, int64_t offsetUs = 0,
                    const std::string& trackId = "", int64_t positionUs = 0);

/// MPRIS `mpris:trackid` of a session: an object path that names it.
std::string trackIdFor(const std::string& sessionId);
/// MPRIS bus name of the app: org.mpris.MediaPlayer2.<app id>.instance<pid>.
std::string busNameFor(const std::string& appId, long pid);

/// What the media controls can do on Linux (mediaCapabilities).
ValueMap mprisCapabilities();

}  // namespace awn_media
