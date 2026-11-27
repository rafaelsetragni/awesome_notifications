import 'package:awesome_notifications_calls/awesome_notifications_calls.dart';
import 'package:awesome_notifications_calls/src/web/web_call_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('value classes: equal ones share a hash, and print their fields', () {
    const a = ActiveCall(callId: 'c', state: CallState.held);
    expect(a.hashCode, const ActiveCall(callId: 'c', state: CallState.held).hashCode);
    expect(a.toString(), 'ActiveCall(c, held)');

    const b = WebCallButton(CallAction.accept, 'Atender');
    expect(b.hashCode, const WebCallButton(CallAction.accept, 'Atender').hashCode);
    expect(b.toString(), 'WebCallButton(accept, Atender)');

    const c = CallCommand(action: CallAction.decline, callId: 'c');
    expect(c.hashCode, const CallCommand(action: CallAction.decline, callId: 'c').hashCode);
    expect(c.toString(), 'CallCommand(decline, c)');
  });

  test('AwesomeNotificationsCalls() is a singleton', () {
    expect(AwesomeNotificationsCalls(), same(AwesomeNotificationsCalls()));
  });

  test('every platform of the 1.0 line is supported, others are not', () {
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    for (final platform in TargetPlatform.values) {
      debugDefaultTargetPlatformOverride = platform;
      expect(AwesomeNotificationsCalls.isPlatformSupported, platform != TargetPlatform.fuchsia,
          reason: platform.name);
    }
  });

  group('parseWebCall', () {
    Map<String, dynamic> valid() => {
          'callId': 'x',
          'caller': {'key': 'k', 'name': 'N'},
          'state': 'ongoing',
        };

    test('keeps startedAt as whole milliseconds', () {
      expect(parseWebCall(valid()..['startedAt'] = 1700000000000.0)['startedAt'], 1700000000000);
    });

    test('refuses a startedAt that is not a number, and controls that are not a list', () {
      for (final map in [valid()..['startedAt'] = 'now', valid()..['controls'] = 'accept']) {
        expect(
            () => parseWebCall(map),
            throwsA(isA<PlatformException>()
                .having((e) => e.details, 'details', 'arguments.invalid.notificationCall')),
            reason: '$map');
      }
    });
  });
}
