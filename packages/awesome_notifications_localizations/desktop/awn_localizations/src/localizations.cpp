#include "awn_localizations/localizations.h"

#include <algorithm>
#include <cctype>
#include <cstdint>
#include <fstream>
#include <sstream>
#include <system_error>
#include <vector>

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
constexpr const char* kTitle = "title";
constexpr const char* kBody = "body";
constexpr const char* kTitleLocKey = "titleLocKey";
constexpr const char* kBodyLocKey = "bodyLocKey";
constexpr const char* kTitleLocArgs = "titleLocArgs";
constexpr const char* kBodyLocArgs = "bodyLocArgs";

std::string lower(std::string text) {
  for (auto& c : text) c = static_cast<char>(std::tolower(static_cast<unsigned char>(c)));
  return text;
}

std::string upper(std::string text) {
  for (auto& c : text) c = static_cast<char>(std::toupper(static_cast<unsigned char>(c)));
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

/// UTF-8 text split into code points (Java counts width / precision in chars).
std::vector<std::string> codePoints(const std::string& text) {
  std::vector<std::string> out;
  for (size_t i = 0; i < text.size();) {
    auto lead = static_cast<unsigned char>(text[i]);
    size_t length = lead < 0x80 ? 1 : (lead >> 5) == 0x6 ? 2 : (lead >> 4) == 0xE ? 3 : (lead >> 3) == 0x1E ? 4 : 1;
    length = std::min(length, text.size() - i);
    out.push_back(text.substr(i, length));
    i += length;
  }
  return out;
}

/// Java's String.hashCode() of a UTF-8 text (over its UTF-16 units).
uint32_t javaHashCode(const std::string& text) {
  uint32_t hash = 0;
  for (const auto& point : codePoints(text)) {
    auto byte = [&](size_t n) { return static_cast<uint32_t>(static_cast<unsigned char>(point[n])); };
    uint32_t code;
    switch (point.size()) {
      case 2: code = ((byte(0) & 0x1F) << 6) | (byte(1) & 0x3F); break;
      case 3: code = ((byte(0) & 0x0F) << 12) | ((byte(1) & 0x3F) << 6) | (byte(2) & 0x3F); break;
      case 4:
        code = ((byte(0) & 0x07) << 18) | ((byte(1) & 0x3F) << 12) | ((byte(2) & 0x3F) << 6) |
               (byte(3) & 0x3F);
        break;
      default: code = byte(0);
    }
    if (code >= 0x10000) {
      code -= 0x10000;
      hash = hash * 31 + (0xD800 + (code >> 10));
      hash = hash * 31 + (0xDC00 + (code & 0x3FF));
    } else {
      hash = hash * 31 + code;
    }
  }
  return hash;
}

/// The 0.12 Android conversion of iOS-style "%@" placeholders (not escaped by
/// a backslash) to "%s".
std::string iosPlaceholdersToJava(const std::string& text) {
  std::string out;
  for (size_t i = 0; i < text.size(); ++i) {
    if (text[i] == '%' && i + 1 < text.size() && text[i + 1] == '@' &&
        (i == 0 || text[i - 1] != '\\')) {
      out += "%s";
      ++i;
    } else {
      out += text[i];
    }
  }
  return out;
}

/// Kotlin's `arg.toString()` for a channel value.
std::string argumentText(const Value& argument) {
  if (auto text = argument.asString()) return *text;
  return awn::Json::encode(argument);
}

/// The localizations block, as a map or — for push/JSON payloads — a JSON string.
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
  std::string code = lower(languageCode ? *languageCode : systemLanguage());
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

std::optional<std::string> LocalizationTransformer::formatWithOneArgument(
    const std::string& format, const std::string& argument) {
  // %[index$][flags][width][.precision]conversion — java.util.Formatter.
  std::string out;
  int ordinaryIndex = 0;
  bool hasPrevious = false;
  auto digit = [&](size_t at) {
    return at < format.size() && std::isdigit(static_cast<unsigned char>(format[at]));
  };
  for (size_t i = 0; i < format.size();) {
    if (format[i] != '%') {
      out += format[i++];
      continue;
    }
    size_t j = i + 1;

    int explicitIndex = -1;
    size_t k = j;
    while (digit(k)) ++k;
    if (k > j && k < format.size() && format[k] == '$') {
      if (k - j > 9) return std::nullopt;
      explicitIndex = std::stoi(format.substr(j, k - j));
      j = k + 1;
    }

    std::string flags;
    while (j < format.size() && std::string("-#+ 0,(<").find(format[j]) != std::string::npos) {
      flags += format[j++];
    }
    auto hasFlag = [&](char flag) { return flags.find(flag) != std::string::npos; };

    int width = -1;
    k = j;
    while (digit(k)) ++k;
    if (k > j) {
      if (k - j > 9) return std::nullopt;
      width = std::stoi(format.substr(j, k - j));
      j = k;
    }

    int precision = -1;
    if (j < format.size() && format[j] == '.' && digit(j + 1)) {
      k = j + 1;
      while (digit(k)) ++k;
      if (k - j - 1 > 9) return std::nullopt;
      precision = std::stoi(format.substr(j + 1, k - j - 1));
      j = k;
    }

    if (j >= format.size()) return std::nullopt;  // UnknownFormatConversion
    char conversion = format[j];
    if (conversion == 't' || conversion == 'T') return std::nullopt;  // a date, not a String
    if (conversion != '%' && !std::isalpha(static_cast<unsigned char>(conversion))) {
      return std::nullopt;
    }
    i = j + 1;

    auto pad = [&](std::string text) -> std::optional<std::string> {
      if (hasFlag('-') && width < 0) return std::nullopt;  // MissingFormatWidth
      auto points = codePoints(text);
      if (precision >= 0 && static_cast<size_t>(precision) < points.size()) {
        text.clear();
        for (size_t n = 0; n < static_cast<size_t>(precision); ++n) text += points[n];
        points.resize(static_cast<size_t>(precision));
      }
      if (width > 0 && static_cast<size_t>(width) > points.size()) {
        std::string spaces(static_cast<size_t>(width) - points.size(), ' ');
        text = hasFlag('-') ? text + spaces : spaces + text;
      }
      return text;
    };

    if (conversion == '%') {
      if (precision >= 0) return std::nullopt;
      for (char flag : flags) {
        if (flag != '-') return std::nullopt;
      }
      auto text = pad("%");
      if (!text) return std::nullopt;
      out += *text;
      continue;
    }
    if (conversion == 'n') {
      if (!flags.empty() || width >= 0 || precision >= 0) return std::nullopt;
      out += '\n';
      continue;
    }

    std::string text;
    switch (conversion) {
      case 's': text = argument; break;
      case 'S': text = upper(argument); break;
      case 'b': text = "true"; break;  // any non-null, non-Boolean argument
      case 'B': text = "TRUE"; break;
      case 'h':
      case 'H': {
        std::ostringstream hex;
        hex << std::hex << javaHashCode(argument);
        text = conversion == 'H' ? upper(hex.str()) : hex.str();
        break;
      }
      default:
        // %d, %f, %c, … with a String argument: IllegalFormatConversion; any
        // other letter: UnknownFormatConversion.
        return std::nullopt;
    }
    for (char flag : flags) {
      if (flag != '-' && flag != '<') return std::nullopt;  // FormatFlagsConversionMismatch
    }

    // The single argument: ordinary (first only), explicit "1$" or previous "<".
    if (hasFlag('<')) {
      if (!hasPrevious) return std::nullopt;
    } else if (explicitIndex >= 0) {
      if (explicitIndex != 1) return std::nullopt;
    } else if (++ordinaryIndex > 1) {
      return std::nullopt;  // MissingFormatArgument
    }
    hasPrevious = true;

    auto padded = pad(text);
    if (!padded) return std::nullopt;
    out += *padded;
  }
  return out;
}

namespace {

/// 0.12 Android `getLocalizedString`: the key's text for the language, with
/// "%@" turned into "%s" and the arguments formatted one at a time; nullopt
/// (the original is kept) when the key is unknown, a format fails or the text
/// ends up empty.
std::optional<std::string> resolveLocKey(LocalizedStrings& strings, const std::string& languageCode,
                                         const ValueMap& content, const char* keyName,
                                         const char* argsName) {
  auto key = awn::getString(content, keyName);
  if (!key || key->empty()) return std::nullopt;
  auto text = strings.lookup(languageCode, *key);
  if (!text) return std::nullopt;
  std::string localized = iosPlaceholdersToJava(*text);
  auto args = content.find(argsName);
  if (args != content.end() && args->second.isList()) {
    for (const auto& argument : args->second.list()) {
      auto formatted = LocalizationTransformer::formatWithOneArgument(localized, argumentText(argument));
      if (!formatted) return std::nullopt;
      localized = *formatted;
    }
  }
  if (localized.empty()) return std::nullopt;
  return localized;
}

}  // namespace

ValueMap LocalizationTransformer::transform(const ValueMap& model, const std::string& languageCode,
                                            LocalizedStrings* strings) {
  auto contentEntry = model.find(awn::defs::NOTIFICATION_CONTENT);
  if (contentEntry == model.end() || !contentEntry->second.isMap()) return model;
  ValueMap content = contentEntry->second.map();

  // 1. Loc keys → the app's localized strings for the current language.
  if (strings) {
    if (auto title = resolveLocKey(*strings, languageCode, content, kTitleLocKey, kTitleLocArgs)) {
      content[kTitle] = *title;
    }
    if (auto body = resolveLocKey(*strings, languageCode, content, kBodyLocKey, kBodyLocArgs)) {
      content[kBody] = *body;
    }
  }

  // 2. The localizations block (overrides the loc-key result).
  std::optional<ValueList> translatedButtons;
  ValueMap localizations = localizationsOf(model);
  if (!localizations.empty()) {
    std::set<std::string> keys;
    for (const auto& entry : localizations) keys.insert(entry.first);
    auto matched = matchLanguage(keys, languageCode);
    if (matched && localizations[*matched].isMap()) {
      const ValueMap& localization = localizations[*matched].map();
      for (const char* key : kTranslatable) {
        auto text = awn::getString(localization, key);
        if (text && !text->empty()) content[key] = *text;
      }
      ValueMap labels = awn::getMap(localization, kButtonLabels);
      auto buttons = model.find(awn::defs::NOTIFICATION_BUTTONS);
      if (!labels.empty() && buttons != model.end() && buttons->second.isList()) {
        ValueList translated;
        for (const auto& entry : buttons->second.list()) {
          ValueMap button = entry.map();
          auto key = awn::getString(button, awn::defs::NOTIFICATION_BUTTON_KEY);
          auto label = key ? awn::getString(labels, *key) : std::nullopt;
          if (label && !label->empty()) button[awn::defs::NOTIFICATION_BUTTON_LABEL] = *label;
          translated.push_back(Value(std::move(button)));
        }
        translatedButtons = std::move(translated);
      }
    }
  }

  ValueMap result = model;
  result[awn::defs::NOTIFICATION_CONTENT] = std::move(content);
  if (translatedButtons) result[awn::defs::NOTIFICATION_BUTTONS] = std::move(*translatedButtons);
  return result;
}

// MARK: - Localized strings

LocalizedStrings::LocalizedStrings(std::filesystem::path folder) : folder_(std::move(folder)) {}

const ValueMap& LocalizedStrings::file(const std::string& name) {
  std::lock_guard<std::mutex> lock(mutex_);
  auto cached = cache_.find(name);
  if (cached != cache_.end()) return cached->second;
  ValueMap strings;
  std::ifstream in(folder_ / (name + ".json"), std::ios::binary);
  if (in) {
    std::stringstream buffer;
    buffer << in.rdbuf();
    if (auto decoded = awn::Json::decode(buffer.str())) strings = decoded->map();
  }
  return cache_.emplace(name, std::move(strings)).first->second;
}

std::optional<std::string> LocalizedStrings::lookup(const std::string& languageCode,
                                                    const std::string& key) {
  // Like Android's Locale(language, COUNTRY) from "<language>-<country>…".
  std::string language = languageCode.substr(0, languageCode.find('-'));
  std::string country;
  if (language.size() < languageCode.size()) {
    std::string rest = languageCode.substr(language.size() + 1);
    country = upper(rest.substr(0, rest.find('-')));
  }
  language = lower(language);

  std::vector<std::string> files;
  if (!language.empty()) {
    if (!country.empty()) files.push_back(language + "-" + country);
    files.push_back(language);
  }
  files.push_back("default");
  for (const auto& name : files) {
    if (auto text = awn::getString(file(name), key)) return text;
  }
  return std::nullopt;
}

// MARK: - Builder / handler

LocalizationBuilder::LocalizationBuilder(std::shared_ptr<awn::NotificationBuilder> inner,
                                         std::shared_ptr<LocalizationManager> manager,
                                         std::shared_ptr<LocalizedStrings> strings)
    : awn::NotificationBuilder(std::move(inner)),
      manager_(std::move(manager)),
      strings_(std::move(strings)) {}

std::optional<awn::BuiltNotification> LocalizationBuilder::build(const ValueMap& model) {
  return next(LocalizationTransformer::transform(model, manager_->getLocalization(), strings_.get()));
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

void RegisterLocalizations(awn::AwesomeNotifications& core, std::filesystem::path stringsFolder) {
  auto manager = std::make_shared<LocalizationManager>(core);
  auto strings = stringsFolder.empty()
                     ? nullptr
                     : std::make_shared<LocalizedStrings>(std::move(stringsFolder));
  awn::NotificationBuilderRegistry::shared().registerDecorator(
      kLocalizationPriority, [manager, strings](std::shared_ptr<awn::NotificationBuilder> inner) {
        return std::make_shared<LocalizationBuilder>(std::move(inner), manager, strings);
      });
  awn::AwesomeMethodHandlerRegistry::shared().registerHandler(
      std::make_shared<LocalizationMethodHandler>(manager));
}

}  // namespace awn_localizations
