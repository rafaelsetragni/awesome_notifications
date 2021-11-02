package me.carda.awesome_notifications.utils;

import java.sql.Time;
import java.text.ParseException;
import java.util.Calendar;
import java.util.Date;
import java.util.TimeZone;

import me.carda.awesome_notifications.externalLibs.CronExpression;
import me.carda.awesome_notifications.notifications.exceptions.AwesomeNotificationException;

public final class CronUtils {

    public static String validDateFormat = "yyyy-MM-dd HH:mm:ss";

    /// https://www.baeldung.com/cron-expressions
    /// <second> <minute> <hour> <day-of-month> <month> <day-of-week> <year>
    public static Calendar getNextCalendar(
        String initialDateTime,
        String crontabRule,
        Date fixedNowDate,
        TimeZone timeZone
    ) throws AwesomeNotificationException {

        if(StringUtils.isNullOrEmpty(crontabRule))
            return null;

        Date now, delayedNow;
        if(fixedNowDate == null){
            now = DateUtils.getUTCDateTime();
        } else {
            now = fixedNowDate;
        }

        if(!StringUtils.isNullOrEmpty(initialDateTime))
        {
            Date initialScheduleDay = DateUtils.stringToDate(initialDateTime, timeZone.getID());

            // if initial date is a future one, show in future. Otherwise, show now
            switch (initialScheduleDay.compareTo(now)){

                case 0: // if initial date is right now or
                case -1: // if initial date is in the past, do not change now
                    break;

                case 1: // if initial date is in future, shows in future
                default:
                    now = initialScheduleDay;
                    break;
            }
        }

        delayedNow = applyToleranceDate(now, timeZone);

        if(CronExpression.isValidExpression(crontabRule)) {
            try {
                CronExpression cronExpression = new CronExpression(crontabRule);
                cronExpression.setTimeZone(timeZone);
                Date nextSchedule = cronExpression.getNextValidTimeAfter(now);

                if (nextSchedule != null && nextSchedule.compareTo(delayedNow) > 0) {

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
    public static Date applyToleranceDate(Date initialScheduleDay, TimeZone timeZone) {
        Calendar calendarHelper = Calendar.getInstance();
        calendarHelper.setTimeZone(timeZone);
        calendarHelper.setTime(initialScheduleDay);
        calendarHelper.set(Calendar.MILLISECOND,(calendarHelper.get(Calendar.MILLISECOND)-999));
        Date delayedScheduleDay = calendarHelper.getTime();
        return delayedScheduleDay;
    }
}

