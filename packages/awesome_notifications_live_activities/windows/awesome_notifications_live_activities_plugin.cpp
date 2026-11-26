#include "awesome_notifications_live_activities_plugin.h"

#include <windows.h>

#include <appmodel.h>

#include <flutter/event_stream_handler_functions.h>
#include <flutter/standard_method_codec.h>

#include <map>
#include <memory>
#include <string>

#include <winrt/Windows.Data.Xml.Dom.h>
#include <winrt/Windows.Foundation.Collections.h>
#include <winrt/Windows.Foundation.h>

#include "awesome_notifications/awn_value_codec.h"
#include "awn/awesome_notifications.h"
#include "awn/definitions.h"
#include "awn/notification_builder.h"

namespace awesome_notifications_live_activities {

using winrt::Windows::Data::Xml::Dom::XmlDocument;
using winrt::Windows::UI::Notifications::NotificationData;
using winrt::Windows::UI::Notifications::NotificationUpdateResult;
using winrt::Windows::UI::Notifications::ToastActivatedEventArgs;
using winrt::Windows::UI::Notifications::ToastDismissalReason;
using winrt::Windows::UI::Notifications::ToastDismissedEventArgs;
using winrt::Windows::UI::Notifications::ToastNotification;
using winrt::Windows::UI::Notifications::ToastNotificationManager;
using winrt::Windows::UI::Notifications::ToastNotifier;

namespace {

/// The pending thread timers (platform thread only).
std::map<UINT_PTR, std::function<void()>>& Timers() {
  static std::map<UINT_PTR, std::function<void()>> timers;
  return timers;
}

void CALLBACK OnTimer(HWND, UINT, UINT_PTR id, DWORD) {
  ::KillTimer(nullptr, id);
  auto& timers = Timers();
  auto it = timers.find(id);
  if (it == timers.end()) return;
  auto work = std::move(it->second);
  timers.erase(it);
  work();
}

std::wstring ExecutablePath() {
  std::wstring path(MAX_PATH, L'\0');
  for (;;) {
    DWORD length = ::GetModuleFileNameW(nullptr, path.data(), static_cast<DWORD>(path.size()));
    if (length == 0) return {};
    if (length < path.size()) {
      path.resize(length);
      return path;
    }
    path.resize(path.size() * 2);
  }
}

NotificationData DataOf(const awn_live::ToastPost& post) {
  NotificationData data;
  for (const auto& [key, value] : post.data)
    data.Values().Insert(winrt::to_hstring(key), winrt::to_hstring(value));
  data.SequenceNumber(post.sequence);
  return data;
}

}  // namespace

// MARK: - Dispatch

void AwesomeNotificationsLiveActivitiesPlugin::Dispatch::Post(std::function<void()> work) {
  HWND target;
  {
    std::lock_guard<std::mutex> lock(mutex);
    if (!window) return;
    queue.push_back(std::move(work));
    target = window;
  }
  ::PostMessageW(target, message, 0, 0);
}

void AwesomeNotificationsLiveActivitiesPlugin::Dispatch::Drain() {
  std::deque<std::function<void()>> due;
  {
    std::lock_guard<std::mutex> lock(mutex);
    due.swap(queue);
  }
  for (auto& work : due) work();
}

void AwesomeNotificationsLiveActivitiesPlugin::Dispatch::Detach() {
  std::lock_guard<std::mutex> lock(mutex);
  window = nullptr;
  queue.clear();
}

// MARK: - Plugin

// static
void AwesomeNotificationsLiveActivitiesPlugin::After(int64_t ms, std::function<void()> work) {
  UINT delay = static_cast<UINT>(ms < USER_TIMER_MINIMUM ? USER_TIMER_MINIMUM
                                 : ms > USER_TIMER_MAXIMUM ? USER_TIMER_MAXIMUM
                                                           : ms);
  UINT_PTR id = ::SetTimer(nullptr, 0, delay, &OnTimer);
  if (id != 0) Timers()[id] = std::move(work);
}

// static
void AwesomeNotificationsLiveActivitiesPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows* registrar) {
  registrar->AddPlugin(std::make_unique<AwesomeNotificationsLiveActivitiesPlugin>(registrar));
}

HWND AwesomeNotificationsLiveActivitiesPlugin::RootWindow() const {
  auto view = registrar_->GetView();
  if (!view) return nullptr;
  return ::GetAncestor(view->GetNativeWindow(), GA_ROOT);
}

AwesomeNotificationsLiveActivitiesPlugin::AwesomeNotificationsLiveActivitiesPlugin(
    flutter::PluginRegistrarWindows* registrar)
    : registrar_(registrar), dispatch_(std::make_shared<Dispatch>()) {
  // The core's app identity: an unpackaged app's toasts go out under the AUMID
  // the core registered, so the core's history / cancel reach them.
  UINT32 length = 0;
  packaged_ = ::GetCurrentPackageFullName(&length, nullptr) != APPMODEL_ERROR_NO_PACKAGE;
  if (!packaged_) aumid_ = awn_live::unpackagedAumid(ExecutablePath());

  dispatch_->window = RootWindow();
  dispatch_->message = ::RegisterWindowMessageW(L"AwesomeNotificationsLiveActivitiesDispatch");
  std::shared_ptr<Dispatch> dispatch = dispatch_;
  windowProcId_ = registrar_->RegisterTopLevelWindowProcDelegate(
      [dispatch](HWND, UINT message, WPARAM, LPARAM) -> std::optional<LRESULT> {
        if (message != dispatch->message) return std::nullopt;
        dispatch->Drain();
        return 0;
      });

  auto& core = awn::AwesomeNotifications::shared();
  awn_live::LiveHost host =
      awn_live::engineHost(core, &AwesomeNotificationsLiveActivitiesPlugin::After);
  // The live toasts are this plugin's: data-bound and updated in place.
  host.present = [this](const awn::BuiltNotification& built, std::function<void(bool)> done) {
    Present(built, std::move(done));
  };
  controller_ = std::make_shared<awn_live::LiveController>(std::move(host),
                                                           awn_live::Surface::toast);

  // The state events, while Dart listens.
  std::weak_ptr<awn_live::LiveController> weak = controller_;
  events_ = std::make_unique<flutter::EventChannel<flutter::EncodableValue>>(
      registrar->messenger(), awn_live::keys::EVENTS_CHANNEL,
      &flutter::StandardMethodCodec::GetInstance());
  events_->SetStreamHandler(
      std::make_unique<flutter::StreamHandlerFunctions<flutter::EncodableValue>>(
          [weak](const flutter::EncodableValue*,
                 std::unique_ptr<flutter::EventSink<flutter::EncodableValue>>&& events)
              -> std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>> {
            std::shared_ptr<flutter::EventSink<flutter::EncodableValue>> sink(std::move(events));
            if (auto controller = weak.lock()) {
              controller->setStreamSink([sink](const awn::ValueMap& event) {
                sink->Success(awesome_notifications::ToEncodable(awn::Value(event)));
              });
            }
            return nullptr;
          },
          [weak](const flutter::EncodableValue*)
              -> std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>> {
            if (auto controller = weak.lock()) controller->setStreamSink(nullptr);
            return nullptr;
          }));

  // Plugins register alphabetically: the core is already registered.
  awn_live::RegisterLiveActivities(controller_, awn_live::desktopCapabilities(), core);
}

AwesomeNotificationsLiveActivitiesPlugin::~AwesomeNotificationsLiveActivitiesPlugin() {
  controller_->setStreamSink(nullptr);
  registrar_->UnregisterTopLevelWindowProcDelegate(windowProcId_);
  dispatch_->Detach();
  for (const auto& [id, work] : Timers()) ::KillTimer(nullptr, id);
  Timers().clear();
}

ToastNotifier AwesomeNotificationsLiveActivitiesPlugin::Notifier() {
  if (!notifier_) {
    notifier_ = aumid_.empty() ? ToastNotificationManager::CreateToastNotifier()
                               : ToastNotificationManager::CreateToastNotifier(aumid_);
  }
  return notifier_;
}

void AwesomeNotificationsLiveActivitiesPlugin::Present(const awn::BuiltNotification& built,
                                                       std::function<void(bool)> done) {
  auto& core = awn::AwesomeNotifications::shared();
  auto channelKey = awn::getString(awn::NotificationBuilder::content(built.model),
                                   awn::defs::NOTIFICATION_CHANNEL_KEY);
  bool silent = awn_live::silentChannel(channelKey ? core.channel(*channelKey) : std::nullopt);
  awn_live::ToastPost post = awn_live::toastPostOf(built.model, silent);
  winrt::hstring tag = winrt::to_hstring(post.tag);
  winrt::hstring group = winrt::to_hstring(awn_live::kToastGroup);

  try {
    auto notifier = Notifier();
    // The same layout on screen: only its data changes, with no new popup.
    if (post.update &&
        notifier.Update(DataOf(post), tag, group) == NotificationUpdateResult::Succeeded) {
      done(true);
      return;
    }

    XmlDocument document;
    document.LoadXml(winrt::to_hstring(post.xml));
    ToastNotification toast(document);
    toast.Tag(tag);
    toast.Group(group);
    toast.Data(DataOf(post));
    toast.SuppressPopup(post.suppressPopup);

    // Dismissed arrives on a background thread; only a user dismissal counts
    // (timing out into the notification center is not a dismissal).
    std::weak_ptr<Dispatch> dispatch = dispatch_;
    int64_t id = post.id;
    toast.Dismissed([this, dispatch, id](const ToastNotification&,
                                         const ToastDismissedEventArgs& args) {
      if (args.Reason() != ToastDismissalReason::UserCanceled) return;
      if (auto alive = dispatch.lock()) {
        alive->Post([this, id] {
          shown_.erase(id);
          awn::AwesomeNotifications::shared().onDismissed(id);
        });
      }
    });

    // A packaged app gets activations as toast events (an unpackaged one
    // through the core's COM activator, from the toast's launch arguments).
    if (packaged_) {
      toast.Activated([this, dispatch](const ToastNotification&,
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
        if (auto alive = dispatch.lock()) {
          alive->Post([this, activation] {
            auto type = awn::AwesomeNotifications::shared().onActivated(activation);
            if (!type || *type == awn::ActionType::SilentAction ||
                *type == awn::ActionType::SilentBackgroundAction ||
                *type == awn::ActionType::DismissAction)
              return;
            if (HWND root = RootWindow()) {
              if (::IsIconic(root)) ::ShowWindow(root, SW_RESTORE);
              ::SetForegroundWindow(root);
            }
          });
        }
      });
    }

    shown_.insert_or_assign(post.id, toast);
    notifier.Show(toast);
    done(true);
  } catch (const winrt::hresult_error&) {
    done(false);
  }
}

}  // namespace awesome_notifications_live_activities
