package me.carda.awesome_notifications.awesome_notifications_core.models;

import android.content.Context;

import androidx.annotation.NonNull;

import java.util.Calendar;
import java.util.Date;
import java.util.Map;
import java.util.TimeZone;

import me.carda.awesome_notifications.awesome_notifications_core.Definitions;
import me.carda.awesome_notifications.awesome_notifications_core.exceptions.AwesomeNotificationsException;
import me.carda.awesome_notifications.awesome_notifications_core.utils.BooleanUtils;
import me.carda.awesome_notifications.awesome_notifications_core.utils.CalendarUtils;
import me.carda.awesome_notifications.awesome_notifications_core.utils.StringUtils;

public class NotificationIntervalModel extends NotificationScheduleModel {

    public Integer interval;

    @Override
    @SuppressWarnings("unchecked")
    public NotificationIntervalModel fromMap(Map<String, Object> arguments) {
        super.fromMap(arguments);

        interval = getValueOrDefault(arguments, Definitions.NOTIFICATION_SCHEDULE_INTERVAL, Integer.class);

        return this;
    }

    @Override
    public Map<String, Object> toMap(){
        Map<String, Object> returnedObject = super.toMap();

        returnedObject.put(Definitions.NOTIFICATION_SCHEDULE_INTERVAL, interval);

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
    public void validate(Context context) throws AwesomeNotificationsException {

        if(interval == null || interval < 0)
            throw new AwesomeNotificationsException("Interval is required and must be greater than zero");

        if(repeats && interval < 60)
            throw new AwesomeNotificationsException("time interval must be at least 60 if repeating");
    }

    @Override
    public Calendar getNextValidDate(@NonNull Calendar fixedNowDate) throws AwesomeNotificationsException {

        CalendarUtils calendarUtils = CalendarUtils.getInstance();
        BooleanUtils booleanUtils = BooleanUtils.getInstance();

        fixedNowDate =
            (fixedNowDate == null) ?
                calendarUtils.getCurrentCalendar(timeZone) :
                fixedNowDate;

        Calendar initialDate = createdDate == null ?
                    fixedNowDate:
                    createdDate;

        Calendar finalDate;
        if(booleanUtils.getValueOrDefault(this.repeats, false))
        {
            Long initialEpoch = initialDate.getTimeInMillis();
            Long currentEpoch = fixedNowDate.getTimeInMillis();
            Long missingSeconds = Math.abs(initialEpoch - currentEpoch)/1000 % interval;

            finalDate = initialDate.after(fixedNowDate) ?
                    (Calendar) initialDate.clone() :
                    (Calendar) fixedNowDate.clone();

            finalDate.add(Calendar.SECOND, missingSeconds.intValue());
        }
        else {
            finalDate = (Calendar) initialDate.clone();
            finalDate.add(Calendar.SECOND, interval);
        }

        if(
            finalDate.after(fixedNowDate) ||
            finalDate.equals(fixedNowDate)
        )
            return finalDate;

        return null;
    }

}
