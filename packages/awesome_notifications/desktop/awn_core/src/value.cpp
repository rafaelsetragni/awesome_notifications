#include "awn/value.h"

#include <cerrno>
#include <cmath>
#include <cstdlib>

namespace awn {

namespace {
const ValueList kEmptyList;
const ValueMap kEmptyMap;
const Value kNull;

std::optional<int64_t> parseInt(const std::string& s) {
  if (s.empty()) return std::nullopt;
  char* end = nullptr;
  errno = 0;
  long long v = std::strtoll(s.c_str(), &end, 10);
  if (errno != 0 || end == s.c_str() || *end != '\0') return std::nullopt;
  return static_cast<int64_t>(v);
}
}  // namespace

std::optional<int64_t> Value::asInt() const {
  if (auto v = std::get_if<int64_t>(&data_)) return *v;
  if (auto v = std::get_if<double>(&data_)) {
    if (std::isfinite(*v)) return static_cast<int64_t>(*v);
    return std::nullopt;
  }
  if (auto v = std::get_if<std::string>(&data_)) return parseInt(*v);
  return std::nullopt;
}

std::optional<double> Value::asDouble() const {
  if (auto v = std::get_if<double>(&data_)) return *v;
  if (auto v = std::get_if<int64_t>(&data_)) return static_cast<double>(*v);
  if (auto v = std::get_if<std::string>(&data_)) {
    if (v->empty()) return std::nullopt;
    char* end = nullptr;
    double d = std::strtod(v->c_str(), &end);
    if (end == v->c_str() || *end != '\0') return std::nullopt;
    return d;
  }
  return std::nullopt;
}

std::optional<bool> Value::asBool() const {
  if (auto v = std::get_if<bool>(&data_)) return *v;
  if (auto v = std::get_if<std::string>(&data_)) {
    if (*v == "true") return true;
    if (*v == "false") return false;
  }
  return std::nullopt;
}

std::optional<std::string> Value::asString() const {
  if (auto v = std::get_if<std::string>(&data_)) return *v;
  return std::nullopt;
}

const ValueList& Value::list() const {
  if (auto v = std::get_if<ValueList>(&data_)) return *v;
  return kEmptyList;
}

const ValueMap& Value::map() const {
  if (auto v = std::get_if<ValueMap>(&data_)) return *v;
  return kEmptyMap;
}

ValueList& Value::mutableList() {
  if (!isList()) data_ = ValueList{};
  return std::get<ValueList>(data_);
}

ValueMap& Value::mutableMap() {
  if (!isMap()) data_ = ValueMap{};
  return std::get<ValueMap>(data_);
}

const Value& Value::operator[](const std::string& key) const {
  const auto& m = map();
  auto it = m.find(key);
  return it == m.end() ? kNull : it->second;
}

std::optional<std::string> getString(const ValueMap& map, const std::string& key) {
  auto it = map.find(key);
  return it == map.end() ? std::nullopt : it->second.asString();
}

std::optional<int64_t> getInt(const ValueMap& map, const std::string& key) {
  auto it = map.find(key);
  return it == map.end() ? std::nullopt : it->second.asInt();
}

std::optional<bool> getBool(const ValueMap& map, const std::string& key) {
  auto it = map.find(key);
  return it == map.end() ? std::nullopt : it->second.asBool();
}

ValueMap getMap(const ValueMap& map, const std::string& key) {
  auto it = map.find(key);
  return it == map.end() ? ValueMap{} : it->second.map();
}

ValueList getList(const ValueMap& map, const std::string& key) {
  auto it = map.find(key);
  return it == map.end() ? ValueList{} : it->second.list();
}

bool has(const ValueMap& map, const std::string& key) {
  auto it = map.find(key);
  return it != map.end() && !it->second.isNull();
}

}  // namespace awn
