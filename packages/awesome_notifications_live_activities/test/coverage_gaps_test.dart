import 'package:awesome_notifications_live_activities/awesome_notifications_live_activities.dart';
import 'package:awesome_notifications_live_activities/src/web/web_live_activity_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('value classes: equal ones share a hash, and print their fields', () {
    const a = ActiveLiveActivity(activityId: 'a', status: LiveActivityStatus.active);
    expect(a.hashCode, const ActiveLiveActivity(activityId: 'a', status: LiveActivityStatus.active).hashCode);
    expect(a.toString(), 'ActiveLiveActivity(a, active)');

    const t = LiveActivityPushToken(activityId: 'a', token: 'x');
    expect(t.hashCode, const LiveActivityPushToken(activityId: 'a', token: 'x').hashCode);
  });

  test('every platform of the 1.0 line is supported, others are not', () {
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    for (final platform in TargetPlatform.values) {
      debugDefaultTargetPlatformOverride = platform;
      expect(AwesomeNotificationsLiveActivities.isPlatformSupported, platform != TargetPlatform.fuchsia,
          reason: platform.name);
    }
  });

  group('parseWebLiveActivity', () {
    Matcher refused() => throwsA(isA<PlatformException>()
        .having((e) => e.details, 'details', 'arguments.invalid.notificationLiveActivity'));

    test('points sit within the sum of the segments', () {
      parseWebLiveActivity({
        'progress': {
          'segments': [{'length': 30}, {'length': 20.0}],
          'points': [{'position': 50}],
        },
      }, 1);
      expect(
          () => parseWebLiveActivity({
                'progress': {
                  'segments': [{'length': 30}],
                  'points': [{'position': 31}],
                },
              }, 1),
          refused());
    });

    test('a timer start or end that is not milliseconds is refused', () {
      expect(() => parseWebLiveActivity({'timer': {'start': 'now'}}, 1), refused());
      expect(() => parseWebLiveActivity({'timer': {'end': 'later'}}, 1), refused());
    });
  });
}
