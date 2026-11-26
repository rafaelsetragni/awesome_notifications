#include "awn/json.h"

#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <sstream>

namespace awn {

namespace {

void encodeString(const std::string& s, std::string& out) {
  out += '"';
  for (unsigned char c : s) {
    switch (c) {
      case '"': out += "\\\""; break;
      case '\\': out += "\\\\"; break;
      case '\b': out += "\\b"; break;
      case '\f': out += "\\f"; break;
      case '\n': out += "\\n"; break;
      case '\r': out += "\\r"; break;
      case '\t': out += "\\t"; break;
      default:
        if (c < 0x20) {
          char buf[8];
          std::snprintf(buf, sizeof(buf), "\\u%04x", c);
          out += buf;
        } else {
          out += static_cast<char>(c);
        }
    }
  }
  out += '"';
}

void encodeValue(const Value& value, std::string& out) {
  const auto& v = value.variant();
  if (std::holds_alternative<std::monostate>(v)) {
    out += "null";
  } else if (auto b = std::get_if<bool>(&v)) {
    out += *b ? "true" : "false";
  } else if (auto i = std::get_if<int64_t>(&v)) {
    out += std::to_string(*i);
  } else if (auto d = std::get_if<double>(&v)) {
    if (!std::isfinite(*d)) {
      out += "null";
    } else {
      char buf[32];
      std::snprintf(buf, sizeof(buf), "%.17g", *d);
      std::string s(buf);
      // Keep it a double on decode.
      if (s.find_first_of(".eE") == std::string::npos) s += ".0";
      out += s;
    }
  } else if (auto s = std::get_if<std::string>(&v)) {
    encodeString(*s, out);
  } else if (auto l = std::get_if<ValueList>(&v)) {
    out += '[';
    bool first = true;
    for (const auto& item : *l) {
      if (!first) out += ',';
      first = false;
      encodeValue(item, out);
    }
    out += ']';
  } else if (auto m = std::get_if<ValueMap>(&v)) {
    out += '{';
    bool first = true;
    for (const auto& [key, item] : *m) {
      if (!first) out += ',';
      first = false;
      encodeString(key, out);
      out += ':';
      encodeValue(item, out);
    }
    out += '}';
  }
}

class Parser {
 public:
  explicit Parser(const std::string& text) : s_(text) {}

  std::optional<Value> parseDocument() {
    auto value = parseValue(0);
    if (!value) return std::nullopt;
    skipWs();
    if (pos_ != s_.size()) return std::nullopt;
    return value;
  }

 private:
  static constexpr int kMaxDepth = 256;
  const std::string& s_;
  size_t pos_ = 0;

  void skipWs() {
    while (pos_ < s_.size() &&
           (s_[pos_] == ' ' || s_[pos_] == '\t' || s_[pos_] == '\n' || s_[pos_] == '\r'))
      ++pos_;
  }

  bool consume(const char* literal) {
    size_t n = std::char_traits<char>::length(literal);
    if (s_.compare(pos_, n, literal) != 0) return false;
    pos_ += n;
    return true;
  }

  std::optional<Value> parseValue(int depth) {
    if (depth > kMaxDepth) return std::nullopt;
    skipWs();
    if (pos_ >= s_.size()) return std::nullopt;
    char c = s_[pos_];
    if (c == '{') return parseObject(depth);
    if (c == '[') return parseArray(depth);
    if (c == '"') {
      auto str = parseString();
      if (!str) return std::nullopt;
      return Value(std::move(*str));
    }
    if (consume("true")) return Value(true);
    if (consume("false")) return Value(false);
    if (consume("null")) return Value();
    return parseNumber();
  }

  std::optional<Value> parseNumber() {
    size_t start = pos_;
    if (pos_ < s_.size() && s_[pos_] == '-') ++pos_;
    bool isDouble = false;
    bool digits = false;
    while (pos_ < s_.size()) {
      char c = s_[pos_];
      if (c >= '0' && c <= '9') {
        digits = true;
      } else if (c == '.' || c == 'e' || c == 'E' || c == '+' ||
                 (c == '-' && pos_ > start)) {
        isDouble = true;
      } else {
        break;
      }
      ++pos_;
    }
    if (!digits) return std::nullopt;
    std::string token = s_.substr(start, pos_ - start);
    char* end = nullptr;
    if (!isDouble) {
      long long v = std::strtoll(token.c_str(), &end, 10);
      if (*end == '\0') return Value(static_cast<int64_t>(v));
    }
    double d = std::strtod(token.c_str(), &end);
    if (*end != '\0') return std::nullopt;
    return Value(d);
  }

  static void appendUtf8(uint32_t cp, std::string& out) {
    if (cp < 0x80) {
      out += static_cast<char>(cp);
    } else if (cp < 0x800) {
      out += static_cast<char>(0xC0 | (cp >> 6));
      out += static_cast<char>(0x80 | (cp & 0x3F));
    } else if (cp < 0x10000) {
      out += static_cast<char>(0xE0 | (cp >> 12));
      out += static_cast<char>(0x80 | ((cp >> 6) & 0x3F));
      out += static_cast<char>(0x80 | (cp & 0x3F));
    } else {
      out += static_cast<char>(0xF0 | (cp >> 18));
      out += static_cast<char>(0x80 | ((cp >> 12) & 0x3F));
      out += static_cast<char>(0x80 | ((cp >> 6) & 0x3F));
      out += static_cast<char>(0x80 | (cp & 0x3F));
    }
  }

  std::optional<uint32_t> parseHex4() {
    if (pos_ + 4 > s_.size()) return std::nullopt;
    uint32_t v = 0;
    for (int i = 0; i < 4; ++i) {
      char c = s_[pos_++];
      v <<= 4;
      if (c >= '0' && c <= '9') v |= static_cast<uint32_t>(c - '0');
      else if (c >= 'a' && c <= 'f') v |= static_cast<uint32_t>(c - 'a' + 10);
      else if (c >= 'A' && c <= 'F') v |= static_cast<uint32_t>(c - 'A' + 10);
      else return std::nullopt;
    }
    return v;
  }

  std::optional<std::string> parseString() {
    ++pos_;  // opening quote
    std::string out;
    while (pos_ < s_.size()) {
      char c = s_[pos_++];
      if (c == '"') return out;
      if (c != '\\') {
        out += c;
        continue;
      }
      if (pos_ >= s_.size()) return std::nullopt;
      char e = s_[pos_++];
      switch (e) {
        case '"': out += '"'; break;
        case '\\': out += '\\'; break;
        case '/': out += '/'; break;
        case 'b': out += '\b'; break;
        case 'f': out += '\f'; break;
        case 'n': out += '\n'; break;
        case 'r': out += '\r'; break;
        case 't': out += '\t'; break;
        case 'u': {
          auto cp = parseHex4();
          if (!cp) return std::nullopt;
          uint32_t code = *cp;
          if (code >= 0xD800 && code <= 0xDBFF && consume("\\u")) {
            auto low = parseHex4();
            if (!low) return std::nullopt;
            code = 0x10000 + ((code - 0xD800) << 10) + (*low - 0xDC00);
          }
          appendUtf8(code, out);
          break;
        }
        default:
          return std::nullopt;
      }
    }
    return std::nullopt;
  }

  std::optional<Value> parseArray(int depth) {
    ++pos_;
    ValueList list;
    skipWs();
    if (pos_ < s_.size() && s_[pos_] == ']') {
      ++pos_;
      return Value(std::move(list));
    }
    while (true) {
      auto item = parseValue(depth + 1);
      if (!item) return std::nullopt;
      list.push_back(std::move(*item));
      skipWs();
      if (pos_ >= s_.size()) return std::nullopt;
      if (s_[pos_] == ',') { ++pos_; continue; }
      if (s_[pos_] == ']') { ++pos_; return Value(std::move(list)); }
      return std::nullopt;
    }
  }

  std::optional<Value> parseObject(int depth) {
    ++pos_;
    ValueMap map;
    skipWs();
    if (pos_ < s_.size() && s_[pos_] == '}') {
      ++pos_;
      return Value(std::move(map));
    }
    while (true) {
      skipWs();
      if (pos_ >= s_.size() || s_[pos_] != '"') return std::nullopt;
      auto key = parseString();
      if (!key) return std::nullopt;
      skipWs();
      if (pos_ >= s_.size() || s_[pos_] != ':') return std::nullopt;
      ++pos_;
      auto item = parseValue(depth + 1);
      if (!item) return std::nullopt;
      map[*key] = std::move(*item);
      skipWs();
      if (pos_ >= s_.size()) return std::nullopt;
      if (s_[pos_] == ',') { ++pos_; continue; }
      if (s_[pos_] == '}') { ++pos_; return Value(std::move(map)); }
      return std::nullopt;
    }
  }
};

}  // namespace

std::string Json::encode(const Value& value) {
  std::string out;
  encodeValue(value, out);
  return out;
}

std::optional<Value> Json::decode(const std::string& text) {
  return Parser(text).parseDocument();
}

}  // namespace awn
