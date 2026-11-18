#pragma once

#include <filesystem>
#include <map>
#include <memory>
#include <mutex>
#include <optional>
#include <set>
#include <string>

#include "awn/awesome_notifications.h"
#include "awn/notification_builder.h"
#include "awn/registries.h"

namespace awn_localizations {

/// The language notifications are translated to: set from Dart, persisted in
/// the app's data folder, defaulting to the device language (lowercase BCP 47).
/// Same as the 0.12 Android manager: the code is only lowercased (an empty code
/// is stored as is).
class LocalizationManager {
 public:
  explicit LocalizationManager(awn::AwesomeNotifications& core);

  /// nullopt resets to the device language. False when it can't be stored.
  bool setLocalization(const std::optional<std::string>& languageCode);
  std::string getLocalization();

 private:
  std::filesystem::path file() const;
  std::string systemLanguage() const;

  awn::AwesomeNotifications& core_;
  std::mutex mutex_;
  std::optional<std::string> cached_;
};

/// The app's localized strings for `titleLocKey` / `bodyLocKey` — the desktop
/// counterpart of Android's `res/values*/strings.xml`. A folder of flat JSON
/// objects (key → text), shipped as Flutter assets:
///   <folder>/default.json   ≙ values/strings.xml
///   <folder>/pt.json        ≙ values-pt/strings.xml
///   <folder>/pt-BR.json     ≙ values-pt-rBR/strings.xml
/// Resolved like Android resources: language + region, then the language, then
/// the default file.
class LocalizedStrings {
 public:
  explicit LocalizedStrings(std::filesystem::path folder);

  std::optional<std::string> lookup(const std::string& languageCode, const std::string& key);

  /// The folder inside a Flutter app's assets (`data/flutter_assets/` next to
  /// the executable on Windows and Linux).
  static constexpr const char* kAssetFolder = "awesome_notifications/strings";

 private:
  const awn::ValueMap& file(const std::string& name);

  std::filesystem::path folder_;
  std::mutex mutex_;
  std::map<std::string, awn::ValueMap> cache_;
};

/// Translates a notification model for a language, like the 0.12 Android core:
///  1. `titleLocKey` / `bodyLocKey` → the app's localized strings (with
///     `titleLocArgs` / `bodyLocArgs`, formatted one argument at a time like
///     Java's String.format — a failure keeps the original text);
///  2. the entry of the model's `localizations` block matching the language
///     overrides title / body / summary / largeIcon / bigPicture and the action
///     button labels (`buttonLabels`).
class LocalizationTransformer {
 public:
  static awn::ValueMap transform(const awn::ValueMap& model, const std::string& languageCode,
                                 LocalizedStrings* strings = nullptr);
  /// Java's `String.format(format, arg)` for one String argument; nullopt where
  /// Java throws (e.g. a second placeholder, or `%d`).
  static std::optional<std::string> formatWithOneArgument(const std::string& format,
                                                          const std::string& argument);
  /// exact → key-as-prefix → code-as-prefix ("pt-br" falls back to "pt").
  static std::optional<std::string> matchLanguage(const std::set<std::string>& keys,
                                                  const std::string& languageCode);
};

/// Builder decorator (high priority = outermost): translates before the other
/// decorators (e.g. scheduling) see the model.
class LocalizationBuilder : public awn::NotificationBuilder {
 public:
  LocalizationBuilder(std::shared_ptr<awn::NotificationBuilder> inner,
                      std::shared_ptr<LocalizationManager> manager,
                      std::shared_ptr<LocalizedStrings> strings = nullptr);
  std::optional<awn::BuiltNotification> build(const awn::ValueMap& model) override;

 private:
  std::shared_ptr<LocalizationManager> manager_;
  std::shared_ptr<LocalizedStrings> strings_;
};

/// Answers setLocalization / getLocalization.
class LocalizationMethodHandler : public awn::AwesomeMethodHandler {
 public:
  explicit LocalizationMethodHandler(std::shared_ptr<LocalizationManager> manager);
  bool handle(const std::string& method, const awn::Value& arguments,
              awn::MethodResult result) override;

 private:
  std::shared_ptr<LocalizationManager> manager_;
};

inline constexpr int kLocalizationPriority = 100;

/// Registers the decorator + method handler in the core registries.
/// `stringsFolder` holds the loc-key strings (see LocalizedStrings); empty =
/// loc keys are not resolved.
void RegisterLocalizations(awn::AwesomeNotifications& core = awn::AwesomeNotifications::shared(),
                           std::filesystem::path stringsFolder = {});

}  // namespace awn_localizations
