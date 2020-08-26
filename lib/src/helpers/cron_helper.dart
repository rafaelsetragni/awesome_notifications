import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:awesome_notifications/src/enumerators/time_and_date.dart';

/// Cron helper to set notification repetitions
/// Use the rule bellow to specify your on cron repetition rule or access
/// the website https://www.baeldung.com/cron-expressions to see more details.
///
/// <second> <minute> <hour> <day-of-month> <month> <day-of-week> <year>
///
/// OBS: Do not use <day-of-month> and <day-of-week> simultaneously. Chose one of
/// then, marking the other one with ? tag to be ignored
class CronHelper {

    DateTime _fixedNow;

    /// FACTORY METHODS *********************************************
    factory CronHelper() => instance;

    @visibleForTesting
    CronHelper.private({DateTime fixedNow})
        : _fixedNow = fixedNow;

    static final CronHelper instance = CronHelper.private();

    String dateFormat = 'dd-MM-yyyy hh:mm';

    DateTime _getNow(){
        return _fixedNow ?? DateTime.now();
    }

    String get utc{
        return DateFormat(dateFormat).format(_getNow().toUtc());
    }

    String atDate(DateTime referenceUtcDate, {int initialSecond}) {
        if(initialSecond != null && initialSecond >= 0 && initialSecond <= 60){
            if(initialSecond == 60) initialSecond = 0;
            return DateFormat('$initialSecond m H d M ? y').format(referenceUtcDate ?? _getNow().toUtc());
        }
        return DateFormat('s m H d M ? y').format(referenceUtcDate ?? _getNow().toUtc());
    }

    String yearly({DateTime referenceUtcDate}) {
        return DateFormat('s m H d M ? *').format(referenceUtcDate ?? _getNow().toUtc());
    }

    String monthly({DateTime referenceUtcDate}) {
        return DateFormat('s m H d * ? *').format(referenceUtcDate ?? _getNow().toUtc());
    }

    String weekly({DateTime referenceUtcDate}) {
        return DateFormat('s m H ? M E *').format(referenceUtcDate ?? _getNow().toUtc()).toUpperCase();
    }

    String daily({DateTime referenceUtcDate}) {
        return DateFormat('s m H * * ? *').format(referenceUtcDate ?? _getNow().toUtc());
    }

    String hourly({DateTime referenceUtcDate}) {
        return DateFormat('s m * * * ? *').format(referenceUtcDate ?? _getNow().toUtc());
    }

    String minutely({DateTime referenceUtcDate, int initialSecond}) {
        if(initialSecond != null && initialSecond >= 0 && initialSecond <= 60){
            if(initialSecond == 60) initialSecond = 0;
            return DateFormat('$initialSecond * * * * ? *').format(referenceUtcDate ?? _getNow().toUtc());
        }
        return DateFormat('s * * * * ? *').format(referenceUtcDate ?? _getNow().toUtc());
    }

    String workweekDay({DateTime referenceUtcDate}) {
        return DateFormat('s m H ? * ').format(referenceUtcDate ?? _getNow().toUtc()) + '$MON-$FRI *';
    }

    String weekendDay({DateTime referenceUtcDate}) {
        return DateFormat('s m H ? * ').format(referenceUtcDate ?? _getNow().toUtc()) + '$SAT,$SUN *';
    }
}