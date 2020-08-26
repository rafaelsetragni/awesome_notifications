package me.carda.awesome_notifications.notifications.models;

import android.content.Context;

import java.util.HashMap;
import java.util.Map;

import me.carda.awesome_notifications.Definitions;
import me.carda.awesome_notifications.externalLibs.CronExpression;
import me.carda.awesome_notifications.notifications.exceptions.PushNotificationException;
import me.carda.awesome_notifications.utils.DateUtils;
import me.carda.awesome_notifications.utils.StringUtils;

public class NotificationScheduleModel extends Model {
    
    public String initialDateTime;
    public String crontabSchedule;
    public Boolean allowWhileIdle;

    public static NotificationScheduleModel fromMap(Map<String, Object> arguments) {
        return (NotificationScheduleModel) new NotificationScheduleModel().fromMapImplementation(arguments);
    }

    @Override
    Model fromMapImplementation(Map<String, Object> arguments) {

        initialDateTime = getValueOrDefault(arguments, Definitions.NOTIFICATION_INITIAL_DATE_TIME, String.class);
        crontabSchedule = getValueOrDefault(arguments, Definitions.NOTIFICATION_CRONTAB_SCHEDULE, String.class);
        allowWhileIdle = getValueOrDefault(arguments, Definitions.NOTIFICATION_ALLOW_WHILE_IDLE, Boolean.class);

        return this;
    }

    @Override
    public Map<String, Object> toMap(){
        Map<String, Object> returnedObject = new HashMap<>();

        returnedObject.put(Definitions.NOTIFICATION_INITIAL_DATE_TIME, initialDateTime);
        returnedObject.put(Definitions.NOTIFICATION_CRONTAB_SCHEDULE, crontabSchedule);
        returnedObject.put(Definitions.NOTIFICATION_ALLOW_WHILE_IDLE, allowWhileIdle);

        return returnedObject;
    }

    @Override
    public void validate(Context context) throws PushNotificationException {

        if(StringUtils.isNullOrEmpty(initialDateTime) && StringUtils.isNullOrEmpty(crontabSchedule))
            throw new PushNotificationException("Schedule cannot have initial date time and cron rule null or empty");

        try {

            if(initialDateTime != null && DateUtils.parseDate(initialDateTime) == null)
                throw new PushNotificationException("Schedule initial date is invalid");

            if(crontabSchedule != null && !CronExpression.isValidExpression(crontabSchedule))
                throw new PushNotificationException("Schedule cron expression is invalid");

        } catch (PushNotificationException e){
            throw e;
        } catch (Exception e){
            throw new PushNotificationException("Schedule time is invalid");
        }
    }
}
