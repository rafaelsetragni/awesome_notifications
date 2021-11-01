import 'package:awesome_notifications/src/enumerators/time_and_date.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Cron helper to set notification repetitions
/// Use the rule bellow to specify your on cron repetition rule or access
/// the website https://www.baeldung.com/cron-expressions to see more details.
///
/// <second> <minute> <hour> <day-of-month> <month> <day-of-week> <year>
///
/// OBS: Do not use <day-of-month> and <day-of-week> simultaneously. Chose one of
/// then, marking the other one with ? tag to be ignored
class CronHelper {
  DateTime? _fixedNow;

  /// FACTORY METHODS *********************************************

  factory CronHelper() => instance;

  @visibleForTesting
  CronHelper.private({DateTime? fixedNow}) : _fixedNow = fixedNow;

  static final CronHelper instance = CronHelper.private();

  /// FACTORY METHODS *********************************************

  String dateFormat = 'dd-MM-yyyy hh:mm';

  DateTime _getNow() {
    return _fixedNow ?? DateTime.now();
  }

  /// Get the current UTC date
  String get utc {
    return DateFormat(dateFormat).format(_getNow().toUtc());
  }

  /// Generates a Cron expression to be played at only exact time
  String atDate({required DateTime referenceDateTime}) {
    return DateFormat('s m H d M ? y').format(referenceDateTime);
  }

  /// Generates a Cron expression to be played only once at year from now
  String yearly({required DateTime referenceDateTime}) {
    return DateFormat('s m H d M ? *').format(referenceDateTime);
  }

  /// Generates a Cron expression to be played only once at month from now
  String monthly({required DateTime referenceDateTime}) {
    return DateFormat('s m H d * ? *').format(referenceDateTime);
  }

  /// Generates a Cron expression to be played only once at week from now
  String weekly({required DateTime referenceDateTime}) {
    return DateFormat('s m H ? M E *').format(referenceDateTime).toUpperCase();
  }

  /// Generates a Cron expression to be played only once at day from now
  String daily({required DateTime referenceDateTime}) {
    return DateFormat('s m H * * ? *').format(referenceDateTime);
  }

  /// Generates a Cron expression to be played only once at hour from now
  String hourly({required DateTime referenceDateTime}) {
    return DateFormat('s m * * * ? *').format(referenceDateTime);
  }

  /// Generates a Cron expression to be played only once at every minute from now
  String minutely({required int initialSecond}) {
    return '$initialSecond * * * * ? *';
  }

  /// Generates a Cron expression to be played only on workweek days from now
  String workweekDay({required DateTime referenceDateTime}) {
    return DateFormat('s m H ? * ').format(referenceDateTime) + '$MON-$FRI *';
  }

  /// Generates a Cron expression to be played only on weekend days from now
  String weekendDay({required DateTime referenceDateTime}) {
    return DateFormat('s m H ? * ').format(referenceDateTime) + '$SAT,$SUN *';
  }
}
