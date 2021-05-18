package me.carda.awesome_notifications.notifications.broadcastReceivers;

import android.annotation.TargetApi;
import android.app.IntentService;
import android.app.Service;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.os.Build;
import android.os.IBinder;
import io.flutter.Log;
import android.widget.Toast;

import me.carda.awesome_notifications.AwesomeNotificationsPlugin;
import me.carda.awesome_notifications.BroadcastSender;
import me.carda.awesome_notifications.Definitions;
import me.carda.awesome_notifications.notifications.NotificationBuilder;
import me.carda.awesome_notifications.notifications.NotificationSender;
import me.carda.awesome_notifications.notifications.models.returnedData.ActionReceived;
import me.carda.awesome_notifications.utils.DateUtils;

@TargetApi(Build.VERSION_CODES.CUPCAKE)
public class DismissedNotificationReceiver extends BroadcastReceiver
{
    static String TAG = "DismissedNotificationReceiver";

    @Override
    public void onReceive(Context context, Intent intent) {

        String action = intent.getAction();

        if (action != null && action.equals(Definitions.DISMISSED_NOTIFICATION)) {
            ActionReceived actionReceived = NotificationBuilder.buildNotificationActionFromIntent(context, intent);
            NotificationSender.sendDismissedNotification(context, actionReceived);
        }
    }
}
