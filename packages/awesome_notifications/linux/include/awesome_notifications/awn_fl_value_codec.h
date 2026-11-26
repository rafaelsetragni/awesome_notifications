#pragma once

#include <flutter_linux/flutter_linux.h>

#include "awn/value.h"

namespace awesome_notifications {

/// Converts between Flutter's (Linux) codec values and the core's Flutter-free
/// `awn::Value`. Header-only so decorator plugins share it.
inline awn::Value ToAwnValue(FlValue* value) {
  if (value == nullptr) return awn::Value();
  switch (fl_value_get_type(value)) {
    case FL_VALUE_TYPE_BOOL:
      return awn::Value(static_cast<bool>(fl_value_get_bool(value)));
    case FL_VALUE_TYPE_INT:
      return awn::Value(static_cast<int64_t>(fl_value_get_int(value)));
    case FL_VALUE_TYPE_FLOAT:
      return awn::Value(fl_value_get_float(value));
    case FL_VALUE_TYPE_STRING:
      return awn::Value(std::string(fl_value_get_string(value)));
    case FL_VALUE_TYPE_LIST: {
      awn::ValueList list;
      for (size_t i = 0; i < fl_value_get_length(value); ++i)
        list.push_back(ToAwnValue(fl_value_get_list_value(value, i)));
      return awn::Value(std::move(list));
    }
    case FL_VALUE_TYPE_MAP: {
      awn::ValueMap map;
      for (size_t i = 0; i < fl_value_get_length(value); ++i) {
        FlValue* key = fl_value_get_map_key(value, i);
        if (fl_value_get_type(key) != FL_VALUE_TYPE_STRING) continue;
        map[fl_value_get_string(key)] = ToAwnValue(fl_value_get_map_value(value, i));
      }
      return awn::Value(std::move(map));
    }
    case FL_VALUE_TYPE_INT32_LIST: {
      awn::ValueList list;
      const int32_t* items = fl_value_get_int32_list(value);
      for (size_t i = 0; i < fl_value_get_length(value); ++i)
        list.push_back(awn::Value(static_cast<int64_t>(items[i])));
      return awn::Value(std::move(list));
    }
    case FL_VALUE_TYPE_INT64_LIST: {
      awn::ValueList list;
      const int64_t* items = fl_value_get_int64_list(value);
      for (size_t i = 0; i < fl_value_get_length(value); ++i)
        list.push_back(awn::Value(static_cast<int64_t>(items[i])));
      return awn::Value(std::move(list));
    }
    case FL_VALUE_TYPE_FLOAT_LIST: {
      awn::ValueList list;
      const double* items = fl_value_get_float_list(value);
      for (size_t i = 0; i < fl_value_get_length(value); ++i) list.push_back(awn::Value(items[i]));
      return awn::Value(std::move(list));
    }
    default:
      return awn::Value();
  }
}

/// A new FlValue (the caller owns the reference).
inline FlValue* ToFlValue(const awn::Value& value) {
  const auto& v = value.variant();
  if (auto b = std::get_if<bool>(&v)) return fl_value_new_bool(*b);
  if (auto i = std::get_if<int64_t>(&v)) return fl_value_new_int(*i);
  if (auto d = std::get_if<double>(&v)) return fl_value_new_float(*d);
  if (auto s = std::get_if<std::string>(&v)) return fl_value_new_string(s->c_str());
  if (auto l = std::get_if<awn::ValueList>(&v)) {
    FlValue* list = fl_value_new_list();
    for (const auto& item : *l) fl_value_append_take(list, ToFlValue(item));
    return list;
  }
  if (auto m = std::get_if<awn::ValueMap>(&v)) {
    FlValue* map = fl_value_new_map();
    for (const auto& [key, item] : *m) fl_value_set_string_take(map, key.c_str(), ToFlValue(item));
    return map;
  }
  return fl_value_new_null();
}

}  // namespace awesome_notifications
