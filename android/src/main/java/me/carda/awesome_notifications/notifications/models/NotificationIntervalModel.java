package me.carda.awesome_notifications.notifications.models;

import android.content.Context;

import java.util.Calendar;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;
import java.util.TimeZone;

import me.carda.awesome_notifications.Definitions;
import me.carda.awesome_notifications.notifications.exceptions.AwesomeNotificationException;
import me.carda.awesome_notifications.utils.DateUtils;
import me.carda.awesome_notifications.utils.StringUtils;

public class NotificationIntervalModel extends NotificationScheduleModel {

    public Integer interval;

    @Override
    @SuppressWarnings("unchecked")
    public NotificationIntervalModel fromMap(Map<String, Object> arguments) {

        timeZone = getValueOrDefault(arguments, Definitions.NOTIFICATION_SCHEDULE_TIMEZONE, String.class);
        interval = getValueOrDefault(arguments, Definitions.NOTIFICATION_SCHEDULE_INTERVAL, Integer.class);
        repeats = getValueOrDefault(arguments, Definitions.NOTIFICATION_SCHEDULE_REPEATS, Boolean.class);
        allowWhileIdle = getValueOrDefault(arguments, Definitions.NOTIFICATION_ALLOW_WHILE_IDLE, Boolean.class);

        return this;
    }

    @Override
    public Map<String, Object> toMap(){
        Map<String, Object> returnedObject = new HashMap<>();

        returnedObject.put(Definitions.NOTIFICATION_SCHEDULE_TIMEZONE, timeZone);
        returnedObject.put(Definitions.NOTIFICATION_SCHEDULE_INTERVAL, interval);
        returnedObject.put(Definitions.NOTIFICATION_SCHEDULE_REPEATS, repeats);
        returnedObject.put(Definitions.NOTIFICATION_ALLOW_WHILE_IDLE, allowWhileIdle);

        return returnedObject;
    }

    @Override
    public String toJson() {
        return templateToJson();
    }

    @Override
    public NotificationIntervalModel fromJson(String json){
        return (NotificationIntervalModel) super.templateFromJson(json);
    }

    @Override
    public void validate(Context context) throws AwesomeNotificationException {

        if(interval == null || interval < 0)
            throw new AwesomeNotificationException("Interval is required and must be greater than zero");
    }

    @Override
    public Calendar getNextValidDate(Date fixedNowDate) throws Exception {
        Date currentDate;

        TimeZone timeZone = StringUtils.isNullOrEmpty(this.timeZone) ?
                DateUtils.localTimeZone :
                TimeZone.getTimeZone(this.timeZone);

        if (timeZone == null)
            throw new AwesomeNotificationException("Invalid time zone");

        if(fixedNowDate == null)
            currentDate = DateUtils.getLocalDateTime(this.timeZone);
        else
            currentDate = fixedNowDate;

        Calendar calendar = Calendar.getInstance();
        calendar.setTimeZone(timeZone);
        calendar.setTime(currentDate);
        calendar.add(Calendar.SECOND, interval);

        if(currentDate.compareTo(calendar.getTime()) <= 0)
            return calendar;

        return null;
    }

}
