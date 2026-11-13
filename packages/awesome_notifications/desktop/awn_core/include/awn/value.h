#pragma once

#include <cstdint>
#include <map>
#include <optional>
#include <string>
#include <variant>
#include <vector>

#include "awn/export.h"

namespace awn {

class Value;
using ValueList = std::vector<Value>;
using ValueMap = std::map<std::string, Value>;

/// A Flutter-free dynamic value: the shape of everything that crosses the method
/// channel (null, bool, int, double, string, list, string-keyed map). The
/// platform bridges convert their native codec values to and from this type, so
/// the core never depends on Flutter.
class AWN_API Value {
 public:
  using Variant = std::variant<std::monostate, bool, int64_t, double, std::string,
                               ValueList, ValueMap>;

  Value() = default;
  Value(std::nullptr_t) {}
  Value(bool v) : data_(v) {}
  Value(int v) : data_(static_cast<int64_t>(v)) {}
  Value(int64_t v) : data_(v) {}
  Value(double v) : data_(v) {}
  Value(const char* v) : data_(std::string(v)) {}
  Value(std::string v) : data_(std::move(v)) {}
  Value(ValueList v) : data_(std::move(v)) {}
  Value(ValueMap v) : data_(std::move(v)) {}

  bool isNull() const { return std::holds_alternative<std::monostate>(data_); }
  bool isBool() const { return std::holds_alternative<bool>(data_); }
  bool isInt() const { return std::holds_alternative<int64_t>(data_); }
  bool isDouble() const { return std::holds_alternative<double>(data_); }
  bool isString() const { return std::holds_alternative<std::string>(data_); }
  bool isList() const { return std::holds_alternative<ValueList>(data_); }
  bool isMap() const { return std::holds_alternative<ValueMap>(data_); }

  const Variant& variant() const { return data_; }

  /// Lenient readers, mirroring the Apple core's MapUtils: numbers and numeric
  /// strings read as ints, "true"/"false" strings read as bools.
  std::optional<int64_t> asInt() const;
  std::optional<double> asDouble() const;
  std::optional<bool> asBool() const;
  std::optional<std::string> asString() const;

  /// Typed access; an empty list / map when the value has another type.
  const ValueList& list() const;
  const ValueMap& map() const;
  ValueList& mutableList();
  /// Turns a non-map value into an empty map first.
  ValueMap& mutableMap();

  /// Map lookup; a null value when absent or when this is not a map.
  const Value& operator[](const std::string& key) const;

  bool operator==(const Value& other) const { return data_ == other.data_; }
  bool operator!=(const Value& other) const { return !(*this == other); }

 private:
  Variant data_;
};

/// Map helpers used throughout the core.
AWN_API std::optional<std::string> getString(const ValueMap& map, const std::string& key);
AWN_API std::optional<int64_t> getInt(const ValueMap& map, const std::string& key);
AWN_API std::optional<bool> getBool(const ValueMap& map, const std::string& key);
/// The sub-map at `key`, or an empty map.
AWN_API ValueMap getMap(const ValueMap& map, const std::string& key);
/// The list at `key`, or an empty list.
AWN_API ValueList getList(const ValueMap& map, const std::string& key);
AWN_API bool has(const ValueMap& map, const std::string& key);

}  // namespace awn
