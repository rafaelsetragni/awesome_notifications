import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:awesome_notifications/src/logs/logger.dart';
import 'package:awesome_notifications/src/utils/awesome_html_utils.dart';
import 'package:awesome_notifications/src/utils/image_file_loader.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Logger', () {
    test('all levels run', () {
      Logger.d('C', 'debug');
      Logger.e('C', 'error');
      Logger.i('C', 'info');
      Logger.w('C', 'warn');
    });
  });

  group('Exceptions', () {
    test('toString', () {
      expect(
          const AwesomeNotificationsException(message: 'boom').toString(),
          contains('boom'));
      expect(IsolateCallbackException('bad').toString(), contains('bad'));
    });
  });

  group('Model.toString + AwesomeMapUtils', () {
    test('pretty-prints a model as sorted JSON', () {
      final channel = NotificationChannel(
        channelKey: 'ch',
        channelName: 'Ch',
        channelDescription: 'desc',
      );
      expect(channel.toString(), contains('channelKey'));
      expect(
          AwesomeMapUtils.printPrettyMap({'b': 2, 'a': 1}).indexOf('"a"'),
          lessThan(AwesomeMapUtils.printPrettyMap({'b': 2, 'a': 1}).indexOf('"b"')));
    });
  });

  group('AwesomeHtmlUtils', () {
    test('removeAllHtmlTags', () {
      expect(AwesomeHtmlUtils.removeAllHtmlTags('<b>hi</b> <i>there</i>'),
          'hi there');
      expect(AwesomeHtmlUtils.removeAllHtmlTags(null), isNull);
    });
  });

  group('NotificationPlayState', () {
    test('toMap / fromMap', () {
      expect(NotificationPlayState.unknown.toMap(), -1);
      expect(NotificationPlayState.playing.toMap(),
          NotificationPlayState.playing.index - 1);
      expect(NotificationPlayState.fromMap('playing'),
          NotificationPlayState.playing);
      expect(NotificationPlayState.fromMap('nope'), isNull);
      expect(NotificationPlayState.fromMap(null), isNull);
      expect(NotificationPlayState.fromMap(0), NotificationPlayState.none);
      expect(NotificationPlayState.fromMap(-1), NotificationPlayState.unknown);
      expect(NotificationPlayState.fromMap(999), isNull);
    });
  });

  group('MediaSource', () {
    test('MediaSourcePrefix values', () {
      expect(MediaSourcePrefix.values, contains('resource://'));
      expect(MediaSourcePrefix.values.length, 5);
    });
  });

  group('AwesomeBitmapUtils', () {
    final bitmaps = AwesomeBitmapUtils();

    test('getMediaSource classifies by scheme', () {
      expect(bitmaps.getMediaSource('https://x/y.png'), MediaSource.Network);
      expect(bitmaps.getMediaSource('http://x/y.png'), MediaSource.Network);
      expect(bitmaps.getMediaSource('file:///a/b.png'), MediaSource.File);
      expect(bitmaps.getMediaSource('asset://a/b.png'), MediaSource.Asset);
      expect(bitmaps.getMediaSource('resource://drawable/ic'),
          MediaSource.Resource);
      expect(bitmaps.getMediaSource('weird'), MediaSource.Unknown);
      expect(bitmaps.getMediaSource(null), MediaSource.Unknown);
    });

    test('cleanMediaPath strips the scheme', () {
      expect(bitmaps.cleanMediaPath('asset://a/b.png'), 'a/b.png');
      expect(bitmaps.cleanMediaPath('resource://drawable/ic'), 'drawable/ic');
      expect(bitmaps.cleanMediaPath('no-scheme'), 'no-scheme');
    });

    test('getFromMediaPath returns a provider per scheme', () {
      expect(bitmaps.getFromMediaPath('asset://a.png'), isA<AssetImage>());
      expect(bitmaps.getFromMediaPath('https://x/a.png'), isA<NetworkImage>());
      expect(bitmaps.getFromMediaPath('resource://drawable/ic'),
          isA<ResourceImage>());
      expect(bitmaps.getFromMediaPath('file:///a.png'), isNotNull);
      expect(bitmaps.getFromMediaPath('weird'), isNull);
    });
  });

  group('image_file_loader', () {
    test('loadFileImage builds a FileImage', () {
      expect(loadFileImage('/tmp/a.png'), isA<FileImage>());
    });
  });

  group('BitmapHelper', () {
    test('constructors, size and clone', () {
      final blank = BitmapHelper.blank(2, 3);
      expect(blank.size, 2 * 3 * 4);
      expect(blank.content.length, 2 * 3 * 4);

      final headless = BitmapHelper.fromHeadless(1, 1, Uint8List(4));
      expect(headless.cloneHeadless().content.length, 4);

      // buildHeaded prepends the RGBA32 header.
      final headed = blank.buildHeaded();
      expect(headed.length, blank.size + RGBA32HeaderSize);
    });

    test('buildImage decodes the headed BMP into a ui.Image', () async {
      final image = await BitmapHelper.blank(2, 2).buildImage();
      expect(image.width, 2);
      expect(image.height, 2);
    });

    testWidgets('fromImageProvider builds from a decoded image',
        (tester) async {
      // A minimal 1x1 PNG. runAsync drives the real image-decode pipeline.
      final png = Uint8List.fromList(const [
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
        0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
        0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
        0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
        0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
        0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82
      ]);
      await tester.runAsync(() async {
        final helper = await BitmapHelper.fromImageProvider(MemoryImage(png));
        expect(helper.width, 1);
        expect(helper.height, 1);
      });
    });
  });

  group('ResourceImage', () {
    test('equality, hashCode, toString and obtainKey', () async {
      const a = ResourceImage('drawable/ic');
      const b = ResourceImage('drawable/ic');
      const c = ResourceImage('drawable/other');
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a == c, isFalse);
      expect(a.toString(), contains('drawable/ic'));
      expect(await a.obtainKey(ImageConfiguration.empty), a);
    });

    test('loadAsync throws when the drawable bytes are empty', () async {
      // On the test host the platform is the no-op Empty impl, whose
      // getDrawableData returns null → the "image is invalid" guard fires.
      const image = ResourceImage('drawable/missing');
      Future<ui.Codec> decode(ui.ImmutableBuffer buffer,
              {ui.TargetImageSizeCallback? getTargetSize}) async =>
          throw UnimplementedError();
      await expectLater(
        image.loadAsync(image, decode),
        throwsA(isA<AwesomeNotificationsException>()),
      );
    });
  });
}
