#include "smtc_mapping.h"

#include <algorithm>

namespace awn_media {

SmtcStatus smtcStatusOf(PlaybackState state) {
  switch (state) {
    case PlaybackState::Playing: return SmtcStatus::Playing;
    case PlaybackState::Paused: return SmtcStatus::Paused;
    case PlaybackState::Changing: return SmtcStatus::Changing;
    case PlaybackState::Stopped: break;
  }
  return SmtcStatus::Stopped;
}

ButtonStates buttonStatesOf(const MediaModel& media) {
  ButtonStates states;
  states.play = media.has(Control::play);
  states.pause = media.has(Control::pause);
  states.stop = media.has(Control::stop);
  states.next = media.has(Control::skipNext);
  states.previous = media.has(Control::skipPrevious);
  states.fastForward = media.has(Control::fastForward) || media.has(Control::skipForward);
  states.rewind = media.has(Control::rewind) || media.has(Control::skipBackward);
  return states;
}

std::optional<Control> controlOf(Button button, const MediaModel& media) {
  auto when = [&media](Control control) -> std::optional<Control> {
    if (media.has(control)) return control;
    return std::nullopt;
  };
  switch (button) {
    case Button::Play: return when(Control::play);
    case Button::Pause: return when(Control::pause);
    case Button::Stop: return when(Control::stop);
    case Button::Next: return when(Control::skipNext);
    case Button::Previous: return when(Control::skipPrevious);
    case Button::FastForward:
      if (auto control = when(Control::fastForward)) return control;
      return when(Control::skipForward);
    case Button::Rewind:
      if (auto control = when(Control::rewind)) return control;
      return when(Control::skipBackward);
  }
  return std::nullopt;
}

Timeline timelineOf(const MediaModel& media) {
  Timeline timeline;
  if (!media.durationMs) return timeline;
  timeline.visible = true;
  timeline.end = *media.durationMs;
  timeline.position = std::max<int64_t>(0, std::min(media.positionMs, timeline.end));
  timeline.maxSeek = media.has(Control::seekTo) ? timeline.end : 0;
  return timeline;
}

bool onButton(MediaController& controller, Button button) {
  const Session* session = controller.active();
  if (!session) return false;
  auto control = controlOf(button, session->media);
  return control && controller.send(Command{*control, std::nullopt});
}

bool onSeek(MediaController& controller, int64_t positionMs) {
  const Session* session = controller.active();
  if (!session || !session->media.has(Control::seekTo) || !session->media.durationMs)
    return false;
  int64_t target = std::max<int64_t>(0, std::min(positionMs, *session->media.durationMs));
  return controller.send(Command{Control::seekTo, target});
}

ValueMap smtcCapabilities() {
  return ValueMap{
      {"seekBar", true}, {"artwork", true}, {"customButtons", false}, {"lockScreen", true}};
}

}  // namespace awn_media
