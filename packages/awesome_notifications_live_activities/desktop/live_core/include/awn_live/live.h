#pragma once

// The portable (Flutter- and OS-free, plain C++17) live activity logic of the
// desktop platforms, Linux and Windows: the `liveActivity` model, its
// notification, the activity registry, the stale / dismissal timers and the
// channel methods, on the desktop core. Neither platform has a live activity
// surface: an activity is its notification, replaced in place. Linux: a
// freedesktop notification drawn by the core's presenter (same replaces_id),
// the progress as a text bar. Windows: a toast with a data-bound progress bar
// that the plugin shows itself and then updates through its NotificationData
// (toastPostOf). Only the first post of an activity alerts (or an update with
// `alert`). The platform plugins (linux/, windows/) supply the timer, the
// event channel and, on Windows, the toast. Unit-tested in tests/.

#include <cstdint>
#include <functional>
#include <map>
#include <memory>
#include <optional>
#include <cwchar>
#include <string>
#include <vector>

#include "awn/awesome_notifications.h"
#include "awn/notification_builder.h"
#include "awn/registries.h"
#include "awn/value.h"

namespace awn_live {

using awn::Value;
using awn::ValueList;
using awn::ValueMap;

/// Map keys and names shared with the Dart side (LiveActivityKeys).
namespace keys {
inline constexpr const char* LIVE_ACTIVITY = "liveActivity";

inline constexpr const char* ACTIVITY_ID = "activityId";
inline constexpr const char* STATE = "state";
inline constexpr const char* PROGRESS = "progress";
inline constexpr const char* TIMER = "timer";
inline constexpr const char* METRICS = "metrics";
inline constexpr const char* SHORT_TEXT = "shortText";
inline constexpr const char* ACCENT_COLOR = "accentColor";
inline constexpr const char* STALE_AT = "staleAt";
inline constexpr const char* RELEVANCE = "relevance";
inline constexpr const char* ALERT = "alert";
inline constexpr const char* DISMISSAL = "dismissal";
inline constexpr const char* PUSH_CHANNEL = "pushChannel";

inline constexpr const char* SEGMENTS = "segments";
inline constexpr const char* POINTS = "points";
inline constexpr const char* TRACKER_ICON = "trackerIcon";
inline constexpr const char* START_ICON = "startIcon";
inline constexpr const char* END_ICON = "endIcon";
inline constexpr const char* LENGTH = "length";
inline constexpr const char* POSITION = "position";
inline constexpr const char* COLOR = "color";

inline constexpr const char* START = "start";
inline constexpr const char* END = "end";
inline constexpr const char* COUNT_DOWN = "countDown";

inline constexpr const char* LABEL = "label";
inline constexpr const char* VALUE = "value";
inline constexpr const char* UNIT = "unit";

inline constexpr const char* DISMISSAL_DEFAULT = "default";
inline constexpr const char* DISMISSAL_IMMEDIATE = "immediate";

inline constexpr const char* PAYLOAD_ACTIVITY_ID = "activityId";

inline constexpr const char* METHOD_END = "liveActivityEnd";
inline constexpr const char* METHOD_LIST = "liveActivityList";
inline constexpr const char* METHOD_CAPABILITIES = "liveActivityCapabilities";
inline constexpr const char* METHOD_ARE_ENABLED = "liveActivityAreEnabled";
inline constexpr const char* METHOD_REQUEST_PERMISSION = "liveActivityRequestPermission";
inline constexpr const char* METHOD_PUSH_TO_START_TOKEN = "liveActivityPushToStartToken";
inline constexpr const char* METHOD_PUSH_TOKEN = "liveActivityPushToken";

inline constexpr const char* EVENTS_CHANNEL = "awesome_notifications_live_activities/events";
inline constexpr const char* KIND = "kind";
inline constexpr const char* KIND_STATE = "state";

inline constexpr const char* CAP_SYSTEM_SURFACE = "systemSurface";
inline constexpr const char* CAP_PROGRESS_SEGMENTS = "progressSegments";
inline constexpr const char* CAP_METRICS = "metrics";
inline constexpr const char* CAP_BUTTONS = "buttons";
inline constexpr const char* CAP_PUSH = "push";

// The core's content progress (0 to 100; null: indeterminate).
inline constexpr const char* CONTENT_PROGRESS = "progress";

// Presentation hints of the live toast (next to the core's, in its
// `desktopPresentation` block; the core's presenter ignores them: the Windows
// plugin shows and updates these toasts itself, see toastPostOf).
inline constexpr const char* HINT_TOAST_DATA = "liveToastData";
inline constexpr const char* HINT_TOAST_SEQUENCE = "liveToastSequence";
inline constexpr const char* HINT_TOAST_PROGRESS = "liveToastProgress";
inline constexpr const char* HINT_TOAST_UPDATE = "liveToastUpdate";
inline constexpr const char* HINT_TOAST_SUPPRESS_POPUP = "liveToastSuppressPopup";

// The data bindings of the Windows toast.
inline constexpr const char* BIND_TITLE = "title";
inline constexpr const char* BIND_BODY = "body";
inline constexpr const char* BIND_PROGRESS_TITLE = "progressTitle";
inline constexpr const char* BIND_PROGRESS_VALUE = "progressValue";
inline constexpr const char* BIND_PROGRESS_VALUE_STRING = "progressValueString";
inline constexpr const char* BIND_PROGRESS_STATUS = "progressStatus";
}  // namespace keys

/// Order of the live activity builder in the desktop chain: inside the
/// localization decorator (100, so the activity sees translated text) and the
/// media one (50), outside the schedules (10, so a scheduled activity is
/// refused before it is scheduled).
inline constexpr int kLivePriority = 45;

/// The longest a platform timer is armed for: a later deadline re-arms.
inline constexpr int64_t kMaxTimerMs = 24LL * 60 * 60 * 1000;

/// Which desktop notification draws the activity.
enum class Surface {
  /// Linux: org.freedesktop.Notifications, replaced through replaces_id.
  freedesktop,
  /// Windows: a toast with a data-bound progress bar, updated in place.
  toast
};

/// `LiveActivityState` of the Dart side.
enum class State { active, ended };

/// What `liveActivityList` and the state events report.
enum class Status { active, stale, ended, dismissed };
const char* statusName(Status status);

struct Segment {
  int64_t length = 0;
  std::optional<int64_t> color;
};

struct Point {
  int64_t position = 0;
  std::optional<int64_t> color;
};

/// `LiveActivityProgress`: how the bar looks. Its value is the content's
/// `progress`. The desktop draws a plain bar (no segments, points or icons).
struct Progress {
  std::vector<Segment> segments;
  std::vector<Point> points;
  std::string trackerIcon;
  std::string startIcon;
  std::string endIcon;
};

/// `LiveActivityTimer` (ms since the epoch, UTC).
struct Timer {
  std::optional<int64_t> start;
  std::optional<int64_t> end;
  bool countDown = false;
};

struct Metric {
  std::string label;
  std::string value;
  std::string unit;
};

/// `LiveActivityDismissal`: when an ended activity leaves the screen.
struct Dismissal {
  enum class Kind { system, immediate, at };
  Kind kind = Kind::system;
  /// Ms since the epoch (UTC), for Kind::at.
  int64_t at = 0;

  /// The wire value: "default", "immediate" or ms; nullopt when unknown.
  static std::optional<Dismissal> from(const Value& value);
};

/// The `liveActivity` block of a model (the Dart `NotificationLiveActivity
/// .toMap()`), parsed with the rules of its validate() (a push never passes
/// through Dart).
struct LiveModel {
  /// The notification id when the block has none.
  std::string activityId;
  State state = State::active;
  std::optional<Progress> progress;
  std::optional<Timer> timer;
  std::vector<Metric> metrics;
  std::string shortText;
  std::optional<int64_t> accentColor;
  std::optional<int64_t> staleAt;
  std::optional<double> relevance;
  bool alert = false;
  Dismissal dismissal;
  std::string pushChannel;

  /// Parses the block of notification `notificationId`; nullopt with the
  /// reason in `error` when it is invalid.
  static std::optional<LiveModel> parse(const Value& block, int64_t notificationId,
                                        std::string* error = nullptr);
};

/// Formats a time (ms since the epoch, UTC) for the text of a timer.
using ClockFormat = std::function<std::string(int64_t ms)>;
/// Local "HH:MM".
std::string localClock(int64_t ms);

/// The lines the desktop folds into the body, as the web one does (no system
/// clock, bar or metric view):
///   the app's body
///   "▰▰▰▰▰▰▱▱▱▱ 60% · <shortText>"   (`withBar`; indeterminate: the shortText)
///   "Ends at HH:mm" / "Started at HH:mm"
///   "Speed 42 km/h · Stops 2"
/// Absent parts are left out.
std::string barText(const ValueMap& content, const LiveModel& live, bool withBar);
std::string timerText(const LiveModel& live, const ClockFormat& clock);
std::string metricsText(const LiveModel& live);
std::string liveBody(const ValueMap& content, const LiveModel& live, bool withBar,
                     const ClockFormat& clock);

/// The content's progress clamped to 0..100; nullopt: indeterminate.
std::optional<double> progressValue(const ValueMap& content);
/// Whether the activity shows a bar: a `progress` block or a content progress.
bool hasBar(const ValueMap& content, const LiveModel& live);

/// How a post is shown.
struct Post {
  /// It alerts (sound, banner): the first post of the activity, or `alert`.
  bool alerts = true;
  /// Windows: the toast of the activity is shown and draws the same layout,
  /// so its NotificationData is updated in place.
  bool update = false;
  /// Windows: the toast's NotificationData sequence (increasing).
  uint32_t sequence = 1;
};

/// The notification of an activity: `activityId` in the payload, the body
/// with what the surface can't draw folded in, and the presentation hints
/// (freedesktop: resident while active, silent unless it alerts; toast: the
/// data bindings of the title, the body and the progress bar, updated in place
/// unless it alerts).
ValueMap liveNotification(const ValueMap& model, const LiveModel& live, Surface surface,
                          const Post& post, const ClockFormat& clock);

/// What makes a toast need a new layout (the bar, the buttons, the images):
/// equal layouts are updated in place.
std::string layoutOf(const ValueMap& model, const LiveModel& live);

/// A live toast as the Windows plugin shows it (from the model liveNotification
/// made). Tag: the notification id; group: the core's ("awn"), so the core's
/// cancel / dismiss remove it as any other toast.
struct ToastPost {
  int64_t id = 0;
  std::string tag;
  /// ToastGeneric with {title} / {body} texts and, with a bar, a <progress>
  /// bound to {progressTitle} {progressValue} {progressValueString}
  /// {progressStatus}.
  std::string xml;
  /// The NotificationData values and sequence number.
  std::map<std::string, std::string> data;
  uint32_t sequence = 1;
  /// Update the shown toast through its data (no popup); show it when gone.
  bool update = false;
  /// Shown straight into the notification center.
  bool suppressPopup = false;
};
/// The core's toast group.
inline constexpr const char* kToastGroup = "awn";
/// `largeIcon`: a local image (file:// or an absolute path) for the toast,
/// whose presenter can't download for these. Empty otherwise.
std::string localImagePath(const std::string& source);
ToastPost toastPostOf(const ValueMap& model, bool silentChannel);
/// Whether the model's channel plays no sound (`channel` from the core).
bool silentChannel(const std::optional<ValueMap>& channel);
/// The AppUserModelID the core gives an unpackaged app (its app_identity.cpp:
/// "AwesomeNotifications.<sanitized exe stem>.<fnv1a of the lowercase path>").
std::wstring unpackagedAumid(const std::wstring& executablePath);

/// The EventChannel event of a state change.
ValueMap stateEvent(const std::string& activityId, Status status);

/// What the activities need from the desktop core (see engineHost);
/// replaceable in tests.
struct LiveHost {
  /// Shows a built notification through the core's presenter (no events).
  std::function<void(const awn::BuiltNotification&, std::function<void(bool)>)> present;
  /// Replaces the stored model of a notification (an activity ended by
  /// liveActivityEnd).
  std::function<void(int64_t id, const ValueMap& model)> store;
  /// Cancels a notification (awn::AwesomeNotifications::cancel).
  std::function<void(int64_t id)> cancel;
  /// Emits the core's action event (awn::AwesomeNotifications::dispatchAction).
  std::function<void(const ValueMap& model, const std::string& buttonKey,
                     const std::optional<std::string>& input, const ValueMap& button)>
      action;
  /// Runs `work` on the platform thread after `ms` milliseconds.
  std::function<void(int64_t ms, std::function<void()> work)> after;
  /// Ms since the epoch (UTC).
  std::function<int64_t()> now;
  /// The text of a timer's time.
  ClockFormat clock;
};

/// The host over the desktop core `core`, with the platform's timer.
LiveHost engineHost(awn::AwesomeNotifications& core,
                    std::function<void(int64_t ms, std::function<void()> work)> after);

/// An activity the system (its notification) shows now.
struct Activity {
  LiveModel live;
  /// The model as the app sent it (re-rendered by liveActivityEnd).
  ValueMap source;
  /// The model of the shown notification.
  ValueMap model;
  int64_t notificationId = 0;
  Status status = Status::active;
  /// The toast layout shown (layoutOf).
  std::string layout;
  /// The generation of its stale / dismissal timer (0: none).
  uint64_t timer = 0;
};

/// The app's activities, between the channel, the builder, the notifications
/// and the timers. Everything runs on the platform thread.
class LiveController : public std::enable_shared_from_this<LiveController> {
 public:
  using StreamSink = std::function<void(const ValueMap& event)>;

  LiveController(LiveHost host, Surface surface);

  /// The events stream while Dart listens; null otherwise.
  void setStreamSink(StreamSink sink) { stream_ = std::move(sink); }
  Surface surface() const { return surface_; }

  /// How the next post of `live` is shown, its `layout` drawn on notification
  /// `id`.
  Post postOf(const LiveModel& live, int64_t id, const std::string& layout);
  /// liveNotification on this controller's surface and clock.
  ValueMap render(const ValueMap& model, const LiveModel& live, const Post& post) const;

  /// Shows a post of an activity (`built` comes from the builder chain): the
  /// same activityId updates its activity; ended starts its dismissal.
  void deliver(const LiveModel& live, const ValueMap& source, const std::string& layout,
               const awn::BuiltNotification& built, std::function<void(bool)> done);
  /// An ended activity with the immediate dismissal: its notification goes.
  void finish(const LiveModel& live, const ValueMap& model);

  /// liveActivityEnd: shows the last content as ended until `dismissal`.
  void end(const std::string& activityId, const Dismissal& dismissal);
  /// The core dismissed / cancelled these notifications: their activities end.
  void onRemoved(const std::vector<int64_t>& ids);
  /// The user dismissed this notification.
  void onDismissed(int64_t id);
  /// An activation of an activity's notification (`buttonKey` empty for the
  /// notification itself, `input` the typed text). A tap opens the app and
  /// keeps the activity; a button emits its action, and ends the activity when
  /// it dismisses. nullopt: the core handles it as usual (a DismissAction).
  std::optional<awn::ActionType> onActivated(const ValueMap& model, const std::string& buttonKey,
                                             const std::optional<std::string>& input);

  /// liveActivityList: [{activityId, state}].
  ValueList list() const;
  const Activity* find(const std::string& activityId) const;

 private:
  void arm(const std::string& activityId, int64_t at);
  void onTimer(const std::string& activityId, uint64_t generation, int64_t at);
  /// Forgets the activity, then cancels its notification (so the core's
  /// removal doesn't end it again).
  void drop(const std::string& activityId);
  void emit(const std::string& activityId, Status status);
  /// The activity shown on notification `id`.
  std::map<std::string, Activity>::iterator byNotification(int64_t id);

  LiveHost host_;
  Surface surface_;
  StreamSink stream_;
  std::map<std::string, Activity> activities_;
  uint64_t nextTimer_ = 1;
  uint32_t nextSequence_ = 1;
};

/// Builder decorator: takes over the models with a `liveActivity` block
/// (validated, never scheduled); a model without one goes through untouched.
class LiveBuilder : public awn::NotificationBuilder {
 public:
  LiveBuilder(std::shared_ptr<awn::NotificationBuilder> inner,
              std::shared_ptr<LiveController> controller);
  std::optional<awn::BuiltNotification> build(const ValueMap& model) override;

 private:
  std::shared_ptr<LiveController> controller_;
};

/// Answers the liveActivity* methods.
class LiveMethodHandler : public awn::AwesomeMethodHandler {
 public:
  LiveMethodHandler(std::shared_ptr<LiveController> controller, ValueMap capabilities);
  bool handle(const std::string& method, const Value& arguments,
              awn::MethodResult result) override;

 private:
  std::shared_ptr<LiveController> controller_;
  ValueMap capabilities_;
};

/// What a desktop platform offers: no system surface, a plain bar, metrics in
/// the text, buttons, no pushes.
ValueMap desktopCapabilities();

/// Registers the live activity builder, method handler, activation
/// interceptor, removal observer and dismissal listener with the desktop core.
void RegisterLiveActivities(std::shared_ptr<LiveController> controller, ValueMap capabilities,
                            awn::AwesomeNotifications& core);

}  // namespace awn_live
