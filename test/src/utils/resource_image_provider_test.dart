import 'package:flutter_test/flutter_test.dart';

import 'package:awesome_notifications/awesome_notifications.dart';

void main() {
  late AwesomeNotifications awesomeNotifications;
  late ResourceImage resourceImage;

  setUp(() async {
    awesomeNotifications = AwesomeNotifications();
    await awesomeNotifications.initialize(null, []);
    resourceImage = const ResourceImage('resource://path/to/image.png');
  });

  group('ResourceImage', () {
    test('Equality and hashCode', () {
      ResourceImage anotherResourceImage =
      const ResourceImage('resource://path/to/image.png');
      expect(resourceImage, anotherResourceImage);
      expect(resourceImage.hashCode, anotherResourceImage.hashCode);
    });
  });
}
