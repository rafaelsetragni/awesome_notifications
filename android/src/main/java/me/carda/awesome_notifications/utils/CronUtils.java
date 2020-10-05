package me.carda.awesome_notifications.utils;

import java.text.ParseException;
import java.util.Calendar;
import java.util.Date;

import me.carda.awesome_notifications.externalLibs.CronExpression;

public final class CronUtils {

    public static Date fixedNowDate;

    public static String validDateFormat = "yyyy-MM-dd HH:mm:ss";

    /// https://www.baeldung.com/cron-expressions
    /// <second> <minute> <hour> <day-of-month> <month> <day-of-week> <year>
    public static Calendar getNextCalendar(
        String initialDateTime,
        String crontabRule
    ){

        if(StringUtils.isNullOrEmpty(initialDateTime) && StringUtils.isNullOrEmpty(crontabRule))
            return null;

        Calendar calendar = Calendar.getInstance();
        calendar.setTimeZone(DateUtils.utcTimeZone);

        Date now, delayedNow;
        if(fixedNowDate == null){
            now = DateUtils.getUTCDateTime();
        } else {
            now = fixedNowDate;
        }

        Date initialScheduleDay;
        if (initialDateTime == null) {
            initialScheduleDay = now;
        }
        else {
            initialScheduleDay = DateUtils.parseDate(initialDateTime);
        }

        // if initial date is a future one, show in future. Otherwise, show now
        switch (initialScheduleDay.compareTo(now)){

            case -1: // if initial date is not a repetition and is in the past, do not show
                if(StringUtils.isNullOrEmpty(crontabRule))
                    return null;
                calendar.setTime(now);
                break;

            case 1: // if initial date is in future, shows in future
            case 0: // if initial date is right now, shows now
            default:
                calendar.setTime(initialScheduleDay);
                break;
        }

        delayedNow = applyToleranceDate(now);

        if (!StringUtils.isNullOrEmpty(crontabRule)) {

            if(CronExpression.isValidExpression(crontabRule)) {
                try {
                    CronExpression cronExpression = new CronExpression(crontabRule);
                    cronExpression.setTimeZone(DateUtils.utcTimeZone);
                    Date nextSchedule = cronExpression.getNextValidTimeAfter(now);

                    if (nextSchedule != null && nextSchedule.compareTo(delayedNow) > 0) {
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

        return calendar;
    }

    /// Processing time tolerance
    public static Date applyToleranceDate(Date initialScheduleDay) {
        Calendar calendarHelper = Calendar.getInstance();
        calendarHelper.setTimeZone(DateUtils.utcTimeZone);
        calendarHelper.setTime(initialScheduleDay);
        calendarHelper.set(Calendar.MILLISECOND,(calendarHelper.get(Calendar.MILLISECOND)-999));
        Date delayedScheduleDay = calendarHelper.getTime();
        return delayedScheduleDay;
    }
}

