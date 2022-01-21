package me.carda.awesome_notifications.awesome_notifications_android_core.broadcasters.receivers;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.util.Log;

//import com.google.common.reflect.TypeToken;

import me.carda.awesome_notifications.awesome_notifications_android_core.AwesomeNotifications;
import me.carda.awesome_notifications.awesome_notifications_android_core.Definitions;
import me.carda.awesome_notifications.awesome_notifications_android_core.builders.NotificationBuilder;
import me.carda.awesome_notifications.awesome_notifications_android_core.models.NotificationModel;
import me.carda.awesome_notifications.awesome_notifications_android_core.builders.NotificationScheduler;
import me.carda.awesome_notifications.awesome_notifications_android_core.builders.NotificationSender;
import me.carda.awesome_notifications.awesome_notifications_android_core.utils.StringUtils;

public class ScheduledNotificationReceiver extends BroadcastReceiver {

    static String TAG = "ScheduledNotificationReceiver";

    @Override
    public void onReceive(final Context context, Intent intent) {

        //Toast.makeText(context, "ScheduledNotificationReceiver", Toast.LENGTH_SHORT).show();

        String notificationDetailsJson = intent.getStringExtra(Definitions.NOTIFICATION_JSON);
        if (!StringUtils.isNullOrEmpty(notificationDetailsJson)) {

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
                            notificationModel);
                }
                else {
                    NotificationScheduler
                        .cancelSchedule(
                            context,
                            notificationModel.content.id);

                    if(AwesomeNotifications.debug)
                        Log.d(TAG,
                            "Schedule "+ notificationModel.content.id.toString() +
                                    " finished since repeat option is off");
                }

            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }
}
