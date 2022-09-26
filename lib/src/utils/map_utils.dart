import 'dart:collection';
import 'dart:convert';

class AwesomeMapUtils {
  static String printPrettyMap(Map mapData) {
    JsonEncoder encoder = const JsonEncoder.withIndent('  ');

    // display map in alphabetic order
    final sortedData =
        SplayTreeMap<String, dynamic>.from(mapData, (a, b) => a.compareTo(b));
    String prettyPrint = encoder.convert(sortedData);

    return prettyPrint;
  }
}
