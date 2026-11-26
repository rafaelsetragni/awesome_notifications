#include <algorithm>

#include "awn/awesome_notifications.h"
#include "awn/method_router.h"
#include "awn_schedules/schedules.h"
#include "awn_test.h"

using namespace awn;
using namespace awn_schedules;

namespace {

/// Records presented notifications; a scheduled one adds one pending entry per
/// pre-armed occurrence (like Windows' scheduled toasts sharing a tag).
class FakePresenter : public NotificationPresenter {
 public:
  std::vector<int64_t> delivered, pending;
  bool allowed = true;

  void present(const BuiltNotification& built, std::function<void(bool)> done) override {
    removePending({built.id});
    if (built.fireDate) {
      pending.push_back(built.id);
      for (size_t i = 0; i < built.repeatDates.size(); ++i) pending.push_back(built.id);
    } else {
      delivered.push_back(built.id);
    }
    done(true);
  }
  void removeDelivered(const std::vector<int64_t>& ids) override { erase(delivered, ids); }
  void removeAllDelivered() override { delivered.clear(); }
  void removePending(const std::vector<int64_t>& ids) override { erase(pending, ids); }
  void removeAllPending() override { pending.clear(); }
  std::vector<int64_t> deliveredIds() override { return delivered; }
  std::vector<int64_t> pendingIds() override { return pending; }
  bool isAllowed() override { return allowed; }
  void requestPermission(std::function<void(bool)> done) override { done(true); }
  std::string localTimeZone() override { return "UTC"; }
  int64_t utcOffset(const std::string&, TimePoint) override { return 0; }
  std::string systemLanguage() override { return "pt-br"; }
  std::filesystem::path dataDirectory() override { return {}; }

  size_t armed(int64_t id) const { return static_cast<size_t>(std::count(pending.begin(), pending.end(), id)); }

 private:
  static void erase(std::vector<int64_t>& from, const std::vector<int64_t>& ids) {
    from.erase(std::remove_if(from.begin(), from.end(),
                              [&](int64_t id) {
                                return std::find(ids.begin(), ids.end(), id) != ids.end();
                              }),
               from.end());
  }
};

class InlineDispatcher : public Dispatcher {
 public:
  void post(std::function<void()> work) override { work(); }
};

struct Harness {
  std::shared_ptr<FakePresenter> presenter = std::make_shared<FakePresenter>();
  std::shared_ptr<NotificationStore> store = std::make_shared<NotificationStore>();
  AwesomeNotifications engine;
  AwesomeMethodRouter router{engine};
  std::vector<std::pair<std::string, ValueMap>> events;
  int token;

  Harness() {
    NotificationBuilderRegistry::shared().clearForTest();
    AwesomeMethodHandlerRegistry::shared().clearForTest();
    engine.configure(presenter, std::make_shared<InlineDispatcher>(), store, false);
    // 0.12 only schedules on an existing channel.
    for (const char* key : {"basic", "a", "b"})
      engine.setChannel(ValueMap{{"channelKey", key}, {"importance", "Default"}});
    engine.setChannel(ValueMap{{"channelKey", "off"}, {"importance", "None"}});
    RegisterSchedules(engine);
    token = AwesomeEventsReceiver::shared().subscribe(
        [this](const std::string& name, const ValueMap& content) {
          events.emplace_back(name, content);
        });
  }
  ~Harness() {
    AwesomeEventsReceiver::shared().unsubscribe(token);
    NotificationBuilderRegistry::shared().clearForTest();
    AwesomeMethodHandlerRegistry::shared().clearForTest();
  }

  /// The answer, or "error <code> <details>" when the call failed.
  std::string outcome(const std::string& method, Value arguments = Value()) {
    std::string out = "(no answer)";
    bool handled = router.handle(
        method, arguments,
        [&](const Value& v) {
          if (v.isNull()) out = "null";
          else if (v.isBool()) out = *v.asBool() ? "true" : "false";
          else out = v.asString().value_or("value");
        },
        [&](const std::string& code, const std::string&, const Value& details) {
          out = "error " + code + " " + details.asString().value_or("");
        });
    EXPECT_TRUE(handled);
    return out;
  }

  Value call(const std::string& method, Value arguments = Value()) {
    Value answer;
    bool handled = router.handle(method, arguments, [&](const Value& v) { answer = v; });
    EXPECT_TRUE(handled);
    return answer;
  }

  std::string create(int id, ValueMap schedule, const char* channel = "basic") {
    ValueMap model{{"content", ValueMap{{"id", id}, {"title", "T"}, {"channelKey", channel}}}};
    if (!schedule.empty()) model["schedule"] = schedule;
    return outcome("createNewNotification", Value(model));
  }
};

}  // namespace

TEST(ScheduledNotificationIsPendingWithScheduleSource) {
  Harness h;
  // 0.12 Android answered false for a notification it did schedule.
  EXPECT_EQ(h.create(1, {{"interval", 120}}), std::string("false"));
  EXPECT_EQ(h.presenter->armed(1), size_t(1));
  EXPECT_TRUE(h.presenter->delivered.empty());
  EXPECT_EQ(h.events.size(), size_t(1));  // created only; displayed comes at fire time
  EXPECT_EQ(getString(h.events[0].second, "createdSource").value_or(""), std::string("Schedule"));
  auto stored = NotificationBuilder::content(*h.store->get(1));
  EXPECT_EQ(getString(stored, "displayedLifeCycle").value_or(""), std::string("Terminated"));
}

TEST(NotificationWithoutScheduleIsImmediate) {
  Harness h;
  EXPECT_EQ(h.create(2, {}), std::string("true"));
  EXPECT_EQ(h.presenter->delivered, (std::vector<int64_t>{2}));
  // An unrecognized schedule block is no schedule either.
  EXPECT_EQ(h.create(3, {{"timeZone", "UTC"}}), std::string("true"));
}

TEST(RepeatingScheduleIsPreArmed) {
  Harness h;
  EXPECT_EQ(h.create(3, {{"interval", 60}, {"repeats", true}}), std::string("false"));
  EXPECT_EQ(h.presenter->armed(3), kMaxArmedOccurrences);
  EXPECT_EQ(h.create(4, {{"hour", 9}, {"minute", 0}, {"second", 0}, {"repeats", true}}),
            std::string("false"));
  EXPECT_EQ(h.presenter->armed(4), kMaxArmedOccurrences);
}

TEST(CreateAnswersLike012) {
  Harness h;
  // No future date: false, not stored.
  EXPECT_EQ(h.create(5, {{"year", 2020}, {"month", 1}, {"day", 1}, {"hour", 0}}),
            std::string("false"));
  // Invalid schedules fail.
  EXPECT_EQ(h.create(6, {{"interval", 30}, {"repeats", true}}),
            std::string("error INVALID_ARGUMENTS arguments.invalid.notificationInterval.interval"));
  EXPECT_EQ(h.create(7, {{"interval", 0}}),
            std::string("error INVALID_ARGUMENTS arguments.invalid.notificationInterval.interval"));
  EXPECT_EQ(h.create(8, {{"hour", 24}}),
            std::string("error INVALID_ARGUMENTS arguments.invalid.notificationCalendar"));
  EXPECT_EQ(h.create(9, {{"hour", nullptr}, {"minute", nullptr}}),
            std::string("error INVALID_ARGUMENTS arguments.invalid.notificationCalendar"));
  // A missing or disabled channel fails.
  EXPECT_EQ(h.create(10, {{"interval", 60}}, "nope"),
            std::string("error INVALID_ARGUMENTS insufficientPermissions.channel.nope"));
  EXPECT_EQ(h.create(11, {{"interval", 60}}, "off"),
            std::string("error INVALID_ARGUMENTS insufficientPermissions.channel.off"));
  EXPECT_TRUE(h.presenter->pending.empty());
}

TEST(NotificationsNotAllowedFail) {
  Harness h;
  h.presenter->allowed = false;
  EXPECT_EQ(h.create(1, {{"interval", 60}}),
            std::string("error INSUFFICIENT_PERMISSIONS insufficientPermissions.global"));
}

TEST(ListAllSchedulesReturnsTheStoredSchedule) {
  Harness h;
  h.create(1, {{"interval", 60}, {"repeats", true}});
  h.create(2, {{"interval", 300}});
  h.create(3, {});
  auto list = h.call("listAllSchedules").list();
  EXPECT_EQ(list.size(), size_t(2));
  ValueMap schedule = getMap(list[0].map(), "schedule");
  EXPECT_EQ(getString(schedule, "timeZone").value_or(""), std::string("UTC"));
  EXPECT_EQ(getInt(schedule, "interval").value_or(0), 60);
}

TEST(CancelSchedulesKeepDeliveredNotifications) {
  Harness h;
  h.create(1, {{"interval", 60}}, "a");
  h.create(2, {{"interval", 60}}, "b");
  h.presenter->delivered.push_back(1);  // occurrence already on screen
  h.call("cancelSchedulesByChannelKey", Value("a"));
  EXPECT_EQ(h.presenter->pending, (std::vector<int64_t>{2}));
  EXPECT_TRUE(h.store->get(1).has_value());  // still on screen: model kept
  h.call("cancelSchedule", Value(2));
  EXPECT_TRUE(h.presenter->pending.empty());
  EXPECT_FALSE(h.store->get(2).has_value());
}

TEST(CancelArgumentsAreValidated) {
  Harness h;
  EXPECT_EQ(h.outcome("cancelSchedule", Value(-1)),
            std::string("error INVALID_ARGUMENTS arguments.invalid.dismiss.id"));
  EXPECT_EQ(h.outcome("cancelSchedulesByChannelKey", Value("")),
            std::string("error INVALID_ARGUMENTS arguments.invalid.dismiss.channelKey"));
  EXPECT_EQ(h.outcome("cancelSchedulesByGroupKey", Value()),
            std::string("error INVALID_ARGUMENTS arguments.invalid.dismiss.groupKey"));
}

TEST(CancelAllSchedules) {
  Harness h;
  h.create(1, {{"interval", 60}, {"repeats", true}});
  h.create(2, {{"interval", 60}});
  h.call("cancelAllSchedules");
  EXPECT_TRUE(h.presenter->pending.empty());
  EXPECT_TRUE(h.store->ids().empty());
}

TEST(GetNextDateAnswersTheWallClockWithItsZone) {
  Harness h;
  ValueMap args{{"fixedDate", "2026-07-05 08:30:00"},
                {"schedule", ValueMap{{"interval", 60}, {"timeZone", "UTC"}}}};
  EXPECT_EQ(h.outcome("getNextDate", Value(args)), std::string("2026-07-05 08:31:00 UTC"));
  ValueMap none{{"fixedDate", "2026-07-05 08:30:00"}, {"schedule", ValueMap{}}};
  EXPECT_EQ(h.outcome("getNextDate", Value(none)),
            std::string("error INVALID_ARGUMENTS arguments.invalid.schedule.data"));
  ValueMap past{{"fixedDate", "2026-07-05 08:30:00"},
                {"schedule", ValueMap{{"year", 2020}, {"timeZone", "UTC"}}}};
  EXPECT_EQ(h.outcome("getNextDate", Value(past)), std::string("null"));
}

TEST(TopUpRearmsRepeatingSchedulesRunningLow) {
  Harness h;
  h.create(1, {{"interval", 60}, {"repeats", true}});
  h.create(2, {{"interval", 600}});  // one-shot: never re-armed
  // Most occurrences already fired.
  h.presenter->pending.erase(std::remove(h.presenter->pending.begin(), h.presenter->pending.end(), 1),
                             h.presenter->pending.end());
  h.presenter->pending.push_back(1);
  EXPECT_EQ(TopUpRepeatingSchedules(h.engine), size_t(1));
  EXPECT_EQ(h.presenter->armed(1), kMaxArmedOccurrences);
  EXPECT_EQ(h.presenter->armed(2), size_t(1));
  EXPECT_EQ(TopUpRepeatingSchedules(h.engine), size_t(0));  // full again
}

TEST(UnknownMethodFallsThrough) {
  Harness h;
  EXPECT_FALSE(h.router.handle("notASchedulesMethod", Value(), [](const Value&) {}));
}
