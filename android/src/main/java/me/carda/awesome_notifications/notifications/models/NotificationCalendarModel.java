package me.carda.awesome_notifications.notifications.models;

import android.content.Context;

import java.util.Calendar;
import java.util.Date;
import java.util.Map;
import java.util.TimeZone;

import me.carda.awesome_notifications.Definitions;
import me.carda.awesome_notifications.notifications.exceptions.AwesomeNotificationException;
import me.carda.awesome_notifications.utils.CronUtils;
import me.carda.awesome_notifications.utils.DateUtils;
import me.carda.awesome_notifications.utils.IntegerUtils;
import me.carda.awesome_notifications.utils.StringUtils;

public class NotificationCalendarModel extends NotificationScheduleModel {

    /// Field number for get and set indicating the era, e.g., AD or BC in the Julian calendar
    public Integer era;
    /// Field number for get and set indicating the year.
    public Integer year;
    /// Field number for get and set indicating the month.
    public Integer month;
    /// Field number for get and set indicating the day number within the current year (1-12).
    public Integer day;
    /// Field number for get and set indicating the hour of the day (0-23).
    public Integer hour;
    /// Field number for get and set indicating the minute within the hour (0-59).
    public Integer minute;
    /// Field number for get and set indicating the second within the minute (0-59).
    public Integer second;
    /// Field number for get and set indicating the millisecond within the second.
    public Integer millisecond;
    /// Field number for get and set indicating the day of the week.
    public Integer weekday;
    /// Field number for get and set indicating the count of weeks of the month.
    public Integer weekOfMonth;
    /// Field number for get and set indicating the weeks of the year.
    public Integer weekOfYear;

    private String weekdayName;

    @Override
    @SuppressWarnings("unchecked")
    public NotificationCalendarModel fromMap(Map<String, Object> arguments) {
        super.fromMap(arguments);

        era = getValueOrDefault(arguments, Definitions.NOTIFICATION_SCHEDULE_ERA, Integer.class);
        year = getValueOrDefault(arguments, Definitions.NOTIFICATION_SCHEDULE_YEAR, Integer.class);
        month = getValueOrDefault(arguments, Definitions.NOTIFICATION_SCHEDULE_MONTH, Integer.class);
        day = getValueOrDefault(arguments, Definitions.NOTIFICATION_SCHEDULE_DAY, Integer.class);
        hour = getValueOrDefault(arguments, Definitions.NOTIFICATION_SCHEDULE_HOUR, Integer.class);
        minute = getValueOrDefault(arguments, Definitions.NOTIFICATION_SCHEDULE_MINUTE, Integer.class);
        second = getValueOrDefault(arguments, Definitions.NOTIFICATION_SCHEDULE_SECOND, Integer.class);
        millisecond = getValueOrDefault(arguments, Definitions.NOTIFICATION_SCHEDULE_MILLISECOND, Integer.class);
        weekday = getValueOrDefault(arguments, Definitions.NOTIFICATION_SCHEDULE_WEEKDAY, Integer.class);
        weekOfMonth = getValueOrDefault(arguments, Definitions.NOTIFICATION_SCHEDULE_WEEKOFMONTH, Integer.class);
        weekOfYear = getValueOrDefault(arguments, Definitions.NOTIFICATION_SCHEDULE_WEEKOFYEAR, Integer.class);

        if(era != null && era < 0){ era = null; }
        if(year != null && year < 0){ year = null; }
        if(month != null && month < 0){ month = null; }
        if(day != null && day < 0){ day = null; }
        if(hour != null && hour < 0){ hour = null; }
        if(minute != null && minute < 0){ minute = null; }
        if(second != null && second < 0){ second = null; }
        if(millisecond != null && millisecond < 0){ millisecond = null; }
        if(weekday != null && weekday < 0){ weekday = null; }
        if(weekOfMonth != null && weekOfMonth < 0){ weekOfMonth = null; }
        if(weekOfYear != null && weekOfYear < 0){ weekOfYear = null; }

        if(weekday != null)
            weekday = weekday == 7 ? 1 : (weekday + 1);

        return this;
    }

    @Override
    public Map<String, Object> toMap(){
        Map<String, Object> returnedObject = super.toMap();

        returnedObject.put(Definitions.NOTIFICATION_SCHEDULE_TIMEZONE, timeZone);
        returnedObject.put(Definitions.NOTIFICATION_SCHEDULE_ERA, era);
        returnedObject.put(Definitions.NOTIFICATION_SCHEDULE_YEAR, year);
        returnedObject.put(Definitions.NOTIFICATION_SCHEDULE_MONTH, month);
        returnedObject.put(Definitions.NOTIFICATION_SCHEDULE_DAY, day);
        returnedObject.put(Definitions.NOTIFICATION_SCHEDULE_HOUR, hour);
        returnedObject.put(Definitions.NOTIFICATION_SCHEDULE_MINUTE, minute);
        returnedObject.put(Definitions.NOTIFICATION_SCHEDULE_SECOND, second);
        returnedObject.put(Definitions.NOTIFICATION_SCHEDULE_MILLISECOND, millisecond);
        returnedObject.put(Definitions.NOTIFICATION_SCHEDULE_WEEKOFMONTH, weekOfMonth);
        returnedObject.put(Definitions.NOTIFICATION_SCHEDULE_WEEKOFYEAR, weekOfYear);

        returnedObject.put(Definitions.NOTIFICATION_SCHEDULE_WEEKDAY, weekday == null ? null : (weekday == 1 ? 7 : (weekday - 1)));

        return returnedObject;
    }

    @Override
    public String toJson() {
        return templateToJson();
    }

    @Override
    public NotificationCalendarModel fromJson(String json){
        return (NotificationCalendarModel) super.templateFromJson(json);
    }

    @Override
    public void validate(Context context) throws AwesomeNotificationException {

        if(
            era != null &&
            year != null &&
            month != null &&
            day != null &&
            hour != null &&
            minute != null &&
            second != null &&
            millisecond != null &&
            weekday != null &&
            weekOfMonth != null &&
            weekOfYear != null
        )
            throw new AwesomeNotificationException("At least one parameter is required");

        if(!(
            (era == null || IntegerUtils.isBetween(era, 0, 99999)) &&
            (year == null || IntegerUtils.isBetween(year, 0, 99999)) &&
            (month == null || IntegerUtils.isBetween(month, 1, 12)) &&
            (day == null || IntegerUtils.isBetween(day, 1, 31)) &&
            (hour == null || IntegerUtils.isBetween(hour, 0, 23)) &&
            (minute == null || IntegerUtils.isBetween(minute, 0, 59)) &&
            (second == null || IntegerUtils.isBetween(second, 0, 59)) &&
            (millisecond == null || IntegerUtils.isBetween(millisecond, 0, 999)) &&
            (weekday == null || IntegerUtils.isBetween(weekday, 1, 7)) &&
            (weekOfMonth == null || IntegerUtils.isBetween(weekOfMonth, 1, 6)) &&
            (weekOfYear == null || IntegerUtils.isBetween(weekOfYear, 1, 53))
        ))
            throw new AwesomeNotificationException("Calendar values are invalid");
    }

    @Override
    public Calendar getNextValidDate(Date fixedNowDate) throws AwesomeNotificationException {
        String cronExpression =
                (second == null ? "*" : second.toString()) + " " +
                (minute == null ? "*" : minute.toString()) + " " +
                (hour == null ? "*" : hour.toString()) + " " +
                (weekday != null ? "?" : (day == null ? "*" : day.toString())) + " " +
                (month == null ? "*" : month.toString()) + " " +
                (weekday == null ? "?" : weekday.toString()) + " " +
                (year == null ? "*" : year.toString());

        TimeZone timeZone = StringUtils.isNullOrEmpty(this.timeZone) ?
                DateUtils.localTimeZone :
                TimeZone.getTimeZone(this.timeZone);

        if (timeZone == null)
            throw new AwesomeNotificationException("Invalid time zone");

        return CronUtils.getNextCalendar(null, cronExpression, fixedNowDate, timeZone );
    }
}

