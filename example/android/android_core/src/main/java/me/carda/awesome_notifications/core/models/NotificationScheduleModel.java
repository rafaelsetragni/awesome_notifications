package me.carda.awesome_notifications.core.models;

import androidx.annotation.NonNull;

import java.util.Calendar;
import java.util.HashMap;
import java.util.Map;
import java.util.TimeZone;

import javax.annotation.Nullable;

import me.carda.awesome_notifications.core.Definitions;
import me.carda.awesome_notifications.core.exceptions.AwesomeNotificationsException;
import me.carda.awesome_notifications.core.utils.BooleanUtils;
import me.carda.awesome_notifications.core.utils.CalendarUtils;

public abstract class NotificationScheduleModel extends AbstractModel {

    public TimeZone timeZone;
    public Calendar createdDate;

    /// Specify false to deliver the notification one time. Specify true to reschedule the notification request each time the notification is delivered.
    public Boolean repeats;
    public Boolean allowWhileIdle;
    public Boolean preciseAlarm;

    public NotificationScheduleModel() {}

    @NonNull
    public NotificationScheduleModel fromMap(Map<String, Object> arguments) {
        timeZone       = getValueOrDefault(arguments, Definitions.NOTIFICATION_SCHEDULE_TIMEZONE, TimeZone.class, TimeZone.getDefault());
        createdDate    = getValueOrDefault(arguments, Definitions.NOTIFICATION_CREATED_DATE, Calendar.class, null);
        repeats        = getValueOrDefault(arguments, Definitions.NOTIFICATION_SCHEDULE_REPEATS, Boolean.class, false);
        allowWhileIdle = getValueOrDefault(arguments, Definitions.NOTIFICATION_ALLOW_WHILE_IDLE, Boolean.class, false);
        preciseAlarm   = getValueOrDefault(arguments, Definitions.NOTIFICATION_SCHEDULE_PRECISE_ALARM, Boolean.class, false);

        return this;
    }

    @Override
    public Map<String, Object> toMap(){
        Map<String, Object> dataMap = new HashMap<>();

        putDataOnSerializedMap(Definitions.NOTIFICATION_SCHEDULE_TIMEZONE, dataMap, timeZone);
        putDataOnSerializedMap(Definitions.NOTIFICATION_CREATED_DATE, dataMap, createdDate);
        putDataOnSerializedMap(Definitions.NOTIFICATION_SCHEDULE_REPEATS, dataMap, repeats);
        putDataOnSerializedMap(Definitions.NOTIFICATION_ALLOW_WHILE_IDLE, dataMap, allowWhileIdle);
        putDataOnSerializedMap(Definitions.NOTIFICATION_SCHEDULE_PRECISE_ALARM, dataMap, preciseAlarm);

        return dataMap;
    }

    @Nullable
    public abstract Calendar getNextValidDate(@Nullable Calendar fixedNowDate) throws AwesomeNotificationsException;

    @NonNull
    public Boolean hasNextValidDate() throws AwesomeNotificationsException {

        CalendarUtils calendarUtils = CalendarUtils.getInstance();

        repeats = BooleanUtils.getInstance().getValue(repeats);
        if(createdDate == null && !repeats)
            return false;

        return hasNextValidDate(calendarUtils.getCurrentCalendar());
    }

    @NonNull
    public Boolean hasNextValidDate(Calendar referenceDate) throws AwesomeNotificationsException {

        Calendar nextSchedule = getNextValidDate(referenceDate);

        return nextSchedule != null &&
            (
                nextSchedule.after(referenceDate) ||
                nextSchedule.equals(referenceDate)
            );
    }

    @Nullable
    public static NotificationScheduleModel getScheduleModelFromMap(Map<String, Object> map){

        if(map == null || map.isEmpty()) return null;

        if(
            map.containsKey(Definitions.NOTIFICATION_CRONTAB_EXPRESSION) ||
            map.containsKey(Definitions.NOTIFICATION_PRECISE_SCHEDULES) ||
            map.containsKey(Definitions.NOTIFICATION_EXPIRATION_DATE_TIME)
        ){
            return new NotificationCrontabModel().fromMap(map);
        }

        if(
            map.containsKey(Definitions.NOTIFICATION_SCHEDULE_SECOND) ||
            map.containsKey(Definitions.NOTIFICATION_SCHEDULE_MINUTE) ||
            map.containsKey(Definitions.NOTIFICATION_SCHEDULE_HOUR) ||
            map.containsKey(Definitions.NOTIFICATION_SCHEDULE_DAY) ||
            map.containsKey(Definitions.NOTIFICATION_SCHEDULE_MONTH) ||
            map.containsKey(Definitions.NOTIFICATION_SCHEDULE_YEAR) ||
            map.containsKey(Definitions.NOTIFICATION_SCHEDULE_ERA) ||
            map.containsKey(Definitions.NOTIFICATION_SCHEDULE_MILLISECOND) ||
            map.containsKey(Definitions.NOTIFICATION_SCHEDULE_WEEKDAY) ||
            map.containsKey(Definitions.NOTIFICATION_SCHEDULE_WEEKOFMONTH) ||
            map.containsKey(Definitions.NOTIFICATION_SCHEDULE_WEEKOFYEAR)
        ){
            return new NotificationCalendarModel().fromMap(map);
        }

        if(map.containsKey(Definitions.NOTIFICATION_SCHEDULE_INTERVAL)){
            return new NotificationIntervalModel().fromMap(map);
        }

        return null;
    }
}
