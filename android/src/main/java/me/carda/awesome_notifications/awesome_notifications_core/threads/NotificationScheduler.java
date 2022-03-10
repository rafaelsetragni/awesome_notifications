package me.carda.awesome_notifications.awesome_notifications_core.threads;

import android.annotation.SuppressLint;
import android.app.AlarmManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.os.Build;
import android.util.Log;

import java.lang.ref.WeakReference;
import java.util.Calendar;
import java.util.List;

import androidx.annotation.NonNull;
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

public class NotificationScheduler extends NotificationThread<Calendar> {

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
        ).execute(notificationModel);
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
        ).execute(notificationModel);
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
    protected Calendar doInBackground() {
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
                            notificationModel);

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
        List<String> notificationIds = ScheduleManager.listScheduledIds(context);
        if (notificationIds.isEmpty()) return;

        for (String id : notificationIds) {
            try {

                if(isScheduleActiveOnAlarmManager(
                    context,
                    Integer.parseInt(id))
                ){
                    continue;
                }

                NotificationModel notificationModel = ScheduleManager.getScheduleById(context, id);
                if(notificationModel == null){
                    ScheduleManager.removeScheduleById(context, id);
                }
                else if(notificationModel.schedule.hasNextValidDate()){
                    schedule(context, notificationModel);
                    continue;
                }
                else {
                    ScheduleManager.removeSchedule(context, notificationModel);
                }

            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }

    public static void cancelScheduleById(
        @NonNull Context context, @NonNull Integer id
    ){
        _removeFromAlarm(context, id);
        ScheduleManager.removeScheduleById(context, id.toString());
        ScheduleManager.commitChanges(context);
    }

    public static void cancelSchedule(
        @NonNull Context context, @NonNull NotificationModel notificationModel
    ){
        _removeFromAlarm(context, notificationModel.content.id);
        ScheduleManager.removeSchedule(context, notificationModel);
        ScheduleManager.commitChanges(context);
    }

    public static void cancelSchedulesByChannelKey(
        @NonNull Context context, @NonNull String channelKey
    ){
        List<String> ids = ScheduleManager.listScheduledIdsFromChannel(context, channelKey);
        _removeAllFromAlarm(context, ids);
        ScheduleManager.cancelSchedulesByChannelKey(context, channelKey);
        ScheduleManager.commitChanges(context);
    }

    public static void cancelSchedulesByGroupKey(
        @NonNull Context context, @NonNull String groupKey
    ){
        List<String> ids = ScheduleManager.listScheduledIdsFromGroup(context, groupKey);
        _removeAllFromAlarm(context, ids);
        ScheduleManager.cancelSchedulesByGroupKey(context, groupKey);
        ScheduleManager.commitChanges(context);
    }

    public static void cancelAllSchedules(@NonNull Context context){
        List<String> ids = ScheduleManager.listScheduledIds(context);
        _removeAllFromAlarm(context, ids);
        ScheduleManager.cancelAllSchedules(context);
        ScheduleManager.commitChanges(context);
    }

    private static void _removeFromAlarm(
        @NonNull Context context, @NonNull Integer id
    ){
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

    private static void _removeAllFromAlarm(
        @NonNull Context context, @NonNull List<String> ids
    ){
        AlarmManager alarmManager = ScheduleManager.getAlarmManager(context);
        Intent intent = new Intent(context, ScheduledNotificationReceiver.class);
        int flags =
                Build.VERSION.SDK_INT >= Build.VERSION_CODES.S ?
                        PendingIntent.FLAG_MUTABLE | PendingIntent.FLAG_UPDATE_CURRENT :
                        PendingIntent.FLAG_UPDATE_CURRENT;

        for(String id : ids){
            @SuppressLint("WrongConstant")
            PendingIntent pendingIntent =
                    PendingIntent
                            .getBroadcast(
                                    context,
                                    Integer.parseInt(id),
                                    intent,
                                    flags);

            alarmManager.cancel(pendingIntent);
        }
    }

    public static boolean isScheduleActiveOnAlarmManager(
        @NonNull Context context, @NonNull Integer notificationId
    ) throws AwesomeNotificationsException {

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
