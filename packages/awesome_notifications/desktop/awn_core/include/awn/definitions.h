#pragma once

#include <string>

namespace awn {

/// Map keys and constants shared with the Dart side (`definitions.dart`), with
/// the same names as the Apple and Android cores.
namespace defs {
// Notification model sections
inline constexpr const char* NOTIFICATION_CONTENT = "content";
inline constexpr const char* NOTIFICATION_BUTTONS = "actionButtons";
inline constexpr const char* NOTIFICATION_SCHEDULE = "schedule";

// Content fields
inline constexpr const char* NOTIFICATION_ID = "id";
inline constexpr const char* NOTIFICATION_TITLE = "title";
inline constexpr const char* NOTIFICATION_BODY = "body";
inline constexpr const char* NOTIFICATION_SUMMARY = "summary";
inline constexpr const char* NOTIFICATION_PAYLOAD = "payload";
inline constexpr const char* NOTIFICATION_AUTO_DISMISSIBLE = "autoDismissible";
inline constexpr const char* NOTIFICATION_LAYOUT = "notificationLayout";
inline constexpr const char* NOTIFICATION_LARGE_ICON = "largeIcon";
inline constexpr const char* NOTIFICATION_BIG_PICTURE = "bigPicture";
inline constexpr const char* NOTIFICATION_ROUNDED_LARGE_ICON = "roundedLargeIcon";
inline constexpr const char* NOTIFICATION_WAKE_UP_SCREEN = "wakeUpScreen";
inline constexpr const char* NOTIFICATION_CATEGORY = "category";

// Action button fields
inline constexpr const char* NOTIFICATION_BUTTON_KEY = "key";
inline constexpr const char* NOTIFICATION_BUTTON_LABEL = "label";
inline constexpr const char* NOTIFICATION_BUTTON_ENABLED = "enabled";
inline constexpr const char* NOTIFICATION_REQUIRE_INPUT_TEXT = "requireInputText";
inline constexpr const char* NOTIFICATION_IS_DANGEROUS_OPTION = "isDangerousOption";
inline constexpr const char* NOTIFICATION_BUTTON_KEY_PRESSED = "buttonKeyPressed";
inline constexpr const char* NOTIFICATION_BUTTON_KEY_INPUT = "buttonKeyInput";

// Permissions
inline constexpr const char* NOTIFICATION_PERMISSIONS = "permissions";

// Channel fields
inline constexpr const char* NOTIFICATION_CHANNEL_KEY = "channelKey";
inline constexpr const char* NOTIFICATION_GROUP_KEY = "groupKey";
inline constexpr const char* NOTIFICATION_CHANNEL_NAME = "channelName";
inline constexpr const char* NOTIFICATION_IMPORTANCE = "importance";
inline constexpr const char* NOTIFICATION_PLAY_SOUND = "playSound";

// Initialize payload
inline constexpr const char* INITIALIZE_CHANNELS = "initializeChannels";
inline constexpr const char* INITIALIZE_DEFAULT_ICON = "defaultIcon";
inline constexpr const char* INITIALIZE_DEBUG_MODE = "debug";

// Lifecycle / action metadata (native -> Dart)
inline constexpr const char* NOTIFICATION_CREATED_SOURCE = "createdSource";
inline constexpr const char* NOTIFICATION_CREATED_LIFECYCLE = "createdLifeCycle";
inline constexpr const char* NOTIFICATION_DISPLAYED_LIFECYCLE = "displayedLifeCycle";
inline constexpr const char* NOTIFICATION_ACTION_TYPE = "actionType";
inline constexpr const char* NOTIFICATION_ACTION_LIFECYCLE = "actionLifeCycle";
inline constexpr const char* NOTIFICATION_CREATED_DATE = "createdDate";
inline constexpr const char* NOTIFICATION_DISPLAYED_DATE = "displayedDate";
inline constexpr const char* NOTIFICATION_ACTION_DATE = "actionDate";
inline constexpr const char* NOTIFICATION_DISMISSED_DATE = "dismissedDate";

// Event method names sent back to Dart.
inline constexpr const char* EVENT_NOTIFICATION_CREATED = "notificationCreated";
inline constexpr const char* EVENT_NOTIFICATION_DISPLAYED = "notificationDisplayed";
inline constexpr const char* EVENT_NOTIFICATION_DISMISSED = "notificationDismissed";
inline constexpr const char* EVENT_DEFAULT_ACTION = "defaultAction";

// The reference time zone all lifecycle dates are serialized in.
inline constexpr const char* UTC_TIMEZONE = "UTC";
}  // namespace defs

/// Presentation hints a decorator may add to a model (top-level block, next to
/// `content`; never sent to Dart): what the channel and the content can't say
/// (e.g. a call's ringing toast). Absent = the 0.12 presentation, unchanged.
namespace presentation {
inline constexpr const char* BLOCK = "desktopPresentation";
/// int 0 low, 1 normal, 2 critical: overrides the channel's (freedesktop).
inline constexpr const char* URGENCY = "urgency";
/// bool: stays on screen after an action (freedesktop "resident").
inline constexpr const char* RESIDENT = "resident";
/// bool true: no sound, whatever the channel says.
inline constexpr const char* SILENT = "silent";
/// Freedesktop sound naming spec name (e.g. "phone-incoming-call").
inline constexpr const char* SOUND_NAME = "soundName";
/// Toast `scenario` attribute (e.g. "incomingCall").
inline constexpr const char* TOAST_SCENARIO = "toastScenario";
/// Toast `<audio src>` (e.g. "ms-winsoundevent:Notification.Looping.Call").
inline constexpr const char* TOAST_AUDIO = "toastAudio";
/// bool: the toast audio loops.
inline constexpr const char* TOAST_AUDIO_LOOP = "toastAudioLoop";
/// Map button key -> toast `hint-buttonStyle` ("Success" / "Critical").
inline constexpr const char* TOAST_BUTTON_STYLES = "toastButtonStyles";
}  // namespace presentation

/// Origin of a notification (wire values of the Dart `NotificationSource`).
namespace source {
inline constexpr const char* LOCAL = "Local";
inline constexpr const char* SCHEDULE = "Schedule";
inline constexpr const char* FIREBASE = "Firebase";
}  // namespace source

/// App lifecycle state (wire values of the Dart `NotificationLifeCycle`).
enum class LifeCycle { Foreground, Background, Terminated };

inline const char* toWire(LifeCycle lifeCycle) {
  switch (lifeCycle) {
    case LifeCycle::Foreground: return "Foreground";
    case LifeCycle::Background: return "Background";
    case LifeCycle::Terminated: return "Terminated";
  }
  return "Foreground";
}

/// Action button / content tap type (wire values of the Dart `ActionType`).
enum class ActionType {
  Default,
  InputField,
  DisabledAction,
  KeepOnTop,
  SilentAction,
  SilentBackgroundAction,
  DismissAction
};

inline const char* toWire(ActionType type) {
  switch (type) {
    case ActionType::Default: return "Default";
    case ActionType::InputField: return "InputField";
    case ActionType::DisabledAction: return "DisabledAction";
    case ActionType::KeepOnTop: return "KeepOnTop";
    case ActionType::SilentAction: return "SilentAction";
    case ActionType::SilentBackgroundAction: return "SilentBackgroundAction";
    case ActionType::DismissAction: return "DismissAction";
  }
  return "Default";
}

/// Parses the wire value, tolerating a legacy "ActionType."-prefixed form; an
/// unknown/empty value falls back to Default.
inline ActionType actionTypeFrom(const std::string& raw) {
  std::string name = raw;
  auto dot = name.rfind('.');
  if (dot != std::string::npos) name = name.substr(dot + 1);
  for (auto type : {ActionType::Default, ActionType::InputField, ActionType::DisabledAction,
                    ActionType::KeepOnTop, ActionType::SilentAction,
                    ActionType::SilentBackgroundAction, ActionType::DismissAction}) {
    if (name == toWire(type)) return type;
  }
  return ActionType::Default;
}

/// Scheme prefixes of a media reference (Dart `MediaSourcePrefix`).
namespace media {
inline constexpr const char* RESOURCE = "resource://";
inline constexpr const char* ASSET = "asset://";
inline constexpr const char* FILE = "file://";
inline constexpr const char* HTTPS = "https://";
inline constexpr const char* HTTP = "http://";
}  // namespace media

}  // namespace awn
