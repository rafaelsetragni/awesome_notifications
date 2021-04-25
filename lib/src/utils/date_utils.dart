import 'package:intl/intl.dart';

class DateUtils {
  static DateTime? parseStringToDate(String? date,
      {String format: 'yyyy-MM-dd HH:mm:ss'}) {
    if (date == null || date.isEmpty) return null;
    return DateFormat(format).parseUTC(date);
  }

  static String? parseDateToString(DateTime? date,
      {String format: 'yyyy-MM-dd HH:mm:ss'}) {
    if (date == null) return null;
    return DateFormat(format).format(date);
  }

  static DateTime utcToLocal(DateTime date,
      {String format: 'yyyy-MM-dd HH:mm:ss'}) {
    DateTime parsedUTCDate =
        DateFormat(format).parseUTC(parseDateToString(date)!);
    return parsedUTCDate.toLocal();
  }

  static DateTime localToUtc(DateTime date,
      {String format: 'yyyy-MM-dd HH:mm:ss'}) {
    DateTime parsedLocalDate =
        DateFormat(format).parse(parseDateToString(date)!);
    return parsedLocalDate.toUtc();
  }
}
