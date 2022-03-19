package me.carda.awesome_notifications.awesome_notifications_core.broadcasters.receivers;

import android.content.Context;
import android.content.Intent;
import me.carda.awesome_notifications.awesome_notifications_core.logs.Logger;

//import com.google.common.reflect.TypeToken;

import me.carda.awesome_notifications.awesome_notifications_core.AwesomeNotifications;
import me.carda.awesome_notifications.awesome_notifications_core.Definitions;
import me.carda.awesome_notifications.awesome_notifications_core.builders.NotificationBuilder;
import me.carda.awesome_notifications.awesome_notifications_core.models.NotificationModel;
import me.carda.awesome_notifications.awesome_notifications_core.threads.NotificationScheduler;
import me.carda.awesome_notifications.awesome_notifications_core.threads.NotificationSender;
import me.carda.awesome_notifications.awesome_notifications_core.utils.StringUtils;

public class ScheduledNotificationReceiver extends AwesomeBroadcastReceiver {

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
                        notificationModel);

                if(notificationModel.schedule.repeats) {
                    NotificationScheduler
                        .schedule(
                            context,
                            notificationModel,
                            intent);
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
