#include "awn/freedesktop.h"

#include <cctype>
#include <cstdio>
#include <map>

#include "awn/definitions.h"
#include "awn/notification_builder.h"
#include "awn/platform.h"

namespace awn {

namespace {

constexpr const char* kLocked = "locked";

/// The spec's categories closest to the Dart NotificationCategory values;
/// unmapped ones send no category.
const std::map<std::string, std::string>& categories() {
  static const std::map<std::string, std::string> map = {
      {"Email", "email.arrived"},   {"Message", "im.received"},
      {"Social", "im.received"},    {"Error", "device.error"},
      {"Transport", "transfer"},    {"Progress", "transfer"},
  };
  return map;
}

std::string decodeEntities(const std::string& text) {
  static const std::pair<const char*, char> entities[] = {
      {"&amp;", '&'}, {"&lt;", '<'}, {"&gt;", '>'}, {"&quot;", '"'}, {"&apos;", '\''},
      {"&#39;", '\''}, {"&nbsp;", ' '}};
  std::string out;
  for (size_t i = 0; i < text.size();) {
    bool replaced = false;
    if (text[i] == '&') {
      for (const auto& [name, c] : entities) {
        size_t n = std::char_traits<char>::length(name);
        if (text.compare(i, n, name) == 0) {
          out += c;
          i += n;
          replaced = true;
          break;
        }
      }
    }
    if (!replaced) out += text[i++];
  }
  return out;
}

std::string escapeMarkup(const std::string& text) {
  std::string out;
  for (char c : text) {
    switch (c) {
      case '&': out += "&amp;"; break;
      case '<': out += "&lt;"; break;
      case '>': out += "&gt;"; break;
      default: out += c;
    }
  }
  return out;
}

std::string lower(std::string text) {
  for (auto& c : text) c = static_cast<char>(std::tolower(static_cast<unsigned char>(c)));
  return text;
}

/// A tag's lowercase name ("b", "/b", "br") from the text between < and >.
std::string tagName(const std::string& inner) {
  size_t end = 0;
  while (end < inner.size() && !std::isspace(static_cast<unsigned char>(inner[end])) &&
         inner[end] != '/')
    ++end;
  if (!inner.empty() && inner[0] == '/') {
    size_t close = 1;
    while (close < inner.size() && std::isalnum(static_cast<unsigned char>(inner[close]))) ++close;
    return lower(inner.substr(0, close));
  }
  return lower(inner.substr(0, end));
}

/// A '<' opens a tag only when a name (or '/' / '!') follows; else it is text.
bool opensTag(const std::string& text, size_t i) {
  if (text[i] != '<' || i + 1 >= text.size()) return false;
  unsigned char next = static_cast<unsigned char>(text[i + 1]);
  return std::isalpha(next) || next == '/' || next == '!';
}

}  // namespace

int Freedesktop::urgencyOf(const std::string& importance) {
  if (importance == "None" || importance == "Min" || importance == "Low") return 0;
  if (importance == "Max") return 2;
  return 1;
}

std::string Freedesktop::plainText(const std::string& html) {
  std::string out;
  for (size_t i = 0; i < html.size(); ++i) {
    if (opensTag(html, i)) {
      size_t close = html.find('>', i);
      if (close == std::string::npos) {
        out += html.substr(i);
        break;
      }
      std::string name = tagName(html.substr(i + 1, close - i - 1));
      if (name == "br" || name == "/p") out += '\n';
      i = close;
    } else {
      out += html[i];
    }
  }
  return decodeEntities(out);
}

std::string Freedesktop::basicMarkup(const std::string& html) {
  std::string out;
  std::string text;
  auto flush = [&] {
    out += escapeMarkup(decodeEntities(text));
    text.clear();
  };
  for (size_t i = 0; i < html.size(); ++i) {
    if (opensTag(html, i)) {
      size_t close = html.find('>', i);
      if (close == std::string::npos) {
        text += html.substr(i);
        break;
      }
      std::string name = tagName(html.substr(i + 1, close - i - 1));
      flush();
      if (name == "b" || name == "i" || name == "u" || name == "/b" || name == "/i" ||
          name == "/u")
        out += "<" + name + ">";
      else if (name == "br" || name == "/p")
        out += '\n';
      i = close;
    } else {
      text += html[i];
    }
  }
  flush();
  return out;
}

std::string Freedesktop::fileUri(const std::string& path) {
  std::string out = "file://";
  for (unsigned char c : path) {
    if (std::isalnum(c) || c == '/' || c == '-' || c == '_' || c == '.' || c == '~') {
      out += static_cast<char>(c);
    } else {
      char buf[4];
      std::snprintf(buf, sizeof(buf), "%%%02X", c);
      out += buf;
    }
  }
  return out;
}

FreedesktopNotification Freedesktop::render(const ValueMap& model, const FreedesktopImages& images,
                                            bool silent, const std::string& importance,
                                            const std::set<std::string>& capabilities) {
  FreedesktopNotification out;
  ValueMap content = NotificationBuilder::content(model);
  int64_t id = NotificationBuilder::readId(content).value_or(0);
  bool markup = capabilities.count("body-markup") > 0;

  out.summary = plainText(getString(content, defs::NOTIFICATION_TITLE).value_or(""));
  std::string body = getString(content, defs::NOTIFICATION_BODY).value_or("");
  std::string summary = getString(content, defs::NOTIFICATION_SUMMARY).value_or("");
  // The spec has no summary line: it goes below the body, as a subtext.
  if (!summary.empty()) body += body.empty() ? summary : "\n" + summary;
  out.body = markup ? basicMarkup(body) : plainText(body);

  // One image slot is shown by every server: the big picture wins; the large
  // icon then becomes the app icon.
  if (!images.bigPicture.empty()) {
    out.imagePath = fileUri(images.bigPicture);
    if (!images.largeIcon.empty()) out.appIcon = fileUri(images.largeIcon);
  } else if (!images.largeIcon.empty()) {
    out.imagePath = fileUri(images.largeIcon);
  }

  out.urgency = urgencyOf(importance);
  out.suppressSound = silent;
  auto category = categories().find(getString(content, defs::NOTIFICATION_CATEGORY).value_or(""));
  if (category != categories().end()) out.category = category->second;
  out.resident = getBool(content, kLocked).value_or(false);

  if (capabilities.count("actions") == 0) return out;

  out.actions.emplace_back(kDefaultAction, "");
  for (const auto& entry : NotificationBuilder::actionButtons(model)) {
    const ValueMap& button = entry.map();
    std::string key = getString(button, defs::NOTIFICATION_BUTTON_KEY).value_or("");
    if (key.empty()) continue;
    if (!getBool(button, defs::NOTIFICATION_BUTTON_ENABLED).value_or(true)) continue;
    std::string label =
        plainText(getString(button, defs::NOTIFICATION_BUTTON_LABEL).value_or(key));
    ActionType type = NotificationBuilder::buttonActionType(button);
    if (type == ActionType::KeepOnTop) out.resident = true;
    bool requiresText = getBool(button, defs::NOTIFICATION_REQUIRE_INPUT_TEXT).value_or(false) ||
                        type == ActionType::InputField;

    std::string action = LaunchArgs::encode(id, key);
    // Only one button can be typed in place, and only where the server can.
    if (requiresText && out.inlineReplyAction.empty() && capabilities.count("inline-reply")) {
      out.inlineReplyAction = action;
      out.inlineReplyPlaceholder = label;
      out.actions.emplace_back(kInlineReplyAction, label);
      continue;
    }
    out.actions.emplace_back(action, label);
  }
  return out;
}

}  // namespace awn
