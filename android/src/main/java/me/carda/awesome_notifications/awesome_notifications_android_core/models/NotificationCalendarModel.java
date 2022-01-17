package me.carda.awesome_notifications.awesome_notifications_android_core.models;

import android.content.Context;

import java.util.Calendar;
import java.util.Date;
import java.util.Map;
import java.util.TimeZone;

import androidx.annotation.Nullable;
import me.carda.awesome_notifications.awesome_notifications_android_core.Definitions;
import me.carda.awesome_notifications.awesome_notifications_android_core.exceptions.AwesomeNotificationException;
import me.carda.awesome_notifications.awesome_notifications_android_core.utils.CronUtils;
import me.carda.awesome_notifications.awesome_notifications_android_core.utils.DateUtils;
import me.carda.awesome_notifications.awesome_notifications_android_core.utils.IntegerUtils;
import me.carda.awesome_notifications.awesome_notifications_android_core.utils.StringUtils;

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

        weekday = weekDayISO8601ToStandard(weekday);

        return this;
    }

    @Override
    public Map<String, Object> toMap() {
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

        returnedObject.put(Definitions.NOTIFICATION_SCHEDULE_WEEKDAY, weekDayStandardToISO8601(weekday));

        return returnedObject;
    }

    static Integer weekDayISO8601ToStandard(@Nullable Integer weekdayISOValue) {
        if (weekdayISOValue == null) return null;
        if (weekdayISOValue <= 0) return weekdayISOValue;
        if (weekdayISOValue > 7) return weekdayISOValue;

        if (weekdayISOValue == 7) return 1;
        return weekdayISOValue + 1;
    }

    static Integer weekDayStandardToISO8601(@Nullable Integer weekdayValue) {
        if (weekdayValue == null) return null;
        if (weekdayValue <= 0) return weekdayValue;
        if (weekdayValue > 7) return weekdayValue;

        if (weekdayValue == 1) return 7;
        return weekdayValue - 1;
    }

    @Override
    public String toJson() {
        return templateToJson();
    }

    @Override
    public NotificationCalendarModel fromJson(String json) {
        return (NotificationCalendarModel) super.templateFromJson(json);
    }

    @Override
    public void validate(Context context) throws AwesomeNotificationException {

        if (
            era == null &&
            year == null &&
            month == null &&
            day == null &&
            hour == null &&
            minute == null &&
            second == null &&
            millisecond == null &&
            weekday == null &&
            weekOfMonth == null &&
            weekOfYear == null
        )
            throw new AwesomeNotificationException("At least one parameter is required");

        if (era != null && !IntegerUtils.isBetween(era, 0, Integer.MAX_VALUE))
            throw new AwesomeNotificationException("Era value is invalid");

        if (year != null && !IntegerUtils.isBetween(year, 0, Integer.MAX_VALUE))
            throw new AwesomeNotificationException("year value is invalid");

        if (month != null && !IntegerUtils.isBetween(month, 1, 12))
            throw new AwesomeNotificationException("month value is invalid");

        if (day != null && !IntegerUtils.isBetween(day, 1, 31))
            throw new AwesomeNotificationException("day value is invalid");

        if (hour != null && !IntegerUtils.isBetween(hour, 0, 23))
            throw new AwesomeNotificationException("hour value is invalid");

        if (minute != null && !IntegerUtils.isBetween(minute, 0, 59))
            throw new AwesomeNotificationException("minute value is invalid");

        if (second != null && !IntegerUtils.isBetween(second, 0, 59))
            throw new AwesomeNotificationException("second value is invalid");

        if (millisecond != null && !IntegerUtils.isBetween(millisecond, 0, 999))
            throw new AwesomeNotificationException("millisecond value is invalid");

        if (weekday != null && !IntegerUtils.isBetween(weekday, 1, 7))
            throw new AwesomeNotificationException("weekday value is invalid");

        if (weekOfMonth != null && !IntegerUtils.isBetween(weekOfMonth, 1, 6))
            throw new AwesomeNotificationException("weekOfMonth value is invalid");

        if (weekOfYear != null && !IntegerUtils.isBetween(weekOfYear, 1, 53))
            throw new AwesomeNotificationException("weekOfYear value is invalid");
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
                DateUtils.getLocalTimeZone() :
                TimeZone.getTimeZone(this.timeZone);

        if (timeZone == null)
            throw new AwesomeNotificationException("Invalid time zone");

        return CronUtils.getNextCalendar(null, cronExpression, fixedNowDate, timeZone);
    }
}

