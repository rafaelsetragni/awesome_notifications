#include <filesystem>
#include <fstream>

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

  explicit Harness(std::filesystem::path directory = {}, std::filesystem::path strings = {}) {
    presenter->directory = std::move(directory);
    NotificationBuilderRegistry::shared().clearForTest();
    AwesomeMethodHandlerRegistry::shared().clearForTest();
    engine.configure(presenter, std::make_shared<InlineDispatcher>(),
                     std::make_shared<NotificationStore>(), false);
    RegisterLocalizations(engine, std::move(strings));
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

TEST(EmptyCodeIsStoredAsIs) {
  // 0.12 Android stores "" instead of falling back to the system language.
  Harness h;
  EXPECT_EQ(h.call("setLocalization", Value("")).asBool().value_or(false), true);
  EXPECT_EQ(h.call("getLocalization").asString().value_or("?"), std::string(""));
}

TEST(NonStringCodeResetsToTheSystemLanguage) {
  Harness h;
  h.call("setLocalization", Value("es"));
  h.call("setLocalization", Value(int64_t(1)));
  EXPECT_EQ(h.call("getLocalization").asString().value_or(""), std::string("pt-br"));
}

TEST(ModelWithoutContentIsUntouched) {
  ValueMap model{{"localizations", ValueMap{{"pt", ValueMap{{"title", "Olá"}}}}}};
  EXPECT_TRUE(Value(LocalizationTransformer::transform(model, "pt")) == Value(model));
}

TEST(NonMapTranslationIsIgnored) {
  ValueMap model{{"content", ValueMap{{"title", "Hello"}}},
                 {"localizations", ValueMap{{"pt", "Olá"}}}};
  auto content = NotificationBuilder::content(LocalizationTransformer::transform(model, "pt"));
  EXPECT_EQ(str(content, "title"), std::string("Hello"));
}

// MARK: - Java String.format with one argument (0.12 Android loc args)

namespace {
std::string fmt(const char* format, const char* argument = "Ana") {
  return LocalizationTransformer::formatWithOneArgument(format, argument).value_or("<fails>");
}
}  // namespace

TEST(FormatsLikeJavaStringFormat) {
  EXPECT_EQ(fmt("Olá, %s!"), std::string("Olá, Ana!"));
  EXPECT_EQ(fmt("no placeholder"), std::string("no placeholder"));
  EXPECT_EQ(fmt("100%%"), std::string("100%"));
  EXPECT_EQ(fmt("a%nb"), std::string("a\nb"));
  EXPECT_EQ(fmt("%1$s e %1$s"), std::string("Ana e Ana"));
  EXPECT_EQ(fmt("%s e %<s"), std::string("Ana e Ana"));
  EXPECT_EQ(fmt("[%5s]"), std::string("[  Ana]"));
  EXPECT_EQ(fmt("[%-5s]"), std::string("[Ana  ]"));
  EXPECT_EQ(fmt("[%.2s]"), std::string("[An]"));
  EXPECT_EQ(fmt("[%4.1s]"), std::string("[   A]"));
  EXPECT_EQ(fmt("%S"), std::string("ANA"));
  EXPECT_EQ(fmt("%b %B"), std::string("<fails>"));  // the second one has no argument
  EXPECT_EQ(fmt("%b"), std::string("true"));
  EXPECT_EQ(fmt("%h"), std::string("101b4"));  // "Ana".hashCode() = 65972
  EXPECT_EQ(fmt("%H", "ação"), std::string("2F9712"));
}

TEST(FormatFailsWhereJavaThrows) {
  EXPECT_EQ(fmt("%s tem %s novidades"), std::string("<fails>"));  // MissingFormatArgument
  EXPECT_EQ(fmt("%2$s"), std::string("<fails>"));
  EXPECT_EQ(fmt("%<s"), std::string("<fails>"));
  EXPECT_EQ(fmt("%d"), std::string("<fails>"));  // IllegalFormatConversion
  EXPECT_EQ(fmt("%f"), std::string("<fails>"));
  EXPECT_EQ(fmt("%tY"), std::string("<fails>"));
  EXPECT_EQ(fmt("%q"), std::string("<fails>"));  // UnknownFormatConversion
  EXPECT_EQ(fmt("50% off"), std::string("<fails>"));
  EXPECT_EQ(fmt("100%"), std::string("<fails>"));
  EXPECT_EQ(fmt("%-s"), std::string("<fails>"));  // MissingFormatWidth
  EXPECT_EQ(fmt("%#s"), std::string("<fails>"));
  EXPECT_EQ(fmt("%05s"), std::string("<fails>"));
  EXPECT_EQ(fmt("%.1%"), std::string("<fails>"));
}

// MARK: - Loc keys (the app's strings, like Android's res/values*/strings.xml)

namespace {

std::filesystem::path writeStrings() {
  auto dir = std::filesystem::temp_directory_path() / "awn_localization_strings_test";
  std::filesystem::remove_all(dir);
  std::filesystem::create_directories(dir);
  auto write = [&](const char* name, const char* json) {
    std::ofstream(dir / name, std::ios::binary) << json;
  };
  write("default.json",
        R"({"compat_greeting":"Hi, %@!","compat_news":"%@ has %@ news","compat_plain":"Plain text",)"
        R"("empty_es":"Default","escaped":"\\%@ stays"})");
  write("pt-BR.json",
        R"({"compat_greeting":"Olá, %@!","compat_news":"%@ tem %@ novidades","compat_plain":"Texto simples"})");
  write("es.json", R"({"compat_greeting":"¡Hola, %@!","empty_es":""})");
  write("broken.json", "not json");
  return dir;
}

ValueMap shownContent(Harness& h, const char* language, ValueMap content) {
  h.call("setLocalization", Value(language));
  content["id"] = 1;
  if (!has(content, "title")) content["title"] = "Hello";
  ValueMap model{{"content", content}};
  if (auto block = content.find("localizations"); block != content.end()) {
    model["localizations"] = block->second;
    model["content"].mutableMap().erase("localizations");
  }
  h.presenter->presented.clear();
  h.call("createNewNotification", Value(model));
  if (h.presenter->presented.empty()) return {};
  return NotificationBuilder::content(h.presenter->presented[0].model);
}

}  // namespace

TEST(LocKeysWithOneArgument) {
  auto dir = writeStrings();
  Harness h({}, dir);
  auto shown = shownContent(h, "pt-br", ValueMap{{"titleLocKey", "compat_greeting"},
                                                 {"titleLocArgs", ValueList{"Ana"}},
                                                 {"bodyLocKey", "compat_plain"}});
  EXPECT_EQ(str(shown, "title"), std::string("Olá, Ana!"));
  EXPECT_EQ(str(shown, "body"), std::string("Texto simples"));
  std::filesystem::remove_all(dir);
}

TEST(LocKeysFollowTheChosenLanguageThenTheDefault) {
  auto dir = writeStrings();
  Harness h({}, dir);
  ValueMap greeting{{"titleLocKey", "compat_greeting"}, {"titleLocArgs", ValueList{"Ana"}},
                    {"bodyLocKey", "compat_plain"}};
  auto es = shownContent(h, "es", greeting);
  EXPECT_EQ(str(es, "title"), std::string("¡Hola, Ana!"));
  EXPECT_EQ(str(es, "body"), std::string("Plain text"));  // missing in es → default
  EXPECT_EQ(str(shownContent(h, "es-mx", greeting), "title"), std::string("¡Hola, Ana!"));
  EXPECT_EQ(str(shownContent(h, "pt", greeting), "title"), std::string("Hi, Ana!"));  // no pt file
  EXPECT_EQ(str(shownContent(h, "fr", greeting), "title"), std::string("Hi, Ana!"));
  EXPECT_EQ(str(shownContent(h, "", greeting), "title"), std::string("Hi, Ana!"));
  // "pt_br" is not split on "_" (Locale("pt_br") has no resources).
  EXPECT_EQ(str(shownContent(h, "PT_BR", greeting), "title"), std::string("Hi, Ana!"));
  std::filesystem::remove_all(dir);
}

TEST(LocKeyFailuresKeepTheOriginal) {
  auto dir = writeStrings();
  Harness h({}, dir);
  // 0.12 Android formats one argument at a time: two placeholders fail.
  EXPECT_EQ(str(shownContent(h, "pt-br", ValueMap{{"titleLocKey", "compat_news"},
                                                  {"titleLocArgs", ValueList{"Ana", "3"}}}),
                "title"),
            std::string("Hello"));
  EXPECT_EQ(str(shownContent(h, "pt-br", ValueMap{{"titleLocKey", "compat_missing"}}), "title"),
            std::string("Hello"));
  // An empty text in the language's file is used (no fallback), then dropped.
  EXPECT_EQ(str(shownContent(h, "es", ValueMap{{"titleLocKey", "empty_es"}}), "title"),
            std::string("Hello"));
  EXPECT_EQ(str(shownContent(h, "pt-br", ValueMap{{"titleLocKey", ""}}), "title"),
            std::string("Hello"));
  std::filesystem::remove_all(dir);
}

TEST(LocKeyWithoutArgumentsKeepsThePlaceholders) {
  auto dir = writeStrings();
  Harness h({}, dir);
  EXPECT_EQ(str(shownContent(h, "pt-br", ValueMap{{"titleLocKey", "compat_greeting"}}), "title"),
            std::string("Olá, %s!"));
  EXPECT_EQ(str(shownContent(h, "en", ValueMap{{"titleLocKey", "escaped"}}), "title"),
            std::string("\\%@ stays"));
  std::filesystem::remove_all(dir);
}

TEST(LocalizationsBlockWinsOverTheKey) {
  auto dir = writeStrings();
  Harness h({}, dir);
  auto shown = shownContent(
      h, "pt-br",
      ValueMap{{"titleLocKey", "compat_greeting"},
               {"titleLocArgs", ValueList{"Ana"}},
               {"bodyLocKey", "compat_plain"},
               {"localizations", ValueMap{{"pt-br", ValueMap{{"title", "Do bloco"}}}}}});
  EXPECT_EQ(str(shown, "title"), std::string("Do bloco"));
  EXPECT_EQ(str(shown, "body"), std::string("Texto simples"));
  std::filesystem::remove_all(dir);
}

TEST(WithoutAStringsFolderLocKeysAreIgnored) {
  Harness h;
  EXPECT_EQ(str(shownContent(h, "pt-br", ValueMap{{"titleLocKey", "compat_greeting"}}), "title"),
            std::string("Hello"));
}

int main() { return awn_test::runAll(); }
