import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:mocktail/mocktail.dart';
import 'dart:ui' as ui show Codec;

// Mock the AwesomeNotifications class
class MockAwesomeNotifications extends Mock implements AwesomeNotifications {}

class MockCodec extends Mock implements ui.Codec {}

void main() {
  group('ResourceImage tests', () {
    test('ResourceImage constructor creates an instance with provided data',
        () {
      ResourceImage resourceImage =
          const ResourceImage('drawable_path', scale: 2.0);

      expect(resourceImage.drawablePath, 'drawable_path');
      expect(resourceImage.scale, 2.0);
    });

    test('ResourceImage equality and hashCode', () {
      ResourceImage resourceImage1 =
          const ResourceImage('drawable_path', scale: 2.0);
      ResourceImage resourceImage2 =
          const ResourceImage('drawable_path', scale: 2.0);
      ResourceImage resourceImage3 =
          const ResourceImage('different_drawable_path', scale: 2.0);
      ResourceImage resourceImage4 =
          const ResourceImage('drawable_path', scale: 1.0);

      expect(resourceImage1.hashCode, resourceImage2.hashCode);
      expect(resourceImage1, resourceImage2);
      expect(resourceImage1.hashCode != resourceImage3.hashCode, true);
      expect(resourceImage1 != resourceImage3, true);
      expect(resourceImage1.hashCode != resourceImage4.hashCode, true);
      expect(resourceImage1 != resourceImage4, true);
    });

    testWidgets('ResourceImage loads and displays the image',
        (WidgetTester tester) async {
      // Replace the real AwesomeNotifications class with the mock
      AwesomeNotifications awesomeNotifications = MockAwesomeNotifications();
      // Mock the getDrawableData method to return Uint8List of a small 1x1 pixel image
      when(() => awesomeNotifications.getDrawableData(any()))
          .thenAnswer((_) async {
        final byteData =
            await rootBundle.load('test/assets/images/test_image.png');
        return byteData.buffer.asUint8List();
      });

      ResourceImage resourceImage = ResourceImage('drawable_path',
          scale: 2.0, awesomeNotifications: awesomeNotifications);

      // Create a widget to test the ResourceImage
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: Builder(
              builder: (BuildContext context) {
                return Image(
                  image: resourceImage,
                );
              },
            ),
          ),
        ),
      );

      // Trigger a frame
      await tester.pump();

      // Verify that the image is displayed
      final Finder imageFinder = find.byType(Image);
      expect(imageFinder, findsOneWidget);

      // Clean up after the test
      await tester.pumpWidget(Container());
    });

    testWidgets('ResourceImage fails to load and display the invalid image',
        (WidgetTester tester) async {
      // Replace the real AwesomeNotifications class with the mock
      AwesomeNotifications awesomeNotifications = MockAwesomeNotifications();
      // Mock the getDrawableData method to return Uint8List of a small 1x1 pixel image
      when(() => awesomeNotifications.getDrawableData(any()))
          .thenAnswer((_) async {
        return Uint8List(0);
      });

      expect(
        () {
          ResourceImage resourceImage = ResourceImage('drawable_path',
              scale: 2.0, awesomeNotifications: awesomeNotifications);
          return resourceImage.loadAsync(
              resourceImage,
              (buffer,
                      {int? cacheWidth,
                      int? cacheHeight,
                      bool allowUpscaling = true}) =>
                  Future.value(MockCodec()));
        },
        throwsA(isA<AwesomeNotificationsException>()),
      );
    });
  });
}
