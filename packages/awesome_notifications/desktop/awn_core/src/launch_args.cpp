#include <cstdio>

#include "awn/platform.h"
#include "awn/value.h"

namespace awn {

namespace {
constexpr const char* kPrefix = "awn";

std::string percentEncode(const std::string& s) {
  std::string out;
  for (unsigned char c : s) {
    if ((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') || c == '-' ||
        c == '_' || c == '.' || c == '~') {
      out += static_cast<char>(c);
    } else {
      char buf[4];
      std::snprintf(buf, sizeof(buf), "%%%02X", c);
      out += buf;
    }
  }
  return out;
}

int hexValue(char c) {
  if (c >= '0' && c <= '9') return c - '0';
  if (c >= 'a' && c <= 'f') return c - 'a' + 10;
  if (c >= 'A' && c <= 'F') return c - 'A' + 10;
  return -1;
}

std::optional<std::string> percentDecode(const std::string& s) {
  std::string out;
  for (size_t i = 0; i < s.size(); ++i) {
    if (s[i] != '%') {
      out += s[i];
      continue;
    }
    if (i + 2 >= s.size()) return std::nullopt;
    int hi = hexValue(s[i + 1]), lo = hexValue(s[i + 2]);
    if (hi < 0 || lo < 0) return std::nullopt;
    out += static_cast<char>(hi * 16 + lo);
    i += 2;
  }
  return out;
}
}  // namespace

std::string LaunchArgs::encode(int64_t id, const std::string& buttonKey) {
  std::string out = std::string(kPrefix) + "&id=" + std::to_string(id);
  if (!buttonKey.empty()) out += "&btn=" + percentEncode(buttonKey);
  return out;
}

std::optional<LaunchArgs> LaunchArgs::decode(const std::string& arguments) {
  // Split on '&'; the first token must be the prefix.
  std::vector<std::string> parts;
  size_t start = 0;
  while (true) {
    size_t amp = arguments.find('&', start);
    parts.push_back(arguments.substr(start, amp - start));
    if (amp == std::string::npos) break;
    start = amp + 1;
  }
  if (parts.empty() || parts[0] != kPrefix) return std::nullopt;

  LaunchArgs result;
  bool hasId = false;
  for (size_t i = 1; i < parts.size(); ++i) {
    auto eq = parts[i].find('=');
    if (eq == std::string::npos) continue;
    std::string key = parts[i].substr(0, eq);
    std::string value = parts[i].substr(eq + 1);
    if (key == "id") {
      auto id = Value(value).asInt();
      if (!id) return std::nullopt;
      result.id = *id;
      hasId = true;
    } else if (key == "btn") {
      auto decoded = percentDecode(value);
      if (!decoded) return std::nullopt;
      result.buttonKey = *decoded;
    }
  }
  if (!hasId) return std::nullopt;
  return result;
}

}  // namespace awn
