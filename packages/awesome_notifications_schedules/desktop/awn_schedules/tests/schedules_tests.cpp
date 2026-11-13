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
  bool isAllowed() override { return true; }
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

  Value call(const std::string& method, Value arguments = Value()) {
    Value answer;
    bool handled = router.handle(method, arguments, [&](const Value& v) { answer = v; });
    EXPECT_TRUE(handled);
    return answer;
  }

  bool create(int id, ValueMap schedule, const char* channel = "basic") {
    ValueMap model{{"content", ValueMap{{"id", id}, {"title", "T"}, {"channelKey", channel}}}};
    if (!schedule.empty()) model["schedule"] = schedule;
    return call("createNewNotification", Value(model)).asBool().value_or(false);
  }
};

}  // namespace

TEST(ScheduledNotificationIsPendingWithScheduleSource) {
  Harness h;
  EXPECT_TRUE(h.create(1, {{"interval", 120}}));
  EXPECT_EQ(h.presenter->armed(1), size_t(1));
  EXPECT_TRUE(h.presenter->delivered.empty());
  EXPECT_EQ(h.events.size(), size_t(1));  // created only; displayed comes at fire time
  EXPECT_EQ(getString(h.events[0].second, "createdSource").value_or(""), std::string("Schedule"));
  auto stored = NotificationBuilder::content(*h.store->get(1));
  EXPECT_EQ(getString(stored, "displayedLifeCycle").value_or(""), std::string("Terminated"));
}

TEST(NotificationWithoutScheduleIsImmediate) {
  Harness h;
  EXPECT_TRUE(h.create(2, {}));
  EXPECT_EQ(h.presenter->delivered, (std::vector<int64_t>{2}));
}

TEST(RepeatingScheduleIsPreArmed) {
  Harness h;
  EXPECT_TRUE(h.create(3, {{"interval", 60}, {"repeats", true}}));
  EXPECT_EQ(h.presenter->armed(3), kMaxArmedOccurrences);
  EXPECT_TRUE(h.create(4, {{"hour", 9}, {"repeats", true}}));
  EXPECT_EQ(h.presenter->armed(4), kMaxArmedOccurrences);
}

TEST(PastOrInvalidScheduleIsRejected) {
  Harness h;
  EXPECT_FALSE(h.create(5, {{"year", 2020}, {"month", 1}, {"day", 1}}));
  EXPECT_FALSE(h.create(6, {{"interval", 10}, {"repeats", true}}));
  EXPECT_TRUE(h.presenter->pending.empty());
}

TEST(ListAllSchedulesReturnsOneModelPerSchedule) {
  Harness h;
  h.create(1, {{"interval", 60}, {"repeats", true}});
  h.create(2, {{"interval", 300}});
  h.create(3, {});
  auto list = h.call("listAllSchedules").list();
  EXPECT_EQ(list.size(), size_t(2));
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

TEST(CancelAllSchedules) {
  Harness h;
  h.create(1, {{"interval", 60}, {"repeats", true}});
  h.create(2, {{"interval", 60}});
  h.call("cancelAllSchedules");
  EXPECT_TRUE(h.presenter->pending.empty());
  EXPECT_TRUE(h.store->ids().empty());
}

TEST(GetNextDateAnswersUtcString) {
  Harness h;
  ValueMap args{{"fixedDate", "2026-07-05 08:30:00"}, {"schedule", ValueMap{{"interval", 60}}}};
  EXPECT_EQ(h.call("getNextDate", Value(args)).asString().value_or(""),
            std::string("2026-07-05 08:31:00"));
  ValueMap none{{"fixedDate", "2026-07-05 08:30:00"}, {"schedule", ValueMap{}}};
  EXPECT_TRUE(h.call("getNextDate", Value(none)).isNull());
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
