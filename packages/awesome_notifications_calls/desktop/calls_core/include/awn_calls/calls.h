#pragma once

// The portable (Flutter- and OS-free, plain C++17) call logic of the desktop
// platforms, Linux and Windows: the `call` model, its notification, the state
// machine, the ring timer, the missed call notification and the command
// routing, on the desktop core. Neither platform has a system call UI: the call
// is the strongest notification each one has (a critical, resident freedesktop
// notification; an incomingCall toast), drawn by the core presenters from the
// presentation hints this builder adds. The platform plugins (linux/, windows/)
// only supply the timer and the event channel. Unit-tested in tests/.

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

namespace awn_calls {

using awn::Value;
using awn::ValueList;
using awn::ValueMap;

/// Map keys and names shared with the Dart side (CallKeys).
namespace keys {
inline constexpr const char* CALL = "call";
inline constexpr const char* CALL_ID = "callId";
inline constexpr const char* CALLER = "caller";
inline constexpr const char* HANDLE = "handle";
inline constexpr const char* VIDEO = "video";
inline constexpr const char* GROUP_NAME = "groupName";
inline constexpr const char* STATE = "state";
inline constexpr const char* STARTED_AT = "startedAt";
inline constexpr const char* RING_TIMEOUT = "ringTimeout";
inline constexpr const char* MISSED_NOTIFICATION = "missedNotification";
inline constexpr const char* CONTROLS = "controls";
inline constexpr const char* COMMAND_TARGET = "commandTarget";
inline constexpr const char* SYSTEM_CALL_UI = "systemCallUI";
inline constexpr const char* TEXTS = "texts";

inline constexpr const char* TEXT_INCOMING = "incoming";
inline constexpr const char* TEXT_INCOMING_VIDEO = "incomingVideo";
inline constexpr const char* TEXT_OUTGOING = "outgoing";
inline constexpr const char* TEXT_ONGOING = "ongoing";
inline constexpr const char* TEXT_MISSED = "missed";
inline constexpr const char* TEXT_MISSED_VIDEO = "missedVideo";
inline constexpr const char* TEXT_ACCEPT = "accept";
inline constexpr const char* TEXT_DECLINE = "decline";
inline constexpr const char* TEXT_HANG_UP = "hangUp";
inline constexpr const char* TEXT_HELD = "held";

// NotificationPerson (core model)
inline constexpr const char* PERSON_KEY = "key";
inline constexpr const char* PERSON_NAME = "name";
inline constexpr const char* PERSON_AVATAR = "avatar";
inline constexpr const char* PERSON_URI = "uri";
inline constexpr const char* PERSON_IS_BOT = "isBot";
inline constexpr const char* PERSON_IS_IMPORTANT = "isImportant";

inline constexpr const char* PAYLOAD_CALL_ID = "callId";
inline constexpr const char* COMMAND_PREFIX = "awn.call.";

inline constexpr const char* METHOD_END = "callEnd";
inline constexpr const char* METHOD_ACTIVE_CALLS = "callActiveCalls";
inline constexpr const char* METHOD_VOIP_TOKEN = "callVoipToken";
inline constexpr const char* METHOD_CAN_USE_FULL_SCREEN_INTENT = "callCanUseFullScreenIntent";
inline constexpr const char* METHOD_REQUEST_FULL_SCREEN_INTENT = "callRequestFullScreenIntent";
inline constexpr const char* METHOD_CAPABILITIES = "callCapabilities";
inline constexpr const char* REASON = "reason";

inline constexpr const char* EVENTS_CHANNEL = "awesome_notifications_calls/events";
inline constexpr const char* KIND = "kind";
inline constexpr const char* KIND_COMMAND = "command";
inline constexpr const char* ACTION = "action";

// callCapabilities
inline constexpr const char* CAP_SYSTEM_CALL_UI = "systemCallUI";
inline constexpr const char* CAP_LOCK_SCREEN = "lockScreen";
inline constexpr const char* CAP_MUTE_AND_HOLD = "muteAndHold";
inline constexpr const char* CAP_PUSH = "push";
}  // namespace keys

/// Order of the call builder in the desktop chain: inside the localization
/// decorator (100, so the call sees translated text), outside the schedules
/// (10, so a scheduled call is refused before it is scheduled).
inline constexpr int kCallsPriority = 40;

/// Freedesktop sound naming spec: the incoming call ring.
inline constexpr const char* kLinuxRingSound = "phone-incoming-call";
/// The looping call ring of Windows toasts.
inline constexpr const char* kToastRingAudio = "ms-winsoundevent:Notification.Looping.Call";

/// `CallState` of the Dart side.
enum class CallState { incoming, outgoing, ongoing, held, ended, missed };
const char* stateName(CallState state);
std::optional<CallState> stateFrom(const std::string& name);

/// `CallControl` of the Dart side.
enum class Control { accept, decline, hangUp, mute, hold };
const char* controlName(Control control);
std::optional<Control> controlFrom(const std::string& name);

/// `CallAction` of the Dart side (the command names).
enum class Action {
  accept,
  decline,
  hangUp,
  mute,
  unmute,
  hold,
  unhold,
  timeout,
  audioActivated,
  audioDeactivated
};
const char* actionName(Action action);
std::optional<Action> actionFrom(const std::string& name);

/// `CallCommandTarget` of the Dart side.
enum class CommandTarget { actionEvent, stream, both };

/// `CallEndReason` of the Dart side.
enum class EndReason { remoteEnded, declinedElsewhere, answeredElsewhere, unanswered, failed };
std::optional<EndReason> endReasonFrom(const std::string& name);

/// The core's NotificationPerson map.
struct Person {
  std::string key;
  std::string name;
  std::string avatar;
  std::string uri;
  bool isBot = false;
  bool isImportant = false;
};

/// `CallTexts` of the Dart side (same defaults).
struct Texts {
  std::string incoming = "Incoming call";
  std::string incomingVideo = "Incoming video call";
  std::string outgoing = "Calling\xE2\x80\xA6";
  std::string ongoing = "Ongoing call";
  std::string missed = "Missed call";
  std::string missedVideo = "Missed video call";
  std::string accept = "Accept";
  std::string decline = "Decline";
  std::string hangUp = "Hang up";
  std::string held = "On hold";
};

/// The `call` block of a model (the Dart `NotificationCall.toMap()`), parsed
/// with the rules of NotificationCall.validate() (pushes never pass through
/// Dart).
struct CallModel {
  std::string callId;
  Person caller;
  /// Absent: the caller's key.
  std::string handle;
  bool video = false;
  std::string groupName;
  CallState state = CallState::incoming;
  /// Ms since the epoch (UTC).
  std::optional<int64_t> startedAt;
  int64_t ringTimeoutMs = 60000;
  bool missedNotification = true;
  std::set<Control> controls;
  CommandTarget target = CommandTarget::actionEvent;
  bool systemCallUI = true;
  Texts texts;

  /// Parses the block; nullopt with the reason in `error` when it is invalid.
  static std::optional<CallModel> parse(const Value& block, std::string* error = nullptr);

  bool has(Control control) const { return controls.count(control) > 0; }
  bool toActionEvent() const { return target != CommandTarget::stream; }
  bool toStream() const { return target != CommandTarget::actionEvent; }
  /// The group's name, or the caller's.
  const std::string& displayName() const { return groupName.empty() ? caller.name : groupName; }
  /// A call the notification still shows (incoming, outgoing, ongoing, held).
  bool isLive() const { return state != CallState::ended && state != CallState::missed; }
};

/// `model` with its `call` block moved to `state` (and `startedAt`, when given).
ValueMap withState(const ValueMap& model, CallState state,
                   std::optional<int64_t> startedAt = std::nullopt);

/// The notification of a live call: the title (when the app left it empty)
/// from the group / caller, the body from the state's text, the caller's
/// avatar as the (round) large icon when the app set none, `callId` in the
/// payload, the call's buttons (Accept / Decline ringing, Hang up after) ahead
/// of the app's own, and the presentation hints of the state (ringing:
/// critical, resident, ring sound, incomingCall toast with looping audio;
/// otherwise: resident and silent).
ValueMap callNotification(const ValueMap& model, const CallModel& call);

/// The id of a call's missed notification: stable per call, never negative.
int64_t missedId(const std::string& callId);
/// The missed call notification (id: Java String.hashCode of "missed:" + callId, masked positive, as on every platform): a regular notification on the call's
/// channel, titled with the group / caller, `callId` in the payload, no
/// buttons.
ValueMap missedNotification(const ValueMap& model, const CallModel& call);

/// The `awn.call.<action>` button of a command, as a pressed button.
std::string buttonKeyOf(Action action);
ValueMap syntheticButton(Action action);
/// The EventChannel event of a command.
ValueMap streamEvent(Action action, const std::string& callId);

/// What the calls need from the desktop core (see engineHost); replaceable in
/// tests.
struct CallHost {
  /// Shows a built notification through the core's presenter (no events).
  std::function<void(const awn::BuiltNotification&, std::function<void(bool)>)> present;
  /// Replaces the stored model of a notification (a call that changed state).
  std::function<void(int64_t id, const ValueMap& model)> store;
  /// Cancels a notification (awn::AwesomeNotifications::cancel).
  std::function<void(int64_t id)> cancel;
  /// Creates a notification as the app would (the missed call notification).
  std::function<void(const ValueMap& model)> create;
  /// Emits the core's action event (awn::AwesomeNotifications::dispatchAction).
  std::function<void(const ValueMap& model, const std::string& buttonKey,
                     const std::optional<std::string>& input, const ValueMap& button)>
      action;
  /// Runs `work` on the platform thread after `ms` milliseconds.
  std::function<void(int64_t ms, std::function<void()> work)> after;
  /// Ms since the epoch (UTC).
  std::function<int64_t()> now;
};

/// The host over the desktop core `core`, with the platform's timer.
CallHost engineHost(awn::AwesomeNotifications& core,
                    std::function<void(int64_t ms, std::function<void()> work)> after);

/// A call the system (its notification) shows now.
struct ActiveCall {
  CallModel call;
  /// The stored model of its notification.
  ValueMap model;
  int64_t notificationId = 0;
  /// The ring timer's generation (0: not ringing).
  uint64_t ring = 0;
};

/// The app's calls, between the channel, the builder, the notifications and
/// the timer. Everything runs on the platform thread.
class CallController : public std::enable_shared_from_this<CallController> {
 public:
  using StreamSink = std::function<void(const ValueMap& event)>;

  explicit CallController(CallHost host);

  /// The events stream while Dart listens; null otherwise.
  void setStreamSink(StreamSink sink) { stream_ = std::move(sink); }

  /// Shows a live call (`built` comes from the builder chain): the same
  /// callId updates its call; ringing starts the ring timer, any other state
  /// stops it.
  void deliver(const CallModel& call, const awn::BuiltNotification& built,
               std::function<void(bool)> done);
  /// ended / missed: the call's notification goes (and the missed one comes,
  /// for missed). No command.
  void finish(const CallModel& call, const ValueMap& model);

  /// An activation of a call notification (`buttonKey` empty for the
  /// notification itself). Applies the command to the call first, then
  /// delivers it to its target(s). nullopt when it isn't a call's.
  std::optional<awn::ActionType> onActivated(const ValueMap& model, const std::string& buttonKey);

  /// callEnd.
  void end(const std::string& callId, EndReason reason);
  /// The core dismissed / cancelled these notifications: their calls end.
  void onRemoved(const std::vector<int64_t>& ids);
  /// callActiveCalls: [{callId, state}].
  ValueList activeCalls() const;

  const ActiveCall* find(const std::string& callId) const;

 private:
  void ringTimeout(const std::string& callId, uint64_t ring);
  /// Forgets a call (stops its timer) and cancels its notification.
  void drop(const std::string& callId);
  void showMissed(const CallModel& call, const ValueMap& model);
  void send(Action action, const CallModel& call, const ValueMap& model);

  CallHost host_;
  StreamSink stream_;
  std::map<std::string, ActiveCall> calls_;
  uint64_t nextRing_ = 1;
};

/// Builder decorator: takes over the models with a `call` block (validated,
/// never scheduled); a model without one goes through untouched.
class CallBuilder : public awn::NotificationBuilder {
 public:
  CallBuilder(std::shared_ptr<awn::NotificationBuilder> inner,
              std::shared_ptr<CallController> controller);
  std::optional<awn::BuiltNotification> build(const ValueMap& model) override;

 private:
  std::shared_ptr<CallController> controller_;
};

/// Answers callEnd / callActiveCalls / callVoipToken / callCanUseFullScreenIntent
/// / callRequestFullScreenIntent / callCapabilities.
class CallMethodHandler : public awn::AwesomeMethodHandler {
 public:
  CallMethodHandler(std::shared_ptr<CallController> controller, ValueMap capabilities);
  bool handle(const std::string& method, const Value& arguments,
              awn::MethodResult result) override;

 private:
  std::shared_ptr<CallController> controller_;
  ValueMap capabilities_;
};

/// What a desktop platform offers: no system call UI, no lock screen, no mute /
/// hold UI, no call pushes.
ValueMap desktopCapabilities();

/// Registers the call builder, method handler, activation interceptor and
/// removal observer with the desktop core.
void RegisterCalls(std::shared_ptr<CallController> controller, ValueMap capabilities,
                   awn::AwesomeNotifications& core);

}  // namespace awn_calls
