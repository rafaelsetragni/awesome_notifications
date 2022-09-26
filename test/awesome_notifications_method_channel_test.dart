import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:awesome_notifications/awesome_notifications_method_channel.dart';

void main() {
  MethodChannelAwesomeNotifications platform = MethodChannelAwesomeNotifications();
  const MethodChannel channel = MethodChannel('awesome_notifications');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}
