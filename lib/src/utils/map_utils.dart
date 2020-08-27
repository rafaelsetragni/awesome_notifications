import 'dart:collection';
import 'dart:convert';

class MapUtils {
  static String printPrettyMap(Map mapData) {
    JsonEncoder encoder = JsonEncoder.withIndent('  ');

    // display map in alphabetic order
    final sortedData = new SplayTreeMap<String, dynamic>.from(
        mapData, (a, b) => a.compareTo(b));
    String prettyPrint = encoder.convert(sortedData);

    return prettyPrint;
  }
}
