package me.carda.awesome_notifications.core.managers;

import android.content.Context;

import androidx.annotation.NonNull;

import me.carda.awesome_notifications.core.exceptions.AwesomeNotificationsException;
import me.carda.awesome_notifications.core.exceptions.ExceptionCode;
import me.carda.awesome_notifications.core.exceptions.ExceptionFactory;
import me.carda.awesome_notifications.core.threads.NotificationScheduler;
import me.carda.awesome_notifications.core.utils.StringUtils;

public class CancellationManager {

    private static final String TAG = "CancellationManager";

    private final StringUtils stringUtils;
    
    // ************** SINGLETON PATTERN ***********************

    protected static CancellationManager instance;

    protected CancellationManager(StringUtils stringUtils){
        this.stringUtils = stringUtils;
    }

    public static CancellationManager getInstance() {
        if (instance == null)
            instance = new CancellationManager(
                    StringUtils.getInstance());
        return instance;
    }

    // ********************************************************

    public boolean dismissNotification(@NonNull final Context context, Integer notificationId) throws AwesomeNotificationsException {

        if (notificationId == null || notificationId < 0)
            throw ExceptionFactory
                    .getInstance()
                    .createNewAwesomeException(
                            TAG,
                            ExceptionCode.CODE_INVALID_ARGUMENTS,
                            "Invalid notification id",
                            ExceptionCode.DETAILED_INVALID_ARGUMENTS+".notificationId");

        StatusBarManager
                .getInstance(context)
                .dismissNotification(context, notificationId);

        return true;
    }

    public boolean dismissNotificationsByChannelKey(@NonNull final Context context, @NonNull final String channelKey) throws AwesomeNotificationsException {

        if(stringUtils.isNullOrEmpty(channelKey))
            throw ExceptionFactory
                    .getInstance()
                    .createNewAwesomeException(
                            TAG,
                            ExceptionCode.CODE_INVALID_ARGUMENTS,
                            "Invalid channel key",
                            ExceptionCode.DETAILED_INVALID_ARGUMENTS+".channelKey");

        StatusBarManager
                .getInstance(context)
                .dismissNotificationsByChannelKey(context, channelKey);

        return true;
    }

    public boolean dismissNotificationsByGroupKey(@NonNull final Context context, @NonNull final String groupKey) throws AwesomeNotificationsException {

        if(stringUtils.isNullOrEmpty(groupKey))
            throw ExceptionFactory
                    .getInstance()
                    .createNewAwesomeException(
                            TAG,
                            ExceptionCode.CODE_INVALID_ARGUMENTS,
                            "Invalid group key",
                            ExceptionCode.DETAILED_INVALID_ARGUMENTS+".groupKey");

        StatusBarManager
                .getInstance(context)
                .dismissNotificationsByGroupKey(context, groupKey);

        return true;
    }

    public void dismissAllNotifications(@NonNull final Context context) throws AwesomeNotificationsException {
        StatusBarManager
                .getInstance(context)
                .dismissAllNotifications(context);
    }

    public boolean cancelSchedule(@NonNull final Context context, Integer notificationId) throws AwesomeNotificationsException {

        if (notificationId == null || notificationId < 0)
            throw ExceptionFactory
                    .getInstance()
                    .createNewAwesomeException(
                            TAG,
                            ExceptionCode.CODE_INVALID_ARGUMENTS,
                            "Invalid notification id",
                            ExceptionCode.DETAILED_INVALID_ARGUMENTS+".notificationId");

        NotificationScheduler.cancelScheduleById(context, notificationId);

        return true;
    }

    public boolean cancelSchedulesByChannelKey(@NonNull final Context context, @NonNull final String channelKey) throws AwesomeNotificationsException {

        if(stringUtils.isNullOrEmpty(channelKey))
            throw ExceptionFactory
                    .getInstance()
                    .createNewAwesomeException(
                            TAG,
                            ExceptionCode.CODE_INVALID_ARGUMENTS,
                            "Invalid channel key",
                            ExceptionCode.DETAILED_INVALID_ARGUMENTS+".channelKey");

        NotificationScheduler.cancelSchedulesByChannelKey(context, channelKey);

        return true;
    }

    public boolean cancelSchedulesByGroupKey(@NonNull final Context context, @NonNull final String groupKey) throws AwesomeNotificationsException {

        if(stringUtils.isNullOrEmpty(groupKey))
            throw ExceptionFactory
                    .getInstance()
                    .createNewAwesomeException(
                            TAG,
                            ExceptionCode.CODE_INVALID_ARGUMENTS,
                            "Invalid group key",
                            ExceptionCode.DETAILED_INVALID_ARGUMENTS+".groupKey");

        NotificationScheduler.cancelSchedulesByGroupKey(context, groupKey);

        return true;
    }

    public void cancelAllSchedules(@NonNull final Context context) throws AwesomeNotificationsException {
        NotificationScheduler.cancelAllSchedules(context);
    }

    public boolean cancelNotification(@NonNull final Context context, Integer notificationId) throws AwesomeNotificationsException {

        if (notificationId == null || notificationId < 0)
            throw ExceptionFactory
                    .getInstance()
                    .createNewAwesomeException(
                            TAG,
                            ExceptionCode.CODE_INVALID_ARGUMENTS,
                            "Invalid notification id",
                            ExceptionCode.DETAILED_INVALID_ARGUMENTS+".notificationId");

        cancelSchedule(context, notificationId);
        dismissNotification(context, notificationId);

        return true;
    }

    public boolean cancelNotificationsByChannelKey(@NonNull final Context context, @NonNull final String channelKey) throws AwesomeNotificationsException {

        if(stringUtils.isNullOrEmpty(channelKey))
            throw ExceptionFactory
                    .getInstance()
                    .createNewAwesomeException(
                            TAG,
                            ExceptionCode.CODE_INVALID_ARGUMENTS,
                            "Invalid channel key",
                            ExceptionCode.DETAILED_INVALID_ARGUMENTS+".channelKey");

        dismissNotificationsByChannelKey(context, channelKey);
        cancelSchedulesByChannelKey(context, channelKey);

        return true;
    }

    public boolean cancelNotificationsByGroupKey(@NonNull final Context context, @NonNull final String groupKey) throws AwesomeNotificationsException {

        if(stringUtils.isNullOrEmpty(groupKey))
            throw ExceptionFactory
                    .getInstance()
                    .createNewAwesomeException(
                            TAG,
                            ExceptionCode.CODE_INVALID_ARGUMENTS,
                            "Invalid group key",
                            ExceptionCode.DETAILED_INVALID_ARGUMENTS+".groupKey");

        dismissNotificationsByGroupKey(context, groupKey);
        cancelSchedulesByGroupKey(context, groupKey);

        return true;
    }


    public void cancelAllNotifications(@NonNull final Context context) throws AwesomeNotificationsException {

        dismissAllNotifications(context);
        cancelAllSchedules(context);
    }
}
