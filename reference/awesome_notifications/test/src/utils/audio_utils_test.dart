import 'package:awesome_notifications/src/utils/audio_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final audioUtils = AwesomeAudioUtils();

  group('getFromMediaPath()', () {
    test('Unknown media path', () {
      expect(audioUtils.getFromMediaPath('unknown:///path/to/audio.mp3'), null);
    });

    test('Network media path', () {
      expect(audioUtils.getFromMediaPath('https://example.com/audio.mp3'), null);
    });

    test('File media path', () {
      expect(audioUtils.getFromMediaPath('file://path/to/audio.mp3'), null);
    });

    test('Asset media path', () {
      expect(audioUtils.getFromMediaPath('asset://path/to/audio.mp3'), null);
    });

    test('Resource media path', () {
      expect(audioUtils.getFromMediaPath('resource://path/to/audio.mp3'), null);
    });
  });
}