#include "awn/displayed_tracker.h"

#include "awn/definitions.h"

namespace awn {

void DisplayedLifecycleTracker::recordForegroundDisplay(int64_t id, const std::string& date) {
  std::lock_guard<std::mutex> lock(mutex_);
  displayed_[id] = date;
}

ValueMap DisplayedLifecycleTracker::resolve(const ValueMap& content, std::optional<int64_t> id) {
  if (!id) return content;
  std::string date;
  {
    std::lock_guard<std::mutex> lock(mutex_);
    auto it = displayed_.find(*id);
    if (it == displayed_.end()) return content;
    date = it->second;
    displayed_.erase(it);
  }
  ValueMap resolved = content;
  resolved[defs::NOTIFICATION_DISPLAYED_DATE] = date;
  resolved[defs::NOTIFICATION_DISPLAYED_LIFECYCLE] = toWire(LifeCycle::Foreground);
  return resolved;
}

void DisplayedLifecycleTracker::forget(int64_t id) {
  std::lock_guard<std::mutex> lock(mutex_);
  displayed_.erase(id);
}

void DisplayedLifecycleTracker::forgetAll() {
  std::lock_guard<std::mutex> lock(mutex_);
  displayed_.clear();
}

}  // namespace awn
