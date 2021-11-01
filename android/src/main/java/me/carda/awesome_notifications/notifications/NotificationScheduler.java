package me.carda.awesome_notifications.notifications;

import android.app.AlarmManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.os.AsyncTask;
import io.flutter.Log;

import java.util.Calendar;
import java.util.List;

import androidx.core.app.AlarmManagerCompat;

import me.carda.awesome_notifications.BroadcastSender;
import me.carda.awesome_notifications.Definitions;
import me.carda.awesome_notifications.AwesomeNotificationsPlugin;
import me.carda.awesome_notifications.notifications.broadcastReceivers.ScheduledNotificationReceiver;
import me.carda.awesome_notifications.notifications.enumerators.NotificationLifeCycle;
import me.carda.awesome_notifications.notifications.enumerators.NotificationSource;
import me.carda.awesome_notifications.notifications.exceptions.AwesomeNotificationException;
import me.carda.awesome_notifications.notifications.managers.ChannelManager;
import me.carda.awesome_notifications.notifications.managers.ScheduleManager;
import me.carda.awesome_notifications.notifications.models.NotificationModel;
import me.carda.awesome_notifications.notifications.models.returnedData.NotificationReceived;

import me.carda.awesome_notifications.utils.BooleanUtils;
import me.carda.awesome_notifications.utils.DateUtils;
import me.carda.awesome_notifications.utils.IntegerUtils;

public class NotificationScheduler extends AsyncTask<String, Void, Calendar> {

    public static String TAG = "NotificationScheduler";

    private Context context;
    private NotificationSource createdSource;
    private NotificationLifeCycle appLifeCycle;
    private NotificationModel notificationModel;

    private Boolean scheduled = false;

    public static void schedule(
            Context context,
            NotificationModel notificationModel
    ) throws AwesomeNotificationException {

        NotificationScheduler.schedule(
            context,
            notificationModel.content.createdSource,
            notificationModel
        );
    }

    public static void schedule(
        Context context,
        NotificationSource createdSource,
        NotificationModel notificationModel
    ) throws AwesomeNotificationException {

        if (notificationModel == null){
            throw new AwesomeNotificationException("Invalid notification content");
        }

        NotificationLifeCycle appLifeCycle;
        if(AwesomeNotificationsPlugin.appLifeCycle != NotificationLifeCycle.AppKilled){
            appLifeCycle = AwesomeNotificationsPlugin.getApplicationLifeCycle();
        }
        else {
            appLifeCycle = NotificationLifeCycle.AppKilled;
        }

        notificationModel.validate(context);

        new NotificationScheduler(
            context,
            appLifeCycle,
            createdSource,
            notificationModel
        ).execute();
    }

    private NotificationScheduler(
        Context context,
        NotificationLifeCycle appLifeCycle,
        NotificationSource createdSource,
        NotificationModel notificationModel
    ){
        this.context = context;
        this.createdSource = createdSource;
        this.appLifeCycle = appLifeCycle;

        this.notificationModel = notificationModel;
    }

    /// AsyncTask METHODS BEGIN *********************************

    @Override
    protected Calendar doInBackground(String... parameters) {
        try {
            Calendar nextValidDate = null;

            if(notificationModel != null){

                if (!ChannelManager.isChannelEnabled(context, notificationModel.content.channelKey)) {
                    throw new AwesomeNotificationException("Channel '" + notificationModel.content.channelKey + "' do not exist or is disabled");
                }

                if(notificationModel.content.createdSource == null){
                    notificationModel.content.createdSource = createdSource;
                    scheduled = true;
                }

                if(notificationModel.schedule == null) return null;

                if(notificationModel.schedule.createdDate == null){
                    notificationModel.content.createdDate = DateUtils.getUTCDate();
                    scheduled = true;
                }

                if(notificationModel.content.createdLifeCycle == null)
                    notificationModel.content.createdLifeCycle = appLifeCycle;

                nextValidDate = notificationModel.schedule.getNextValidDate(null);

                if(nextValidDate != null){

                    notificationModel = scheduleNotification(context, notificationModel, nextValidDate);

                    if(notificationModel != null){
                        scheduled = true;
                    }

                    return nextValidDate;
                }
                else {

                    /*
                    if(!ListUtils.isNullOrEmpty(notificationModel.schedule.preciseSchedules)){

                        for (String nextDateTime: notificationModel.schedule.preciseSchedules) {

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

                            notificationModel = scheduleNotification(context, notificationModel, nextValidDate);

                            if(notificationModel != null){
                                scheduled = true;
                            }

                            return nextValidDate;
                        }
                    }
                    */

                    cancelSchedule(context, notificationModel.content.id);

                    String msg = "Date is not more valid. ("+DateUtils.getUTCDate()+")";
                    Log.d(TAG, msg);
                }
            }

        } catch (Exception e) {
            notificationModel = null;
            e.printStackTrace();
        }

        return null;
    }

    @Override
    protected void onPostExecute(Calendar nextValidDate) {

        // Only fire ActionReceived if notificationModel is valid
        if(notificationModel != null){
            
            if(nextValidDate != null) {

                if(scheduled){
                    ScheduleManager.saveSchedule(context, notificationModel);
                    BroadcastSender.SendBroadcastNotificationCreated(
                            context,
                            new NotificationReceived(notificationModel.content)
                    );

                    Log.d(TAG, "Scheduled created");
                    ScheduleManager.commitChanges(context);
                    return;
                }
            }

            ScheduleManager.removeSchedule(context, notificationModel);
            _removeFromAlarm(context, notificationModel.content.id);

            Log.d(TAG, "Scheduled removed");
            ScheduleManager.commitChanges(context);
        }
    }

    /// AsyncTask METHODS END *********************************

    private NotificationModel scheduleNotification(Context context, NotificationModel notificationModel, Calendar nextValidDate) {

        if(nextValidDate != null){

            String notificationDetailsJson = notificationModel.toJson();
            Intent notificationIntent = new Intent(context, ScheduledNotificationReceiver.class);

            // Only generate randomly for first time to avoid collisions
            if(notificationModel.content.id  == null || notificationModel.content.id < 0)
                notificationModel.content.id = IntegerUtils.generateNextRandomId();

            notificationIntent.putExtra(Definitions.NOTIFICATION_ID, notificationModel.content.id);
            notificationIntent.putExtra(Definitions.NOTIFICATION_JSON, notificationDetailsJson);

            PendingIntent pendingIntent = PendingIntent.getBroadcast(
                    context,
                    notificationModel.content.id,
                    notificationIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT
            );

            AlarmManager alarmManager = getAlarmManager(context);

            if (BooleanUtils.getValue(notificationModel.schedule.allowWhileIdle)) {
                AlarmManagerCompat.setExactAndAllowWhileIdle(alarmManager, AlarmManager.RTC_WAKEUP, nextValidDate.getTimeInMillis(), pendingIntent);
            } else {
                AlarmManagerCompat.setExact(alarmManager, AlarmManager.RTC_WAKEUP, nextValidDate.getTimeInMillis(), pendingIntent);
            }

            return notificationModel;
        }
        return null;
    }

    public static void refreshScheduleNotifications(Context context) {
        List<NotificationModel> notificationModels = ScheduleManager.listSchedules(context);
        if (notificationModels == null || notificationModels.isEmpty()) return;

        for (NotificationModel notificationModel : notificationModels) {
            try {
                if(notificationModel.schedule.hasNextValidDate()){
                    schedule(context, notificationModel);
                }
                else {
                    ScheduleManager.cancelSchedule(context, notificationModel.content.id);
                }
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }

    public static void cancelSchedule(Context context, Integer id) {
        if(context != null){
            _removeFromAlarm(context, id);
            ScheduleManager.cancelSchedule(context, id);
            ScheduleManager.commitChanges(context);
        }
    }

    public static void cancelSchedulesByChannelKey(Context context, String channelKey) {
        ScheduleManager.cancelSchedulesByChannelKey(context, channelKey);
        ScheduleManager.commitChanges(context);
    }

    public static void cancelSchedulesByGroupKey(Context context, String groupKey) {
        ScheduleManager.cancelSchedulesByGroupKey(context, groupKey);
        ScheduleManager.commitChanges(context);
    }

    public static boolean cancelAllSchedules(Context context) {
        if(context != null){
            _removeAllFromAlarm(context);
            ScheduleManager.cancelAllSchedules(context);
            ScheduleManager.commitChanges(context);
            return true;
        }
        return false;
    }

    private static void _removeFromAlarm(Context context, int id) {
        if(context != null){
            Intent intent = new Intent(context, ScheduledNotificationReceiver.class);

            PendingIntent pendingIntent = PendingIntent.getBroadcast(context, id, intent, PendingIntent.FLAG_UPDATE_CURRENT);
            AlarmManager alarmManager = getAlarmManager(context);
            alarmManager.cancel(pendingIntent);
        }
    }

    private static void _removeAllFromAlarm(Context context) {
        if(context != null){
            List<NotificationModel> schedules = ScheduleManager.listSchedules(context);
            for(NotificationModel schedule : schedules){
                _removeFromAlarm(context, schedule.content.id);
            }
        }
    }

    private static AlarmManager getAlarmManager(Context context) {
        return (AlarmManager) context.getSystemService(Context.ALARM_SERVICE);
    }
}
