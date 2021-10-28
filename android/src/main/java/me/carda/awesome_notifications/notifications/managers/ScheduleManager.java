package me.carda.awesome_notifications.notifications.managers;

import android.content.Context;

import java.util.List;

import me.carda.awesome_notifications.Definitions;
import me.carda.awesome_notifications.notifications.NotificationBuilder;
import me.carda.awesome_notifications.notifications.NotificationScheduler;
import me.carda.awesome_notifications.notifications.models.NotificationChannelModel;
import me.carda.awesome_notifications.notifications.models.PushNotification;

public class ScheduleManager {

    private static final SharedManager<PushNotification> shared
            = new SharedManager<>(
                    "ScheduleManager",
                    PushNotification.class,
                    "PushNotification");

    public static Boolean removeSchedule(Context context, PushNotification received) {
        return shared.remove(context, Definitions.SHARED_SCHEDULED_NOTIFICATIONS, received.content.id.toString());
    }

    public static List<PushNotification> listSchedules(Context context) {
        return shared.getAllObjects(context, Definitions.SHARED_SCHEDULED_NOTIFICATIONS);
    }

    public static void saveSchedule(Context context, PushNotification received) {
        shared.set(context, Definitions.SHARED_SCHEDULED_NOTIFICATIONS, received.content.id.toString(), received);
    }

    public static PushNotification getScheduleByKey(Context context, String scheduleKey){
        return shared.get(context, Definitions.SHARED_SCHEDULED_NOTIFICATIONS, scheduleKey);
    }

    public static void cancelSchedule(Context context, Integer id) {
        PushNotification schedule = shared.get(context, Definitions.SHARED_SCHEDULED_NOTIFICATIONS, id.toString());
        if(schedule != null)
            removeSchedule(context, schedule);
    }

    public static void cancelSchedulesByChannelKey(Context context, String channelKey) {
        List<PushNotification> listSchedules = shared.getAllObjects(context, Definitions.SHARED_SCHEDULED_NOTIFICATIONS);
        if(listSchedules != null) {
            for (PushNotification pushNotification : listSchedules) {
                if (pushNotification.content.channelKey.equals(channelKey))
                    NotificationScheduler.cancelSchedule(context, pushNotification.content.id);
            }
        }
    }

    public static void cancelSchedulesByGroupKey(Context context, String groupKey) {
        List<PushNotification> listSchedules = shared.getAllObjects(context, Definitions.SHARED_SCHEDULED_NOTIFICATIONS);
        if(listSchedules != null) {
            for (PushNotification pushNotification : listSchedules) {
                NotificationChannelModel channelModel = ChannelManager.getChannelByKey(context, pushNotification.content.channelKey);
                String finalGroupKey = NotificationBuilder.getGroupKey(pushNotification.content, channelModel);
                if (finalGroupKey != null && finalGroupKey.equals(groupKey))
                    NotificationScheduler.cancelSchedule(context, pushNotification.content.id);
            }
        }
    }

    public static void cancelAllSchedules(Context context) {
        List<PushNotification> listSchedules = shared.getAllObjects(context, Definitions.SHARED_SCHEDULED_NOTIFICATIONS);
        if(listSchedules != null) {
            for (PushNotification pushNotification : listSchedules) {
                NotificationScheduler.cancelSchedule(context, pushNotification.content.id);
            }
        }
    }

    public static void commitChanges(Context context){
        shared.commit(context);
    }
}
