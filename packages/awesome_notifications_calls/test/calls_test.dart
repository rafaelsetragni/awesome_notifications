import 'dart:async';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:awesome_notifications_calls/awesome_notifications_calls.dart';
import 'package:awesome_notifications_calls/src/call_keys.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const ana = NotificationPerson(key: 'u-2', name: 'Ana', avatar: 'https://x/ana.jpg');

class _Bridge implements CallsPlatformBridge {
  final calls = <MethodCall>[];
  final controller = StreamController<Object?>.broadcast();
  Object? Function(String method)? answer;

  @override
  Future<Object?> invokeMethod(String method, [Object? arguments]) async {
    calls.add(MethodCall(method, arguments));
    return answer?.call(method);
  }

  @override
  Stream<Object?> get events => controller.stream;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationCall', () {
    test('serializes every field under the call key', () {
      final started = DateTime.utc(2026, 11, 26, 12);
      final map = NotificationCall(
        callId: 'c-1',
        caller: ana,
        state: CallState.ongoing,
        handle: 'tel:+5511999',
        video: true,
        groupName: 'Family',
        startedAt: started,
        ringTimeout: const Duration(seconds: 30),
        missedNotification: false,
        controls: const {CallControl.hangUp, CallControl.mute},
        commandTarget: CallCommandTarget.both,
        systemCallUI: false,
        texts: const CallTexts(missed: 'Chamada perdida'),
      ).toMap();
      final call = map['call'] as Map<String, dynamic>;
      expect(call['callId'], 'c-1');
      expect(call['caller'], ana.toMap());
      expect(call['handle'], 'tel:+5511999');
      expect(call['video'], true);
      expect(call['groupName'], 'Family');
      expect(call['state'], 'ongoing');
      expect(call['startedAt'], started.millisecondsSinceEpoch);
      expect(call['ringTimeout'], 30000);
      expect(call['missedNotification'], false);
      expect(call['controls'], ['hangUp', 'mute']);
      expect(call['commandTarget'], 'both');
      expect(call['systemCallUI'], false);
      expect((call['texts'] as Map)['missed'], 'Chamada perdida');
      expect((call['texts'] as Map)['accept'], 'Accept');
    });

    test('defaults: 60 s ring, missed notification, every control, action event', () {
      final call = const NotificationCall(callId: 'c', caller: ana, state: CallState.incoming)
          .toMap()['call'] as Map<String, dynamic>;
      expect(call.containsKey('handle'), isFalse);
      expect(call.containsKey('startedAt'), isFalse);
      expect(call['video'], false);
      expect(call['ringTimeout'], 60000);
      expect(call['missedNotification'], true);
      expect(call['controls'], ['accept', 'decline', 'hangUp', 'mute', 'hold']);
      expect(call['commandTarget'], 'actionEvent');
      expect(call['systemCallUI'], true);
    });

    test('a local startedAt is sent as UTC milliseconds', () {
      final local = DateTime(2026, 11, 26, 9);
      final call = NotificationCall(
              callId: 'c', caller: ana, state: CallState.ongoing, startedAt: local)
          .toMap()['call'] as Map<String, dynamic>;
      expect(call['startedAt'], local.toUtc().millisecondsSinceEpoch);
    });

    test('validation refuses an invalid call before it reaches the platform', () {
      Matcher refused = throwsA(isA<AwesomeNotificationsException>());
      expect(() => const NotificationCall(callId: ' ', caller: ana, state: CallState.incoming).toMap(),
          refused);
      expect(
          () => const NotificationCall(
                  callId: 'c', caller: NotificationPerson(key: '', name: 'A'), state: CallState.incoming)
              .toMap(),
          refused);
      expect(
          () => const NotificationCall(callId: 'c', caller: ana, state: CallState.incoming, handle: '')
              .toMap(),
          refused);
      expect(
          () => const NotificationCall(
                  callId: 'c', caller: ana, state: CallState.incoming, groupName: ' ')
              .toMap(),
          refused);
      expect(
          () => const NotificationCall(
                  callId: 'c', caller: ana, state: CallState.incoming, ringTimeout: Duration.zero)
              .toMap(),
          refused);
      expect(
          () => const NotificationCall(
                  callId: 'c',
                  caller: ana,
                  state: CallState.incoming,
                  controls: {CallControl.hangUp}).toMap(),
          refused);
      // An ongoing call needs no accept / decline.
      const NotificationCall(
              callId: 'c', caller: ana, state: CallState.ongoing, controls: {CallControl.hangUp})
          .toMap();
    });

    test('createNotification merges the block next to content', () async {
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('awesome_notifications'), (call) async {
        calls.add(call);
        return true;
      });
      await AwesomeNotifications().createNotification(
        content: NotificationContent(id: 300, channelKey: 'calls'),
        extensions: [const NotificationCall(callId: 'c', caller: ana, state: CallState.incoming)],
      );
      final args = (calls.last.arguments as Map).cast<String, dynamic>();
      expect(args.containsKey('content'), isTrue);
      expect((args['call'] as Map)['callId'], 'c');
      // The web core has no channel: web_call_notifications_test covers it there.
    }, testOn: 'vm');
  });

  group('CallCommand', () {
    test('parses every action key', () {
      for (final action in CallAction.values) {
        expect(CallCommand.parse(key: action.key, callId: 'c'),
            CallCommand(action: action, callId: 'c'));
      }
    });

    test('ignores keys that are not call commands', () {
      expect(CallCommand.parse(key: null), isNull);
      expect(CallCommand.parse(key: 'REPLY'), isNull);
      expect(CallCommand.parse(key: 'awn.call.dance'), isNull);
      expect(CallCommand.parse(key: 'awn.media.play'), isNull);
    });

    test('commandOf reads the action event and its payload', () {
      final action = ReceivedAction().fromMap({
        'id': 1,
        'channelKey': 'calls',
        'buttonKeyPressed': 'awn.call.accept',
        'payload': {'callId': 'c-9'},
      });
      expect(AwesomeNotificationsCalls.commandOf(action),
          const CallCommand(action: CallAction.accept, callId: 'c-9'));
      expect(AwesomeNotificationsCalls.callIdOf(action), 'c-9');
    });
  });

  group('AwesomeNotificationsCalls', () {
    late _Bridge bridge;
    setUp(() {
      bridge = _Bridge();
      AwesomeNotificationsCalls.bridge = bridge;
    });
    tearDown(() => AwesomeNotificationsCalls.bridge = null);

    AwesomeNotificationsCalls calls() => AwesomeNotificationsCalls.private(
        const MethodChannel('awesome_notifications'), const EventChannel('unused'));

    test('endCall sends the id and the reason', () async {
      await calls().endCall('c', reason: CallEndReason.answeredElsewhere);
      expect(bridge.calls.single.method, CallKeys.methodEnd);
      expect(bridge.calls.single.arguments, {'callId': 'c', 'reason': 'answeredElsewhere'});
      await calls().endCall('d');
      expect(bridge.calls.last.arguments, {'callId': 'd', 'reason': 'remoteEnded'});
    });

    test('activeCalls skips malformed entries', () async {
      bridge.answer = (_) => [
            {'callId': 'a', 'state': 'ongoing'},
            {'callId': 'b', 'state': 'bogus'},
            {'state': 'held'},
            'junk',
            {'callId': 'c', 'state': 'held'},
          ];
      expect(await calls().activeCalls(), const [
        ActiveCall(callId: 'a', state: CallState.ongoing),
        ActiveCall(callId: 'c', state: CallState.held),
      ]);
      bridge.answer = (_) => null;
      expect(await calls().activeCalls(), isEmpty);
    });

    test('voipToken, full-screen and capabilities read the native answers', () async {
      bridge.answer = (method) => switch (method) {
            CallKeys.methodVoipToken => 'abc',
            CallKeys.methodCanUseFullScreenIntent => true,
            CallKeys.methodRequestFullScreenIntent => false,
            CallKeys.methodCapabilities => {
                'systemCallUI': true,
                'lockScreen': true,
                'muteAndHold': false,
                'push': true
              },
            _ => null,
          };
      expect(await calls().voipToken(), 'abc');
      expect(await calls().canUseFullScreenIntent(), isTrue);
      expect(await calls().requestFullScreenIntent(), isFalse);
      final caps = await calls().capabilities();
      expect(caps.systemCallUI, isTrue);
      expect(caps.muteAndHold, isFalse);
      expect(caps.push, isTrue);
      bridge.answer = (_) => '';
      expect(await calls().voipToken(), isNull);
      expect((await calls().capabilities()).systemCallUI, isFalse);
    });

    test('the event stream splits commands and VoIP tokens', () async {
      final api = calls();
      final commands = <CallCommand>[];
      final tokens = <String>[];
      final s1 = api.commands.listen(commands.add);
      final s2 = api.onVoipToken.listen(tokens.add);
      bridge.controller
        ..add({'kind': 'command', 'action': 'hangUp', 'callId': 'c'})
        ..add({'kind': 'command', 'action': 'nope', 'callId': 'c'})
        ..add({'kind': 'voipToken', 'token': 't1'})
        ..add({'kind': 'voipToken', 'token': ''})
        ..add('junk');
      await Future<void>.delayed(Duration.zero);
      expect(commands, const [CallCommand(action: CallAction.hangUp, callId: 'c')]);
      expect(tokens, ['t1']);
      await s1.cancel();
      await s2.cancel();
    });
  });
}
