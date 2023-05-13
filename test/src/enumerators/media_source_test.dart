import 'package:awesome_notifications/src/enumerators/media_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MediaSourcePrefix tests', () {
    test('MediaSourcePrefix values are set correctly', () {
      expect(MediaSourcePrefix.Resource, 'resource://');
      expect(MediaSourcePrefix.Asset, 'asset://');
      expect(MediaSourcePrefix.File, 'file://');
      expect(MediaSourcePrefix.Network, 'https://');
      expect(MediaSourcePrefix.Unknown, '');

      expect(MediaSourcePrefix.values,
          containsAll(['resource://', 'asset://', 'file://', 'https://', '']));
    });

    test('MediaSourcePrefix index is set correctly', () {
      expect(const MediaSourcePrefix(1).value, 1);
    });
  });
}
