#include "awesome_notifications_calls_plugin.h"

#include <windows.h>

#include <flutter/event_stream_handler_functions.h>
#include <flutter/standard_method_codec.h>

#include <map>
#include <memory>
#include <string>

#include "awesome_notifications/awn_value_codec.h"
#include "awn/awesome_notifications.h"

namespace awesome_notifications_calls {

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

}  // namespace

// static
void AwesomeNotificationsCallsPlugin::After(int64_t ms, std::function<void()> work) {
  UINT delay = static_cast<UINT>(ms < USER_TIMER_MINIMUM ? USER_TIMER_MINIMUM
                                 : ms > USER_TIMER_MAXIMUM ? USER_TIMER_MAXIMUM
                                                           : ms);
  UINT_PTR id = ::SetTimer(nullptr, 0, delay, &OnTimer);
  if (id != 0) Timers()[id] = std::move(work);
}

// static
void AwesomeNotificationsCallsPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows* registrar) {
  registrar->AddPlugin(std::make_unique<AwesomeNotificationsCallsPlugin>(registrar));
}

AwesomeNotificationsCallsPlugin::AwesomeNotificationsCallsPlugin(
    flutter::PluginRegistrarWindows* registrar) {
  auto& core = awn::AwesomeNotifications::shared();
  controller_ = std::make_shared<awn_calls::CallController>(
      awn_calls::engineHost(core, &AwesomeNotificationsCallsPlugin::After));

  // The commands stream, while Dart listens.
  std::weak_ptr<awn_calls::CallController> weak = controller_;
  events_ = std::make_unique<flutter::EventChannel<flutter::EncodableValue>>(
      registrar->messenger(), awn_calls::keys::EVENTS_CHANNEL,
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

  // Plugins register alphabetically: the core is already registered. Its
  // bridge brings the window forward for Accept (a Default action, foreground
  // toast activation) and leaves it for Decline / Hang up (background).
  awn_calls::RegisterCalls(controller_, awn_calls::desktopCapabilities(), core);
}

AwesomeNotificationsCallsPlugin::~AwesomeNotificationsCallsPlugin() {
  controller_->setStreamSink(nullptr);
  for (const auto& [id, work] : Timers()) ::KillTimer(nullptr, id);
  Timers().clear();
}

}  // namespace awesome_notifications_calls
