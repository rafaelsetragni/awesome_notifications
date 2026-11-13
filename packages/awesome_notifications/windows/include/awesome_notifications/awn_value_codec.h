#pragma once

#include <flutter/encodable_value.h>

#include "awn/value.h"

namespace awesome_notifications {

/// Converts between Flutter's codec values and the core's Flutter-free
/// `awn::Value`. Header-only so decorator plugins share it.
inline awn::Value ToAwnValue(const flutter::EncodableValue& value) {
  if (auto v = std::get_if<bool>(&value)) return awn::Value(*v);
  if (auto v = std::get_if<int32_t>(&value)) return awn::Value(static_cast<int64_t>(*v));
  if (auto v = std::get_if<int64_t>(&value)) return awn::Value(*v);
  if (auto v = std::get_if<double>(&value)) return awn::Value(*v);
  if (auto v = std::get_if<std::string>(&value)) return awn::Value(*v);
  if (auto v = std::get_if<flutter::EncodableList>(&value)) {
    awn::ValueList list;
    for (const auto& item : *v) list.push_back(ToAwnValue(item));
    return awn::Value(std::move(list));
  }
  if (auto v = std::get_if<flutter::EncodableMap>(&value)) {
    awn::ValueMap map;
    for (const auto& [key, item] : *v) {
      if (auto k = std::get_if<std::string>(&key)) map[*k] = ToAwnValue(item);
    }
    return awn::Value(std::move(map));
  }
  if (auto v = std::get_if<std::vector<int32_t>>(&value)) {
    awn::ValueList list;
    for (auto item : *v) list.push_back(awn::Value(static_cast<int64_t>(item)));
    return awn::Value(std::move(list));
  }
  if (auto v = std::get_if<std::vector<int64_t>>(&value)) {
    awn::ValueList list;
    for (auto item : *v) list.push_back(awn::Value(item));
    return awn::Value(std::move(list));
  }
  if (auto v = std::get_if<std::vector<double>>(&value)) {
    awn::ValueList list;
    for (auto item : *v) list.push_back(awn::Value(item));
    return awn::Value(std::move(list));
  }
  return awn::Value();
}

inline flutter::EncodableValue ToEncodable(const awn::Value& value) {
  const auto& v = value.variant();
  if (auto b = std::get_if<bool>(&v)) return flutter::EncodableValue(*b);
  if (auto i = std::get_if<int64_t>(&v)) return flutter::EncodableValue(*i);
  if (auto d = std::get_if<double>(&v)) return flutter::EncodableValue(*d);
  if (auto s = std::get_if<std::string>(&v)) return flutter::EncodableValue(*s);
  if (auto l = std::get_if<awn::ValueList>(&v)) {
    flutter::EncodableList list;
    for (const auto& item : *l) list.push_back(ToEncodable(item));
    return flutter::EncodableValue(std::move(list));
  }
  if (auto m = std::get_if<awn::ValueMap>(&v)) {
    flutter::EncodableMap map;
    for (const auto& [key, item] : *m) map[flutter::EncodableValue(key)] = ToEncodable(item);
    return flutter::EncodableValue(std::move(map));
  }
  return flutter::EncodableValue();
}

}  // namespace awesome_notifications
