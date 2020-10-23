package me.carda.awesome_notifications.notifications;

import android.app.AlarmManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.os.AsyncTask;
import android.util.Log;

import java.util.Calendar;
import java.util.List;

import androidx.core.app.AlarmManagerCompat;
import me.carda.awesome_notifications.BroadcastSender;
import me.carda.awesome_notifications.Definitions;
import me.carda.awesome_notifications.AwesomeNotificationsPlugin;
import me.carda.awesome_notifications.notifications.broadcastReceivers.ScheduledNotificationReceiver;
import me.carda.awesome_notifications.notifications.enumeratos.NotificationLifeCycle;
import me.carda.awesome_notifications.notifications.enumeratos.NotificationSource;
import me.carda.awesome_notifications.notifications.exceptions.PushNotificationException;
import me.carda.awesome_notifications.notifications.managers.ScheduleManager;
import me.carda.awesome_notifications.notifications.models.returnedData.NotificationReceived;
import me.carda.awesome_notifications.utils.BooleanUtils;
import me.carda.awesome_notifications.utils.CronUtils;
import me.carda.awesome_notifications.utils.DateUtils;
import me.carda.awesome_notifications.utils.ListUtils;

public class NotificationScheduler extends AsyncTask<String, Void, Calendar> {

    public static String TAG = "NotificationScheduler";

    private Context context;
    private NotificationSource createdSource;
    private NotificationLifeCycle appLifeCycle;
    private PushNotification pushNotification;

    private Boolean scheduled = false;

    public static void schedule(
            Context context,
            PushNotification pushNotification
    ) throws PushNotificationException {

        NotificationScheduler.schedule(
            context,
            pushNotification.content.createdSource,
            pushNotification
        );
    }

    public static void schedule(
        Context context,
        NotificationSource createdSource,
        PushNotification pushNotification
    ) throws PushNotificationException {

        if (pushNotification == null){
            throw new PushNotificationException("Invalid notification content");
        }

        NotificationLifeCycle appLifeCycle;
        if(AwesomeNotificationsPlugin.appLifeCycle != NotificationLifeCycle.AppKilled){
            appLifeCycle = AwesomeNotificationsPlugin.getApplicationLifeCycle();
        }
        else {
            appLifeCycle = NotificationLifeCycle.AppKilled;
        }

        pushNotification.validate(context);

        new NotificationScheduler(
            context,
            appLifeCycle,
            createdSource,
            pushNotification
        ).execute();
    }

    private NotificationScheduler(
        Context context,
        NotificationLifeCycle appLifeCycle,
        NotificationSource createdSource,
        PushNotification pushNotification
    ){
        this.context = context;
        this.createdSource = createdSource;
        this.appLifeCycle = appLifeCycle;

        this.pushNotification = pushNotification;
    }

    /// AsyncTask METHODS BEGIN *********************************

    @Override
    protected Calendar doInBackground(String... parameters) {
        try {
            Calendar nextValidDate;

            if(pushNotification != null){

                if(pushNotification.content.createdSource == null){
                    pushNotification.content.createdSource = createdSource;
                    scheduled = true;
                }

                if(pushNotification.content.createdLifeCycle == null)
                    pushNotification.content.createdLifeCycle = appLifeCycle;

                nextValidDate = CronUtils.getNextCalendar(
                    pushNotification.schedule.initialDateTime,
                    pushNotification.schedule.crontabSchedule
                );

                if(nextValidDate != null){

                    pushNotification = scheduleNotification(context, pushNotification, nextValidDate);

                    if(pushNotification != null){
                        scheduled = true;
                    }

                    return nextValidDate;
                }
                else {

                    if(!ListUtils.isNullOrEmpty(pushNotification.schedule.preciseSchedules)){

                        for (String nextDateTime: pushNotification.schedule.preciseSchedules) {

                            Calendar closestDate = CronUtils.getNextCalendar(
                                nextDateTime,
                                null
                            );

                            if(closestDate != null){
                                if(nextValidDate == null){
                                    nextValidDate = closestDate;
                                }
                                else {
                                    if(closestDate.compareTo(nextValidDate) < 0){
                                        nextValidDate = closestDate;
                                    }
                                }
                            }
                        }

                        if(nextValidDate != null){

                            pushNotification = scheduleNotification(context, pushNotification, nextValidDate);

                            if(pushNotification != null){
                                scheduled = true;
                            }

                            return nextValidDate;
                        }
                    }

                    cancelNotification(context, pushNotification.content.id);

                    String msg = "Date is not more valid. ("+DateUtils.getUTCDate()+")";
                    Log.d(TAG, msg);
                }
            }

        } catch (Exception e) {
            pushNotification = null;
            e.printStackTrace();
        }
        return null;
    }

    @Override
    protected void onPostExecute(Calendar nextValidDate) {

        // Only fire ActionReceived if notificationModel is valid
        if(pushNotification != null){
            
            if(nextValidDate != null) {

                if(scheduled){
                    ScheduleManager.saveSchedule(context, pushNotification);
                    BroadcastSender.SendBroadcastNotificationCreated(
                            context,
                            new NotificationReceived(pushNotification.content)
                    );
                    Log.d(TAG, "Scheduled created");
                    return;
                }
            }

            ScheduleManager.removeSchedule(context, pushNotification);
            _removeFromAlarm(context, pushNotification.content.id);
            Log.d(TAG, "Scheduled removed");
        }
    }

    /// AsyncTask METHODS END *********************************

    private PushNotification scheduleNotification(Context context, PushNotification pushNotification, Calendar nextValidDate) {

        if(nextValidDate != null){

            String notificationDetailsJson = pushNotification.toJson();
            Intent notificationIntent = new Intent(context, ScheduledNotificationReceiver.class);

            notificationIntent.putExtra(Definitions.NOTIFICATION_ID, pushNotification.content.id);
            notificationIntent.putExtra(Definitions.NOTIFICATION_JSON, notificationDetailsJson);

            PendingIntent pendingIntent = PendingIntent.getBroadcast(
                    context,
                    pushNotification.content.id,
                    notificationIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT
            );

            AlarmManager alarmManager = getAlarmManager(context);

            if (BooleanUtils.getValue(pushNotification.schedule.allowWhileIdle)) {
                AlarmManagerCompat.setExactAndAllowWhileIdle(alarmManager, AlarmManager.RTC_WAKEUP, nextValidDate.getTimeInMillis(), pendingIntent);
            } else {
                AlarmManagerCompat.setExact(alarmManager, AlarmManager.RTC_WAKEUP, nextValidDate.getTimeInMillis(), pendingIntent);
            }

            return pushNotification;
        }
        return null;
    }

    public static void refreshScheduleNotifications(Context context) {
        List<PushNotification> pushNotifications = ScheduleManager.listSchedules(context);
        if (pushNotifications == null || pushNotifications.isEmpty()) return;

        for (PushNotification pushNotification : pushNotifications) {
            try {
                schedule(context, pushNotification);
            } catch (PushNotificationException e) {
                e.printStackTrace();
            }
        }
    }

    public static void cancelNotification(Context context, Integer id) {
        if(context != null){
            _removeFromAlarm(context, id);
            ScheduleManager.cancelSchedule(context, id);
        }
    }

    public static boolean cancelAllNotifications(Context context) {
        ScheduleManager.cancelAllSchedules(context);
        return true;
    }

    private static void _removeFromAlarm(Context context, int id) {
        if(context != null){
            Intent intent = new Intent(context, ScheduledNotificationReceiver.class);

            PendingIntent pendingIntent = PendingIntent.getBroadcast(context, id, intent, PendingIntent.FLAG_UPDATE_CURRENT);
            AlarmManager alarmManager = getAlarmManager(context);
            alarmManager.cancel(pendingIntent);
        }
    }

    private static AlarmManager getAlarmManager(Context context) {
        return (AlarmManager) context.getSystemService(Context.ALARM_SERVICE);
    }
}
