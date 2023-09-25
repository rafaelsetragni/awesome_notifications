import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AwesomeBitmapUtils bitmapUtils;

  setUp(() {
    bitmapUtils = AwesomeBitmapUtils();
  });

  group('getFromMediaPath()', () {
    test('Unknown media path', () {
      expect(bitmapUtils.getFromMediaPath('unknown:///path/to/image.png'), null);
    });

    test('Network media path', () {
      ImageProvider? imageProvider1 = bitmapUtils.getFromMediaPath('http://example.com/image.png');
      expect(imageProvider1, isA<NetworkImage>());

      ImageProvider? imageProvider2 = bitmapUtils.getFromMediaPath('https://example.com/image.png');
      expect(imageProvider2, isA<NetworkImage>());
    });

    test('File media path', () {
      ImageProvider? imageProvider = bitmapUtils.getFromMediaPath('file://path/to/image.png');
      expect(imageProvider, isA<FileImage>());
    });

    test('Asset media path', () {
      ImageProvider? imageProvider = bitmapUtils.getFromMediaPath('asset://path/to/image.png');
      expect(imageProvider, isA<AssetImage>());
    });

    test('Resource media path', () {
      ImageProvider? imageProvider = bitmapUtils.getFromMediaPath('resource://path/to/image.png');
      expect(imageProvider, isA<ResourceImage>());
    });
  });
}
