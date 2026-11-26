#include "awesome_notifications_media_plugin.h"

#include <windows.h>

#include <flutter/event_stream_handler_functions.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <optional>
#include <string>

#include "awesome_notifications/awn_value_codec.h"
#include "awn/awesome_notifications.h"

namespace awesome_notifications_media {

// MARK: - PlatformThread

PlatformThread::PlatformThread()
    : message_(::RegisterWindowMessageW(L"AwesomeNotificationsMediaDispatch")) {}

void PlatformThread::Post(std::function<void()> work) {
  HWND window;
  {
    std::lock_guard<std::mutex> lock(mutex_);
    if (!window_) return;
    queue_.push_back(std::move(work));
    window = window_;
  }
  ::PostMessageW(window, message_, 0, 0);
}

void PlatformThread::SetWindow(HWND window) {
  std::lock_guard<std::mutex> lock(mutex_);
  window_ = window;
}

std::optional<LRESULT> PlatformThread::Handle(UINT message) {
  if (message != message_) return std::nullopt;
  std::deque<std::function<void()>> work;
  {
    std::lock_guard<std::mutex> lock(mutex_);
    work.swap(queue_);
  }
  for (auto& item : work) item();
  return 0;
}

void PlatformThread::Detach() {
  std::lock_guard<std::mutex> lock(mutex_);
  queue_.clear();
  window_ = nullptr;
}

// MARK: - Plugin

// static
void AwesomeNotificationsMediaPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows* registrar) {
  registrar->AddPlugin(std::make_unique<AwesomeNotificationsMediaPlugin>(registrar));
}

AwesomeNotificationsMediaPlugin::AwesomeNotificationsMediaPlugin(
    flutter::PluginRegistrarWindows* registrar)
    : registrar_(registrar), thread_(std::make_shared<PlatformThread>()) {
  auto thread = thread_;
  windowProcId_ = registrar_->RegisterTopLevelWindowProcDelegate(
      [thread](HWND, UINT message, WPARAM, LPARAM) { return thread->Handle(message); });

  surface_ = std::make_shared<SmtcSurface>(
      [this, thread]() {
        HWND root = RootWindow();
        thread->SetWindow(root);
        return root;
      },
      [thread](std::function<void()> work) { thread->Post(std::move(work)); });
  controller_ = std::make_shared<awn_media::MediaController>(
      surface_,
      [](const awn::ValueMap& model, const std::string& buttonKey,
         const std::optional<std::string>& input, const awn::ValueMap& button) {
        awn::AwesomeNotifications::shared().dispatchAction(model, buttonKey, input, button);
      },
      [](int64_t id) {
        auto& core = awn::AwesomeNotifications::shared();
        if (core.isConfigured()) core.cancel(id);
      });

  std::weak_ptr<awn_media::MediaController> weak = controller_;
  SmtcSurface::Callbacks callbacks;
  callbacks.onButton = [weak](awn_media::Button button) {
    if (auto controller = weak.lock()) awn_media::onButton(*controller, button);
  };
  callbacks.onSeek = [weak](int64_t position) {
    if (auto controller = weak.lock()) awn_media::onSeek(*controller, position);
  };
  surface_->SetCallbacks(std::move(callbacks));

  // The commands stream, while Dart listens.
  commands_ = std::make_unique<flutter::EventChannel<flutter::EncodableValue>>(
      registrar->messenger(), awn_media::keys::COMMANDS_CHANNEL,
      &flutter::StandardMethodCodec::GetInstance());
  commands_->SetStreamHandler(
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
  awn_media::RegisterMedia(controller_, awn_media::smtcCapabilities(),
                           awn::AwesomeNotifications::shared());
}

AwesomeNotificationsMediaPlugin::~AwesomeNotificationsMediaPlugin() {
  registrar_->UnregisterTopLevelWindowProcDelegate(windowProcId_);
  thread_->Detach();
  controller_->setStreamSink(nullptr);
}

HWND AwesomeNotificationsMediaPlugin::RootWindow() const {
  auto view = registrar_->GetView();
  if (!view) return nullptr;
  return ::GetAncestor(view->GetNativeWindow(), GA_ROOT);
}

}  // namespace awesome_notifications_media
