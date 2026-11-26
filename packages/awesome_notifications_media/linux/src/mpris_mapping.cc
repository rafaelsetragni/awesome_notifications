#include "mpris_mapping.h"

#include <algorithm>
#include <cctype>
#include <cstdio>

namespace awn_media {

const char* mprisPlaybackStatus(PlaybackState state) {
  switch (state) {
    case PlaybackState::Playing: return "Playing";
    case PlaybackState::Paused:
    case PlaybackState::Changing: return "Paused";
    case PlaybackState::Stopped: break;
  }
  return "Stopped";
}

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
                                  int64_t positionMs, int64_t offsetUs,
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
    return ifHas(media.playback() == PlaybackState::Playing ? Control::pause : Control::play);
  if (method == "Stop") return ifHas(Control::stop);
  if (method == "Next") return ifHas(Control::skipNext);
  if (method == "Previous") return ifHas(Control::skipPrevious);
  if (method == "Seek") {
    if (offsetUs == 0) return std::nullopt;
    if (media.has(Control::seekTo)) return seekTo(positionMs + offsetUs / 1000);
    return ifHas(offsetUs > 0 ? Control::skipForward : Control::skipBackward);
  }
  if (method == "SetPosition") {
    // MPRIS: ignored for another track or a position out of the track.
    if (!media.has(Control::seekTo) || trackId != trackIdFor(media.sessionId) || positionUs < 0)
      return std::nullopt;
    if (media.durationMs && positionUs / 1000 > *media.durationMs) return std::nullopt;
    return seekTo(positionUs / 1000);
  }
  return std::nullopt;
}

bool onPlayerMethod(MediaController& controller, const std::string& method, int64_t offsetUs,
                    const std::string& trackId, int64_t positionUs) {
  const Session* session = controller.active();
  if (!session) return false;
  auto command =
      commandFor(method, *session, controller.position(), offsetUs, trackId, positionUs);
  return command && controller.send(*command);
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

ValueMap mprisCapabilities() {
  return ValueMap{
      {"seekBar", true}, {"artwork", true}, {"customButtons", false}, {"lockScreen", false}};
}

}  // namespace awn_media
