package me.carda.awesome_notifications.core.threads;

import android.annotation.SuppressLint;
import android.app.AlarmManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.os.Build;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.core.app.AlarmManagerCompat;

import java.lang.ref.WeakReference;
import java.util.Calendar;
import java.util.List;

import me.carda.awesome_notifications.core.AwesomeNotifications;
import me.carda.awesome_notifications.core.Definitions;
import me.carda.awesome_notifications.core.broadcasters.senders.BroadcastSender;
import me.carda.awesome_notifications.core.completion_handlers.NotificationThreadCompletionHandler;
import me.carda.awesome_notifications.core.enumerators.NotificationLifeCycle;
import me.carda.awesome_notifications.core.enumerators.NotificationSource;
import me.carda.awesome_notifications.core.exceptions.AwesomeNotificationsException;
import me.carda.awesome_notifications.core.exceptions.ExceptionCode;
import me.carda.awesome_notifications.core.exceptions.ExceptionFactory;
import me.carda.awesome_notifications.core.logs.Logger;
import me.carda.awesome_notifications.core.managers.ChannelManager;
import me.carda.awesome_notifications.core.managers.ScheduleManager;
import me.carda.awesome_notifications.core.models.NotificationModel;
import me.carda.awesome_notifications.core.models.returnedData.NotificationReceived;
import me.carda.awesome_notifications.core.utils.BooleanUtils;
import me.carda.awesome_notifications.core.utils.CalendarUtils;
import me.carda.awesome_notifications.core.utils.IntegerUtils;

public class NotificationScheduler extends NotificationThread<Calendar> {

    public static String TAG = "NotificationScheduler";

    private final WeakReference<Context> wContextReference;

    private final NotificationSource createdSource;
    private final NotificationLifeCycle appLifeCycle;
    private NotificationModel notificationModel;
    private final Intent originalIntent;

    private Boolean scheduled = false;
    private Boolean rescheduled = false;
    private long startTime = 0L, endTime = 0L;
    private final Calendar initialDate;

    private final NotificationThreadCompletionHandler threadCompletionHandler;

    public static void schedule(
            Context context,
            NotificationModel notificationModel,
            Intent originalIntent,
            NotificationThreadCompletionHandler threadCompletionHandler
    ) throws AwesomeNotificationsException {

        if (notificationModel == null)
            throw ExceptionFactory
                    .getInstance()
                    .createNewAwesomeException(
                            TAG,
                            ExceptionCode.CODE_INVALID_ARGUMENTS,
                            "Invalid notification content",
                            ExceptionCode.DETAILED_INVALID_ARGUMENTS + ".notificationModel");

        notificationModel.validate(context);

        new NotificationScheduler(
                context,
                AwesomeNotifications.getApplicationLifeCycle(),
                notificationModel.content.createdSource,
                notificationModel,
                originalIntent,
                true,
                threadCompletionHandler
        ).execute(notificationModel);
    }

    public static void schedule(
        Context context,
        NotificationSource createdSource,
        NotificationModel notificationModel,
        NotificationThreadCompletionHandler threadCompletionHandler
    ) throws AwesomeNotificationsException {

        if (notificationModel == null)
            throw ExceptionFactory
                    .getInstance()
                    .createNewAwesomeException(
                            TAG,
                            ExceptionCode.CODE_INVALID_ARGUMENTS,
                            "Invalid notification content",
                            ExceptionCode.DETAILED_INVALID_ARGUMENTS + ".notificationModel");

        notificationModel.validate(context);

        new NotificationScheduler(
                context,
                AwesomeNotifications.getApplicationLifeCycle(),
                createdSource,
                notificationModel,
                null,
                false,
                threadCompletionHandler
        ).execute(notificationModel);
    }

    private NotificationScheduler(
            Context context,
            NotificationLifeCycle appLifeCycle,
            NotificationSource createdSource,
            NotificationModel notificationModel,
            Intent originalIntent,
            boolean isReschedule,
            NotificationThreadCompletionHandler threadCompletionHandler
    ) throws AwesomeNotificationsException {
        this.wContextReference = new WeakReference<>(context);
        this.rescheduled = isReschedule;
        this.createdSource = createdSource;
        this.appLifeCycle = appLifeCycle;
        this.notificationModel = notificationModel;
        this.startTime = System.nanoTime();
        this.originalIntent = originalIntent;
        this.threadCompletionHandler = threadCompletionHandler;

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
    protected Calendar doInBackground() throws Exception {
        Calendar nextValidDate = null;

        if(notificationModel != null){

            if (!ChannelManager
                    .getInstance()
                    .isChannelEnabled(
                            wContextReference.get(),
                            notificationModel.content.channelKey)
            )
                throw ExceptionFactory
                        .getInstance()
                        .createNewAwesomeException(
                                TAG,
                                ExceptionCode.CODE_INVALID_ARGUMENTS,
                                "Channel '" + notificationModel.content.channelKey +
                                        "' do not exist or is disabled",
                                ExceptionCode.DETAILED_INSUFFICIENT_PERMISSIONS+
                                        ".channel."+notificationModel.content.channelKey);

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
                Logger.d(TAG, msg);
            }
        }

        return null;
    }

    @Override
    protected Calendar onPostExecute(Calendar nextValidDate) throws AwesomeNotificationsException {

        // Only fire ActionReceived if notificationModel is valid
        if(notificationModel != null){
            
            if(nextValidDate != null) {

                if(scheduled){

                    ScheduleManager.saveSchedule(wContextReference.get(), notificationModel);
                    if (!rescheduled) {
                        BroadcastSender.sendBroadcastNotificationCreated(
                                wContextReference.get(),
                                new NotificationReceived(
                                        notificationModel.content,
                                        originalIntent)
                        );
                        Logger.d(TAG, "Scheduled created");
                    }

                    ScheduleManager.commitChanges(wContextReference.get());

                    if(this.endTime == 0L)
                        this.endTime = System.nanoTime();

                    if(AwesomeNotifications.debug){
                        long elapsed = (endTime - startTime)/1000000;
                        Logger.d(TAG, "Notification "+(
                                rescheduled ? "rescheduled" : "scheduled"
                                )+" in "+elapsed+"ms");
                    }
                    return nextValidDate;
                }
            }

            ScheduleManager.removeSchedule(wContextReference.get(), notificationModel);
            _removeFromAlarm(wContextReference.get(), notificationModel.content.id);

            Logger.d(TAG, "Scheduled removed");
            ScheduleManager.commitChanges(wContextReference.get());
        }

        if(this.endTime == 0L)
            this.endTime = System.nanoTime();

        if(AwesomeNotifications.debug){
            long elapsed = (endTime - startTime)/1000000;
            Logger.d(TAG, "Notification schedule removed in "+elapsed+"ms");
        }

        return null;
    }

    @Override
    protected void whenComplete(
            @Nullable Calendar calendar,
            @Nullable AwesomeNotificationsException exception
    ) throws AwesomeNotificationsException {
        if(threadCompletionHandler != null)
            threadCompletionHandler.handle(exception != null, exception);
    }

    /// AsyncTask METHODS END *********************************

    private NotificationModel scheduleNotification(Context context, NotificationModel notificationModel, Calendar nextValidDate) {

        if(nextValidDate != null){

            String notificationDetailsJson = notificationModel.toJson();
            Intent notificationIntent = new Intent(context, AwesomeNotifications.scheduleReceiverClass);
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

    public static void refreshScheduledNotifications(
            Context context
    ) throws AwesomeNotificationsException {

        List<String> notificationIds = ScheduleManager.listScheduledIds(context);
        if (notificationIds.isEmpty()) return;

        for (String id : notificationIds) {

            if(isScheduleActiveOnAlarmManager(
                context,
                Integer.parseInt(id)))
                continue;

            NotificationModel notificationModel = ScheduleManager.getScheduleById(context, id);
            if(notificationModel == null){
                ScheduleManager.cancelScheduleById(context, id);
            }
            else if(notificationModel.schedule.hasNextValidDate()){
                // TODO save original intents to be restored later
                schedule(context, notificationModel, null, null);
            }
            else {
                ScheduleManager.removeSchedule(context, notificationModel);
            }
        }
    }

    public static void cancelScheduleById(
        @NonNull Context context, @NonNull Integer id
    ) throws AwesomeNotificationsException {
        _removeFromAlarm(context, id);
        ScheduleManager.cancelScheduleById(context, id.toString());
        ScheduleManager.commitChanges(context);
    }

    public static void cancelSchedule(
        @NonNull Context context, @NonNull NotificationModel notificationModel
    ) throws AwesomeNotificationsException {
        _removeFromAlarm(context, notificationModel.content.id);
        ScheduleManager.removeSchedule(context, notificationModel);
        ScheduleManager.commitChanges(context);
    }

    public static void cancelSchedulesByChannelKey(
        @NonNull Context context, @NonNull String channelKey
    ) throws AwesomeNotificationsException {
        List<String> ids = ScheduleManager.listScheduledIdsFromChannel(context, channelKey);
        _removeAllFromAlarm(context, ids);
        ScheduleManager.cancelSchedulesByChannelKey(context, channelKey);
        ScheduleManager.commitChanges(context);
    }

    public static void cancelSchedulesByGroupKey(
        @NonNull Context context, @NonNull String groupKey
    ) throws AwesomeNotificationsException {
        List<String> ids = ScheduleManager.listScheduledIdsFromGroup(context, groupKey);
        _removeAllFromAlarm(context, ids);
        ScheduleManager.cancelSchedulesByGroupKey(context, groupKey);
        ScheduleManager.commitChanges(context);
    }

    public static void cancelAllSchedules(@NonNull Context context) throws AwesomeNotificationsException {
        List<String> ids = ScheduleManager.listScheduledIds(context);
        _removeAllFromAlarm(context, ids);
        ScheduleManager.cancelAllSchedules(context);
        ScheduleManager.commitChanges(context);
    }

    private static void _removeFromAlarm(
        @NonNull Context context, @NonNull Integer id
    ){
        Intent intent = new Intent(context, AwesomeNotifications.scheduleReceiverClass);

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
        Intent intent = new Intent(context, AwesomeNotifications.scheduleReceiverClass);
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
        @NonNull Context context,
        @NonNull Integer notificationId
    ) throws AwesomeNotificationsException {

        if(notificationId < 0)
            throw ExceptionFactory
                    .getInstance()
                    .createNewAwesomeException(
                            TAG,
                            ExceptionCode.CODE_INVALID_ARGUMENTS,
                            "Scheduled notification Id is invalid",
                            ExceptionCode.DETAILED_INVALID_ARGUMENTS + ".notificationId");

        Intent notificationIntent = new Intent(context, AwesomeNotifications.scheduleReceiverClass);

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
