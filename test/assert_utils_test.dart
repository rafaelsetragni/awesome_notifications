import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:awesome_notifications/src/enumerators/time_and_date.dart';
import 'package:awesome_notifications/src/helpers/cron_helper.dart';
import 'package:awesome_notifications/src/utils/assert_utils.dart';

void main() {

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
  });

  tearDown(() {
  });

  test('test isNullOrEmptyOrInvalid', () async {

    expect(AssertUtils.isNullOrEmptyOrInvalid(null, String), true);
    expect(AssertUtils.isNullOrEmptyOrInvalid('', String), true);
    expect(AssertUtils.isNullOrEmptyOrInvalid(0, String), true);
    expect(AssertUtils.isNullOrEmptyOrInvalid(false, String), true);
    expect(AssertUtils.isNullOrEmptyOrInvalid('test', String), false);

    expect(AssertUtils.isNullOrEmptyOrInvalid(null, List), true);
    expect(AssertUtils.isNullOrEmptyOrInvalid('', List), true);
    expect(AssertUtils.isNullOrEmptyOrInvalid(0, List), true);
    expect(AssertUtils.isNullOrEmptyOrInvalid(false, List), true);
    expect(AssertUtils.isNullOrEmptyOrInvalid('test', List), true);
    expect(AssertUtils.isNullOrEmptyOrInvalid([], List), true);
    expect(AssertUtils.isNullOrEmptyOrInvalid(['test'], List), true);
    expect(AssertUtils.isNullOrEmptyOrInvalid([0], List<String>().runtimeType), true);
    expect(AssertUtils.isNullOrEmptyOrInvalid(['test'], List<String>().runtimeType), false);

  });

  test('test extractMap', () async {

    Map<String, dynamic> testStringDynamicMap = {
      'test1':'test',
      'test2':1
    };

    Map<dynamic, dynamic> testDynamicDynamicMap = {
      'test1':'test',
      'test2':1
    };

    Map<String, String> testStringStringMap = {
      'test1':'test',
      'test2':'1'
    };

    Map<String, dynamic> testGeneralMap = {
      'testDynamicDynamicMap':testDynamicDynamicMap,
      'testStringDynamicMap':testStringDynamicMap,
      'testStringStringMap':testStringStringMap
    };

    Map<String, dynamic> testStringMapReturned1 = AssertUtils.extractMap<String, dynamic>(testGeneralMap, 'testStringDynamicMap');
    expect(testStringMapReturned1, testStringDynamicMap);

    Map<String, String> testStringMapReturned2 = AssertUtils.extractMap<String, String>(testGeneralMap, 'testStringStringMap');
    expect(testStringMapReturned2, testStringStringMap);

    Map<String, String> testStringMapReturned3 = AssertUtils.extractMap<String, String>(testGeneralMap, 'testStringStringMap');
    expect(testStringMapReturned3, testStringStringMap);

    Map<String, dynamic> testStringMapReturned4 = AssertUtils.extractMap<String, dynamic>(testGeneralMap, 'testStringDynamicMap');
    expect(testStringMapReturned4, testStringDynamicMap);

    Map<String, dynamic> testStringMapReturned5 = AssertUtils.extractMap<String, dynamic>(testGeneralMap, 'testDynamicDynamicMap');
    expect(testStringMapReturned5, testDynamicDynamicMap);

    Map<String, String> testStringMapReturned6 = AssertUtils.extractMap<String, String>(testGeneralMap, 'testDynamicDynamicMap');
    expect(testStringMapReturned6, null);

  });
}
