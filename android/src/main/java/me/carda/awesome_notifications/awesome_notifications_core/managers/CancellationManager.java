package me.carda.awesome_notifications.awesome_notifications_core.managers;

import android.content.Context;

import androidx.annotation.NonNull;
import me.carda.awesome_notifications.awesome_notifications_core.threads.NotificationScheduler;
import me.carda.awesome_notifications.awesome_notifications_core.exceptions.AwesomeNotificationsException;
import me.carda.awesome_notifications.awesome_notifications_core.utils.StringUtils;

public class CancellationManager {

    private static final String TAG = "CancellationManager";

    public static boolean dismissNotification(@NonNull final Context context, Integer notificationId) throws AwesomeNotificationsException {

        if (notificationId == null || notificationId < 0)
            throw new AwesomeNotificationsException("Invalid notification id");

        StatusBarManager
                .getInstance(context)
                .dismissNotification(notificationId);

        return true;
    }

    public static boolean dismissNotificationsByChannelKey(@NonNull final Context context, @NonNull final String channelKey) throws AwesomeNotificationsException {

        if(StringUtils.isNullOrEmpty(channelKey))
            throw new AwesomeNotificationsException("Invalid channel key");

        StatusBarManager
                .getInstance(context)
                .dismissNotificationsByChannelKey(channelKey);

        return true;
    }

    public static boolean dismissNotificationsByGroupKey(@NonNull final Context context, @NonNull final String groupKey) throws AwesomeNotificationsException {

        if(StringUtils.isNullOrEmpty(groupKey))
            throw new AwesomeNotificationsException("Invalid group key");

        StatusBarManager
                .getInstance(context)
                .dismissNotificationsByGroupKey(groupKey);

        return true;
    }

    public static void dismissAllNotifications(@NonNull final Context context) {

        StatusBarManager
                .getInstance(context)
                .dismissAllNotifications();
    }

    public static boolean cancelSchedule(@NonNull final Context context, Integer notificationId) throws AwesomeNotificationsException {

        if (notificationId == null || notificationId < 0)
            throw new AwesomeNotificationsException("Invalid notification id");

        NotificationScheduler.cancelSchedule(context, notificationId);

        return true;
    }

    public static boolean cancelSchedulesByChannelKey(@NonNull final Context context, @NonNull final String channelKey) throws AwesomeNotificationsException {

        if(StringUtils.isNullOrEmpty(channelKey))
            throw new AwesomeNotificationsException("Invalid channel key");

        NotificationScheduler.cancelSchedulesByChannelKey(context, channelKey);

        return true;
    }

    public static boolean cancelSchedulesByGroupKey(@NonNull final Context context, @NonNull final String groupKey) throws AwesomeNotificationsException {

        if(StringUtils.isNullOrEmpty(groupKey))
            throw new AwesomeNotificationsException("Invalid group key");

        NotificationScheduler.cancelSchedulesByGroupKey(context, groupKey);

        return true;
    }

    public static void cancelAllSchedules(@NonNull final Context context) {
        NotificationScheduler.cancelAllSchedules(context);
    }

    public static boolean cancelNotification(@NonNull final Context context, Integer notificationId) throws AwesomeNotificationsException {

        if (notificationId == null || notificationId < 0)
            throw new AwesomeNotificationsException("Invalid notification id");

        cancelSchedule(context, notificationId);
        dismissNotification(context, notificationId);

        return true;
    }

    public static boolean cancelNotificationsByChannelKey(@NonNull final Context context, @NonNull final String channelKey) throws AwesomeNotificationsException {

        if(StringUtils.isNullOrEmpty(channelKey))
            throw new AwesomeNotificationsException("Invalid channel key");

        dismissNotificationsByChannelKey(context, channelKey);
        cancelSchedulesByChannelKey(context, channelKey);

        return true;
    }

    public static boolean cancelNotificationsByGroupKey(@NonNull final Context context, @NonNull final String groupKey) throws AwesomeNotificationsException {

        if(StringUtils.isNullOrEmpty(groupKey))
            throw new AwesomeNotificationsException("Invalid group key");

        dismissNotificationsByGroupKey(context, groupKey);
        cancelSchedulesByGroupKey(context, groupKey);

        return true;
    }


    public static void cancelAllNotifications(@NonNull final Context context) {

        dismissAllNotifications(context);
        cancelAllSchedules(context);
    }
}
