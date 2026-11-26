#pragma once

#include <filesystem>
#include <functional>
#include <map>
#include <mutex>
#include <optional>
#include <vector>

#include "awn/export.h"
#include "awn/value.h"

namespace awn {

/// Persists the models of the notifications the plugin delivered or scheduled.
///
/// Desktop notification systems hand back only a small activation string when a
/// notification is tapped — possibly in a later process, after the app was
/// closed — so the full model (payload, buttons, lifecycle dates) is kept here,
/// keyed by id, the way the Apple core keeps it in `userInfo`.
class AWN_API NotificationStore {
 public:
  /// An empty `file` keeps the store in memory only (tests).
  explicit NotificationStore(std::filesystem::path file = {});

  void put(int64_t id, const ValueMap& model);
  std::optional<ValueMap> get(int64_t id) const;
  void remove(int64_t id);
  void remove(const std::vector<int64_t>& ids);
  void removeAll();
  std::vector<int64_t> ids() const;
  /// Ids whose model content has `key` == `value` (e.g. channelKey, groupKey).
  std::vector<int64_t> idsWhereContent(const std::string& key, const std::string& value) const;
  /// Keeps only the ids `keep` returns true for.
  void retainWhere(const std::function<bool(int64_t)>& keep);

 private:
  void load();
  void save() const;

  std::filesystem::path file_;
  mutable std::mutex mutex_;
  std::map<int64_t, ValueMap> models_;
};

}  // namespace awn
