#include "awn/freedesktop.h"
#include "awn/platform.h"
#include "awn/value.h"
#include "awn_test.h"

using namespace awn;

namespace {

const std::set<std::string> kFull = {"actions", "body", "body-markup", "inline-reply"};

ValueMap modelWith(ValueMap content, ValueList buttons = {}) {
  ValueMap model{{"content", Value(std::move(content))}};
  if (!buttons.empty()) model["actionButtons"] = Value(std::move(buttons));
  return model;
}

}  // namespace

TEST(FreedesktopRendersTitleBodyAndSummary) {
  auto n = Freedesktop::render(
      modelWith({{"id", 3}, {"title", "Hi <b>there</b>"}, {"body", "a &amp; <i>b</i>"},
                 {"summary", "sub"}}),
      {}, false, "Default", kFull);
  EXPECT_EQ(n.summary, std::string("Hi there"));
  EXPECT_EQ(n.body, std::string("a &amp; <i>b</i>\nsub"));
  EXPECT_EQ(n.urgency, 1);
  EXPECT_FALSE(n.suppressSound);
}

TEST(FreedesktopStripsMarkupWhereTheServerHasNone) {
  auto n = Freedesktop::render(modelWith({{"id", 1}, {"body", "x<br>y &lt;z&gt; <b>w</b>"}}), {},
                               false, "Default", {"actions"});
  EXPECT_EQ(n.body, std::string("x\ny <z> w"));
}

TEST(FreedesktopMarkupEscapesUnknownTags) {
  EXPECT_EQ(Freedesktop::basicMarkup("<span>1 < 2</span> <u>ok</u>"),
            std::string("1 &lt; 2 <u>ok</u>"));
}

TEST(FreedesktopActionsCarryTheLaunchArguments) {
  auto n = Freedesktop::render(
      modelWith({{"id", 7}},
                ValueList{ValueMap{{"key", "OK"}, {"label", "Ok"}},
                          ValueMap{{"key", "OFF"}, {"label", "Off"}, {"enabled", false}},
                          ValueMap{{"key", "LOCK"}, {"label", "Keep"}, {"actionType", "KeepOnTop"}}}),
      {}, false, "Default", kFull);
  EXPECT_EQ(n.actions.size(), static_cast<size_t>(3));
  EXPECT_EQ(n.actions[0].first, std::string(Freedesktop::kDefaultAction));
  EXPECT_EQ(n.actions[1].first, LaunchArgs::encode(7, "OK"));
  EXPECT_EQ(n.actions[1].second, std::string("Ok"));
  EXPECT_EQ(n.actions[2].first, LaunchArgs::encode(7, "LOCK"));
  // A KeepOnTop button keeps the notification on screen after it is pressed.
  EXPECT_TRUE(n.resident);
}

TEST(FreedesktopWithoutActionsCapabilitySendsNone) {
  auto n = Freedesktop::render(modelWith({{"id", 7}}, ValueList{ValueMap{{"key", "OK"}}}), {},
                               false, "Default", {"body"});
  EXPECT_TRUE(n.actions.empty());
}

TEST(FreedesktopInputButtonIsTypedInPlaceWhenSupported) {
  ValueList buttons{ValueMap{{"key", "REPLY"}, {"label", "Reply"}, {"requireInputText", true}}};
  auto inPlace = Freedesktop::render(modelWith({{"id", 2}}, buttons), {}, false, "Default", kFull);
  EXPECT_EQ(inPlace.inlineReplyAction, LaunchArgs::encode(2, "REPLY"));
  EXPECT_EQ(inPlace.inlineReplyPlaceholder, std::string("Reply"));
  EXPECT_EQ(inPlace.actions[1].first, std::string(Freedesktop::kInlineReplyAction));

  // Without the capability it is a plain button (no typed text).
  auto plain = Freedesktop::render(modelWith({{"id", 2}}, buttons), {}, false, "Default",
                                   {"actions"});
  EXPECT_TRUE(plain.inlineReplyAction.empty());
  EXPECT_EQ(plain.actions[1].first, LaunchArgs::encode(2, "REPLY"));
}

TEST(FreedesktopImagesFillTheSingleImageSlot) {
  auto both = Freedesktop::render(modelWith({{"id", 1}}), {"/tmp/icon.png", "/tmp/big pic.jpg"},
                                  false, "Default", kFull);
  EXPECT_EQ(both.imagePath, std::string("file:///tmp/big%20pic.jpg"));
  EXPECT_EQ(both.appIcon, std::string("file:///tmp/icon.png"));

  auto icon = Freedesktop::render(modelWith({{"id", 1}}), {"/tmp/icon.png", ""}, false, "Default",
                                  kFull);
  EXPECT_EQ(icon.imagePath, std::string("file:///tmp/icon.png"));
  EXPECT_TRUE(icon.appIcon.empty());
}

TEST(FreedesktopUrgencyFollowsTheChannelImportance) {
  EXPECT_EQ(Freedesktop::urgencyOf("Min"), 0);
  EXPECT_EQ(Freedesktop::urgencyOf("Low"), 0);
  EXPECT_EQ(Freedesktop::urgencyOf("Default"), 1);
  EXPECT_EQ(Freedesktop::urgencyOf("High"), 1);
  EXPECT_EQ(Freedesktop::urgencyOf("Max"), 2);
  EXPECT_EQ(Freedesktop::urgencyOf(""), 1);
}

TEST(FreedesktopSilentLockedAndCategory) {
  auto n = Freedesktop::render(modelWith({{"id", 1}, {"locked", true}, {"category", "Email"}}), {},
                               true, "Default", kFull);
  EXPECT_TRUE(n.suppressSound);
  EXPECT_TRUE(n.resident);
  EXPECT_EQ(n.category, std::string("email.arrived"));
  auto none = Freedesktop::render(modelWith({{"id", 1}, {"category", "Alarm"}}), {}, false,
                                  "Default", kFull);
  EXPECT_TRUE(none.category.empty());
}
