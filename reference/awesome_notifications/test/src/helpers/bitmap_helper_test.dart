import 'dart:typed_data';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/painting.dart';

void main() {
  group('BitmapHelper tests', () {
    const int width = 10;
    const int height = 10;

    test('Creating BitmapHelper using different constructors', () {
      final Uint8List content = Uint8List.fromList(
          List.filled(width * height * bitmapPixelLength, 0));

      // Test BitmapHelper.fromHeadless
      final BitmapHelper bitmapHeadless =
          BitmapHelper.fromHeadless(width, height, content);
      expect(bitmapHeadless.width, width);
      expect(bitmapHeadless.height, height);
      expect(bitmapHeadless.content, content);

      // Test BitmapHelper.fromHeadful
      final Uint8List headedContent =
          Uint8List.fromList([...List.filled(RGBA32HeaderSize, 0), ...content]);
      final BitmapHelper bitmapHeadful =
          BitmapHelper.fromHeadful(width, height, headedContent);
      expect(bitmapHeadful.width, width);
      expect(bitmapHeadful.height, height);
      expect(bitmapHeadful.content, content);

      // Test BitmapHelper.blank
      final BitmapHelper bitmapBlank = BitmapHelper.blank(width, height);
      expect(bitmapBlank.width, width);
      expect(bitmapBlank.height, height);
      expect(bitmapBlank.content, content);
    });

    test('Cloning BitmapHelper', () {
      final Uint8List content = Uint8List.fromList(
          List.filled(width * height * bitmapPixelLength, 0));
      final BitmapHelper original =
          BitmapHelper.fromHeadless(width, height, content);
      final BitmapHelper clone = original.cloneHeadless();

      expect(clone.width, original.width);
      expect(clone.height, original.height);
      expect(clone.content, original.content);
    });

    test('Build image from BitmapHelper', () async {
      final Uint8List content = Uint8List.fromList(
          List.filled(width * height * bitmapPixelLength, 0));
      final BitmapHelper bitmap =
          BitmapHelper.fromHeadless(width, height, content);

      final image = await bitmap.buildImage();
      expect(image.width, width);
      expect(image.height, height);
    });

    test('Build headed content from BitmapHelper', () {
      final Uint8List content = Uint8List.fromList(
          List.filled(width * height * bitmapPixelLength, 0));
      final BitmapHelper bitmap =
          BitmapHelper.fromHeadless(width, height, content);

      final headedContent = bitmap.buildHeaded();
      expect(headedContent.length, bitmap.size + RGBA32HeaderSize);
      expect(headedContent.sublist(RGBA32HeaderSize), content);
    });
  });

  group('BitmapHelper tests', () {
    const int width = 2480;
    const int height = 2480;

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    // Other test cases (previously provided) go here

    test('Create BitmapHelper from ImageProvider', () async {
      const ImageProvider provider = AssetImage(
          'test/assets/images/test_image.png'); // Replace with an actual image file in your assets folder
      final BitmapHelper bitmap = await BitmapHelper.fromImageProvider(provider);

      expect(bitmap.width, width); // Replace with actual image width
      expect(bitmap.height, height); // Replace with actual image height

      final image = await bitmap.buildImage();
      expect(image.width, width); // Replace with actual image width
      expect(image.height, height); // Replace with actual image height
    });
  });
}
