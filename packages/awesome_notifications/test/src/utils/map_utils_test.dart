import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Test with non-empty map', () {
    Map<String, dynamic> mapData = {
      "c": 3,
      "a": 1,
      "b": 2,
      "nested": {"y": 5, "x": 4},
    };

    String expectedOutput =
'''{
  "a": 1,
  "b": 2,
  "c": 3,
  "nested": {
    "y": 5,
    "x": 4
  }
}''';

    expect(AwesomeMapUtils.printPrettyMap(mapData), expectedOutput);
  });

  test('Test with empty map', () {
    Map<String, dynamic> emptyMapData = {};

    String expectedEmptyOutput = '{}';
    expect(AwesomeMapUtils.printPrettyMap(emptyMapData), expectedEmptyOutput);
  });

  test('Test with null values', () {
    Map<String, dynamic> mapWithNullValues = {
      "a": null,
      "b": 2,
      "c": null,
    };

    String expectedOutputWithNullValues =
'''{
  "a": null,
  "b": 2,
  "c": null
}''';

    expect(
        AwesomeMapUtils.printPrettyMap(mapWithNullValues),
        expectedOutputWithNullValues);
  });
}