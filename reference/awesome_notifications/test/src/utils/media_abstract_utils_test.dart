import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:awesome_notifications/src/utils/media_abstract_utils.dart';
import 'package:flutter_test/flutter_test.dart';

class TestAwesomeMediaUtils extends AwesomeMediaUtils {
  @override
  getFromMediaAsset(String mediaPath) {
    return null;
  }

  @override
  getFromMediaNetwork(String mediaPath) {
    return null;
  }

  @override
  getFromMediaResource(String mediaPath) {
    return null;
  }
}

void main() {
  final mediaUtils = TestAwesomeMediaUtils();

  group('getMediaSource()', () {
    test('Null media path', () {
      expect(mediaUtils.getMediaSource(null), MediaSource.Unknown);
    });

    test('Network media path', () {
      expect(
          mediaUtils.getMediaSource('http://example.com/image.jpg'),
          MediaSource.Network);
      expect(
          mediaUtils.getMediaSource('https://example.com/image.jpg'),
          MediaSource.Network);
    });

    test('File media path', () {
      expect(
          mediaUtils.getMediaSource('file://path/to/image.jpg'),
          MediaSource.File);
    });

    test('Asset media path', () {
      expect(
          mediaUtils.getMediaSource('asset://path/to/image.jpg'),
          MediaSource.Asset);
    });

    test('Resource media path', () {
      expect(
          mediaUtils.getMediaSource('resource://path/to/image.jpg'),
          MediaSource.Resource);
    });
  });

  group('cleanMediaPath()', () {
    test('File media path', () {
      expect(mediaUtils.cleanMediaPath('file://path/to/image.jpg'),
          '/path/to/image.jpg');
    });

    test('Asset media path', () {
      expect(mediaUtils.cleanMediaPath('asset://path/to/image.jpg'),
          'path/to/image.jpg');
    });

    test('Resource media path', () {
      expect(mediaUtils.cleanMediaPath('resource://path/to/image.jpg'),
          'path/to/image.jpg');
    });

    test('Non-prefixed media path', () {
      expect(mediaUtils.cleanMediaPath('/path/to/image.jpg'),
          '/path/to/image.jpg');
    });
  });

  // Since getFromMediaAsset, getFromMediaNetwork, and getFromMediaResource
  // are marked as @protected, you should test getFromMediaPath() method
  // which internally calls these methods.
  group('getFromMediaPath()', () {
    test('Unknown media path', () {
      expect(mediaUtils.getFromMediaPath('unknown://path/to/image.jpg'),
          null);
      expect(mediaUtils.getFromMediaPath('resources://path/to/image.jpg'),
          null);
      expect(mediaUtils.getFromMediaPath('assets://path/to/image.jpg'),
          null);
      expect(mediaUtils.getFromMediaPath('files://path/to/image.jpg'),
          null);
    });

    test('Network media path', () {
      expect(mediaUtils.getFromMediaPath('https://example.com/image.jpg'),
          null);
    });

    test('File media path', () {
      // Due to the usage of FileImage, this test case will not work in this example.
      // You should test this on a real device or emulator.
    });

    test('Asset media path', () {
      expect(mediaUtils.getFromMediaPath('asset://path/to/image.jpg'), null);
    });

    test('Resource media path', () {
      expect(mediaUtils.getFromMediaPath('resource://path/to/image.jpg'),
          null);
    });
  });
}
