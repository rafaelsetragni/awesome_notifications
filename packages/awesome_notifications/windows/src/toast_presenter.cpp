#include "toast_presenter.h"

#include <shellapi.h>

#include <algorithm>
#include <cctype>
#include <thread>

#include <winrt/Windows.Data.Xml.Dom.h>
#include <winrt/Windows.Foundation.Collections.h>
#include <winrt/Windows.Foundation.h>

#include "awn/definitions.h"
#include "awn/notification_builder.h"
#include "icu_time_zone.h"
#include "win_utils.h"

namespace awesome_notifications {

using winrt::Windows::Data::Xml::Dom::XmlDocument;
using winrt::Windows::UI::Notifications::NotificationSetting;
using winrt::Windows::UI::Notifications::ScheduledToastNotification;
using winrt::Windows::UI::Notifications::ToastActivatedEventArgs;
using winrt::Windows::UI::Notifications::ToastDismissalReason;
using winrt::Windows::UI::Notifications::ToastDismissedEventArgs;
using winrt::Windows::UI::Notifications::ToastNotification;
using winrt::Windows::UI::Notifications::ToastNotificationHistory;
using winrt::Windows::UI::Notifications::ToastNotificationManager;
using winrt::Windows::UI::Notifications::ToastNotifier;

namespace {

/// Every toast of the plugin shares one history group; the Tag is the id.
const wchar_t kGroup[] = L"awn";

std::optional<int64_t> IdFromTag(const winrt::hstring& tag) {
  return awn::Value(winrt::to_string(tag)).asInt();
}

winrt::hstring TagOf(int64_t id) { return winrt::to_hstring(id); }

}  // namespace

ToastPresenter::ToastPresenter(AppIdentity identity, std::shared_ptr<WinDispatcher> dispatcher,
                               Callbacks callbacks)
    : identity_(std::move(identity)),
      dispatcher_(std::move(dispatcher)),
      callbacks_(std::move(callbacks)),
      images_(identity_.dataDirectory / L"images") {}

ToastNotifier ToastPresenter::Notifier() {
  if (!notifier_) {
    notifier_ = identity_.aumid.empty()
                    ? ToastNotificationManager::CreateToastNotifier()
                    : ToastNotificationManager::CreateToastNotifier(identity_.aumid);
  }
  return notifier_;
}

ToastNotificationHistory ToastPresenter::History() { return ToastNotificationManager::History(); }

// MARK: - Present

void ToastPresenter::present(const awn::BuiltNotification& built, std::function<void(bool)> done) {
  bool silent = callbacks_.isSilent ? callbacks_.isSilent(built.model) : false;
  awn::ValueMap content = awn::NotificationBuilder::content(built.model);
  std::string largeIcon = awn::getString(content, awn::defs::NOTIFICATION_LARGE_ICON).value_or("");
  std::string bigPicture =
      awn::getString(content, awn::defs::NOTIFICATION_BIG_PICTURE).value_or("");

  // Resolve (download) the images off the platform thread, then show on it.
  std::weak_ptr<ToastPresenter> weak = weak_from_this();
  std::thread([weak, built, largeIcon, bigPicture, silent, done]() {
    HRESULT com = ::CoInitializeEx(nullptr, COINIT_MULTITHREADED);
    awn::ToastImages images;
    if (auto self = weak.lock()) {
      images.largeIcon = WideToUtf8(self->images_.Resolve(largeIcon));
      images.bigPicture = WideToUtf8(self->images_.Resolve(bigPicture));
    }
    if (SUCCEEDED(com)) ::CoUninitialize();

    auto self = weak.lock();
    if (!self) return;
    self->dispatcher_->post([weak, built, images, silent, done]() {
      auto presenter = weak.lock();
      done(presenter && presenter->Show(built, images, silent));
    });
  }).detach();
}

bool ToastPresenter::Show(const awn::BuiltNotification& built, const awn::ToastImages& images,
                          bool silent) {
  try {
    XmlDocument document;
    document.LoadXml(winrt::to_hstring(awn::ToastXml::render(built.model, images, silent)));

    // Replace whatever this id showed or scheduled before.
    removePending({built.id});

    auto now = awn::DateUtils::now();
    if (built.fireDate && *built.fireDate > now) {
      // Every occurrence (a repeating schedule is pre-armed) shares the id tag,
      // so they replace each other on screen and cancel together.
      std::vector<awn::TimePoint> dates{*built.fireDate};
      dates.insert(dates.end(), built.repeatDates.begin(), built.repeatDates.end());
      auto notifier = Notifier();
      for (const auto& date : dates) {
        if (date <= now) continue;
        ScheduledToastNotification scheduled(document, winrt::clock::from_sys(date));
        scheduled.Tag(TagOf(built.id));
        scheduled.Group(kGroup);
        notifier.AddToSchedule(scheduled);
      }
      ArmDisplayedTimer(built.id, *built.fireDate);
      return true;
    }

    ToastNotification toast(document);
    toast.Tag(TagOf(built.id));
    toast.Group(kGroup);
    Track(built.id, toast);
    Notifier().Show(toast);
    return true;
  } catch (const winrt::hresult_error&) {
    return false;
  }
}

void ToastPresenter::Track(int64_t id, const ToastNotification& toast) {
  std::weak_ptr<ToastPresenter> weak = weak_from_this();
  auto dispatcher = dispatcher_;

  // Dismissed arrives on a background thread; only a user dismissal counts
  // (timing out into the notification center is not a dismissal).
  toast.Dismissed([weak, dispatcher, id](const ToastNotification&,
                                         const ToastDismissedEventArgs& args) {
    if (args.Reason() != ToastDismissalReason::UserCanceled) return;
    dispatcher->post([weak, id]() {
      auto self = weak.lock();
      if (!self) return;
      {
        std::lock_guard<std::mutex> lock(self->mutex_);
        self->shown_.erase(id);
      }
      if (self->callbacks_.onDismissed) self->callbacks_.onDismissed(id);
    });
  });

  // A packaged app gets activations as toast events (no COM activator of ours).
  if (identity_.packaged) {
    toast.Activated([weak, dispatcher](const ToastNotification&,
                                       const winrt::Windows::Foundation::IInspectable& raw) {
      awn::Activation activation;
      if (auto args = raw.try_as<ToastActivatedEventArgs>()) {
        activation.arguments = winrt::to_string(args.Arguments());
        try {
          for (const auto& pair : args.UserInput()) {
            if (auto text = pair.Value().try_as<winrt::Windows::Foundation::IPropertyValue>())
              activation.userInputs[winrt::to_string(pair.Key())] =
                  winrt::to_string(text.GetString());
          }
        } catch (const winrt::hresult_error&) {
        }
      }
      dispatcher->post([weak, activation]() {
        auto self = weak.lock();
        if (self && self->callbacks_.onActivated) self->callbacks_.onActivated(activation);
      });
    });
  }

  std::lock_guard<std::mutex> lock(mutex_);
  shown_.insert_or_assign(id, toast);
}

// MARK: - Displayed timers (scheduled toasts firing while the app runs)

void ToastPresenter::ArmDisplayedTimer(int64_t id, awn::TimePoint fireDate) {
  CancelDisplayedTimer(id);
  auto delay = std::chrono::duration_cast<std::chrono::milliseconds>(fireDate -
                                                                     awn::DateUtils::now());
  std::weak_ptr<ToastPresenter> weak = weak_from_this();
  UINT_PTR handle = dispatcher_->PostDelayed(delay, [weak, id, fireDate]() {
    auto self = weak.lock();
    if (!self) return;
    self->displayedTimers_.erase(id);
    if (self->callbacks_.onDisplayed) self->callbacks_.onDisplayed(id);
    // Chain to the next pre-armed occurrence of a repeating schedule.
    if (auto following = self->NextScheduledDate(id, fireDate))
      self->ArmDisplayedTimer(id, *following);
  });
  displayedTimers_[id] = handle;
}

void ToastPresenter::CancelDisplayedTimer(int64_t id) {
  auto it = displayedTimers_.find(id);
  if (it == displayedTimers_.end()) return;
  dispatcher_->CancelDelayed(it->second);
  displayedTimers_.erase(it);
}

std::optional<awn::TimePoint> ToastPresenter::NextScheduledDate(int64_t id,
                                                                awn::TimePoint after) {
  std::optional<awn::TimePoint> earliest;
  try {
    for (const auto& scheduled : Notifier().GetScheduledToastNotifications()) {
      if (IdFromTag(scheduled.Tag()) != id) continue;
      auto fire = std::chrono::time_point_cast<std::chrono::seconds>(
          winrt::clock::to_sys(scheduled.DeliveryTime()));
      if (fire > after && (!earliest || fire < *earliest)) earliest = fire;
    }
  } catch (const winrt::hresult_error&) {
  }
  return earliest;
}

void ToastPresenter::ArmPendingTimers() {
  std::vector<int64_t> ids = pendingIds();
  std::sort(ids.begin(), ids.end());
  ids.erase(std::unique(ids.begin(), ids.end()), ids.end());
  for (auto id : ids) {
    if (auto fire = NextScheduledDate(id, awn::DateUtils::now())) ArmDisplayedTimer(id, *fire);
  }
}

// MARK: - Remove / query

void ToastPresenter::removeDelivered(const std::vector<int64_t>& ids) {
  try {
    auto history = History();
    for (auto id : ids) {
      {
        std::lock_guard<std::mutex> lock(mutex_);
        shown_.erase(id);
      }
      if (identity_.aumid.empty())
        history.Remove(TagOf(id), kGroup);
      else
        history.Remove(TagOf(id), kGroup, identity_.aumid);
    }
  } catch (const winrt::hresult_error&) {
  }
}

void ToastPresenter::removeAllDelivered() {
  {
    std::lock_guard<std::mutex> lock(mutex_);
    shown_.clear();
  }
  try {
    if (identity_.aumid.empty())
      History().Clear();
    else
      History().Clear(identity_.aumid);
  } catch (const winrt::hresult_error&) {
  }
}

void ToastPresenter::removePending(const std::vector<int64_t>& ids) {
  for (auto id : ids) CancelDisplayedTimer(id);
  try {
    auto notifier = Notifier();
    for (const auto& scheduled : notifier.GetScheduledToastNotifications()) {
      auto id = IdFromTag(scheduled.Tag());
      if (id && std::find(ids.begin(), ids.end(), *id) != ids.end())
        notifier.RemoveFromSchedule(scheduled);
    }
  } catch (const winrt::hresult_error&) {
  }
}

void ToastPresenter::removeAllPending() {
  for (const auto& timer : displayedTimers_) dispatcher_->CancelDelayed(timer.second);
  displayedTimers_.clear();
  try {
    auto notifier = Notifier();
    for (const auto& scheduled : notifier.GetScheduledToastNotifications())
      notifier.RemoveFromSchedule(scheduled);
  } catch (const winrt::hresult_error&) {
  }
}

std::vector<int64_t> ToastPresenter::deliveredIds() {
  std::vector<int64_t> ids;
  try {
    auto history = identity_.aumid.empty() ? History().GetHistory()
                                           : History().GetHistory(identity_.aumid);
    for (const auto& toast : history) {
      if (auto id = IdFromTag(toast.Tag())) ids.push_back(*id);
    }
  } catch (const winrt::hresult_error&) {
  }
  return ids;
}

std::vector<int64_t> ToastPresenter::pendingIds() {
  std::vector<int64_t> ids;
  try {
    for (const auto& scheduled : Notifier().GetScheduledToastNotifications()) {
      if (auto id = IdFromTag(scheduled.Tag())) ids.push_back(*id);
    }
  } catch (const winrt::hresult_error&) {
  }
  return ids;
}

// MARK: - Permission / time zone

bool ToastPresenter::isAllowed() {
  try {
    return Notifier().Setting() == NotificationSetting::Enabled;
  } catch (const winrt::hresult_error&) {
    return false;
  }
}

void ToastPresenter::requestPermission(std::function<void(bool)> done) {
  // Windows never prompts: when notifications are off, open the settings page
  // so the user can turn them on, and report the current (still missing) state.
  bool allowed = isAllowed();
  if (!allowed)
    ::ShellExecuteW(nullptr, L"open", L"ms-settings:notifications", nullptr, nullptr,
                    SW_SHOWNORMAL);
  done(allowed);
}

std::string ToastPresenter::localTimeZone() {
  static const std::string zone = IcuTimeZone::DefaultZone().value_or(awn::defs::UTC_TIMEZONE);
  return zone;
}

int64_t ToastPresenter::utcOffset(const std::string& zone, awn::TimePoint utc) {
  return IcuTimeZone::Offset(zone, utc).value_or(0);
}

std::string ToastPresenter::systemLanguage() {
  wchar_t name[LOCALE_NAME_MAX_LENGTH] = {};
  if (::GetUserDefaultLocaleName(name, LOCALE_NAME_MAX_LENGTH) == 0) return "en";
  std::string tag = WideToUtf8(name);
  for (auto& c : tag) c = static_cast<char>(std::tolower(static_cast<unsigned char>(c)));
  return tag;
}

}  // namespace awesome_notifications
