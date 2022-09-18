package me.carda.awesome_notifications.core.utils;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import java.text.ParseException;
import java.util.Calendar;
import java.util.Date;
import java.util.TimeZone;

import me.carda.awesome_notifications.core.exceptions.AwesomeNotificationsException;
import me.carda.awesome_notifications.core.externalLibs.CronExpression;

public final class CronUtils {

    public static String validDateFormat = "yyyy-MM-dd HH:mm:ss";

    /// https://www.baeldung.com/cron-expressions
    /// <second> <minute> <hour> <day-of-month> <month> <day-of-week> <year>
    @Nullable
    public static Calendar getNextCalendar(
        @NonNull Calendar fixedNowDate,
        @NonNull String crontabRule,
        @NonNull TimeZone timeZone
    ) throws AwesomeNotificationsException {

        if(
            fixedNowDate == null ||
            timeZone == null ||
            StringUtils.getInstance().isNullOrEmpty(crontabRule)
        ) return null;

        if(CronExpression.isValidExpression(crontabRule)) {
            try {
                CronExpression cronExpression = new CronExpression(crontabRule);
                cronExpression.setTimeZone(timeZone);
                Date nextSchedule =
                        cronExpression
                                .getNextValidTimeAfter(fixedNowDate.getTime());

                Calendar delayedNow = applyToleranceDate(fixedNowDate);
                if (nextSchedule != null && nextSchedule.compareTo(delayedNow.getTime()) >= 0) {

                    Calendar calendar = Calendar.getInstance();
                    calendar.setTimeZone(timeZone);
                    calendar.setTime(nextSchedule);
                    return calendar;

                } else {
                    // if there is no more valid dates, remove the repetitions
                    return null;
                }

            } catch (ParseException e) {
                e.printStackTrace();
            }
        }

        return null;
    }

    /// Processing time tolerance
    public static Calendar applyToleranceDate(Calendar initialScheduleDay) {
        Calendar shifted = (Calendar) initialScheduleDay.clone();
        shifted.set(Calendar.MILLISECOND, 0);
        return shifted;
    }
}

