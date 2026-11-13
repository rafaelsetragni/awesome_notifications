#include "awn_localizations/localizations.h"

#include <algorithm>
#include <cctype>
#include <fstream>
#include <sstream>
#include <system_error>

#include "awn/definitions.h"
#include "awn/json.h"

namespace awn_localizations {

using awn::Value;
using awn::ValueList;
using awn::ValueMap;

namespace {

constexpr const char* kLocalizations = "localizations";
constexpr const char* kButtonLabels = "buttonLabels";
constexpr const char* kLanguageCode = "languageCode";
constexpr const char* kTranslatable[] = {"title", "body", "summary", "largeIcon", "bigPicture"};

std::string lower(std::string text) {
  for (auto& c : text) c = static_cast<char>(std::tolower(static_cast<unsigned char>(c)));
  return text;
}

std::string normalized(const std::string& code) {
  std::string out = lower(code);
  std::replace(out.begin(), out.end(), '-', '_');
  return out;
}

bool startsWith(const std::string& text, const std::string& prefix) {
  return text.rfind(prefix, 0) == 0;
}

/// The `localizations` block, as a map or — for push/JSON payloads — a JSON string.
ValueMap localizationsOf(const ValueMap& model) {
  auto it = model.find(kLocalizations);
  if (it == model.end()) return {};
  if (it->second.isMap()) return it->second.map();
  if (auto json = it->second.asString()) {
    if (auto decoded = awn::Json::decode(*json)) return decoded->map();
  }
  return {};
}

}  // namespace

// MARK: - Manager

LocalizationManager::LocalizationManager(awn::AwesomeNotifications& core) : core_(core) {}

std::filesystem::path LocalizationManager::file() const {
  if (!core_.presenter()) return {};
  auto directory = core_.presenter()->dataDirectory();
  return directory.empty() ? std::filesystem::path() : directory / "localization.json";
}

std::string LocalizationManager::systemLanguage() const {
  return core_.presenter() ? lower(core_.presenter()->systemLanguage()) : "en";
}

bool LocalizationManager::setLocalization(const std::optional<std::string>& languageCode) {
  std::lock_guard<std::mutex> lock(mutex_);
  std::string code = lower(languageCode && !languageCode->empty() ? *languageCode
                                                                   : systemLanguage());
  cached_ = code;
  auto path = file();
  if (path.empty()) return true;  // in-memory only (tests)
  std::error_code ec;
  std::filesystem::create_directories(path.parent_path(), ec);
  std::ofstream out(path, std::ios::binary | std::ios::trunc);
  out << awn::Json::encode(Value(ValueMap{{kLanguageCode, code}}));
  return static_cast<bool>(out);
}

std::string LocalizationManager::getLocalization() {
  std::lock_guard<std::mutex> lock(mutex_);
  if (cached_) return *cached_;
  auto path = file();
  if (!path.empty()) {
    std::ifstream in(path, std::ios::binary);
    std::stringstream buffer;
    buffer << in.rdbuf();
    if (auto decoded = awn::Json::decode(buffer.str())) {
      if (auto code = awn::getString(decoded->map(), kLanguageCode)) {
        cached_ = *code;
        return *code;
      }
    }
  }
  return systemLanguage();
}

// MARK: - Transformer

std::optional<std::string> LocalizationTransformer::matchLanguage(
    const std::set<std::string>& keys, const std::string& languageCode) {
  std::string code = lower(languageCode);
  for (const auto& key : keys) {
    if (lower(key) == code) return key;
  }
  std::string wanted = normalized(code);
  std::optional<std::string> keyPrefix, codePrefix;
  // Descending, like the Android decorator, so the result is deterministic.
  for (auto it = keys.rbegin(); it != keys.rend(); ++it) {
    std::string key = normalized(*it);
    if (key == wanted) return *it;
    if (startsWith(key, wanted + "_")) {
      keyPrefix = *it;
    } else if (startsWith(wanted, key + "_")) {
      codePrefix = *it;
    }
  }
  return keyPrefix ? keyPrefix : codePrefix;
}

ValueMap LocalizationTransformer::transform(const ValueMap& model,
                                            const std::string& languageCode) {
  ValueMap localizations = localizationsOf(model);
  if (localizations.empty()) return model;

  std::set<std::string> keys;
  for (const auto& entry : localizations) keys.insert(entry.first);
  auto matched = matchLanguage(keys, languageCode);
  if (!matched) return model;
  const ValueMap& localization = localizations[*matched].map();
  if (localization.empty()) return model;

  ValueMap result = model;
  ValueMap content = awn::NotificationBuilder::content(model);
  for (const char* key : kTranslatable) {
    auto text = awn::getString(localization, key);
    if (text && !text->empty()) content[key] = *text;
  }
  result[awn::defs::NOTIFICATION_CONTENT] = std::move(content);

  ValueMap labels = awn::getMap(localization, kButtonLabels);
  if (!labels.empty() && awn::has(model, awn::defs::NOTIFICATION_BUTTONS)) {
    ValueList buttons;
    for (const auto& entry : awn::getList(model, awn::defs::NOTIFICATION_BUTTONS)) {
      ValueMap button = entry.map();
      auto key = awn::getString(button, awn::defs::NOTIFICATION_BUTTON_KEY);
      auto label = key ? awn::getString(labels, *key) : std::nullopt;
      if (label && !label->empty()) button[awn::defs::NOTIFICATION_BUTTON_LABEL] = *label;
      buttons.push_back(Value(std::move(button)));
    }
    result[awn::defs::NOTIFICATION_BUTTONS] = std::move(buttons);
  }
  return result;
}

// MARK: - Builder / handler

LocalizationBuilder::LocalizationBuilder(std::shared_ptr<awn::NotificationBuilder> inner,
                                         std::shared_ptr<LocalizationManager> manager)
    : awn::NotificationBuilder(std::move(inner)), manager_(std::move(manager)) {}

std::optional<awn::BuiltNotification> LocalizationBuilder::build(const ValueMap& model) {
  return next(LocalizationTransformer::transform(model, manager_->getLocalization()));
}

LocalizationMethodHandler::LocalizationMethodHandler(std::shared_ptr<LocalizationManager> manager)
    : manager_(std::move(manager)) {}

bool LocalizationMethodHandler::handle(const std::string& method, const Value& arguments,
                                       awn::MethodResult result) {
  if (method == "setLocalization") {
    result(Value(manager_->setLocalization(arguments.asString())));
    return true;
  }
  if (method == "getLocalization") {
    result(Value(manager_->getLocalization()));
    return true;
  }
  return false;
}

void RegisterLocalizations(awn::AwesomeNotifications& core) {
  auto manager = std::make_shared<LocalizationManager>(core);
  awn::NotificationBuilderRegistry::shared().registerDecorator(
      kLocalizationPriority, [manager](std::shared_ptr<awn::NotificationBuilder> inner) {
        return std::make_shared<LocalizationBuilder>(std::move(inner), manager);
      });
  awn::AwesomeMethodHandlerRegistry::shared().registerHandler(
      std::make_shared<LocalizationMethodHandler>(manager));
}

}  // namespace awn_localizations
