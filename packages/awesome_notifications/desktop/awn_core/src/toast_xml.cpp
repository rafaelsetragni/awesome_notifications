#include "awn/toast_xml.h"

#include <cstdio>

#include "awn/definitions.h"
#include "awn/notification_builder.h"
#include "awn/platform.h"

namespace awn {

std::string ToastXml::escape(const std::string& text) {
  std::string out;
  out.reserve(text.size());
  for (char c : text) {
    switch (c) {
      case '&': out += "&amp;"; break;
      case '<': out += "&lt;"; break;
      case '>': out += "&gt;"; break;
      case '"': out += "&quot;"; break;
      case '\'': out += "&apos;"; break;
      default: out += c;
    }
  }
  return out;
}

std::string ToastXml::fileUri(const std::string& path) {
  std::string out = "file:///";
  for (unsigned char c : path) {
    if (c == '\\') {
      out += '/';
    } else if (c == ' ' || c == '#' || c == '%' || c == '?') {
      char buf[4];
      std::snprintf(buf, sizeof(buf), "%%%02X", c);
      out += buf;
    } else {
      out += static_cast<char>(c);
    }
  }
  return out;
}

namespace {

std::string attr(const char* name, const std::string& value) {
  return std::string(" ") + name + "=\"" + ToastXml::escape(value) + "\"";
}

/// Silent actions run without bringing the app forward.
bool isBackground(ActionType type) {
  return type == ActionType::SilentAction || type == ActionType::SilentBackgroundAction ||
         type == ActionType::DismissAction;
}

}  // namespace

std::string ToastXml::render(const ValueMap& model, const ToastImages& images, bool silent) {
  ValueMap content = NotificationBuilder::content(model);
  int64_t id = NotificationBuilder::readId(content).value_or(0);
  std::string title = getString(content, defs::NOTIFICATION_TITLE).value_or("");
  std::string body = getString(content, defs::NOTIFICATION_BODY).value_or("");
  std::string summary = getString(content, defs::NOTIFICATION_SUMMARY).value_or("");
  bool rounded = getBool(content, defs::NOTIFICATION_ROUNDED_LARGE_ICON).value_or(false);
  ActionType contentAction =
      actionTypeFrom(getString(content, defs::NOTIFICATION_ACTION_TYPE).value_or(""));
  // A decorator's presentation hints (defs::presentation), when it set some.
  ValueMap hints = getMap(model, presentation::BLOCK);
  if (getBool(hints, presentation::SILENT).value_or(false)) silent = true;
  std::string scenario = getString(hints, presentation::TOAST_SCENARIO).value_or("");
  std::string audio = getString(hints, presentation::TOAST_AUDIO).value_or("");
  ValueMap buttonStyles = getMap(hints, presentation::TOAST_BUTTON_STYLES);

  std::string xml = "<toast" + attr("launch", LaunchArgs::encode(id));
  if (isBackground(contentAction)) xml += attr("activationType", "background");
  if (!scenario.empty()) xml += attr("scenario", scenario);
  xml += "><visual><binding template=\"ToastGeneric\">";
  if (!title.empty()) xml += "<text>" + escape(title) + "</text>";
  if (!body.empty()) xml += "<text>" + escape(body) + "</text>";
  if (!summary.empty()) xml += "<text placement=\"attribution\">" + escape(summary) + "</text>";
  if (!images.largeIcon.empty()) {
    xml += "<image placement=\"appLogoOverride\"" + attr("src", fileUri(images.largeIcon));
    if (rounded) xml += " hint-crop=\"circle\"";
    xml += "/>";
  }
  if (!images.bigPicture.empty()) xml += "<image" + attr("src", fileUri(images.bigPicture)) + "/>";
  xml += "</binding></visual>";

  // Buttons: disabled ones are left out (toasts have no disabled state); a
  // button that requires text gets an input box bound to it by its key.
  std::string inputs, actions;
  size_t count = 0;
  bool styled = false;
  for (const auto& entry : NotificationBuilder::actionButtons(model)) {
    if (count == kMaxButtons) break;
    const ValueMap& button = entry.map();
    std::string key = getString(button, defs::NOTIFICATION_BUTTON_KEY).value_or("");
    if (key.empty()) continue;
    if (!getBool(button, defs::NOTIFICATION_BUTTON_ENABLED).value_or(true)) continue;
    std::string label = getString(button, defs::NOTIFICATION_BUTTON_LABEL).value_or(key);
    ActionType type = NotificationBuilder::buttonActionType(button);
    bool requiresText = getBool(button, defs::NOTIFICATION_REQUIRE_INPUT_TEXT).value_or(false) ||
                        type == ActionType::InputField;

    if (requiresText) {
      inputs += "<input" + attr("id", key) + " type=\"text\"" + attr("placeHolderContent", label) +
                "/>";
    }
    actions += "<action" + attr("content", label) + attr("arguments", LaunchArgs::encode(id, key));
    if (isBackground(type)) actions += attr("activationType", "background");
    if (requiresText) actions += attr("hint-inputId", key);
    std::string style = getString(buttonStyles, key).value_or("");
    if (!style.empty()) {
      actions += attr("hint-buttonStyle", style);
      styled = true;
    } else if (getBool(button, defs::NOTIFICATION_IS_DANGEROUS_OPTION).value_or(false))
    {
      actions += " hint-buttonStyle=\"Critical\"";
      styled = true;
    }
    actions += "/>";
    ++count;
  }
  if (!actions.empty()) xml += "<actions>" + inputs + actions + "</actions>";
  // Button styles only apply when the toast opts in.
  if (styled) xml.insert(6, " useButtonStyle=\"true\"");

  if (silent) {
    xml += "<audio silent=\"true\"/>";
  } else if (!audio.empty()) {
    xml += "<audio" + attr("src", audio);
    if (getBool(hints, presentation::TOAST_AUDIO_LOOP).value_or(false)) xml += " loop=\"true\"";
    xml += "/>";
  }
  xml += "</toast>";
  return xml;
}

}  // namespace awn
