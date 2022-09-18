package me.carda.awesome_notifications.core.models;

import android.content.Context;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import java.util.Calendar;
import java.util.Map;

import me.carda.awesome_notifications.core.Definitions;
import me.carda.awesome_notifications.core.exceptions.AwesomeNotificationsException;
import me.carda.awesome_notifications.core.exceptions.ExceptionCode;
import me.carda.awesome_notifications.core.exceptions.ExceptionFactory;
import me.carda.awesome_notifications.core.utils.CronUtils;
import me.carda.awesome_notifications.core.utils.IntegerUtils;

public class NotificationCalendarModel extends NotificationScheduleModel {

    private static final String TAG = "NotificationCalendarModel";

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

        era         = getValueOrDefault(arguments, Definitions.NOTIFICATION_SCHEDULE_ERA, Integer.class, null);
        year        = getValueOrDefault(arguments, Definitions.NOTIFICATION_SCHEDULE_YEAR, Integer.class, null);
        month       = getValueOrDefault(arguments, Definitions.NOTIFICATION_SCHEDULE_MONTH, Integer.class, null);
        day         = getValueOrDefault(arguments, Definitions.NOTIFICATION_SCHEDULE_DAY, Integer.class, null);
        hour        = getValueOrDefault(arguments, Definitions.NOTIFICATION_SCHEDULE_HOUR, Integer.class, null);
        minute      = getValueOrDefault(arguments, Definitions.NOTIFICATION_SCHEDULE_MINUTE, Integer.class, null);
        second      = getValueOrDefault(arguments, Definitions.NOTIFICATION_SCHEDULE_SECOND, Integer.class, null);
        millisecond = getValueOrDefault(arguments, Definitions.NOTIFICATION_SCHEDULE_MILLISECOND, Integer.class, null);
        weekday     = getValueOrDefault(arguments, Definitions.NOTIFICATION_SCHEDULE_WEEKDAY, Integer.class, null);
        weekOfMonth = getValueOrDefault(arguments, Definitions.NOTIFICATION_SCHEDULE_WEEKOFMONTH, Integer.class, null);
        weekOfYear  = getValueOrDefault(arguments, Definitions.NOTIFICATION_SCHEDULE_WEEKOFYEAR, Integer.class, null);
        weekday     = weekDayISO8601ToStandard(weekday);

        return this;
    }

    @Override
    public Map<String, Object> toMap() {
        Map<String, Object> dataMap = super.toMap();

        putDataOnSerializedMap(Definitions.NOTIFICATION_SCHEDULE_ERA, dataMap, era);
        putDataOnSerializedMap(Definitions.NOTIFICATION_SCHEDULE_YEAR, dataMap, year);
        putDataOnSerializedMap(Definitions.NOTIFICATION_SCHEDULE_MONTH, dataMap, month);
        putDataOnSerializedMap(Definitions.NOTIFICATION_SCHEDULE_DAY, dataMap, day);
        putDataOnSerializedMap(Definitions.NOTIFICATION_SCHEDULE_HOUR, dataMap, hour);
        putDataOnSerializedMap(Definitions.NOTIFICATION_SCHEDULE_MINUTE, dataMap, minute);
        putDataOnSerializedMap(Definitions.NOTIFICATION_SCHEDULE_SECOND, dataMap, second);
        putDataOnSerializedMap(Definitions.NOTIFICATION_SCHEDULE_MILLISECOND, dataMap, millisecond);
        putDataOnSerializedMap(Definitions.NOTIFICATION_SCHEDULE_WEEKOFMONTH, dataMap, weekOfMonth);
        putDataOnSerializedMap(Definitions.NOTIFICATION_SCHEDULE_WEEKOFYEAR, dataMap, weekOfYear);

        putDataOnSerializedMap(Definitions.NOTIFICATION_SCHEDULE_WEEKDAY, dataMap,
                weekDayStandardToISO8601(weekday));

        return dataMap;
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
    public void validate(Context context) throws AwesomeNotificationsException {

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
            throw ExceptionFactory
                    .getInstance()
                    .createNewAwesomeException(
                            TAG,
                            ExceptionCode.CODE_INVALID_ARGUMENTS,
                            "At least one time condition is required",
                            ExceptionCode.DETAILED_INVALID_ARGUMENTS+".notificationCalendar");

        if (
           era != null && !IntegerUtils.isBetween(era, 0, Integer.MAX_VALUE) ||
           year != null && !IntegerUtils.isBetween(year, 0, Integer.MAX_VALUE) ||
           month != null && !IntegerUtils.isBetween(month, 1, 12) ||
           day != null && !IntegerUtils.isBetween(day, 1, 31) ||
           hour != null && !IntegerUtils.isBetween(hour, 0, 23) ||
           minute != null && !IntegerUtils.isBetween(minute, 0, 59) ||
           second != null && !IntegerUtils.isBetween(second, 0, 59) ||
           millisecond != null && !IntegerUtils.isBetween(millisecond, 0, 999) ||
           weekday != null && !IntegerUtils.isBetween(weekday, 1, 7) ||
           weekOfMonth != null && !IntegerUtils.isBetween(weekOfMonth, 1, 6) ||
           weekOfYear != null && !IntegerUtils.isBetween(weekOfYear, 1, 53)
        )
            throw ExceptionFactory
                    .getInstance()
                    .createNewAwesomeException(
                            TAG,
                            ExceptionCode.CODE_INVALID_ARGUMENTS,
                            "The time conditions are invalid",
                            ExceptionCode.DETAILED_INVALID_ARGUMENTS+".notificationCalendar");
    }

    @Override
    @Nullable
    public Calendar getNextValidDate(
            @NonNull Calendar fixedNowDate
    ) throws AwesomeNotificationsException {

        if (timeZone == null)
            throw ExceptionFactory
                    .getInstance()
                    .createNewAwesomeException(
                            TAG,
                            ExceptionCode.CODE_INVALID_ARGUMENTS,
                            "Invalid time zone",
                            ExceptionCode.DETAILED_INVALID_ARGUMENTS+".notificationCalendar.timeZone");

        String cronExpression =
                (second == null ? "*" : second.toString()) + " " +
                (minute == null ? "*" : minute.toString()) + " " +
                (hour == null ? "*" : hour.toString()) + " " +
                (weekday != null ? "?" : (day == null ? "*" : day.toString())) + " " +
                (month == null ? "*" : month.toString()) + " " +
                (weekday == null ? "?" : weekday.toString()) + " " +
                (year == null ? "*" : year.toString());

        return CronUtils
                .getNextCalendar(
                        fixedNowDate,
                        cronExpression,
                        timeZone);
    }
}

