package me.carda.awesome_notifications.notifications.models;

import android.content.Context;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import me.carda.awesome_notifications.Definitions;
import me.carda.awesome_notifications.externalLibs.CronExpression;
import me.carda.awesome_notifications.notifications.exceptions.PushNotificationException;
import me.carda.awesome_notifications.utils.DateUtils;
import me.carda.awesome_notifications.utils.ListUtils;
import me.carda.awesome_notifications.utils.StringUtils;

public class NotificationScheduleModel extends Model {
    
    public String initialDateTime;
    public String crontabSchedule;
    public Boolean allowWhileIdle;
    public List<String> preciseSchedules;

    public NotificationScheduleModel(){}

    @Override
    @SuppressWarnings("unchecked")
    public NotificationScheduleModel fromMap(Map<String, Object> arguments) {

        initialDateTime = getValueOrDefault(arguments, Definitions.NOTIFICATION_INITIAL_DATE_TIME, String.class);
        crontabSchedule = getValueOrDefault(arguments, Definitions.NOTIFICATION_CRONTAB_SCHEDULE, String.class);
        allowWhileIdle = getValueOrDefault(arguments, Definitions.NOTIFICATION_ALLOW_WHILE_IDLE, Boolean.class);

        if(arguments.containsKey("preciseSchedules"))
        {
           try {
               preciseSchedules = (List<String>) arguments.get("preciseSchedules");
           }
           catch (Exception e){
               e.printStackTrace();
           }
        }

        return this;
    }

    @Override
    public Map<String, Object> toMap(){
        Map<String, Object> returnedObject = new HashMap<>();

        returnedObject.put(Definitions.NOTIFICATION_INITIAL_DATE_TIME, initialDateTime);
        returnedObject.put(Definitions.NOTIFICATION_CRONTAB_SCHEDULE, crontabSchedule);
        returnedObject.put(Definitions.NOTIFICATION_ALLOW_WHILE_IDLE, allowWhileIdle);
        returnedObject.put(Definitions.NOTIFICATION_PRECISE_SCHEDULES, preciseSchedules);

        return returnedObject;
    }

    @Override
    public String toJson() {
        return templateToJson();
    }

    @Override
    public NotificationScheduleModel fromJson(String json){
        return (NotificationScheduleModel) super.templateFromJson(json);
    }

    @Override
    public void validate(Context context) throws PushNotificationException {

        if(StringUtils.isNullOrEmpty(initialDateTime) && StringUtils.isNullOrEmpty(crontabSchedule) && ListUtils.isNullOrEmpty(preciseSchedules))
            throw new PushNotificationException("At least one schedule parameter is required");

        try {

            if(initialDateTime != null && DateUtils.parseDate(initialDateTime) == null)
                throw new PushNotificationException("Schedule initial date is invalid");

            if(crontabSchedule != null && !CronExpression.isValidExpression(crontabSchedule))
                throw new PushNotificationException("Schedule cron expression is invalid");

            if(preciseSchedules != null){
                for(String schedule : preciseSchedules){
                    if(DateUtils.parseDate(schedule) == null){
                        throw new PushNotificationException("Precise schedule '"+schedule+"' is invalid");
                    }
                }
            }

        } catch (PushNotificationException e){
            throw e;
        } catch (Exception e){
            throw new PushNotificationException("Schedule time is invalid");
        }
    }
}
