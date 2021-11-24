package me.carda.awesome_notifications.notifications.managers;

import android.app.AlarmManager;
import android.content.Context;

import java.util.List;

import me.carda.awesome_notifications.Definitions;
import me.carda.awesome_notifications.notifications.NotificationBuilder;
import me.carda.awesome_notifications.notifications.NotificationScheduler;
import me.carda.awesome_notifications.notifications.models.NotificationChannelModel;
import me.carda.awesome_notifications.notifications.models.NotificationModel;

public class ScheduleManager {

    private static final SharedManager<NotificationModel> shared
            = new SharedManager<>(
                    "ScheduleManager",
                    NotificationModel.class,
                    "NotificationModel");

    public static Boolean removeSchedule(Context context, NotificationModel received) {
        return shared.remove(context, Definitions.SHARED_SCHEDULED_NOTIFICATIONS, received.content.id.toString());
    }

    public static List<NotificationModel> listSchedules(Context context) {
        return shared.getAllObjects(context, Definitions.SHARED_SCHEDULED_NOTIFICATIONS);
    }

    public static void saveSchedule(Context context, NotificationModel received) {
        shared.set(context, Definitions.SHARED_SCHEDULED_NOTIFICATIONS, received.content.id.toString(), received);
    }

    public static NotificationModel getScheduleByKey(Context context, String scheduleKey){
        return shared.get(context, Definitions.SHARED_SCHEDULED_NOTIFICATIONS, scheduleKey);
    }

    public static void cancelSchedule(Context context, Integer id) {
        NotificationModel schedule = shared.get(context, Definitions.SHARED_SCHEDULED_NOTIFICATIONS, id.toString());
        if(schedule != null)
            removeSchedule(context, schedule);
    }

    public static void cancelSchedulesByChannelKey(Context context, String channelKey) {
        List<NotificationModel> listSchedules = shared.getAllObjects(context, Definitions.SHARED_SCHEDULED_NOTIFICATIONS);
        if(listSchedules != null) {
            for (NotificationModel notificationModel : listSchedules) {
                if (notificationModel.content.channelKey.equals(channelKey))
                    NotificationScheduler.cancelSchedule(context, notificationModel.content.id);
            }
        }
    }

    public static void cancelSchedulesByGroupKey(Context context, String groupKey) {
        List<NotificationModel> listSchedules = shared.getAllObjects(context, Definitions.SHARED_SCHEDULED_NOTIFICATIONS);
        if(listSchedules != null) {
            for (NotificationModel notificationModel : listSchedules) {
                NotificationChannelModel channelModel = ChannelManager.getChannelByKey(context, notificationModel.content.channelKey);
                String finalGroupKey = NotificationBuilder.getGroupKey(notificationModel.content, channelModel);
                if (finalGroupKey != null && finalGroupKey.equals(groupKey))
                    NotificationScheduler.cancelSchedule(context, notificationModel.content.id);
            }
        }
    }

    public static void cancelAllSchedules(Context context) {
        List<NotificationModel> listSchedules = shared.getAllObjects(context, Definitions.SHARED_SCHEDULED_NOTIFICATIONS);
        if(listSchedules != null) {
            for (NotificationModel notificationModel : listSchedules) {
                NotificationScheduler.cancelSchedule(context, notificationModel.content.id);
            }
        }
    }

    public static AlarmManager getAlarmManager(Context context) {
        return (AlarmManager) context.getSystemService(Context.ALARM_SERVICE);
    }

    public static boolean isPreciseAlarmGloballyAllowed(Context context){
        AlarmManager alarmManager = getAlarmManager(context);
        return isPreciseAlarmGloballyAllowed(alarmManager);
    }

    public static boolean isPreciseAlarmGloballyAllowed(AlarmManager alarmManager){
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.S /*Android 12*/)
            return alarmManager.canScheduleExactAlarms();
        return true;
    }

    public static void commitChanges(Context context){
        shared.commit(context);
    }
}
