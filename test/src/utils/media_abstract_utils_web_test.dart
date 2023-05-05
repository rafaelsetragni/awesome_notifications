import 'package:awesome_notifications/src/utils/media_abstract_utils.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:awesome_notifications/src/enumerators/media_source.dart';

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
  late TestAwesomeMediaUtils mediaUtils;

  setUp(() {
    mediaUtils = TestAwesomeMediaUtils();
  });

  group('AwesomeMediaUtils', () {

    test('Get media source', () {
      expect(mediaUtils.getMediaSource('https://example.com/image.png'),
          MediaSource.Network);
      expect(mediaUtils.getMediaSource('file://path/to/image.png'),
          MediaSource.File);
      expect(mediaUtils.getMediaSource('asset://path/to/image.png'),
          MediaSource.Asset);
      expect(mediaUtils.getMediaSource('resource://path/to/image.png'),
          MediaSource.Resource);
      expect(mediaUtils.getMediaSource(null), MediaSource.Unknown);
    });

    test('Clean media path', () {
      expect(
          mediaUtils.cleanMediaPath('file://path/to/image.png'),
          '/path/to/image.png');
      expect(
          mediaUtils.cleanMediaPath('asset://path/to/image.png'),
          'path/to/image.png');
      expect(
          mediaUtils.cleanMediaPath('resource://path/to/image.png'),
          'path/to/image.png');
      expect(mediaUtils.cleanMediaPath('https://example.com/image.png'),
          'https://example.com/image.png');
    });

    test('Get from media path', () {
      expect(mediaUtils.getFromMediaPath('http://example.com/image.png'),
          null);
      expect(mediaUtils.getFromMediaPath('https://example.com/image.png'),
          null);
      expect(mediaUtils.getFromMediaPath('asset://path/to/image.png'), null);
      expect(mediaUtils.getFromMediaPath('resource://path/to/image.png'),
          null);
    });
  });
}
