import 'package:awesome_notifications/src/utils/html_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('removeAllHtmlTags()', () {
    test('Null string', () {
      expect(AwesomeHtmlUtils.removeAllHtmlTags(null), null);
    });

    test('Empty string', () {
      expect(AwesomeHtmlUtils.removeAllHtmlTags(""), "");
    });

    test('Plain text without HTML tags', () {
      expect(AwesomeHtmlUtils.removeAllHtmlTags("Hello, World!"), "Hello, World!");
    });

    test('Text with single HTML tag', () {
      expect(
          AwesomeHtmlUtils.removeAllHtmlTags("<p>Hello, World!</p>"),
          "Hello, World!");
    });

    test('Text with nested HTML tags', () {
      expect(
          AwesomeHtmlUtils.removeAllHtmlTags(
              "<div><p><strong>Hello, World!</strong></p></div>"),
          "Hello, World!");
    });

    test('Text with multiple HTML tags', () {
      expect(
          AwesomeHtmlUtils.removeAllHtmlTags(
              "<h1>Title</h1><p>Paragraph <em>with</em> emphasis.</p>"),
          "TitleParagraph with emphasis.");
    });
  });
}