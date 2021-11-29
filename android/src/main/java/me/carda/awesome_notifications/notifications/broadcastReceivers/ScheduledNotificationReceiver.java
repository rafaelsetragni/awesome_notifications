package me.carda.awesome_notifications.notifications.broadcastReceivers;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.util.Log;

//import com.google.common.reflect.TypeToken;

import me.carda.awesome_notifications.AwesomeNotificationsPlugin;
import me.carda.awesome_notifications.Definitions;
import me.carda.awesome_notifications.notifications.models.NotificationModel;
import me.carda.awesome_notifications.notifications.NotificationScheduler;
import me.carda.awesome_notifications.notifications.NotificationSender;
import me.carda.awesome_notifications.utils.StringUtils;

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

                NotificationSender.send(
                    context,
                    notificationModel
                );

                if(notificationModel.schedule.repeats)
                    NotificationScheduler.schedule(
                        context,
                        notificationModel
                    );
                else {

                    if(AwesomeNotificationsPlugin.debug)
                        Log.d(TAG,
                            "Schedule "+ notificationModel.content.id.toString() +
                                    " finished since repeat option is off");

                    NotificationScheduler.cancelSchedule(
                            context,
                            notificationModel.content.id
                    );
                }

            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }
}
