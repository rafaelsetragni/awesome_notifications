#include <filesystem>
#include <fstream>

#include "awn/date_utils.h"
#include "awn/displayed_tracker.h"
#include "awn/json.h"
#include "awn/notification_store.h"
#include "awn/platform.h"
#include "awn/toast_xml.h"
#include "awn/value.h"
#include "awn_test.h"

using namespace awn;

// MARK: - Value / JSON

TEST(ValueReadsLeniently) {
  EXPECT_EQ(Value("42").asInt().value_or(-1), 42);
  EXPECT_EQ(Value(7.9).asInt().value_or(-1), 7);
  EXPECT_FALSE(Value("4x").asInt().has_value());
  EXPECT_EQ(Value("true").asBool().value_or(false), true);
  EXPECT_FALSE(Value(1).asBool().has_value());
  EXPECT_TRUE(Value(ValueMap{{"a", 1}})["missing"].isNull());
}

TEST(JsonRoundTripKeepsTypes) {
  ValueMap model{{"content", ValueMap{{"id", 10},
                                      {"title", "Olá \"mundo\"\n"},
                                      {"ratio", 0.5},
                                      {"whole", 2.0},
                                      {"flag", true},
                                      {"none", nullptr}}},
                 {"actionButtons", ValueList{ValueMap{{"key", "OK"}}}}};
  auto encoded = Json::encode(Value(model));
  auto decoded = Json::decode(encoded);
  EXPECT_TRUE(decoded.has_value());
  EXPECT_TRUE(*decoded == Value(model));
  EXPECT_TRUE((*decoded)["content"]["whole"].isDouble());
  EXPECT_TRUE((*decoded)["content"]["id"].isInt());
}

TEST(JsonDecodesUnicodeEscapes) {
  auto decoded = Json::decode(R"({"s":"\u00e9\ud83d\ude00"})");
  EXPECT_TRUE(decoded.has_value());
  EXPECT_EQ((*decoded)["s"].asString().value_or(""), std::string("é\xF0\x9F\x98\x80"));
}

TEST(JsonRejectsGarbage) {
  EXPECT_FALSE(Json::decode("{\"a\":}").has_value());
  EXPECT_FALSE(Json::decode("[1,2").has_value());
  EXPECT_FALSE(Json::decode("{} x").has_value());
}

// MARK: - Dates

TEST(DatesRoundTripInUtc) {
  auto parsed = DateUtils::parseUtc("2026-07-05 08:30:15");
  EXPECT_TRUE(parsed.has_value());
  EXPECT_EQ(parsed->time_since_epoch().count(), int64_t(1783240215));
  EXPECT_EQ(DateUtils::formatUtc(*parsed), std::string("2026-07-05 08:30:15"));
  EXPECT_EQ(DateUtils::formatUtc(TimePoint(std::chrono::seconds(0))),
            std::string("1970-01-01 00:00:00"));
  EXPECT_FALSE(DateUtils::parseUtc("2026-07-05T08:30:15Z").has_value());
  EXPECT_FALSE(DateUtils::parseUtc("2026-13-05 08:30:15").has_value());
}

// MARK: - Launch args

TEST(LaunchArgsRoundTrip) {
  auto encoded = LaunchArgs::encode(12, "REPLY & go");
  EXPECT_EQ(encoded, std::string("awn&id=12&btn=REPLY%20%26%20go"));
  auto decoded = LaunchArgs::decode(encoded);
  EXPECT_TRUE(decoded.has_value());
  EXPECT_EQ(decoded->id, int64_t(12));
  EXPECT_EQ(decoded->buttonKey, std::string("REPLY & go"));

  auto tap = LaunchArgs::decode(LaunchArgs::encode(-3));
  EXPECT_EQ(tap->id, int64_t(-3));
  EXPECT_TRUE(tap->buttonKey.empty());
}

TEST(LaunchArgsRejectForeignArguments) {
  EXPECT_FALSE(LaunchArgs::decode("").has_value());
  EXPECT_FALSE(LaunchArgs::decode("other&id=1").has_value());
  EXPECT_FALSE(LaunchArgs::decode("awn&btn=x").has_value());
  EXPECT_FALSE(LaunchArgs::decode("awn&id=abc").has_value());
}

// MARK: - Toast XML

static ValueMap toastModel() {
  return ValueMap{
      {"content", ValueMap{{"id", 5}, {"title", "Hi <you>"}, {"body", "A & B"}}},
      {"actionButtons",
       ValueList{ValueMap{{"key", "REPLY"}, {"label", "Reply"}, {"requireInputText", true}},
                 ValueMap{{"key", "OFF"}, {"label", "Off"}, {"enabled", false}},
                 ValueMap{{"key", "DEL"},
                          {"label", "Delete"},
                          {"isDangerousOption", true},
                          {"actionType", "SilentAction"}}}}};
}

TEST(ToastXmlRendersTextImagesAndButtons) {
  auto xml = ToastXml::render(toastModel(), {"C:\\img\\icon.png", "C:\\my pics\\big.png"}, false);
  EXPECT_CONTAINS(xml, "<toast useButtonStyle=\"true\" launch=\"awn&amp;id=5\">");
  EXPECT_CONTAINS(xml, "<text>Hi &lt;you&gt;</text><text>A &amp; B</text>");
  EXPECT_CONTAINS(xml, "placement=\"appLogoOverride\" src=\"file:///C:/img/icon.png\"");
  EXPECT_CONTAINS(xml, "<image src=\"file:///C:/my%20pics/big.png\"/>");
  EXPECT_CONTAINS(xml, "<input id=\"REPLY\" type=\"text\" placeHolderContent=\"Reply\"/>");
  EXPECT_CONTAINS(xml, "arguments=\"awn&amp;id=5&amp;btn=REPLY\" hint-inputId=\"REPLY\"");
  EXPECT_CONTAINS(xml, "arguments=\"awn&amp;id=5&amp;btn=DEL\" activationType=\"background\"");
  EXPECT_CONTAINS(xml, "hint-buttonStyle=\"Critical\"");
  EXPECT_FALSE(xml.find("OFF") != std::string::npos);
  EXPECT_FALSE(xml.find("<audio") != std::string::npos);
}

TEST(ToastXmlSilentAndPlain) {
  ValueMap model{{"content", ValueMap{{"id", 1}, {"title", "T"}}}};
  auto xml = ToastXml::render(model, {}, true);
  EXPECT_EQ(xml, std::string("<toast launch=\"awn&amp;id=1\"><visual><binding "
                             "template=\"ToastGeneric\"><text>T</text></binding></visual>"
                             "<audio silent=\"true\"/></toast>"));
}

TEST(ToastXmlCapsButtonsAtFive) {
  ValueList buttons;
  for (int i = 0; i < 8; ++i) buttons.push_back(ValueMap{{"key", "K" + std::to_string(i)}});
  ValueMap model{{"content", ValueMap{{"id", 1}}}, {"actionButtons", buttons}};
  auto xml = ToastXml::render(model, {}, false);
  EXPECT_CONTAINS(xml, "btn=K4");
  EXPECT_FALSE(xml.find("btn=K5") != std::string::npos);
}

// MARK: - Store

TEST(StorePersistsAcrossInstances) {
  auto dir = std::filesystem::temp_directory_path() / "awn_store_test";
  std::filesystem::remove_all(dir);
  auto file = dir / "store.json";
  {
    NotificationStore store(file);
    store.put(1, ValueMap{{"content", ValueMap{{"id", 1}, {"channelKey", "a"}}}});
    store.put(2, ValueMap{{"content", ValueMap{{"id", 2}, {"channelKey", "b"}}}});
    store.put(3, ValueMap{{"content", ValueMap{{"id", 3}, {"channelKey", "a"}}}});
  }
  NotificationStore reloaded(file);
  EXPECT_EQ(reloaded.ids().size(), size_t(3));
  EXPECT_EQ(reloaded.idsWhereContent("channelKey", "a"), (std::vector<int64_t>{1, 3}));
  reloaded.retainWhere([](int64_t id) { return id != 3; });
  reloaded.remove(1);
  EXPECT_EQ(NotificationStore(file).ids(), (std::vector<int64_t>{2}));
  std::filesystem::remove_all(dir);
}

TEST(StoreStartsEmptyOnCorruptFile) {
  auto dir = std::filesystem::temp_directory_path() / "awn_store_corrupt";
  std::filesystem::create_directories(dir);
  { std::ofstream(dir / "store.json") << "{not json"; }
  NotificationStore store(dir / "store.json");
  EXPECT_TRUE(store.ids().empty());
  std::filesystem::remove_all(dir);
}

// MARK: - Displayed tracker

TEST(TrackerOverridesPredictionOnce) {
  DisplayedLifecycleTracker tracker;
  ValueMap predicted{{"id", 7}, {"displayedLifeCycle", "Terminated"}};
  tracker.recordForegroundDisplay(7, "2026-01-01 10:00:05");
  auto resolved = tracker.resolve(predicted, 7);
  EXPECT_EQ(getString(resolved, "displayedLifeCycle").value_or(""), std::string("Foreground"));
  EXPECT_EQ(getString(resolved, "displayedDate").value_or(""),
            std::string("2026-01-01 10:00:05"));
  EXPECT_EQ(getString(tracker.resolve(predicted, 7), "displayedLifeCycle").value_or(""),
            std::string("Terminated"));
  EXPECT_EQ(getString(tracker.resolve(predicted, std::nullopt), "displayedLifeCycle").value_or(""),
            std::string("Terminated"));
}
