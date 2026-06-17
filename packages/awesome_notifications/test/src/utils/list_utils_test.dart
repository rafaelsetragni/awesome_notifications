import 'package:awesome_notifications/src/utils/list_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isNullOrEmpty test', () {
    test('detect if list is null or empty', () {
      expect(AwesomeListUtils.isNullOrEmpty(null), true);
      expect(AwesomeListUtils.isNullOrEmpty([]), true);
    });

    test('detect if a non empty list is not empty', () {
      expect(AwesomeListUtils.isNullOrEmpty([null]), false);
      expect(AwesomeListUtils.isNullOrEmpty([1]), false);
      expect(AwesomeListUtils.isNullOrEmpty([1, 2]), false);
      expect(AwesomeListUtils.isNullOrEmpty([1, 2, 3]), false);
    });
  });
}
