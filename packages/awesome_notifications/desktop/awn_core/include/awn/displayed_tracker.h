#pragma once

#include <map>
#include <mutex>
#include <optional>
#include <string>

#include "awn/export.h"
#include "awn/value.h"

namespace awn {

/// Remembers which notifications were displayed while the app was running, so
/// the later action / dismiss events report the real displayed lifecycle instead
/// of the one predicted at creation (a scheduled notification is stored as
/// terminated). Same contract as the Apple core's DisplayedLifecycleTracker.
class AWN_API DisplayedLifecycleTracker {
 public:
  void recordForegroundDisplay(int64_t id, const std::string& date);
  /// `content` with the real displayed date/lifecycle when `id` was displayed in
  /// the foreground; unchanged otherwise. Consumes the record.
  ValueMap resolve(const ValueMap& content, std::optional<int64_t> id);
  void forget(int64_t id);
  void forgetAll();

 private:
  std::mutex mutex_;
  std::map<int64_t, std::string> displayed_;
};

}  // namespace awn
