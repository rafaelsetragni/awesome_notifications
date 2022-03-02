package me.carda.awesome_notifications.awesome_notifications_core.managers;

import android.content.Context;

import androidx.annotation.NonNull;
import me.carda.awesome_notifications.awesome_notifications_core.threads.NotificationScheduler;
import me.carda.awesome_notifications.awesome_notifications_core.exceptions.AwesomeNotificationsException;
import me.carda.awesome_notifications.awesome_notifications_core.utils.BitmapUtils;
import me.carda.awesome_notifications.awesome_notifications_core.utils.StringUtils;

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
            throw new AwesomeNotificationsException("Invalid notification id");

        StatusBarManager
                .getInstance(context)
                .dismissNotification(notificationId);

        return true;
    }

    public boolean dismissNotificationsByChannelKey(@NonNull final Context context, @NonNull final String channelKey) throws AwesomeNotificationsException {

        if(stringUtils.isNullOrEmpty(channelKey))
            throw new AwesomeNotificationsException("Invalid channel key");

        StatusBarManager
                .getInstance(context)
                .dismissNotificationsByChannelKey(channelKey);

        return true;
    }

    public boolean dismissNotificationsByGroupKey(@NonNull final Context context, @NonNull final String groupKey) throws AwesomeNotificationsException {

        if(stringUtils.isNullOrEmpty(groupKey))
            throw new AwesomeNotificationsException("Invalid group key");

        StatusBarManager
                .getInstance(context)
                .dismissNotificationsByGroupKey(groupKey);

        return true;
    }

    public void dismissAllNotifications(@NonNull final Context context) {

        StatusBarManager
                .getInstance(context)
                .dismissAllNotifications();
    }

    public boolean cancelSchedule(@NonNull final Context context, Integer notificationId) throws AwesomeNotificationsException {

        if (notificationId == null || notificationId < 0)
            throw new AwesomeNotificationsException("Invalid notification id");

        NotificationScheduler.cancelScheduleById(context, notificationId);

        return true;
    }

    public boolean cancelSchedulesByChannelKey(@NonNull final Context context, @NonNull final String channelKey) throws AwesomeNotificationsException {

        if(stringUtils.isNullOrEmpty(channelKey))
            throw new AwesomeNotificationsException("Invalid channel key");

        NotificationScheduler.cancelSchedulesByChannelKey(context, channelKey);

        return true;
    }

    public boolean cancelSchedulesByGroupKey(@NonNull final Context context, @NonNull final String groupKey) throws AwesomeNotificationsException {

        if(stringUtils.isNullOrEmpty(groupKey))
            throw new AwesomeNotificationsException("Invalid group key");

        NotificationScheduler.cancelSchedulesByGroupKey(context, groupKey);

        return true;
    }

    public void cancelAllSchedules(@NonNull final Context context) {
        NotificationScheduler.cancelAllSchedules(context);
    }

    public boolean cancelNotification(@NonNull final Context context, Integer notificationId) throws AwesomeNotificationsException {

        if (notificationId == null || notificationId < 0)
            throw new AwesomeNotificationsException("Invalid notification id");

        cancelSchedule(context, notificationId);
        dismissNotification(context, notificationId);

        return true;
    }

    public boolean cancelNotificationsByChannelKey(@NonNull final Context context, @NonNull final String channelKey) throws AwesomeNotificationsException {

        if(stringUtils.isNullOrEmpty(channelKey))
            throw new AwesomeNotificationsException("Invalid channel key");

        dismissNotificationsByChannelKey(context, channelKey);
        cancelSchedulesByChannelKey(context, channelKey);

        return true;
    }

    public boolean cancelNotificationsByGroupKey(@NonNull final Context context, @NonNull final String groupKey) throws AwesomeNotificationsException {

        if(stringUtils.isNullOrEmpty(groupKey))
            throw new AwesomeNotificationsException("Invalid group key");

        dismissNotificationsByGroupKey(context, groupKey);
        cancelSchedulesByGroupKey(context, groupKey);

        return true;
    }


    public void cancelAllNotifications(@NonNull final Context context) {

        dismissAllNotifications(context);
        cancelAllSchedules(context);
    }
}
