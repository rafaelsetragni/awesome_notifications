import 'package:awesome_notifications_media/awesome_notifications_media.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('AwesomeNotificationsMedia() is a singleton', () {
    expect(AwesomeNotificationsMedia(), same(AwesomeNotificationsMedia()));
  });

  test('every platform of the 1.0 line is supported, others are not', () {
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    for (final platform in TargetPlatform.values) {
      debugDefaultTargetPlatformOverride = platform;
      expect(AwesomeNotificationsMedia.isPlatformSupported, platform != TargetPlatform.fuchsia,
          reason: platform.name);
    }
  });

  test('a media command prints its fields', () {
    expect(
        const MediaCommand(control: MediaControl.seekTo, sessionId: 's', position: Duration(seconds: 1))
            .toString(),
        'MediaCommand(seekTo, s, 0:00:01.000000)');
  });
}
