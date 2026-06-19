import 'package:intl/intl.dart';

class AwesomeDateUtils {
  static DateTime? parseStringToDateUtc(String? date,
      {String format = 'yyyy-MM-dd HH:mm:ss'}) {
    if (date == null || date.isEmpty) return null;

    RegExp dateRegex =
        RegExp(r'(\d{4}-\d{2}-\d{2})[T\s]+(\d{2}:\d{2}:\d{2})(.\d{1,3})?');
    Match? match = dateRegex.firstMatch(date);
    if (match == null) return null;

    date = '${match.group(1)} ${match.group(2)}';
    return DateFormat(format).parseUTC(date);
  }

  static DateTime? parseStringToDate(String? date,
      {String format = 'yyyy-MM-dd HH:mm:ss'}) {
    if (date == null || date.isEmpty) return null;

    RegExp dateRegex =
        RegExp(r'(\d{4}-\d{2}-\d{2})[T\s]+(\d{2}:\d{2}:\d{2})(.\d{1,3})?');
    Match? match = dateRegex.firstMatch(date);
    if (match == null) return null;

    date = '${match.group(1)} ${match.group(2)}';
    return DateFormat(format).parse(date);
  }

  static String? parseDateToString(DateTime? date,
      {String format = 'yyyy-MM-dd HH:mm:ss'}) {
    if (date == null) return null;
    return DateFormat(format).format(date);
  }

  static DateTime utcToLocal(DateTime date,
      {String format = 'yyyy-MM-dd HH:mm:ss'}) {
    DateTime parsedUTCDate =
        DateFormat(format).parseUTC(parseDateToString(date)!);
    return parsedUTCDate.toLocal();
  }

  static DateTime localToUtc(DateTime date,
      {String format = 'yyyy-MM-dd HH:mm:ss'}) {
    DateTime parsedLocalDate =
        DateFormat(format).parse(parseDateToString(date)!);
    return parsedLocalDate.toUtc();
  }
}
