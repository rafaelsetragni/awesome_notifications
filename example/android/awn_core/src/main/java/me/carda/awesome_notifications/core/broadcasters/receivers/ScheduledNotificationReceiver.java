package me.carda.awesome_notifications.core.broadcasters.receivers;

import android.content.Context;
import android.content.Intent;

import me.carda.awesome_notifications.core.AwesomeNotifications;
import me.carda.awesome_notifications.core.Definitions;
import me.carda.awesome_notifications.core.builders.NotificationBuilder;
import me.carda.awesome_notifications.core.logs.Logger;
import me.carda.awesome_notifications.core.models.NotificationModel;
import me.carda.awesome_notifications.core.threads.NotificationScheduler;
import me.carda.awesome_notifications.core.threads.NotificationSender;
import me.carda.awesome_notifications.core.utils.StringUtils;

public abstract class ScheduledNotificationReceiver extends AwesomeBroadcastReceiver {

    static String TAG = "ScheduledNotificationReceiver";

    @Override
    public void onReceiveBroadcastEvent(final Context context, Intent intent) {

        //Toast.makeText(context, "ScheduledNotificationReceiver", Toast.LENGTH_SHORT).show();

        String notificationDetailsJson = intent.getStringExtra(Definitions.NOTIFICATION_JSON);
        if (!StringUtils.getInstance().isNullOrEmpty(notificationDetailsJson)) {

            try {
                NotificationModel notificationModel = new NotificationModel().fromJson(notificationDetailsJson);

                if(notificationModel == null){ return; }

                NotificationSender
                    .send(
                        context,
                        NotificationBuilder.getNewBuilder(),
                        AwesomeNotifications.getApplicationLifeCycle(),
                        notificationModel,
                        null);

                if(notificationModel.schedule.repeats) {
                    NotificationScheduler
                        .schedule(
                            context,
                            notificationModel,
                            intent,
                            null);
                }
                else {
                    NotificationScheduler
                        .cancelSchedule(
                            context,
                            notificationModel);

                    if(AwesomeNotifications.debug)
                        Logger.d(TAG,
                            "Schedule "+ notificationModel.content.id.toString() +
                                    " finished since repeat option is off");
                }

            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }
}
