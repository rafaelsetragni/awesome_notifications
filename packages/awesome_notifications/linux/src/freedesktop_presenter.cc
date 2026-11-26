#include "freedesktop_presenter.h"

#include <unistd.h>

#include <algorithm>
#include <fstream>
#include <sstream>
#include <system_error>
#include <thread>

#include "awn/date_utils.h"
#include "awn/definitions.h"
#include "awn/json.h"
#include "awn/notification_builder.h"
#include "linux_platform.h"

namespace awesome_notifications {

namespace {

constexpr const char* kBusName = "org.freedesktop.Notifications";
constexpr const char* kObjectPath = "/org/freedesktop/Notifications";
constexpr const char* kInterface = "org.freedesktop.Notifications";

/// The spec's close reasons.
constexpr guint32 kClosedByUser = 2;

/// The timer never sleeps longer than this, so a suspend or a clock change
/// can't delay a schedule by more than it.
constexpr auto kMaxTimerSleep = std::chrono::seconds(30);

/// Keeps the presenter alive-check and the completion of an async D-Bus call.
struct CallContext {
  std::weak_ptr<FreedesktopPresenter> presenter;
  int64_t id = 0;
  std::function<void(bool)> done;
  std::string inlineReply;
};

}  // namespace

FreedesktopPresenter::FreedesktopPresenter(std::filesystem::path dataDirectory, std::string appId,
                                           std::shared_ptr<GlibDispatcher> dispatcher,
                                           Callbacks callbacks)
    : dataDirectory_(std::move(dataDirectory)),
      appId_(std::move(appId)),
      dispatcher_(std::move(dispatcher)),
      callbacks_(std::move(callbacks)),
      images_(dataDirectory_ / "images") {
  std::error_code ec;
  std::filesystem::create_directories(dataDirectory_, ec);
  LoadPending();
}

FreedesktopPresenter::~FreedesktopPresenter() {
  if (timer_ != 0) dispatcher_->CancelDelayed(timer_);
  if (bus_ != nullptr) {
    if (signalSubscription_ != 0) g_dbus_connection_signal_unsubscribe(bus_, signalSubscription_);
    g_object_unref(bus_);
  }
}

void FreedesktopPresenter::Start() {
  Connect();
  OnTimer();
}

bool FreedesktopPresenter::Connect() {
  if (bus_ == nullptr) {
    GError* error = nullptr;
    bus_ = g_bus_get_sync(G_BUS_TYPE_SESSION, nullptr, &error);
    if (bus_ == nullptr) {
      g_clear_error(&error);
      return false;
    }
    signalSubscription_ = g_dbus_connection_signal_subscribe(
        bus_, kBusName, kInterface, nullptr, kObjectPath, nullptr, G_DBUS_SIGNAL_FLAGS_NONE,
        &FreedesktopPresenter::SignalThunk, this, nullptr);
  }
  if (serverReachable_) return true;

  // Also starts a D-Bus-activated server that is not running yet.
  GError* error = nullptr;
  GVariant* reply = g_dbus_connection_call_sync(
      bus_, kBusName, kObjectPath, kInterface, "GetCapabilities", nullptr,
      G_VARIANT_TYPE("(as)"), G_DBUS_CALL_FLAGS_NONE, 5000, nullptr, &error);
  if (reply == nullptr) {
    g_clear_error(&error);
    return false;
  }
  GVariantIter* iter = nullptr;
  const gchar* capability = nullptr;
  g_variant_get(reply, "(as)", &iter);
  while (g_variant_iter_loop(iter, "&s", &capability)) capabilities_.insert(capability);
  g_variant_iter_free(iter);
  g_variant_unref(reply);
  serverReachable_ = true;
  return true;
}

// MARK: - Present

void FreedesktopPresenter::present(const awn::BuiltNotification& built,
                                   std::function<void(bool)> done) {
  // Replace whatever this id scheduled before.
  removePending({built.id});

  auto now = awn::DateUtils::now();
  if (built.fireDate && *built.fireDate > now) {
    Pending pending;
    pending.model = built.model;
    pending.dates.push_back(*built.fireDate);
    for (const auto& date : built.repeatDates)
      if (date > now) pending.dates.push_back(date);
    std::sort(pending.dates.begin(), pending.dates.end());
    pending.dates.erase(std::unique(pending.dates.begin(), pending.dates.end()),
                        pending.dates.end());
    pending_[built.id] = std::move(pending);
    SavePending();
    ArmTimer();
    done(true);
    return;
  }
  Show(built.id, built.model, std::move(done));
}

void FreedesktopPresenter::Show(int64_t id, const awn::ValueMap& model,
                                std::function<void(bool)> done) {
  if (!Connect()) {
    done(false);
    return;
  }
  awn::ValueMap content = awn::NotificationBuilder::content(model);
  std::string largeIcon = awn::getString(content, awn::defs::NOTIFICATION_LARGE_ICON).value_or("");
  std::string bigPicture =
      awn::getString(content, awn::defs::NOTIFICATION_BIG_PICTURE).value_or("");
  bool silent = callbacks_.isSilent ? callbacks_.isSilent(model) : false;
  std::string importance = callbacks_.importance ? callbacks_.importance(model) : "Default";

  // Resolve (download) the images off the platform thread, then notify on it.
  std::weak_ptr<FreedesktopPresenter> weak = weak_from_this();
  std::thread([weak, id, model, largeIcon, bigPicture, silent, importance, done]() {
    awn::FreedesktopImages images;
    std::shared_ptr<GlibDispatcher> dispatcher;
    if (auto self = weak.lock()) {
      images.largeIcon = self->images_.Resolve(largeIcon);
      images.bigPicture = self->images_.Resolve(bigPicture);
      dispatcher = self->dispatcher_;
    }
    if (!dispatcher) return;
    dispatcher->post([weak, id, model, images, silent, importance, done]() {
      auto self = weak.lock();
      if (!self) return;
      self->Notify(id,
                   awn::Freedesktop::render(model, images, silent, importance,
                                            self->capabilities_),
                   done);
    });
  }).detach();
}

void FreedesktopPresenter::Notify(int64_t id, const awn::FreedesktopNotification& n,
                                  std::function<void(bool)> done) {
  GVariantBuilder actions;
  g_variant_builder_init(&actions, G_VARIANT_TYPE("as"));
  for (const auto& [key, label] : n.actions) {
    g_variant_builder_add(&actions, "s", key.c_str());
    g_variant_builder_add(&actions, "s", label.c_str());
  }

  GVariantBuilder hints;
  g_variant_builder_init(&hints, G_VARIANT_TYPE("a{sv}"));
  g_variant_builder_add(&hints, "{sv}", "urgency",
                        g_variant_new_byte(static_cast<guchar>(n.urgency)));
  g_variant_builder_add(&hints, "{sv}", "desktop-entry", g_variant_new_string(appId_.c_str()));
  g_variant_builder_add(&hints, "{sv}", "sender-pid",
                        g_variant_new_int64(static_cast<gint64>(getpid())));
  if (!n.imagePath.empty())
    g_variant_builder_add(&hints, "{sv}", "image-path", g_variant_new_string(n.imagePath.c_str()));
  if (!n.category.empty())
    g_variant_builder_add(&hints, "{sv}", "category", g_variant_new_string(n.category.c_str()));
  if (n.suppressSound)
    g_variant_builder_add(&hints, "{sv}", "suppress-sound", g_variant_new_boolean(TRUE));
  if (n.resident) g_variant_builder_add(&hints, "{sv}", "resident", g_variant_new_boolean(TRUE));
  if (!n.inlineReplyAction.empty())
    g_variant_builder_add(&hints, "{sv}", "x-kde-reply-placeholder-text",
                          g_variant_new_string(n.inlineReplyPlaceholder.c_str()));

  auto replaces = serverIds_.find(id);
  guint32 replacesId = replaces == serverIds_.end() ? 0 : replaces->second;

  auto* context = new CallContext{weak_from_this(), id, std::move(done), n.inlineReplyAction};
  g_dbus_connection_call(
      bus_, kBusName, kObjectPath, kInterface, "Notify",
      g_variant_new("(susssasa{sv}i)", appId_.c_str(), replacesId, n.appIcon.c_str(),
                    n.summary.c_str(), n.body.c_str(), &actions, &hints, -1),
      G_VARIANT_TYPE("(u)"), G_DBUS_CALL_FLAGS_NONE, -1, nullptr,
      [](GObject* source, GAsyncResult* result, gpointer data) {
        std::unique_ptr<CallContext> context(static_cast<CallContext*>(data));
        GError* error = nullptr;
        GVariant* reply =
            g_dbus_connection_call_finish(G_DBUS_CONNECTION(source), result, &error);
        auto self = context->presenter.lock();
        if (reply == nullptr || !self) {
          g_clear_error(&error);
          if (reply) g_variant_unref(reply);
          if (context->done) context->done(false);
          return;
        }
        guint32 serverId = 0;
        g_variant_get(reply, "(u)", &serverId);
        g_variant_unref(reply);

        // A replaced notification keeps its server id; a new one may not.
        auto previous = self->serverIds_.find(context->id);
        if (previous != self->serverIds_.end() && previous->second != serverId)
          self->Forget(previous->second);
        self->serverIds_[context->id] = serverId;
        self->awnIds_[serverId] = context->id;
        if (context->inlineReply.empty())
          self->inlineReplies_.erase(serverId);
        else
          self->inlineReplies_[serverId] = context->inlineReply;
        if (context->done) context->done(true);
      },
      context);
}

// MARK: - Server signals

void FreedesktopPresenter::SignalThunk(GDBusConnection*, const gchar*, const gchar*,
                                       const gchar*, const gchar* signal, GVariant* parameters,
                                       gpointer self) {
  static_cast<FreedesktopPresenter*>(self)->OnSignal(signal, parameters);
}

void FreedesktopPresenter::OnSignal(const gchar* signal, GVariant* parameters) {
  std::string name = signal;
  if (name == "ActionInvoked" && g_variant_is_of_type(parameters, G_VARIANT_TYPE("(us)"))) {
    guint32 serverId = 0;
    const gchar* key = nullptr;
    g_variant_get(parameters, "(u&s)", &serverId, &key);
    auto it = awnIds_.find(serverId);
    if (it == awnIds_.end()) return;  // another app's notification
    std::string action = key;
    // The typed text arrives with NotificationReplied.
    if (action == awn::Freedesktop::kInlineReplyAction) return;
    notDismissals_.insert(serverId);
    awn::Activation activation;
    activation.arguments =
        action == awn::Freedesktop::kDefaultAction ? awn::LaunchArgs::encode(it->second) : action;
    if (callbacks_.onActivated) callbacks_.onActivated(activation);
  } else if (name == "NotificationReplied" &&
             g_variant_is_of_type(parameters, G_VARIANT_TYPE("(us)"))) {
    guint32 serverId = 0;
    const gchar* text = nullptr;
    g_variant_get(parameters, "(u&s)", &serverId, &text);
    auto reply = inlineReplies_.find(serverId);
    if (reply == inlineReplies_.end()) return;
    notDismissals_.insert(serverId);
    awn::Activation activation;
    activation.arguments = reply->second;
    if (auto args = awn::LaunchArgs::decode(reply->second))
      activation.userInputs[args->buttonKey] = text;
    if (callbacks_.onActivated) callbacks_.onActivated(activation);
  } else if (name == "NotificationClosed" &&
             g_variant_is_of_type(parameters, G_VARIANT_TYPE("(uu)"))) {
    guint32 serverId = 0;
    guint32 reason = 0;
    g_variant_get(parameters, "(uu)", &serverId, &reason);
    auto it = awnIds_.find(serverId);
    if (it == awnIds_.end()) return;
    int64_t id = it->second;
    bool dismissal = reason == kClosedByUser && notDismissals_.count(serverId) == 0;
    Forget(serverId);
    if (serverIds_.count(id) && serverIds_[id] == serverId) serverIds_.erase(id);
    if (dismissal && callbacks_.onDismissed) callbacks_.onDismissed(id);
  }
}

void FreedesktopPresenter::Forget(uint32_t serverId) {
  awnIds_.erase(serverId);
  notDismissals_.erase(serverId);
  inlineReplies_.erase(serverId);
}

void FreedesktopPresenter::Close(uint32_t serverId) {
  if (bus_ == nullptr) return;
  notDismissals_.insert(serverId);
  g_dbus_connection_call(bus_, kBusName, kObjectPath, kInterface, "CloseNotification",
                         g_variant_new("(u)", serverId), nullptr, G_DBUS_CALL_FLAGS_NONE, -1,
                         nullptr, nullptr, nullptr);
}

// MARK: - Remove / query

void FreedesktopPresenter::removeDelivered(const std::vector<int64_t>& ids) {
  for (auto id : ids) {
    auto it = serverIds_.find(id);
    if (it == serverIds_.end()) continue;
    Close(it->second);
    serverIds_.erase(it);
  }
}

void FreedesktopPresenter::removeAllDelivered() {
  for (const auto& [id, serverId] : serverIds_) Close(serverId);
  serverIds_.clear();
}

void FreedesktopPresenter::removePending(const std::vector<int64_t>& ids) {
  bool changed = false;
  for (auto id : ids) changed |= pending_.erase(id) > 0;
  if (!changed) return;
  SavePending();
  ArmTimer();
}

void FreedesktopPresenter::removeAllPending() {
  if (pending_.empty()) return;
  pending_.clear();
  SavePending();
  ArmTimer();
}

std::vector<int64_t> FreedesktopPresenter::deliveredIds() {
  std::vector<int64_t> ids;
  for (const auto& [id, serverId] : serverIds_) ids.push_back(id);
  return ids;
}

std::vector<int64_t> FreedesktopPresenter::pendingIds() {
  // One entry per armed occurrence, as the schedules top-up counts them.
  std::vector<int64_t> ids;
  for (const auto& [id, pending] : pending_) ids.insert(ids.end(), pending.dates.size(), id);
  return ids;
}

// MARK: - Schedules (this presenter's own timer)

void FreedesktopPresenter::ArmTimer() {
  if (timer_ != 0) {
    dispatcher_->CancelDelayed(timer_);
    timer_ = 0;
  }
  std::optional<awn::TimePoint> earliest;
  for (const auto& [id, pending] : pending_) {
    if (!pending.dates.empty() && (!earliest || pending.dates.front() < *earliest))
      earliest = pending.dates.front();
  }
  if (!earliest) return;
  auto wait = std::chrono::duration_cast<std::chrono::milliseconds>(*earliest -
                                                                    awn::DateUtils::now());
  wait = std::clamp(wait, std::chrono::milliseconds(0),
                    std::chrono::duration_cast<std::chrono::milliseconds>(kMaxTimerSleep));
  std::weak_ptr<FreedesktopPresenter> weak = weak_from_this();
  timer_ = dispatcher_->PostDelayed(wait, [weak]() {
    if (auto self = weak.lock()) {
      self->timer_ = 0;
      self->OnTimer();
    }
  });
}

void FreedesktopPresenter::OnTimer() {
  auto now = awn::DateUtils::now();
  std::vector<std::pair<int64_t, awn::ValueMap>> due;
  for (auto it = pending_.begin(); it != pending_.end();) {
    auto& dates = it->second.dates;
    auto firstFuture = std::upper_bound(dates.begin(), dates.end(), now);
    if (firstFuture != dates.begin()) {
      // Occurrences missed together (the app was closed) replace each other on
      // screen anyway: show the latest once.
      due.emplace_back(it->first, it->second.model);
      dates.erase(dates.begin(), firstFuture);
    }
    it = dates.empty() ? pending_.erase(it) : std::next(it);
  }
  if (!due.empty()) SavePending();
  ArmTimer();

  std::weak_ptr<FreedesktopPresenter> weak = weak_from_this();
  for (const auto& [id, model] : due) {
    int64_t shownId = id;
    Show(id, model, [weak, shownId](bool shown) {
      auto self = weak.lock();
      if (shown && self && self->callbacks_.onDisplayed) self->callbacks_.onDisplayed(shownId);
    });
  }
}

void FreedesktopPresenter::LoadPending() {
  std::ifstream file(dataDirectory_ / "schedules.json");
  if (!file) return;
  std::stringstream text;
  text << file.rdbuf();
  auto decoded = awn::Json::decode(text.str());
  if (!decoded) return;
  for (const auto& [key, entry] : decoded->map()) {
    auto id = awn::Value(key).asInt();
    if (!id) continue;
    Pending pending;
    pending.model = awn::getMap(entry.map(), "model");
    for (const auto& date : awn::getList(entry.map(), "dates")) {
      if (auto text = date.asString())
        if (auto parsed = awn::DateUtils::parseUtc(*text)) pending.dates.push_back(*parsed);
    }
    std::sort(pending.dates.begin(), pending.dates.end());
    if (!pending.dates.empty()) pending_[*id] = std::move(pending);
  }
}

void FreedesktopPresenter::SavePending() const {
  awn::ValueMap root;
  for (const auto& [id, pending] : pending_) {
    awn::ValueList dates;
    for (const auto& date : pending.dates) dates.push_back(awn::DateUtils::formatUtc(date));
    root[std::to_string(id)] = awn::ValueMap{{"dates", dates}, {"model", pending.model}};
  }
  std::error_code ec;
  std::filesystem::create_directories(dataDirectory_, ec);
  auto target = dataDirectory_ / "schedules.json";
  auto partial = target;
  partial += ".part";
  {
    std::ofstream file(partial, std::ios::trunc);
    if (!file) return;
    file << awn::Json::encode(awn::Value(root));
  }
  std::filesystem::rename(partial, target, ec);
}

// MARK: - Permission / platform

bool FreedesktopPresenter::isAllowed() {
  // Linux has no per-app notification permission an app can read: allowed is
  // having a notification server to talk to.
  return Connect();
}

void FreedesktopPresenter::requestPermission(std::function<void(bool)> done) {
  done(isAllowed());
}

std::string FreedesktopPresenter::localTimeZone() {
  static const std::string zone = linux_platform::LocalTimeZone();
  return zone;
}

bool FreedesktopPresenter::isKnownTimeZone(const std::string& zone) {
  return linux_platform::IsKnownTimeZone(zone);
}

int64_t FreedesktopPresenter::utcOffset(const std::string& zone, awn::TimePoint utc) {
  return linux_platform::UtcOffset(zone, utc);
}

std::string FreedesktopPresenter::systemLanguage() { return linux_platform::SystemLanguage(); }

}  // namespace awesome_notifications
