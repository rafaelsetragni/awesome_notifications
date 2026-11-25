#include "awesome_notifications_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>

#include <flutter/standard_method_codec.h>

#include <VersionHelpers.h>

#include <chrono>
#include <memory>

#include "awn/awesome_notifications.h"
#include "awn/definitions.h"
#include "awn/notification_builder.h"
#include "awn/registries.h"
#include "include/awesome_notifications/awn_value_codec.h"
#include "src/toast_activator.h"

namespace awesome_notifications {

namespace {
/// How long a toast-launched process waits for Windows to deliver the
/// activation before answering getInitialAction with nothing.
constexpr std::chrono::milliseconds kLaunchActivationTimeout(5000);
}  // namespace

// static
void AwesomeNotificationsPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows* registrar) {
  auto channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      registrar->messenger(), "awesome_notifications",
      &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<AwesomeNotificationsPlugin>(registrar, std::move(channel));
  registrar->AddPlugin(std::move(plugin));
}

AwesomeNotificationsPlugin::AwesomeNotificationsPlugin(
    flutter::PluginRegistrarWindows* registrar,
    std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel)
    : registrar_(registrar),
      channel_(std::move(channel)),
      identity_(AppIdentity::Resolve()),
      router_(awn::AwesomeNotifications::shared()) {
  auto& core = awn::AwesomeNotifications::shared();

  channel_->SetMethodCallHandler([this](const auto& call, auto result) {
    HandleMethodCall(call, std::move(result));
  });

  dispatcher_ = std::make_shared<WinDispatcher>(RootWindow());
  windowProcId_ = registrar_->RegisterTopLevelWindowProcDelegate(
      [this](HWND hwnd, UINT message, WPARAM wparam, LPARAM lparam) {
        return HandleWindowProc(hwnd, message, wparam, lparam);
      });

  identity_.RegisterInRegistry();

  ToastPresenter::Callbacks callbacks;
  callbacks.onDismissed = [](int64_t id) { awn::AwesomeNotifications::shared().onDismissed(id); };
  callbacks.onDisplayed = [](int64_t id) { awn::AwesomeNotifications::shared().onDisplayed(id); };
  callbacks.onActivated = [this](const awn::Activation& activation) { OnActivated(activation); };
  callbacks.isSilent = [](const awn::ValueMap& model) {
    auto key = awn::getString(awn::NotificationBuilder::content(model),
                              awn::defs::NOTIFICATION_CHANNEL_KEY);
    if (!key) return false;
    auto channelModel = awn::AwesomeNotifications::shared().channel(*key);
    return channelModel &&
           !awn::getBool(*channelModel, awn::defs::NOTIFICATION_PLAY_SOUND).value_or(true);
  };
  presenter_ = std::make_shared<ToastPresenter>(identity_, dispatcher_, std::move(callbacks));

  bool launchedByToast = AppIdentity::LaunchedByToast();
  core.configure(presenter_, dispatcher_,
                 std::make_shared<awn::NotificationStore>(identity_.dataDirectory /
                                                          L"notifications.json"),
                 launchedByToast, [this] { return CurrentLifeCycle(); });
  presenter_->ArmPendingTimers();

  // Forward core lifecycle events (created/displayed/action/dismissed) to Dart.
  // The core emits them on the platform thread.
  eventsToken_ = awn::AwesomeEventsReceiver::shared().subscribe(
      [this](const std::string& event, const awn::ValueMap& content) {
        channel_->InvokeMethod(event, std::make_unique<flutter::EncodableValue>(
                                          ToEncodable(awn::Value(content))));
      });

  // Toast activations (COM, any thread) are re-posted to the platform thread.
  auto dispatcher = dispatcher_;
  if (!identity_.packaged) {
    ToastActivator::Register(identity_.activatorClsid,
                             [this, dispatcher](const awn::Activation& activation) {
                               dispatcher->post([this, activation] { OnActivated(activation); });
                             });
  }

  if (launchedByToast) {
    dispatcher_->PostDelayed(kLaunchActivationTimeout,
                             [] { awn::AwesomeNotifications::shared().finishLaunching(); });
  }
}

AwesomeNotificationsPlugin::~AwesomeNotificationsPlugin() {
  ToastActivator::Unregister();
  awn::AwesomeEventsReceiver::shared().unsubscribe(eventsToken_);
  registrar_->UnregisterTopLevelWindowProcDelegate(windowProcId_);
  dispatcher_->Detach();
}

HWND AwesomeNotificationsPlugin::RootWindow() const {
  auto view = registrar_->GetView();
  if (!view) return nullptr;
  return ::GetAncestor(view->GetNativeWindow(), GA_ROOT);
}

awn::LifeCycle AwesomeNotificationsPlugin::CurrentLifeCycle() const {
  HWND root = RootWindow();
  if (root && ::GetForegroundWindow() == root && !::IsIconic(root))
    return awn::LifeCycle::Foreground;
  return awn::LifeCycle::Background;
}

void AwesomeNotificationsPlugin::OnActivated(const awn::Activation& activation) {
  auto type = awn::AwesomeNotifications::shared().onActivated(activation);
  if (!type) return;
  switch (*type) {
    case awn::ActionType::SilentAction:
    case awn::ActionType::SilentBackgroundAction:
    case awn::ActionType::DismissAction:
      return;
    default:
      BringToFront();
  }
}

void AwesomeNotificationsPlugin::BringToFront() const {
  HWND root = RootWindow();
  if (!root) return;
  if (::IsIconic(root)) ::ShowWindow(root, SW_RESTORE);
  ::SetForegroundWindow(root);
}

std::optional<LRESULT> AwesomeNotificationsPlugin::HandleWindowProc(HWND, UINT message,
                                                                    WPARAM wparam,
                                                                    LPARAM lparam) {
  return dispatcher_ ? dispatcher_->HandleMessage(message, wparam, lparam) : std::nullopt;
}

void AwesomeNotificationsPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue>& method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (method_call.method_name() == "getPlatformVersion") {
    result->Success(flutter::EncodableValue(IsWindows10OrGreater() ? "Windows 10+" : "Windows"));
    return;
  }

  awn::Value arguments =
      method_call.arguments() ? ToAwnValue(*method_call.arguments()) : awn::Value();
  // std::function must be copyable: share the one-shot result.
  std::shared_ptr<flutter::MethodResult<flutter::EncodableValue>> shared(std::move(result));
  bool handled = router_.handle(
      method_call.method_name(), arguments,
      [shared](const awn::Value& value) { shared->Success(ToEncodable(value)); },
      [shared](const std::string& code, const std::string& message, const awn::Value& details) {
        shared->Error(code, message, ToEncodable(details));
      });
  if (!handled) shared->NotImplemented();
}

}  // namespace awesome_notifications
