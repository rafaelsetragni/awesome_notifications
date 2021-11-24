package me.carda.awesome_notifications.notifications.models;

import java.util.Calendar;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;
import java.util.TimeZone;

import me.carda.awesome_notifications.Definitions;
import me.carda.awesome_notifications.notifications.exceptions.AwesomeNotificationException;
import me.carda.awesome_notifications.utils.DateUtils;
import me.carda.awesome_notifications.utils.MapUtils;
import me.carda.awesome_notifications.utils.StringUtils;

public abstract class NotificationScheduleModel extends AbstractModel {

    public String timeZone;
    public String createdDate;

    /// Specify false to deliver the notification one time. Specify true to reschedule the notification request each time the notification is delivered.
    public Boolean repeats;
    public Boolean allowWhileIdle;
    public Boolean preciseAlarm;

    public NotificationScheduleModel fromMap(Map<String, Object> arguments) {
        timeZone = getValueOrDefault(arguments, Definitions.NOTIFICATION_SCHEDULE_TIMEZONE, String.class);

        createdDate = MapUtils.extractValue(arguments, Definitions.NOTIFICATION_CREATED_DATE, String.class)
                .or(DateUtils.getUTCDate());

        repeats = getValueOrDefault(arguments, Definitions.NOTIFICATION_SCHEDULE_REPEATS, Boolean.class);
        allowWhileIdle = getValueOrDefault(arguments, Definitions.NOTIFICATION_ALLOW_WHILE_IDLE, Boolean.class);

        preciseAlarm = getValueOrDefault(arguments, Definitions.NOTIFICATION_SCHEDULE_PRECISE_ALARM, Boolean.class);

        return this;
    }

    @Override
    public Map<String, Object> toMap(){
        Map<String, Object> returnedObject = new HashMap<>();

        returnedObject.put(Definitions.NOTIFICATION_SCHEDULE_TIMEZONE, timeZone);
        returnedObject.put(Definitions.NOTIFICATION_CREATED_DATE, createdDate);

        returnedObject.put(Definitions.NOTIFICATION_SCHEDULE_REPEATS, repeats);
        returnedObject.put(Definitions.NOTIFICATION_ALLOW_WHILE_IDLE, allowWhileIdle);

        returnedObject.put(Definitions.NOTIFICATION_SCHEDULE_PRECISE_ALARM, preciseAlarm);

        return returnedObject;
    }

    public abstract Calendar getNextValidDate(Date fixedNowDate) throws Exception;

    public Boolean hasNextValidDate() throws Exception {

        TimeZone timeZone = StringUtils.isNullOrEmpty(this.timeZone) ?
                DateUtils.localTimeZone :
                TimeZone.getTimeZone(this.timeZone);

        if (timeZone == null)
            throw new AwesomeNotificationException("Invalid time zone");

        if(createdDate == null && !repeats)
            return false;

        Date referenceDate = repeats ?
                DateUtils.getLocalDateTime(this.timeZone) :
                DateUtils.stringToDate(createdDate, this.timeZone);

        Calendar nextSchedule = getNextValidDate(referenceDate);
        if(nextSchedule == null)
            return false;

        Date nextValidDate = nextSchedule.getTime();
        return nextValidDate != null && nextValidDate.compareTo(DateUtils.getLocalDateTime(this.timeZone)) >= 0;
    }

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
