#include "awn_live/live.h"

#include <algorithm>
#include <cctype>
#include <chrono>
#include <cmath>
#include <cstdio>
#include <ctime>
#include <cwctype>

#include "awn/definitions.h"
#include "awn/exception.h"
#include "awn/json.h"
#include "awn/toast_xml.h"

namespace awn_live {

namespace {

namespace defs = awn::defs;
namespace hints = awn::presentation;

/// " · " (U+00B7), between the parts of a line.
constexpr const char* kSeparator = " \xC2\xB7 ";
/// "▰" / "▱" (U+25B0 / U+25B1): the text bar's cells.
constexpr const char* kFilled = "\xE2\x96\xB0";
constexpr const char* kEmpty = "\xE2\x96\xB1";

std::string text(const ValueMap& map, const char* key) {
  return awn::getString(map, key).value_or("");
}

bool blank(const std::string& value) {
  return std::all_of(value.begin(), value.end(),
                     [](unsigned char c) { return std::isspace(c) != 0; });
}

/// Present and not null.
const Value* field(const ValueMap& map, const char* key) {
  auto it = map.find(key);
  return it == map.end() || it->second.isNull() ? nullptr : &it->second;
}

[[noreturn]] void invalid(const std::string& message, const std::string& detail) {
  throw awn::AwesomeNotificationsException(
      awn::exception_code::INVALID_ARGUMENTS, message,
      std::string(awn::exception_code::DETAILED_INVALID_ARGUMENTS) +
          ".notificationLiveActivity" + detail);
}

int64_t idOf(const ValueMap& model) {
  return awn::NotificationBuilder::readId(awn::NotificationBuilder::content(model)).value_or(0);
}

/// "0.6", "1", "0.125": a number without trailing zeros.
std::string number(double value) {
  char buffer[32];
  std::snprintf(buffer, sizeof(buffer), "%.4f", value);
  std::string out = buffer;
  out.erase(out.find_last_not_of('0') + 1);
  if (!out.empty() && out.back() == '.') out.pop_back();
  return out;
}

std::string percent(double value) {
  return std::to_string(static_cast<int64_t>(std::lround(value))) + "%";
}

}  // namespace

// MARK: - Enums

const char* statusName(Status status) {
  switch (status) {
    case Status::active: return "active";
    case Status::stale: return "stale";
    case Status::ended: return "ended";
    case Status::dismissed: return "dismissed";
  }
  return "active";
}

std::optional<Dismissal> Dismissal::from(const Value& value) {
  Dismissal dismissal;
  if (value.isNull()) return dismissal;
  if (value.isInt() || value.isDouble()) {
    dismissal.kind = Kind::at;
    dismissal.at = value.asInt().value_or(0);
    return dismissal;
  }
  auto name = value.asString();
  if (name && *name == keys::DISMISSAL_DEFAULT) return dismissal;
  if (name && *name == keys::DISMISSAL_IMMEDIATE) {
    dismissal.kind = Kind::immediate;
    return dismissal;
  }
  return std::nullopt;
}

// MARK: - Model

std::optional<LiveModel> LiveModel::parse(const Value& block, int64_t notificationId,
                                          std::string* error) {
  auto fail = [error](const std::string& message) -> std::optional<LiveModel> {
    if (error) *error = message;
    return std::nullopt;
  };
  if (!block.isMap()) return fail("The liveActivity block must be a map");
  const ValueMap& map = block.map();

  LiveModel live;
  if (const Value* activityId = field(map, keys::ACTIVITY_ID)) {
    live.activityId = activityId->asString().value_or("");
    if (blank(live.activityId))
      return fail(
          "The live activity's activityId can't be empty (leave it out to use the notification "
          "id)");
  } else {
    live.activityId = std::to_string(notificationId);
  }

  std::string state = text(map, keys::STATE);
  if (state == "ended")
    live.state = State::ended;
  else if (state.empty() || state == "active")
    live.state = State::active;
  else
    return fail("Unknown live activity state '" + state + "'");

  if (const Value* progress = field(map, keys::PROGRESS)) {
    if (!progress->isMap()) return fail("The live activity's progress must be a map");
    const ValueMap& bar = progress->map();
    Progress parsed;
    int64_t total = 0;
    for (const auto& entry : awn::getList(bar, keys::SEGMENTS)) {
      if (!entry.isMap()) return fail("A live activity segment must be a map");
      Segment segment;
      segment.length = awn::getInt(entry.map(), keys::LENGTH).value_or(0);
      segment.color = awn::getInt(entry.map(), keys::COLOR);
      if (segment.length <= 0) return fail("A live activity segment needs a positive length");
      total += segment.length;
      parsed.segments.push_back(segment);
    }
    if (parsed.segments.empty()) total = 100;
    for (const auto& entry : awn::getList(bar, keys::POINTS)) {
      if (!entry.isMap()) return fail("A live activity point must be a map");
      Point point;
      point.position = awn::getInt(entry.map(), keys::POSITION).value_or(-1);
      point.color = awn::getInt(entry.map(), keys::COLOR);
      if (point.position < 0 || point.position > total)
        return fail("A live activity point must sit within the segments (0 to " +
                    std::to_string(total) + ")");
      parsed.points.push_back(point);
    }
    parsed.trackerIcon = text(bar, keys::TRACKER_ICON);
    parsed.startIcon = text(bar, keys::START_ICON);
    parsed.endIcon = text(bar, keys::END_ICON);
    live.progress = std::move(parsed);
  }

  if (const Value* timer = field(map, keys::TIMER)) {
    if (!timer->isMap()) return fail("The live activity's timer must be a map");
    Timer parsed;
    parsed.start = awn::getInt(timer->map(), keys::START);
    parsed.end = awn::getInt(timer->map(), keys::END);
    parsed.countDown = awn::getBool(timer->map(), keys::COUNT_DOWN).value_or(parsed.end.has_value());
    if (parsed.countDown && !parsed.end) return fail("A live activity countdown needs an end");
    if (!parsed.countDown && !parsed.start) return fail("A live activity timer needs a start");
    if (parsed.start && parsed.end && *parsed.end <= *parsed.start)
      return fail("A live activity countdown must end after it starts");
    live.timer = parsed;
  }

  ValueList metrics = awn::getList(map, keys::METRICS);
  if (metrics.size() > 3) return fail("A live activity has at most 3 metrics");
  for (const auto& entry : metrics) {
    if (!entry.isMap()) return fail("A live activity metric must be a map");
    Metric metric;
    metric.label = text(entry.map(), keys::LABEL);
    metric.value = text(entry.map(), keys::VALUE);
    metric.unit = text(entry.map(), keys::UNIT);
    if (blank(metric.label)) return fail("A live activity metric needs a label");
    live.metrics.push_back(metric);
  }

  if (const Value* shortText = field(map, keys::SHORT_TEXT)) {
    live.shortText = shortText->asString().value_or("");
    if (blank(live.shortText)) return fail("The live activity's shortText can't be empty");
  }
  if (const Value* pushChannel = field(map, keys::PUSH_CHANNEL)) {
    live.pushChannel = pushChannel->asString().value_or("");
    if (blank(live.pushChannel)) return fail("The live activity's pushChannel can't be empty");
  }
  live.accentColor = awn::getInt(map, keys::ACCENT_COLOR);
  live.staleAt = awn::getInt(map, keys::STALE_AT);
  if (const Value* relevance = field(map, keys::RELEVANCE)) live.relevance = relevance->asDouble();
  live.alert = awn::getBool(map, keys::ALERT).value_or(false);

  auto dismissal = map.find(keys::DISMISSAL);
  if (dismissal != map.end()) {
    auto parsed = Dismissal::from(dismissal->second);
    if (!parsed) return fail("Unknown live activity dismissal");
    live.dismissal = *parsed;
  }
  return live;
}

// MARK: - Text

std::string localClock(int64_t ms) {
  std::time_t seconds = static_cast<std::time_t>(ms / 1000);
  std::tm local{};
#ifdef _WIN32
  localtime_s(&local, &seconds);
#else
  localtime_r(&seconds, &local);
#endif
  char buffer[8];
  std::strftime(buffer, sizeof(buffer), "%H:%M", &local);
  return buffer;
}

std::optional<double> progressValue(const ValueMap& content) {
  const Value* progress = field(content, keys::CONTENT_PROGRESS);
  if (!progress) return std::nullopt;
  auto value = progress->asDouble();
  if (!value || !std::isfinite(*value)) return std::nullopt;
  return std::clamp(*value, 0.0, 100.0);
}

bool hasBar(const ValueMap& content, const LiveModel& live) {
  return live.progress.has_value() || progressValue(content).has_value();
}

std::string barText(const ValueMap& content, const LiveModel& live, bool withBar) {
  std::vector<std::string> parts;
  auto value = progressValue(content);
  if (withBar && value) {
    int64_t rounded = std::lround(*value);
    int64_t filled = std::lround(static_cast<double>(rounded) / 10.0);
    std::string bar;
    for (int64_t i = 0; i < 10; ++i) bar += i < filled ? kFilled : kEmpty;
    parts.push_back(bar + " " + percent(*value));
  }
  if (!live.shortText.empty()) parts.push_back(live.shortText);
  std::string out;
  for (const auto& part : parts) out += (out.empty() ? "" : kSeparator) + part;
  return out;
}

std::string metricsText(const LiveModel& live) {
  std::string out;
  for (const auto& metric : live.metrics) {
    std::string line;
    for (const auto* part : {&metric.label, &metric.value, &metric.unit})
      if (!part->empty()) line += (line.empty() ? "" : " ") + *part;
    out += (out.empty() ? "" : kSeparator) + line;
  }
  return out;
}

std::string timerText(const LiveModel& live, const ClockFormat& clock) {
  if (!live.timer) return "";
  const ClockFormat& format = clock ? clock : ClockFormat(&localClock);
  if (live.timer->end) return "Ends at " + format(*live.timer->end);
  if (live.timer->start) return "Started at " + format(*live.timer->start);
  return "";
}

std::string liveBody(const ValueMap& content, const LiveModel& live, bool withBar,
                     const ClockFormat& clock) {
  std::string out;
  for (const auto& line : {text(content, defs::NOTIFICATION_BODY), barText(content, live, withBar),
                           timerText(live, clock), metricsText(live)}) {
    if (line.empty()) continue;
    if (!out.empty()) out += "\n";
    out += line;
  }
  return out;
}

// MARK: - Notification

ValueMap liveNotification(const ValueMap& model, const LiveModel& live, Surface surface,
                          const Post& post, const ClockFormat& clock) {
  ValueMap result = model;
  ValueMap content = awn::NotificationBuilder::content(model);
  ValueMap payload = awn::getMap(content, defs::NOTIFICATION_PAYLOAD);
  payload[keys::PAYLOAD_ACTIVITY_ID] = live.activityId;
  content[defs::NOTIFICATION_PAYLOAD] = std::move(payload);

  bool active = live.state == State::active;
  auto value = progressValue(content);
  ValueMap presentation;

  if (surface == Surface::freedesktop) {
    // The text bar, as on the web (most servers draw no "value" bar).
    content[defs::NOTIFICATION_BODY] = liveBody(content, live, true, clock);
    presentation = ValueMap{{hints::RESIDENT, active}, {hints::SILENT, !post.alerts}};
  } else {
    // The native <progress> replaces the text bar; the shortText is its status.
    bool bar = hasBar(content, live);
    LiveModel textual = live;
    if (bar) textual.shortText.clear();
    std::string body = liveBody(content, textual, false, clock);
    content[defs::NOTIFICATION_BODY] = body;
    ValueMap data{{keys::BIND_TITLE, text(content, defs::NOTIFICATION_TITLE)},
                  {keys::BIND_BODY, body},
                  {keys::BIND_PROGRESS_TITLE, ""},
                  {keys::BIND_PROGRESS_VALUE, value ? number(*value / 100.0) : "indeterminate"},
                  {keys::BIND_PROGRESS_VALUE_STRING, value ? percent(*value) : std::string()},
                  {keys::BIND_PROGRESS_STATUS, bar ? live.shortText : std::string()}};
    presentation = ValueMap{{hints::SILENT, !post.alerts},
                            {keys::HINT_TOAST_DATA, std::move(data)},
                            {keys::HINT_TOAST_SEQUENCE, static_cast<int64_t>(post.sequence)},
                            {keys::HINT_TOAST_PROGRESS, bar},
                            {keys::HINT_TOAST_UPDATE, post.update},
                            {keys::HINT_TOAST_SUPPRESS_POPUP, !post.alerts}};
  }
  result[defs::NOTIFICATION_CONTENT] = std::move(content);
  result[hints::BLOCK] = std::move(presentation);
  return result;
}

// MARK: - Windows toast

std::string localImagePath(const std::string& source) {
  std::string path = source;
  if (path.rfind(awn::media::FILE, 0) == 0) {
    path = path.substr(std::char_traits<char>::length(awn::media::FILE));
    // file:///C:/x.png -> C:/x.png
    if (path.size() > 2 && path[0] == '/' && path[2] == ':') path = path.substr(1);
  }
  bool drive = path.size() > 2 && std::isalpha(static_cast<unsigned char>(path[0])) &&
               path[1] == ':' && (path[2] == '/' || path[2] == '\\');
  bool unc = path.rfind("\\\\", 0) == 0;
  return drive || unc ? path : std::string();
}

ToastPost toastPostOf(const ValueMap& model, bool silentChannel) {
  ToastPost post;
  ValueMap content = awn::NotificationBuilder::content(model);
  post.id = awn::NotificationBuilder::readId(content).value_or(0);
  post.tag = std::to_string(post.id);
  ValueMap hintsMap = awn::getMap(model, hints::BLOCK);
  for (const auto& [key, value] : awn::getMap(hintsMap, keys::HINT_TOAST_DATA))
    post.data[key] = value.asString().value_or("");
  post.sequence = static_cast<uint32_t>(awn::getInt(hintsMap, keys::HINT_TOAST_SEQUENCE).value_or(1));
  post.update = awn::getBool(hintsMap, keys::HINT_TOAST_UPDATE).value_or(false);
  post.suppressPopup = awn::getBool(hintsMap, keys::HINT_TOAST_SUPPRESS_POPUP).value_or(false);

  // The core's toast, with its texts bound to the data; the bar under them.
  ValueMap bound = model;
  content[defs::NOTIFICATION_TITLE] = "{" + std::string(keys::BIND_TITLE) + "}";
  content[defs::NOTIFICATION_BODY] = "{" + std::string(keys::BIND_BODY) + "}";
  bound[defs::NOTIFICATION_CONTENT] = content;
  awn::ToastImages images;
  images.largeIcon = localImagePath(text(content, defs::NOTIFICATION_LARGE_ICON));
  images.bigPicture = localImagePath(text(content, defs::NOTIFICATION_BIG_PICTURE));
  post.xml = awn::ToastXml::render(bound, images, silentChannel);
  if (awn::getBool(hintsMap, keys::HINT_TOAST_PROGRESS).value_or(false)) {
    std::string bar = std::string("<progress title=\"{") + keys::BIND_PROGRESS_TITLE +
                      "}\" value=\"{" + keys::BIND_PROGRESS_VALUE +
                      "}\" valueStringOverride=\"{" + keys::BIND_PROGRESS_VALUE_STRING +
                      "}\" status=\"{" + keys::BIND_PROGRESS_STATUS + "}\"/>";
    auto close = post.xml.find("</binding>");
    if (close != std::string::npos) post.xml.insert(close, bar);
  }
  return post;
}

bool silentChannel(const std::optional<ValueMap>& channel) {
  return channel && !awn::getBool(*channel, defs::NOTIFICATION_PLAY_SOUND).value_or(true);
}

std::wstring unpackagedAumid(const std::wstring& executablePath) {
  auto fnv1a = [](const std::wstring& value) {
    uint64_t hash = 14695981039346656037ULL;
    for (wchar_t c : value) {
      hash ^= static_cast<uint64_t>(c);
      hash *= 1099511628211ULL;
    }
    return hash;
  };
  std::wstring lower = executablePath;
  for (auto& c : lower) c = static_cast<wchar_t>(std::towlower(c));
  // The file name without its extension.
  size_t slash = executablePath.find_last_of(L"\\/");
  std::wstring stem = slash == std::wstring::npos ? executablePath : executablePath.substr(slash + 1);
  size_t dot = stem.find_last_of(L'.');
  if (dot != std::wstring::npos && dot != 0) stem = stem.substr(0, dot);
  std::wstring sanitized;
  for (wchar_t c : stem) {
    if ((c >= L'a' && c <= L'z') || (c >= L'A' && c <= L'Z') || (c >= L'0' && c <= L'9') ||
        c == L'-' || c == L'_')
      sanitized += c;
  }
  if (sanitized.empty()) sanitized = L"App";
  wchar_t hash[17];
  std::swprintf(hash, 17, L"%08llx",
                static_cast<unsigned long long>(fnv1a(lower) & 0xFFFFFFFFULL));
  return L"AwesomeNotifications." + sanitized + L"." + hash;
}

std::string layoutOf(const ValueMap& model, const LiveModel& live) {
  ValueMap content = awn::NotificationBuilder::content(model);
  ValueMap layout{
      {"bar", hasBar(content, live)},
      {"buttons", awn::NotificationBuilder::actionButtons(model)},
      {"largeIcon", text(content, defs::NOTIFICATION_LARGE_ICON)},
      {"bigPicture", text(content, defs::NOTIFICATION_BIG_PICTURE)},
      {"summary", text(content, defs::NOTIFICATION_SUMMARY)},
      {"actionType", text(content, defs::NOTIFICATION_ACTION_TYPE)},
  };
  return awn::Json::encode(Value(layout));
}

ValueMap stateEvent(const std::string& activityId, Status status) {
  return ValueMap{{keys::KIND, keys::KIND_STATE},
                  {keys::ACTIVITY_ID, activityId},
                  {keys::STATE, statusName(status)}};
}

// MARK: - Host

LiveHost engineHost(awn::AwesomeNotifications& core,
                    std::function<void(int64_t ms, std::function<void()> work)> after) {
  LiveHost host;
  awn::AwesomeNotifications* engine = &core;
  host.present = [engine](const awn::BuiltNotification& built, std::function<void(bool)> done) {
    auto* presenter = engine->presenter();
    if (!presenter) {
      done(false);
      return;
    }
    presenter->present(built, std::move(done));
  };
  host.store = [engine](int64_t id, const ValueMap& model) {
    if (auto* store = engine->store()) store->put(id, model);
  };
  host.cancel = [engine](int64_t id) {
    if (engine->isConfigured()) engine->cancel(id);
  };
  host.action = [engine](const ValueMap& model, const std::string& buttonKey,
                         const std::optional<std::string>& input, const ValueMap& pressed) {
    engine->dispatchAction(model, buttonKey, input, pressed);
  };
  host.after = std::move(after);
  host.now = [] {
    return std::chrono::duration_cast<std::chrono::milliseconds>(
               std::chrono::system_clock::now().time_since_epoch())
        .count();
  };
  host.clock = &localClock;
  return host;
}

// MARK: - Controller

LiveController::LiveController(LiveHost host, Surface surface)
    : host_(std::move(host)), surface_(surface) {}

const Activity* LiveController::find(const std::string& activityId) const {
  auto it = activities_.find(activityId);
  return it == activities_.end() ? nullptr : &it->second;
}

std::map<std::string, Activity>::iterator LiveController::byNotification(int64_t id) {
  return std::find_if(activities_.begin(), activities_.end(),
                      [id](const auto& entry) { return entry.second.notificationId == id; });
}

ValueList LiveController::list() const {
  ValueList out;
  for (const auto& [activityId, activity] : activities_)
    out.push_back(ValueMap{{keys::ACTIVITY_ID, activityId},
                           {keys::STATE, statusName(activity.status)}});
  return out;
}

void LiveController::emit(const std::string& activityId, Status status) {
  if (stream_) stream_(stateEvent(activityId, status));
}

Post LiveController::postOf(const LiveModel& live, int64_t id, const std::string& layout) {
  auto it = activities_.find(live.activityId);
  bool shown = it != activities_.end() && it->second.notificationId == id;
  Post post;
  post.alerts = !shown || live.alert;
  post.update = surface_ == Surface::toast && shown && !live.alert && it->second.layout == layout;
  post.sequence = nextSequence_++;
  return post;
}

ValueMap LiveController::render(const ValueMap& model, const LiveModel& live,
                                const Post& post) const {
  return liveNotification(model, live, surface_, post, host_.clock);
}

void LiveController::deliver(const LiveModel& live, const ValueMap& source,
                             const std::string& layout, const awn::BuiltNotification& built,
                             std::function<void(bool)> done) {
  std::weak_ptr<LiveController> weak = weak_from_this();
  std::string body = text(awn::NotificationBuilder::content(source), defs::NOTIFICATION_BODY);
  host_.present(built, [weak, live, body, layout, built, done](bool shown) {
    auto self = weak.lock();
    if (shown && self) {
      std::optional<int64_t> replaced;
      bool wasEnded = false;
      auto previous = self->activities_.find(live.activityId);
      if (previous != self->activities_.end()) {
        if (previous->second.notificationId != built.id) replaced = previous->second.notificationId;
        wasEnded = previous->second.status == Status::ended;
      }
      // Another activity shown on this notification was replaced by this one.
      for (auto it = self->activities_.begin(); it != self->activities_.end();) {
        if (it->first != live.activityId && it->second.notificationId == built.id)
          it = self->activities_.erase(it);
        else
          ++it;
      }

      // The model to re-render later: the shown one (with the core's stamps)
      // with the app's own body and no hints.
      ValueMap source = built.model;
      ValueMap content = awn::NotificationBuilder::content(source);
      content[defs::NOTIFICATION_BODY] = body;
      source[defs::NOTIFICATION_CONTENT] = std::move(content);
      source.erase(hints::BLOCK);

      bool ended = live.state == State::ended;
      Activity activity;
      activity.live = live;
      activity.source = std::move(source);
      activity.model = built.model;
      activity.notificationId = built.id;
      activity.status = ended ? Status::ended : Status::active;
      activity.layout = layout;
      self->activities_[live.activityId] = std::move(activity);

      if (ended) {
        if (!wasEnded) self->emit(live.activityId, Status::ended);
        if (live.dismissal.kind == Dismissal::Kind::at)
          self->arm(live.activityId, live.dismissal.at);
      } else if (live.staleAt) {
        self->arm(live.activityId, *live.staleAt);
      }
      // The activity moved to another notification id: the old one goes (it
      // no longer matches the activity, so its removal doesn't end it).
      if (replaced) self->host_.cancel(*replaced);
    }
    done(shown);
  });
}

void LiveController::finish(const LiveModel& live, const ValueMap& model) {
  std::vector<int64_t> ids{idOf(model)};
  auto it = activities_.find(live.activityId);
  if (it != activities_.end()) {
    if (it->second.notificationId != ids.front()) ids.push_back(it->second.notificationId);
    bool wasEnded = it->second.status == Status::ended;
    activities_.erase(it);
    if (!wasEnded) emit(live.activityId, Status::ended);
    emit(live.activityId, Status::dismissed);
  }
  for (auto id : ids) host_.cancel(id);
}

void LiveController::drop(const std::string& activityId) {
  auto it = activities_.find(activityId);
  if (it == activities_.end()) return;
  int64_t id = it->second.notificationId;
  activities_.erase(it);
  host_.cancel(id);
}

void LiveController::end(const std::string& activityId, const Dismissal& dismissal) {
  auto it = activities_.find(activityId);
  if (it == activities_.end()) return;
  Activity& activity = it->second;
  bool wasEnded = activity.status == Status::ended;

  if (dismissal.kind == Dismissal::Kind::immediate) {
    drop(activityId);
    if (!wasEnded) emit(activityId, Status::ended);
    emit(activityId, Status::dismissed);
    return;
  }

  // The last content, ended: quiet, no longer resident, updated in place.
  LiveModel live = activity.live;
  live.state = State::ended;
  live.dismissal = dismissal;
  live.alert = false;
  ValueMap source = activity.source;
  ValueMap block = awn::getMap(source, keys::LIVE_ACTIVITY);
  block[keys::STATE] = "ended";
  block[keys::ALERT] = false;
  block[keys::DISMISSAL] = dismissal.kind == Dismissal::Kind::at
                               ? Value(dismissal.at)
                               : Value(keys::DISMISSAL_DEFAULT);
  source[keys::LIVE_ACTIVITY] = std::move(block);

  Post post = postOf(live, activity.notificationId, activity.layout);
  awn::BuiltNotification built;
  built.id = activity.notificationId;
  built.model = render(source, live, post);
  activity.live = live;
  activity.source = source;
  activity.model = built.model;
  activity.status = Status::ended;
  activity.timer = 0;
  if (host_.store) host_.store(built.id, built.model);
  if (host_.present) host_.present(built, [](bool) {});

  if (!wasEnded) emit(activityId, Status::ended);
  if (dismissal.kind == Dismissal::Kind::at) arm(activityId, dismissal.at);
}

void LiveController::arm(const std::string& activityId, int64_t at) {
  auto it = activities_.find(activityId);
  if (it == activities_.end() || !host_.after) return;
  uint64_t generation = nextTimer_++;
  it->second.timer = generation;
  int64_t now = host_.now ? host_.now() : 0;
  int64_t delay = std::clamp<int64_t>(at - now, 0, kMaxTimerMs);
  std::weak_ptr<LiveController> weak = weak_from_this();
  host_.after(delay, [weak, activityId, generation, at] {
    if (auto self = weak.lock()) self->onTimer(activityId, generation, at);
  });
}

void LiveController::onTimer(const std::string& activityId, uint64_t generation, int64_t at) {
  auto it = activities_.find(activityId);
  if (it == activities_.end() || it->second.timer != generation) return;
  int64_t now = host_.now ? host_.now() : at;
  if (now < at) {
    // A deadline beyond the longest timer: wait again.
    std::weak_ptr<LiveController> weak = weak_from_this();
    host_.after(std::min<int64_t>(at - now, kMaxTimerMs),
                [weak, activityId, generation, at] {
                  if (auto self = weak.lock()) self->onTimer(activityId, generation, at);
                });
    return;
  }
  // Out of date (no update came by staleAt: the desktop's timeout), or the
  // end of an ended activity's dismissal: the notification goes, as on the web.
  drop(activityId);
  emit(activityId, Status::dismissed);
}

void LiveController::onRemoved(const std::vector<int64_t>& ids) {
  for (auto id : ids) {
    for (auto it = byNotification(id); it != activities_.end(); it = byNotification(id)) {
      std::string activityId = it->first;
      bool wasEnded = it->second.status == Status::ended;
      activities_.erase(it);
      if (!wasEnded) emit(activityId, Status::ended);
      emit(activityId, Status::dismissed);
    }
  }
}

void LiveController::onDismissed(int64_t id) {
  auto it = byNotification(id);
  if (it == activities_.end()) return;
  std::string activityId = it->first;
  activities_.erase(it);
  emit(activityId, Status::dismissed);
}

std::optional<awn::ActionType> LiveController::onActivated(
    const ValueMap& model, const std::string& buttonKey, const std::optional<std::string>& input) {
  int64_t id = idOf(model);
  auto it = byNotification(id);
  if (it == activities_.end() || !field(model, keys::LIVE_ACTIVITY)) return std::nullopt;
  std::string activityId = it->first;
  bool ended = it->second.status == Status::ended;

  if (buttonKey.empty()) {
    ValueMap content = awn::NotificationBuilder::content(model);
    awn::ActionType type = awn::actionTypeFrom(text(content, defs::NOTIFICATION_ACTION_TYPE));
    // A dismiss action reaches onDismissed through the core's event.
    if (type == awn::ActionType::DismissAction) return std::nullopt;
    if (ended) {
      // An ended activity leaves with the tap, as any notification.
      activities_.erase(it);
      emit(activityId, Status::dismissed);
      return std::nullopt;
    }
    // A live one stays: the app opens, the activity goes on.
    if (host_.action)
      host_.action(model, "", std::nullopt,
                   ValueMap{{defs::NOTIFICATION_ACTION_TYPE, awn::toWire(type)}});
    return type;
  }

  // The activity's buttons are emitted here, so its stored model stays for
  // the next press (the core forgets a model after an action).
  auto button = awn::NotificationBuilder::findButton(model, buttonKey);
  if (!button) return std::nullopt;
  awn::ActionType type = awn::NotificationBuilder::buttonActionType(button);
  if (type == awn::ActionType::DismissAction) return std::nullopt;
  if (host_.action) host_.action(model, buttonKey, input, *button);
  if (awn::NotificationBuilder::shouldButtonAutoDismiss(button)) {
    // The notification goes after the action: the activity ends.
    drop(activityId);
    if (!ended) emit(activityId, Status::ended);
    emit(activityId, Status::dismissed);
  }
  return type;
}

// MARK: - Builder

LiveBuilder::LiveBuilder(std::shared_ptr<awn::NotificationBuilder> inner,
                         std::shared_ptr<LiveController> controller)
    : awn::NotificationBuilder(std::move(inner)), controller_(std::move(controller)) {}

std::optional<awn::BuiltNotification> LiveBuilder::build(const ValueMap& model) {
  const Value* block = field(model, keys::LIVE_ACTIVITY);
  if (!block) return next(model);

  // An activity starts now (or by push), never later.
  if (field(model, defs::NOTIFICATION_SCHEDULE))
    invalid("A live activity can't be scheduled", ".schedule");

  std::string error;
  auto live = LiveModel::parse(*block, idOf(model), &error);
  if (!live) invalid(error, "");

  auto controller = controller_;
  LiveModel parsed = *live;
  if (live->state == State::ended && live->dismissal.kind == Dismissal::Kind::immediate) {
    // Nothing to show: the activity and its notification go.
    auto built = next(model);
    if (!built) return built;
    built->deliver = [controller, parsed](const awn::BuiltNotification& final,
                                          std::function<void(bool)> done) {
      controller->finish(parsed, final.model);
      done(true);
    };
    return built;
  }

  std::string layout = layoutOf(model, *live);
  Post post = controller_->postOf(*live, idOf(model), layout);
  auto built = next(controller_->render(model, *live, post));
  if (!built) return built;
  built->deliver = [controller, parsed, model, layout](const awn::BuiltNotification& final,
                                                       std::function<void(bool)> done) {
    controller->deliver(parsed, model, layout, final, std::move(done));
  };
  return built;
}

// MARK: - Channel

LiveMethodHandler::LiveMethodHandler(std::shared_ptr<LiveController> controller,
                                     ValueMap capabilities)
    : controller_(std::move(controller)), capabilities_(std::move(capabilities)) {}

bool LiveMethodHandler::handle(const std::string& method, const Value& arguments,
                               awn::MethodResult result) {
  if (method == keys::METHOD_END) {
    std::optional<std::string> activityId;
    Dismissal dismissal;
    if (arguments.isMap()) {
      const ValueMap& map = arguments.map();
      activityId = awn::getString(map, keys::ACTIVITY_ID);
      auto value = map.find(keys::DISMISSAL);
      if (value != map.end())
        dismissal = Dismissal::from(value->second).value_or(Dismissal{});
    } else {
      activityId = arguments.asString();
    }
    if (activityId) controller_->end(*activityId, dismissal);
    result(Value());
    return true;
  }
  if (method == keys::METHOD_LIST) {
    result(Value(controller_->list()));
    return true;
  }
  if (method == keys::METHOD_CAPABILITIES) {
    result(Value(capabilities_));
    return true;
  }
  if (method == keys::METHOD_ARE_ENABLED || method == keys::METHOD_REQUEST_PERMISSION) {
    result(Value(true));  // no per-app switch on the desktop
    return true;
  }
  if (method == keys::METHOD_PUSH_TO_START_TOKEN || method == keys::METHOD_PUSH_TOKEN) {
    result(Value());  // ActivityKit pushes are iOS only
    return true;
  }
  return false;
}

ValueMap desktopCapabilities() {
  return ValueMap{{keys::CAP_SYSTEM_SURFACE, false},
                  {keys::CAP_PROGRESS_SEGMENTS, false},
                  {keys::CAP_METRICS, false},
                  {keys::CAP_BUTTONS, true},
                  {keys::CAP_PUSH, false}};
}

void RegisterLiveActivities(std::shared_ptr<LiveController> controller, ValueMap capabilities,
                            awn::AwesomeNotifications& core) {
  awn::NotificationBuilderRegistry::shared().registerDecorator(
      kLivePriority, [controller](std::shared_ptr<awn::NotificationBuilder> inner) {
        return std::make_shared<LiveBuilder>(std::move(inner), controller);
      });
  awn::AwesomeMethodHandlerRegistry::shared().registerHandler(
      std::make_shared<LiveMethodHandler>(controller, std::move(capabilities)));
  std::weak_ptr<LiveController> weak = controller;
  core.addRemovalObserver([weak](const std::vector<int64_t>& ids) {
    if (auto alive = weak.lock()) alive->onRemoved(ids);
  });
  core.addActivationInterceptor(
      [weak](const ValueMap& model, const std::string& buttonKey,
             const awn::Activation& activation) -> std::optional<awn::ActionType> {
        auto alive = weak.lock();
        if (!alive) return std::nullopt;
        std::optional<std::string> input;
        auto typed = activation.userInputs.find(buttonKey);
        if (typed != activation.userInputs.end()) input = typed->second;
        return alive->onActivated(model, buttonKey, input);
      });
  // The user dismissed it (or a DismissAction): the core's event says which.
  awn::AwesomeEventsReceiver::shared().subscribe(
      [weak](const std::string& event, const ValueMap& content) {
        if (event != defs::EVENT_NOTIFICATION_DISMISSED) return;
        auto alive = weak.lock();
        auto id = awn::NotificationBuilder::readId(content);
        if (alive && id) alive->onDismissed(*id);
      });
}

}  // namespace awn_live
