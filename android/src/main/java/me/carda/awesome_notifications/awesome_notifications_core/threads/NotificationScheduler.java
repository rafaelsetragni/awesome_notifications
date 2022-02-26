package me.carda.awesome_notifications.awesome_notifications_core.threads;

import android.annotation.SuppressLint;
import android.app.AlarmManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.os.AsyncTask;
import android.os.Build;
import android.util.Log;

import java.lang.ref.WeakReference;
import java.util.Calendar;
import java.util.List;

import androidx.core.app.AlarmManagerCompat;

import me.carda.awesome_notifications.awesome_notifications_core.AwesomeNotifications;
import me.carda.awesome_notifications.awesome_notifications_core.Definitions;
import me.carda.awesome_notifications.awesome_notifications_core.broadcasters.senders.BroadcastSender;
import me.carda.awesome_notifications.awesome_notifications_core.broadcasters.receivers.ScheduledNotificationReceiver;
import me.carda.awesome_notifications.awesome_notifications_core.enumerators.NotificationLifeCycle;
import me.carda.awesome_notifications.awesome_notifications_core.enumerators.NotificationSource;
import me.carda.awesome_notifications.awesome_notifications_core.exceptions.AwesomeNotificationsException;
import me.carda.awesome_notifications.awesome_notifications_core.managers.ChannelManager;
import me.carda.awesome_notifications.awesome_notifications_core.managers.ScheduleManager;
import me.carda.awesome_notifications.awesome_notifications_core.models.NotificationModel;
import me.carda.awesome_notifications.awesome_notifications_core.models.returnedData.NotificationReceived;

import me.carda.awesome_notifications.awesome_notifications_core.utils.BooleanUtils;
import me.carda.awesome_notifications.awesome_notifications_core.utils.CalendarUtils;
import me.carda.awesome_notifications.awesome_notifications_core.utils.IntegerUtils;

public class NotificationScheduler extends NotificationThread<String, Void, Calendar> {

    public static String TAG = "NotificationScheduler";

    private final WeakReference<Context> wContextReference;

    private final NotificationSource createdSource;
    private final NotificationLifeCycle appLifeCycle;
    private NotificationModel notificationModel;

    private Boolean scheduled = false;
    private Boolean rescheduled = false;
    private long startTime = 0L, endTime = 0L;
    private final Calendar initialDate;

    public static void schedule(
            Context context,
            NotificationModel notificationModel
    ) throws AwesomeNotificationsException {

        if (notificationModel == null)
            throw new AwesomeNotificationsException("Invalid notification content");

        notificationModel.validate(context);

        new NotificationScheduler(
                context,
                AwesomeNotifications.getApplicationLifeCycle(),
                notificationModel.content.createdSource,
                notificationModel,
                true
        ).executeNotificationThread(notificationModel);
    }

    public static void schedule(
        Context context,
        NotificationSource createdSource,
        NotificationModel notificationModel
    ) throws AwesomeNotificationsException {

        if (notificationModel == null)
            throw new AwesomeNotificationsException("Invalid notification content");

        notificationModel.validate(context);

        new NotificationScheduler(
                context,
                AwesomeNotifications.getApplicationLifeCycle(),
                createdSource,
                notificationModel,
                false
        ).execute();
    }

    private NotificationScheduler(
        Context context,
        NotificationLifeCycle appLifeCycle,
        NotificationSource createdSource,
        NotificationModel notificationModel,
        boolean isReschedule
    ) throws AwesomeNotificationsException {
        this.wContextReference = new WeakReference<>(context);
        this.rescheduled = isReschedule;
        this.createdSource = createdSource;
        this.appLifeCycle = appLifeCycle;
        this.notificationModel = notificationModel;
        this.startTime = System.nanoTime();

        this.initialDate =
            CalendarUtils
                .getInstance()
                .getCurrentCalendar(
                        notificationModel
                                .schedule
                                .timeZone);

        // Only generate randomly for first time to avoid collisions
        if(notificationModel.content.id  == null || notificationModel.content.id < 0)
            notificationModel.content.id = IntegerUtils.generateNextRandomId();
    }

    /// AsyncTask METHODS BEGIN *********************************

    @Override
    protected Calendar doInBackground(String... parameters) {
        try {
            Calendar nextValidDate = null;

            if(notificationModel != null){

                if (!ChannelManager
                        .getInstance()
                        .isChannelEnabled(
                                wContextReference.get(),
                                notificationModel.content.channelKey)
                ) {
                    throw new AwesomeNotificationsException("Channel '" + notificationModel.content.channelKey + "' do not exist or is disabled");
                }

                if(notificationModel.schedule == null)
                    return null;

                scheduled = notificationModel
                                .content
                                .registerCreatedEvent(
                                        appLifeCycle,
                                        createdSource);

                nextValidDate = notificationModel
                                    .schedule
                                    .getNextValidDate(initialDate);

                if(nextValidDate != null){

                    notificationModel = scheduleNotification(
                            wContextReference.get(),
                            notificationModel,
                            nextValidDate);

                    if(notificationModel != null){
                        scheduled = true;
                    }

                    return nextValidDate;
                }
                else {
                    cancelSchedule(
                            wContextReference.get(),
                            notificationModel.content.id);

                    String now = CalendarUtils.getInstance().getNowStringCalendar();
                    String msg = "Date is not more valid. ("+now+")";
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

                    ScheduleManager.saveSchedule(wContextReference.get(), notificationModel);
                    if (!rescheduled) {
                        BroadcastSender.sendBroadcastNotificationCreated(
                                wContextReference.get(),
                                new NotificationReceived(notificationModel.content)
                        );
                        Log.d(TAG, "Scheduled created");
                    }

                    ScheduleManager.commitChanges(wContextReference.get());

                    if(this.endTime == 0L)
                        this.endTime = System.nanoTime();

                    if(AwesomeNotifications.debug){
                        long elapsed = (endTime - startTime)/1000000;
                        Log.d(TAG, "Notification "+(
                                rescheduled ? "rescheduled" : "scheduled"
                                )+" in "+elapsed+"ms");
                    }
                    return;
                }
            }

            ScheduleManager.removeSchedule(wContextReference.get(), notificationModel);
            _removeFromAlarm(wContextReference.get(), notificationModel.content.id);

            Log.d(TAG, "Scheduled removed");
            ScheduleManager.commitChanges(wContextReference.get());
        }

        if(this.endTime == 0L)
            this.endTime = System.nanoTime();

        if(AwesomeNotifications.debug){
            long elapsed = (endTime - startTime)/1000000;
            Log.d(TAG, "Notification schedule removed in "+elapsed+"ms");
        }
    }

    /// AsyncTask METHODS END *********************************

    private NotificationModel scheduleNotification(Context context, NotificationModel notificationModel, Calendar nextValidDate) {

        if(nextValidDate != null){

            String notificationDetailsJson = notificationModel.toJson();
            Intent notificationIntent = new Intent(context, ScheduledNotificationReceiver.class);
            notificationIntent.setFlags(Intent.FLAG_INCLUDE_STOPPED_PACKAGES);

            notificationIntent.putExtra(Definitions.NOTIFICATION_ID, notificationModel.content.id);
            notificationIntent.putExtra(Definitions.NOTIFICATION_JSON, notificationDetailsJson);

            @SuppressLint("WrongConstant") PendingIntent pendingIntent =
                    PendingIntent
                            .getBroadcast(
                                context,
                                notificationModel.content.id,
                                notificationIntent,
                                Build.VERSION.SDK_INT >= Build.VERSION_CODES.S ?
                                    PendingIntent.FLAG_MUTABLE | PendingIntent.FLAG_UPDATE_CURRENT :
                                    PendingIntent.FLAG_UPDATE_CURRENT );

            //scheduleNotificationWithWorkManager(context, notificationModel, nextValidDate);
            scheduleNotificationWithAlarmManager(
                    context,
                    notificationModel,
                    nextValidDate,
                    pendingIntent);

            return notificationModel;
        }
        return null;
    }

    // WorkManager does not not meet the requirements to be used in scheduling process
//    private void scheduleNotificationWithWorkManager(Context context, NotificationModel notificationModel, Calendar nextValidDate) {
//        Constraints myConstraints = new Constraints.Builder()
//                .setRequiresDeviceIdle(!notificationModel.schedule.allowWhileIdle)
//                .setRequiresBatteryNotLow(!notificationModel.schedule.allowWhileIdle)
//                .setRequiresStorageNotLow(false)
//                .build();
//
//        OneTimeWorkRequest notificationWork = new OneTimeWorkRequest.Builder(ScheduleWorker.class)
//                .setInitialDelay(calculateDelay(nextValidDate), TimeUnit.MILLISECONDS)
//                .addTag(notificationModel.content.id.toString())
//                .setConstraints(myConstraints)
//                .build();
//
//        WorkManager.getInstance(context).enqueue(notificationWork);
//    }

    private void scheduleNotificationWithAlarmManager(Context context, NotificationModel notificationModel, Calendar nextValidDate, PendingIntent pendingIntent) {
        AlarmManager alarmManager = ScheduleManager.getAlarmManager(context);
        long timeMillis = nextValidDate.getTimeInMillis();

        if (
            BooleanUtils.getInstance().getValue(notificationModel.schedule.preciseAlarm) &&
            ScheduleManager.isPreciseAlarmGloballyAllowed(alarmManager)
        ) {
            AlarmManager.AlarmClockInfo info = new AlarmManager.AlarmClockInfo(timeMillis, pendingIntent);
            alarmManager.setAlarmClock(info, pendingIntent);
            return;
        }

        if (BooleanUtils.getInstance().getValue(notificationModel.schedule.allowWhileIdle)) {
            AlarmManagerCompat.setExactAndAllowWhileIdle(alarmManager, AlarmManager.RTC_WAKEUP, timeMillis, pendingIntent);
            return;
        }

        AlarmManagerCompat.setExact(alarmManager, AlarmManager.RTC_WAKEUP, timeMillis, pendingIntent);
    }

    public static void refreshScheduledNotifications(Context context) {
        List<NotificationModel> notificationModels = ScheduleManager.listSchedules(context);
        if (notificationModels == null || notificationModels.isEmpty()) return;

        for (NotificationModel notificationModel : notificationModels) {
            try {

                if(isScheduleActiveOnAlarmManager(
                    context,
                    notificationModel.content.id)
                ){
                    continue;
                }

                if(notificationModel.schedule.hasNextValidDate()){
                    schedule(context, notificationModel);
                    continue;
                }

                ScheduleManager.cancelSchedule(context, notificationModel.content.id);

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

    public static void cancelAllSchedules(Context context) {
        if(context != null){
            _removeAllFromAlarm(context);
            ScheduleManager.cancelAllSchedules(context);
            ScheduleManager.commitChanges(context);
        }
    }

    private static void _removeFromAlarm(Context context, int id) {
        if(context != null){
            Intent intent = new Intent(context, ScheduledNotificationReceiver.class);

            @SuppressLint("WrongConstant")
            PendingIntent pendingIntent =
                PendingIntent
                    .getBroadcast(
                        context,
                        id,
                        intent,
                        Build.VERSION.SDK_INT >= Build.VERSION_CODES.S ?
                                PendingIntent.FLAG_MUTABLE | PendingIntent.FLAG_UPDATE_CURRENT :
                                PendingIntent.FLAG_UPDATE_CURRENT );

            AlarmManager alarmManager = ScheduleManager.getAlarmManager(context);
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

    public static boolean isScheduleActiveOnAlarmManager(Context context, int notificationId) throws AwesomeNotificationsException {

        if(notificationId < 0)
            throw new AwesomeNotificationsException("Scheduled notification Id is invalid");

        Intent notificationIntent = new Intent(context, ScheduledNotificationReceiver.class);

        @SuppressLint("WrongConstant")
        PendingIntent pendingIntent1 =
                PendingIntent
                        .getBroadcast(
                                context,
                                notificationId,
                                notificationIntent,
                                Build.VERSION.SDK_INT >= Build.VERSION_CODES.S ?
                                        PendingIntent.FLAG_MUTABLE | PendingIntent.FLAG_NO_CREATE :
                                        PendingIntent.FLAG_NO_CREATE );

        return pendingIntent1 != null;
    }
}
