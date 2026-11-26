#include "awn/notification_store.h"

#include <fstream>
#include <sstream>
#include <system_error>

#include "awn/definitions.h"
#include "awn/json.h"
#include "awn/notification_builder.h"

namespace awn {

NotificationStore::NotificationStore(std::filesystem::path file) : file_(std::move(file)) {
  load();
}

void NotificationStore::put(int64_t id, const ValueMap& model) {
  std::lock_guard<std::mutex> lock(mutex_);
  models_[id] = model;
  save();
}

std::optional<ValueMap> NotificationStore::get(int64_t id) const {
  std::lock_guard<std::mutex> lock(mutex_);
  auto it = models_.find(id);
  if (it == models_.end()) return std::nullopt;
  return it->second;
}

void NotificationStore::remove(int64_t id) {
  std::lock_guard<std::mutex> lock(mutex_);
  if (models_.erase(id) > 0) save();
}

void NotificationStore::remove(const std::vector<int64_t>& ids) {
  std::lock_guard<std::mutex> lock(mutex_);
  bool changed = false;
  for (auto id : ids) changed |= models_.erase(id) > 0;
  if (changed) save();
}

void NotificationStore::removeAll() {
  std::lock_guard<std::mutex> lock(mutex_);
  if (models_.empty()) return;
  models_.clear();
  save();
}

std::vector<int64_t> NotificationStore::ids() const {
  std::lock_guard<std::mutex> lock(mutex_);
  std::vector<int64_t> result;
  for (const auto& entry : models_) result.push_back(entry.first);
  return result;
}

std::vector<int64_t> NotificationStore::idsWhereContent(const std::string& key,
                                                        const std::string& value) const {
  std::lock_guard<std::mutex> lock(mutex_);
  std::vector<int64_t> result;
  for (const auto& [id, model] : models_) {
    if (getString(NotificationBuilder::content(model), key) == value) result.push_back(id);
  }
  return result;
}

void NotificationStore::retainWhere(const std::function<bool(int64_t)>& keep) {
  std::lock_guard<std::mutex> lock(mutex_);
  bool changed = false;
  for (auto it = models_.begin(); it != models_.end();) {
    if (keep(it->first)) {
      ++it;
    } else {
      it = models_.erase(it);
      changed = true;
    }
  }
  if (changed) save();
}

void NotificationStore::load() {
  if (file_.empty()) return;
  std::ifstream in(file_, std::ios::binary);
  if (!in) return;
  std::stringstream buffer;
  buffer << in.rdbuf();
  auto decoded = Json::decode(buffer.str());
  if (!decoded) return;  // A corrupt store starts empty rather than failing.
  for (const auto& [key, model] : decoded->map()) {
    auto id = Value(key).asInt();
    if (id && model.isMap()) models_[*id] = model.map();
  }
}

void NotificationStore::save() const {
  if (file_.empty()) return;
  ValueMap root;
  for (const auto& [id, model] : models_) root[std::to_string(id)] = model;

  std::error_code ec;
  std::filesystem::create_directories(file_.parent_path(), ec);
  // Write a sibling temp file then swap it in, so a crash never leaves a
  // half-written store.
  auto temp = file_;
  temp += ".tmp";
  {
    std::ofstream out(temp, std::ios::binary | std::ios::trunc);
    if (!out) return;
    out << Json::encode(Value(std::move(root)));
    if (!out) return;
  }
  std::filesystem::rename(temp, file_, ec);
  if (ec) {
    std::filesystem::remove(file_, ec);
    std::filesystem::rename(temp, file_, ec);
  }
}

}  // namespace awn
