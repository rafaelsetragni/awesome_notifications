package me.carda.awesome_notifications.notifications.broadcastReceivers;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;

import com.google.common.reflect.TypeToken;

import me.carda.awesome_notifications.Definitions;
import me.carda.awesome_notifications.notifications.PushNotification;
import me.carda.awesome_notifications.notifications.NotificationScheduler;
import me.carda.awesome_notifications.notifications.NotificationSender;
import me.carda.awesome_notifications.utils.JsonUtils;
import me.carda.awesome_notifications.utils.StringUtils;

/**
 * Created by michaelbui on 24/3/18.
 */

public class ScheduledNotificationReceiver extends BroadcastReceiver {


    @Override
    public void onReceive(final Context context, Intent intent) {

        String notificationDetailsJson = intent.getStringExtra(Definitions.NOTIFICATION_JSON);
        if (!StringUtils.isNullOrEmpty(notificationDetailsJson)) {

            PushNotification pushNotification = JsonUtils.fromJson(new TypeToken<PushNotification>(){}.getType(), notificationDetailsJson);
            if(pushNotification != null){

                try {

                    pushNotification.schedule.initialDateTime = null;

                    if(pushNotification.schedule.crontabSchedule != null){

                        NotificationScheduler.schedule(
                                context,
                                pushNotification
                        );
                    } else {

                        pushNotification.schedule = null;
                    }

                    NotificationSender.send(
                            context,
                            pushNotification
                    );

                } catch (Exception e) {
                    e.printStackTrace();
                }
            }
        }
    }
}
