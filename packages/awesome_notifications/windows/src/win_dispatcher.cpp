#include "win_dispatcher.h"

#include <algorithm>

namespace awesome_notifications {

namespace {
// Timer ids are private to the window; start high to stay clear of the ids the
// runner or other plugins might use on the same window.
constexpr UINT_PTR kFirstTimerId = 0xA3E00000;
// SetTimer's limit (USER_TIMER_MAXIMUM, ~24.8 days); longer delays re-arm.
constexpr long long kMaxTimerMs = 0x7FFFFFFF;
}  // namespace

WinDispatcher::WinDispatcher(HWND window)
    : window_(window),
      message_(::RegisterWindowMessageW(L"AwesomeNotificationsDispatch")),
      nextTimer_(kFirstTimerId) {}

void WinDispatcher::post(std::function<void()> work) {
  HWND window;
  {
    std::lock_guard<std::mutex> lock(mutex_);
    if (!window_) return;
    queue_.push_back(std::move(work));
    window = window_;
  }
  ::PostMessageW(window, message_, 0, 0);
}

UINT_PTR WinDispatcher::PostDelayed(std::chrono::milliseconds delay, std::function<void()> work) {
  long long ms = std::max<long long>(0, delay.count());
  UINT_PTR id = nextTimer_++;
  if (ms > kMaxTimerMs) {
    // Re-arm for the remainder when the first leg elapses.
    auto remaining = std::chrono::milliseconds(ms - kMaxTimerMs);
    timers_[id] = [this, remaining, work = std::move(work)]() mutable {
      PostDelayed(remaining, std::move(work));
    };
    ms = kMaxTimerMs;
  } else {
    timers_[id] = std::move(work);
  }
  ::SetTimer(window_, id, static_cast<UINT>(ms), nullptr);
  return id;
}

void WinDispatcher::CancelDelayed(UINT_PTR handle) {
  if (timers_.erase(handle) > 0) ::KillTimer(window_, handle);
}

std::optional<LRESULT> WinDispatcher::HandleMessage(UINT message, WPARAM wparam, LPARAM) {
  if (message == message_) {
    Drain();
    return 0;
  }
  if (message == WM_TIMER) {
    auto it = timers_.find(static_cast<UINT_PTR>(wparam));
    if (it == timers_.end()) return std::nullopt;
    ::KillTimer(window_, it->first);
    auto work = std::move(it->second);
    timers_.erase(it);
    work();
    return 0;
  }
  return std::nullopt;
}

void WinDispatcher::Detach() {
  std::lock_guard<std::mutex> lock(mutex_);
  for (const auto& timer : timers_) ::KillTimer(window_, timer.first);
  timers_.clear();
  queue_.clear();
  window_ = nullptr;
}

void WinDispatcher::Drain() {
  std::deque<std::function<void()>> work;
  {
    std::lock_guard<std::mutex> lock(mutex_);
    work.swap(queue_);
  }
  for (auto& item : work) item();
}

}  // namespace awesome_notifications
