package me.carda.awesome_notifications.core.models;

import android.content.Context;

import java.util.Calendar;
import java.util.List;
import java.util.Map;

import javax.annotation.Nullable;

import me.carda.awesome_notifications.core.Definitions;
import me.carda.awesome_notifications.core.exceptions.AwesomeNotificationsException;
import me.carda.awesome_notifications.core.exceptions.ExceptionCode;
import me.carda.awesome_notifications.core.exceptions.ExceptionFactory;
import me.carda.awesome_notifications.core.externalLibs.CronExpression;
import me.carda.awesome_notifications.core.utils.CalendarUtils;
import me.carda.awesome_notifications.core.utils.CronUtils;
import me.carda.awesome_notifications.core.utils.ListUtils;

public class NotificationCrontabModel extends NotificationScheduleModel {

    private static final String TAG = "NotificationCrontabModel";

    public Calendar initialDateTime;
    public Calendar expirationDateTime;
    public String crontabExpression;
    public List<Calendar> preciseSchedules;

    @Override
    @SuppressWarnings("unchecked")
    public NotificationCrontabModel fromMap(Map<String, Object> arguments) {
        super.fromMap(arguments);

        initialDateTime    = getValueOrDefault(arguments, Definitions.NOTIFICATION_INITIAL_DATE_TIME, Calendar.class, null);
        expirationDateTime = getValueOrDefault(arguments, Definitions.NOTIFICATION_EXPIRATION_DATE_TIME, Calendar.class, null);
        crontabExpression  = getValueOrDefault(arguments, Definitions.NOTIFICATION_CRONTAB_EXPRESSION, String.class, null);
        preciseSchedules   = getValueOrDefault(arguments, Definitions.NOTIFICATION_PRECISE_SCHEDULES, List.class, null);

        return this;
    }

    @Override
    public Map<String, Object> toMap(){
        Map<String, Object> dataMap = super.toMap();

        putDataOnSerializedMap(Definitions.NOTIFICATION_INITIAL_DATE_TIME, dataMap, initialDateTime);
        putDataOnSerializedMap(Definitions.NOTIFICATION_EXPIRATION_DATE_TIME, dataMap, expirationDateTime);
        putDataOnSerializedMap(Definitions.NOTIFICATION_CRONTAB_EXPRESSION, dataMap, crontabExpression);
        putDataOnSerializedMap(Definitions.NOTIFICATION_PRECISE_SCHEDULES, dataMap, preciseSchedules);

        return dataMap;
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
    public void validate(Context context) throws AwesomeNotificationsException {

        if(
            stringUtils.isNullOrEmpty(crontabExpression) &&
            ListUtils.isNullOrEmpty(preciseSchedules)
        )
            throw ExceptionFactory
                    .getInstance()
                    .createNewAwesomeException(
                            TAG,
                            ExceptionCode.CODE_INVALID_ARGUMENTS,
                            "At least one schedule parameter is required",
                            ExceptionCode.DETAILED_REQUIRED_ARGUMENTS);

        try {
            if(initialDateTime != null && expirationDateTime != null){
                if(
                    initialDateTime.equals(expirationDateTime) ||
                    initialDateTime.after(expirationDateTime)
                )
                    throw ExceptionFactory
                            .getInstance()
                            .createNewAwesomeException(
                                    TAG,
                                    ExceptionCode.CODE_INVALID_ARGUMENTS,
                                    "Expiration date must be greater than initial date",
                                    ExceptionCode.DETAILED_INVALID_ARGUMENTS + ".periodOrder");
            }

            if(crontabExpression != null && !CronExpression.isValidExpression(crontabExpression))
                throw ExceptionFactory
                        .getInstance()
                        .createNewAwesomeException(
                                TAG,
                                ExceptionCode.CODE_INVALID_ARGUMENTS,
                                "Schedule cron expression is invalid",
                                ExceptionCode.DETAILED_INVALID_ARGUMENTS + ".crontabExpression");

        } catch (AwesomeNotificationsException e){
            throw e;
        } catch (Exception e){
            throw ExceptionFactory
                    .getInstance()
                    .createNewAwesomeException(
                            TAG,
                            ExceptionCode.CODE_INVALID_ARGUMENTS,
                            "Schedule time is invalid",
                            ExceptionCode.DETAILED_INVALID_ARGUMENTS + ".scheduleTime");
        }
    }

    @Override
    public Calendar getNextValidDate(@Nullable Calendar fixedNowDate) throws AwesomeNotificationsException {

        try {
            CalendarUtils calendarUtils = CalendarUtils.getInstance();

            if (fixedNowDate == null)
                fixedNowDate = calendarUtils.getCurrentCalendar(timeZone);

            if (
                expirationDateTime != null &&
                fixedNowDate.after(expirationDateTime) ||
                fixedNowDate.equals(expirationDateTime)
            ) return null;

            Calendar preciseCalendar = null, crontabCalendar = null;

            if (!ListUtils.isNullOrEmpty(preciseSchedules)){
                for (Calendar preciseSchedule : preciseSchedules) {
                    if(
                        initialDateTime != null &&
                        preciseSchedule.before(preciseSchedule)
                    )
                        continue;

                    if(preciseSchedule.before(fixedNowDate))
                        continue;

                    if(
                        preciseCalendar == null ||
                        preciseCalendar.after(preciseSchedule)
                    )
                        preciseCalendar = preciseSchedule;
                }
            }

            if(!stringUtils.isNullOrEmpty(crontabExpression))
                crontabCalendar = CronUtils
                        .getNextCalendar(
                                initialDateTime != null ?
                                        initialDateTime : fixedNowDate,
                                crontabExpression,
                                timeZone);

            if (preciseCalendar == null)
                return crontabCalendar;

            if (crontabCalendar == null)
                return preciseCalendar;

            if (preciseCalendar.before(crontabCalendar))
                return preciseCalendar;

            return crontabCalendar;

        } catch (AwesomeNotificationsException e){
            throw e;
        } catch (Exception e){
            throw ExceptionFactory
                    .getInstance()
                    .createNewAwesomeException(
                            TAG,
                            ExceptionCode.CODE_INVALID_ARGUMENTS,
                            "Schedule time is invalid",
                            ExceptionCode.DETAILED_INVALID_ARGUMENTS+".notificationCrontab");
        }
    }
}
