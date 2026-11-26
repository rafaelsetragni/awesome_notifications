#pragma once

#include <windows.h>

#include <functional>
#include <map>
#include <memory>
#include <mutex>
#include <optional>
#include <vector>

#include <winrt/Windows.UI.Notifications.h>

#include "app_identity.h"
#include "awn/platform.h"
#include "awn/toast_xml.h"
#include "image_resolver.h"
#include "win_dispatcher.h"

namespace awesome_notifications {

/// `awn::NotificationPresenter` over WinRT toasts (Windows.UI.Notifications),
/// without the Windows App SDK. Toasts carry the notification id as their Tag;
/// scheduled ones go through ScheduledToastNotification.
class ToastPresenter : public awn::NotificationPresenter,
                       public std::enable_shared_from_this<ToastPresenter> {
 public:
  struct Callbacks {
    /// The user dismissed a toast (platform thread).
    std::function<void(int64_t)> onDismissed;
    /// A scheduled toast fired while the app was running (platform thread).
    std::function<void(int64_t)> onDisplayed;
    /// A packaged app has no COM activator: activations arrive as toast events.
    std::function<void(const awn::Activation&)> onActivated;
    /// Whether the model's channel plays no sound.
    std::function<bool(const awn::ValueMap&)> isSilent;
  };

  ToastPresenter(AppIdentity identity, std::shared_ptr<WinDispatcher> dispatcher,
                 Callbacks callbacks);

  /// Re-arms the "displayed" timers of toasts scheduled by a previous process.
  void ArmPendingTimers();

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
  int64_t utcOffset(const std::string& zone, awn::TimePoint utc) override;
  std::string systemLanguage() override;
  std::filesystem::path dataDirectory() override { return identity_.dataDirectory; }

 private:
  bool Show(const awn::BuiltNotification& built, const awn::ToastImages& images, bool silent);
  void Track(int64_t id, const winrt::Windows::UI::Notifications::ToastNotification& toast);
  void ArmDisplayedTimer(int64_t id, awn::TimePoint fireDate);
  void CancelDisplayedTimer(int64_t id);
  /// The earliest delivery still scheduled for `id` after `after`.
  std::optional<awn::TimePoint> NextScheduledDate(int64_t id, awn::TimePoint after);
  winrt::Windows::UI::Notifications::ToastNotifier Notifier();
  winrt::Windows::UI::Notifications::ToastNotificationHistory History();

  AppIdentity identity_;
  std::shared_ptr<WinDispatcher> dispatcher_;
  Callbacks callbacks_;
  ImageResolver images_;
  winrt::Windows::UI::Notifications::ToastNotifier notifier_{nullptr};

  // Shown toasts are kept alive so their Dismissed events keep arriving.
  std::mutex mutex_;
  std::map<int64_t, winrt::Windows::UI::Notifications::ToastNotification> shown_;
  std::map<int64_t, UINT_PTR> displayedTimers_;
};

}  // namespace awesome_notifications
