#pragma once

#include <gio/gio.h>

#include <filesystem>
#include <functional>
#include <map>
#include <memory>
#include <set>
#include <string>
#include <vector>

#include "awn/freedesktop.h"
#include "awn/platform.h"
#include "glib_dispatcher.h"
#include "image_resolver.h"

namespace awesome_notifications {

/// `awn::NotificationPresenter` over the Desktop Notifications Specification
/// (org.freedesktop.Notifications on the session bus): GNOME, KDE, XFCE,
/// dunst, mako, …
///
/// Linux has no system scheduler for notifications, so scheduled ones are kept
/// by this presenter (persisted next to the store) and shown by its own timer
/// while the app runs. Occurrences that came due while the app was closed are
/// shown as soon as it starts again (the latest one per id).
class FreedesktopPresenter : public awn::NotificationPresenter,
                             public std::enable_shared_from_this<FreedesktopPresenter> {
 public:
  struct Callbacks {
    /// The user dismissed a notification (platform thread).
    std::function<void(int64_t)> onDismissed;
    /// A scheduled notification was shown (platform thread).
    std::function<void(int64_t)> onDisplayed;
    /// A notification, or one of its buttons, was activated (platform thread).
    std::function<void(const awn::Activation&)> onActivated;
    /// Whether the model's channel plays no sound.
    std::function<bool(const awn::ValueMap&)> isSilent;
    /// The model's channel importance (None/Min/Low/Default/High/Max).
    std::function<std::string(const awn::ValueMap&)> importance;
  };

  FreedesktopPresenter(std::filesystem::path dataDirectory, std::string appId,
                       std::shared_ptr<GlibDispatcher> dispatcher, Callbacks callbacks);
  ~FreedesktopPresenter() override;

  /// Connects to the notification server, then shows the occurrences that
  /// came due while the app was closed and arms the timer for the next ones.
  void Start();

  // awn::NotificationPresenter
  void present(const awn::BuiltNotification& built, std::function<void(bool)> done) override;
  void removeDelivered(const std::vector<int64_t>& ids) override;
  void removeAllDelivered() override;
  void removePending(const std::vector<int64_t>& ids) override;
  void removeAllPending() override;
  std::vector<int64_t> deliveredIds() override;
  std::vector<int64_t> pendingIds() override;
  bool isAllowed() override;
  void requestPermission(std::function<void(bool)> done) override;
  std::string localTimeZone() override;
  bool isKnownTimeZone(const std::string& zone) override;
  int64_t utcOffset(const std::string& zone, awn::TimePoint utc) override;
  std::string systemLanguage() override;
  std::filesystem::path dataDirectory() override { return dataDirectory_; }

 private:
  struct Pending {
    std::vector<awn::TimePoint> dates;  // ascending
    awn::ValueMap model;
  };

  bool Connect();
  void Show(int64_t id, const awn::ValueMap& model, std::function<void(bool)> done);
  void Notify(int64_t id, const awn::FreedesktopNotification& notification,
              std::function<void(bool)> done);
  void Close(uint32_t serverId);
  void Forget(uint32_t serverId);

  void OnSignal(const gchar* signal, GVariant* parameters);
  static void SignalThunk(GDBusConnection*, const gchar*, const gchar*, const gchar*,
                          const gchar* signal, GVariant* parameters, gpointer self);

  void ArmTimer();
  void OnTimer();
  void LoadPending();
  void SavePending() const;

  std::filesystem::path dataDirectory_;
  std::string appId_;
  std::shared_ptr<GlibDispatcher> dispatcher_;
  Callbacks callbacks_;
  ImageResolver images_;

  GDBusConnection* bus_ = nullptr;
  guint signalSubscription_ = 0;
  bool serverReachable_ = false;
  std::set<std::string> capabilities_;

  // Shown notifications: awn id <-> the server's id.
  std::map<int64_t, uint32_t> serverIds_;
  std::map<uint32_t, int64_t> awnIds_;
  /// Server ids whose close is ours (or follows an action): not a dismissal.
  std::set<uint32_t> notDismissals_;
  /// Server id -> the LaunchArgs of the button typed in place.
  std::map<uint32_t, std::string> inlineReplies_;

  std::map<int64_t, Pending> pending_;
  guint timer_ = 0;
};

}  // namespace awesome_notifications
