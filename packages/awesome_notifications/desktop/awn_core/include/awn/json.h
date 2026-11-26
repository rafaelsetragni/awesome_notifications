#pragma once

#include <optional>
#include <string>

#include "awn/export.h"
#include "awn/value.h"

namespace awn {

/// Minimal JSON (RFC 8259) codec for `Value`, used to persist notification
/// models. Integers stay integers (no float round-trip); strings are UTF-8.
class AWN_API Json {
 public:
  static std::string encode(const Value& value);
  /// nullopt when `text` is not valid JSON.
  static std::optional<Value> decode(const std::string& text);
};

}  // namespace awn
