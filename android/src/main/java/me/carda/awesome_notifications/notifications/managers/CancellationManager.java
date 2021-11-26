package me.carda.awesome_notifications.notifications.managers;

import android.content.Context;
import android.content.SharedPreferences;

import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;

import java.lang.reflect.Type;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import androidx.annotation.NonNull;
import me.carda.awesome_notifications.notifications.NotificationScheduler;
import me.carda.awesome_notifications.notifications.NotificationSender;
import me.carda.awesome_notifications.notifications.enumerators.NotificationLayout;
import me.carda.awesome_notifications.notifications.exceptions.AwesomeNotificationException;
import me.carda.awesome_notifications.notifications.models.NotificationModel;
import me.carda.awesome_notifications.utils.StringUtils;

public class CancellationManager {

    private static final String TAG = "CancellationManager";

    public static boolean dismissNotification(@NonNull final Context context, Integer notificationId) throws AwesomeNotificationException {

        if (notificationId == null || notificationId < 0)
            throw new AwesomeNotificationException("Invalid notification id");

        NotificationSender.dismissNotification(context, notificationId);
        StatusBarManager.getInstance(context).unregisterActiveNotification(notificationId);

        return true;
    }

    public static boolean cancelSchedule(@NonNull final Context context, Integer notificationId) throws AwesomeNotificationException {

        if (notificationId == null || notificationId < 0)
            throw new AwesomeNotificationException("Invalid notification id");

        NotificationScheduler.cancelSchedule(context, notificationId);

        return true;
    }

    public static boolean cancelNotification(@NonNull final Context context, Integer notificationId) throws AwesomeNotificationException {

        if (notificationId == null || notificationId < 0)
            throw new AwesomeNotificationException("Invalid notification id");

        cancelSchedule(context, notificationId);
        dismissNotification(context, notificationId);

        return true;
    }

    public static boolean dismissNotificationsByChannelKey(@NonNull final Context context, @NonNull final String channelKey) throws AwesomeNotificationException {

        if(StringUtils.isNullOrEmpty(channelKey))
            throw new AwesomeNotificationException("Invalid channel key");

        List<String> notificationIds = StatusBarManager.getInstance(context).unregisterActiveChannelKey(channelKey);
        if (notificationIds != null)
            for (String idKey : notificationIds){
                NotificationSender.dismissNotification(context, Integer.parseInt(idKey));
            }

        return true;
    }

    public static boolean cancelSchedulesByChannelKey(@NonNull final Context context, @NonNull final String channelKey) throws AwesomeNotificationException {

        if(StringUtils.isNullOrEmpty(channelKey))
            throw new AwesomeNotificationException("Invalid channel key");

        NotificationScheduler.cancelSchedulesByChannelKey(context, channelKey);

        return true;
    }

    public static boolean cancelNotificationsByChannelKey(@NonNull final Context context, @NonNull final String channelKey) throws AwesomeNotificationException {

        if(StringUtils.isNullOrEmpty(channelKey))
            throw new AwesomeNotificationException("Invalid channel key");

        dismissNotificationsByChannelKey(context, channelKey);
        cancelSchedulesByChannelKey(context, channelKey);

        return true;
    }

    public static boolean dismissNotificationsByGroupKey(@NonNull final Context context, @NonNull final String groupKey) throws AwesomeNotificationException {

        if(StringUtils.isNullOrEmpty(groupKey))
            throw new AwesomeNotificationException("Invalid group key");

        List<String> notificationIds = StatusBarManager.getInstance(context).unregisterActiveGroupKey(groupKey);
        if (notificationIds != null)
            for (String idKey : notificationIds)
                NotificationSender.dismissNotification(context, Integer.parseInt(idKey));

        return true;
    }

    public static boolean cancelSchedulesByGroupKey(@NonNull final Context context, @NonNull final String groupKey) throws AwesomeNotificationException {

        if(StringUtils.isNullOrEmpty(groupKey))
            throw new AwesomeNotificationException("Invalid group key");

        NotificationScheduler.cancelSchedulesByGroupKey(context, groupKey);

        return true;
    }

    public static boolean cancelNotificationsByGroupKey(@NonNull final Context context, @NonNull final String groupKey) throws AwesomeNotificationException {

        if(StringUtils.isNullOrEmpty(groupKey))
            throw new AwesomeNotificationException("Invalid group key");

        dismissNotificationsByGroupKey(context, groupKey);
        cancelSchedulesByGroupKey(context, groupKey);

        return true;
    }

    public static boolean cancelAllSchedules(@NonNull final Context context) {

        NotificationScheduler.cancelAllSchedules(context);

        return true;
    }

    public static boolean dismissAllNotifications(@NonNull final Context context) {

        StatusBarManager.getInstance(context).resetRegisters();
        NotificationSender.dismissAllNotifications(context);

        return true;
    }


    public static boolean cancelAllNotifications(@NonNull final Context context) {

        dismissAllNotifications(context);
        cancelAllSchedules(context);

        return true;
    }
}
