#include <filesystem>

#include "awn/json.h"
#include "awn/method_router.h"
#include "awn_localizations/localizations.h"
#include "awn_test.h"

using namespace awn;
using namespace awn_localizations;

namespace {

class FakePresenter : public NotificationPresenter {
 public:
  std::vector<BuiltNotification> presented;
  std::filesystem::path directory;

  void present(const BuiltNotification& built, std::function<void(bool)> done) override {
    presented.push_back(built);
    done(true);
  }
  void removeDelivered(const std::vector<int64_t>&) override {}
  void removeAllDelivered() override {}
  void removePending(const std::vector<int64_t>&) override {}
  void removeAllPending() override {}
  std::vector<int64_t> deliveredIds() override { return {}; }
  std::vector<int64_t> pendingIds() override { return {}; }
  bool isAllowed() override { return true; }
  void requestPermission(std::function<void(bool)> done) override { done(true); }
  std::string localTimeZone() override { return "UTC"; }
  int64_t utcOffset(const std::string&, TimePoint) override { return 0; }
  std::string systemLanguage() override { return "pt-BR"; }
  std::filesystem::path dataDirectory() override { return directory; }
};

class InlineDispatcher : public Dispatcher {
 public:
  void post(std::function<void()> work) override { work(); }
};

ValueMap translatable() {
  return ValueMap{
      {"content", ValueMap{{"id", 1}, {"title", "Hello"}, {"body", "World"}}},
      {"actionButtons", ValueList{ValueMap{{"key", "OK"}, {"label", "Ok"}},
                                  ValueMap{{"key", "NO"}, {"label", "No"}}}},
      {"localizations",
       ValueMap{{"pt", ValueMap{{"title", "Olá"},
                                {"body", ""},
                                {"buttonLabels", ValueMap{{"OK", "Certo"}}}}},
                {"es-ES", ValueMap{{"title", "Hola"}}}}}};
}

std::string str(const ValueMap& map, const char* key) { return getString(map, key).value_or(""); }

struct Harness {
  std::shared_ptr<FakePresenter> presenter = std::make_shared<FakePresenter>();
  AwesomeNotifications engine;
  AwesomeMethodRouter router{engine};

  explicit Harness(std::filesystem::path directory = {}) {
    presenter->directory = std::move(directory);
    NotificationBuilderRegistry::shared().clearForTest();
    AwesomeMethodHandlerRegistry::shared().clearForTest();
    engine.configure(presenter, std::make_shared<InlineDispatcher>(),
                     std::make_shared<NotificationStore>(), false);
    RegisterLocalizations(engine);
  }
  ~Harness() {
    NotificationBuilderRegistry::shared().clearForTest();
    AwesomeMethodHandlerRegistry::shared().clearForTest();
  }

  Value call(const std::string& method, Value arguments = Value()) {
    Value answer;
    router.handle(method, arguments, [&](const Value& v) { answer = v; });
    return answer;
  }
};

}  // namespace

TEST(MatchLanguageFallsBackByPrefix) {
  std::set<std::string> keys{"en", "pt", "pt-BR", "es_ES"};
  EXPECT_EQ(LocalizationTransformer::matchLanguage(keys, "PT-br").value_or(""), std::string("pt-BR"));
  EXPECT_EQ(LocalizationTransformer::matchLanguage(keys, "pt-pt").value_or(""), std::string("pt"));
  EXPECT_EQ(LocalizationTransformer::matchLanguage(keys, "es-es").value_or(""), std::string("es_ES"));
  EXPECT_EQ(LocalizationTransformer::matchLanguage(keys, "es").value_or(""), std::string("es_ES"));
  EXPECT_FALSE(LocalizationTransformer::matchLanguage(keys, "fr").has_value());
}

TEST(TransformOverridesTextsAndButtonLabels) {
  auto result = LocalizationTransformer::transform(translatable(), "pt-br");
  auto content = NotificationBuilder::content(result);
  EXPECT_EQ(str(content, "title"), std::string("Olá"));
  EXPECT_EQ(str(content, "body"), std::string("World"));  // empty translation keeps the original
  auto buttons = getList(result, "actionButtons");
  EXPECT_EQ(str(buttons[0].map(), "label"), std::string("Certo"));
  EXPECT_EQ(str(buttons[1].map(), "label"), std::string("No"));
}

TEST(TransformWithoutMatchKeepsTheModel) {
  auto model = translatable();
  EXPECT_TRUE(Value(LocalizationTransformer::transform(model, "fr")) == Value(model));
  ValueMap plain{{"content", ValueMap{{"id", 1}, {"title", "T"}}}};
  EXPECT_TRUE(Value(LocalizationTransformer::transform(plain, "pt")) == Value(plain));
}

TEST(TransformAcceptsJsonEncodedLocalizations) {
  ValueMap model = translatable();
  model["localizations"] = Json::encode(model["localizations"]);
  auto content = NotificationBuilder::content(LocalizationTransformer::transform(model, "es"));
  EXPECT_EQ(str(content, "title"), std::string("Hola"));
}

TEST(DefaultLanguageIsTheSystemOne) {
  Harness h;
  EXPECT_EQ(h.call("getLocalization").asString().value_or(""), std::string("pt-br"));
}

TEST(CreatedNotificationIsTranslatedForTheCurrentLanguage) {
  Harness h;
  EXPECT_EQ(h.call("setLocalization", Value("ES")).asBool().value_or(false), true);
  EXPECT_EQ(h.call("getLocalization").asString().value_or(""), std::string("es"));
  h.call("createNewNotification", Value(translatable()));
  EXPECT_EQ(h.presenter->presented.size(), size_t(1));
  auto content = NotificationBuilder::content(h.presenter->presented[0].model);
  EXPECT_EQ(str(content, "title"), std::string("Hola"));

  h.call("setLocalization");  // null → back to the system language
  EXPECT_EQ(h.call("getLocalization").asString().value_or(""), std::string("pt-br"));
}

TEST(LanguageIsPersisted) {
  auto dir = std::filesystem::temp_directory_path() / "awn_localization_test";
  std::filesystem::remove_all(dir);
  { Harness(dir).call("setLocalization", Value("de")); }
  EXPECT_EQ(Harness(dir).call("getLocalization").asString().value_or(""), std::string("de"));
  std::filesystem::remove_all(dir);
}

int main() { return awn_test::runAll(); }
