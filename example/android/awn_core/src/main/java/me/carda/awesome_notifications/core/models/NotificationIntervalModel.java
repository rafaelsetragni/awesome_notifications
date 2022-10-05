package me.carda.awesome_notifications.core.models;

import android.content.Context;

import androidx.annotation.Nullable;

import java.util.Calendar;
import java.util.Map;

import me.carda.awesome_notifications.core.Definitions;
import me.carda.awesome_notifications.core.exceptions.AwesomeNotificationsException;
import me.carda.awesome_notifications.core.exceptions.ExceptionCode;
import me.carda.awesome_notifications.core.exceptions.ExceptionFactory;
import me.carda.awesome_notifications.core.utils.BooleanUtils;
import me.carda.awesome_notifications.core.utils.CalendarUtils;

public class NotificationIntervalModel extends NotificationScheduleModel {

    private static final String TAG = "NotificationIntervalModel";

    public Integer interval;

    @Override
    @SuppressWarnings("unchecked")
    public NotificationIntervalModel fromMap(Map<String, Object> arguments) {
        super.fromMap(arguments);

        interval = getValueOrDefault(arguments, Definitions.NOTIFICATION_SCHEDULE_INTERVAL, Integer.class, null);

        return this;
    }

    @Override
    public Map<String, Object> toMap(){
        Map<String, Object> dataMap = super.toMap();

        putDataOnSerializedMap(Definitions.NOTIFICATION_SCHEDULE_INTERVAL, dataMap, interval);

        return dataMap;
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

        if(interval == null || interval < 5)
            throw ExceptionFactory
                    .getInstance()
                    .createNewAwesomeException(
                            TAG,
                            ExceptionCode.CODE_INVALID_ARGUMENTS,
                            "Interval is required and must be greater than 5",
                            ExceptionCode.DETAILED_INVALID_ARGUMENTS+".notificationInterval.interval");

        if(repeats && interval < 60)
            throw ExceptionFactory
                    .getInstance()
                    .createNewAwesomeException(
                            TAG,
                            ExceptionCode.CODE_INVALID_ARGUMENTS,
                            "time interval must be at least 60 if repeating",
                            ExceptionCode.DETAILED_INVALID_ARGUMENTS+".notificationInterval.interval");
    }

    @Override
    public Calendar getNextValidDate(@Nullable Calendar fixedNowDate) throws AwesomeNotificationsException {

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
