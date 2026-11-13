#pragma once

#include <filesystem>
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

/// Translates a notification model for a language: the entry of the model's
/// `localizations` block matching the language overrides title / body / summary
/// / largeIcon / bigPicture and the action button labels (`buttonLabels`).
/// Same rules as the Android decorator. (Desktop has no string resources, so
/// `titleLocKey` / `bodyLocKey` are not resolved there.)
class LocalizationTransformer {
 public:
  static awn::ValueMap transform(const awn::ValueMap& model, const std::string& languageCode);
  /// exact → key-as-prefix → code-as-prefix ("pt-br" falls back to "pt").
  static std::optional<std::string> matchLanguage(const std::set<std::string>& keys,
                                                  const std::string& languageCode);
};

/// Builder decorator (high priority = outermost): translates before the other
/// decorators (e.g. scheduling) see the model.
class LocalizationBuilder : public awn::NotificationBuilder {
 public:
  LocalizationBuilder(std::shared_ptr<awn::NotificationBuilder> inner,
                      std::shared_ptr<LocalizationManager> manager);
  std::optional<awn::BuiltNotification> build(const awn::ValueMap& model) override;

 private:
  std::shared_ptr<LocalizationManager> manager_;
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
void RegisterLocalizations(awn::AwesomeNotifications& core = awn::AwesomeNotifications::shared());

}  // namespace awn_localizations
