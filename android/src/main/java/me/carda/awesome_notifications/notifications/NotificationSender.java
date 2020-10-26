package me.carda.awesome_notifications.notifications;

import android.annotation.SuppressLint;
import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.content.Context;
import android.os.AsyncTask;
import android.os.Build;
import io.flutter.Log;

import com.google.common.reflect.TypeToken;

import java.util.List;

import androidx.core.app.NotificationCompat;
import androidx.core.app.NotificationManagerCompat;

import me.carda.awesome_notifications.BroadcastSender;
import me.carda.awesome_notifications.AwesomeNotificationsPlugin;
import me.carda.awesome_notifications.notifications.enumeratos.NotificationLifeCycle;
import me.carda.awesome_notifications.notifications.enumeratos.NotificationSource;
import me.carda.awesome_notifications.notifications.exceptions.PushNotificationException;
import me.carda.awesome_notifications.notifications.managers.CreatedManager;
import me.carda.awesome_notifications.notifications.managers.DisplayedManager;
import me.carda.awesome_notifications.notifications.models.returnedData.NotificationReceived;
import me.carda.awesome_notifications.utils.DateUtils;
import me.carda.awesome_notifications.utils.StringUtils;

public class NotificationSender extends AsyncTask<String, Void, NotificationReceived> {

    public static String TAG = "NotificationSender";

    @SuppressLint("StaticFieldLeak")
    private Context context;
    private NotificationSource createdSource;
    private NotificationLifeCycle appLifeCycle;
    private PushNotification pushNotification;

    private Boolean created = false;
    private Boolean displayed = false;

    private NotificationBuilder notificationBuilder = new NotificationBuilder();

    public static void send(
            Context context,
            PushNotification pushNotification
    ) throws PushNotificationException {

        NotificationSender.send(
                context,
                pushNotification.content.createdSource,
                pushNotification
        );
    }

    public static void send(
        Context context,
        NotificationSource createdSource,
        PushNotification pushNotification
    ) throws PushNotificationException {

        if (pushNotification == null ){
            throw new PushNotificationException("Notification cannot be empty or null");
        }

        NotificationLifeCycle appLifeCycle;
        if(AwesomeNotificationsPlugin.appLifeCycle != NotificationLifeCycle.AppKilled){
            appLifeCycle = AwesomeNotificationsPlugin.getApplicationLifeCycle();
        }
        else {
            appLifeCycle = NotificationLifeCycle.AppKilled;
        }

        pushNotification.validate(context);

        new NotificationSender(
            context,
            appLifeCycle,
            createdSource,
            pushNotification
        ).execute();
    }

    private NotificationSender(
            Context context,
            NotificationLifeCycle appLifeCycle,
            NotificationSource createdSource,
            PushNotification pushNotification
    ){
        this.context = context;
        this.createdSource = createdSource;
        this.appLifeCycle = appLifeCycle;
        this.pushNotification = pushNotification;
    }

    /// AsyncTask METHODS BEGIN *********************************

    @Override
    protected NotificationReceived doInBackground(String... parameters) {

        try {

            if (pushNotification != null){

                NotificationReceived receivedNotification = null;

                if(pushNotification.content.createdSource == null){
                    pushNotification.content.createdSource = createdSource;
                    created = true;
                }

                if(pushNotification.content.createdLifeCycle == null)
                    pushNotification.content.createdLifeCycle = appLifeCycle;

                if (
                    !StringUtils.isNullOrEmpty(pushNotification.content.title) ||
                    !StringUtils.isNullOrEmpty(pushNotification.content.body)
                ){

                    if(pushNotification.content.displayedLifeCycle == null)
                        pushNotification.content.displayedLifeCycle = appLifeCycle;

                    pushNotification.content.displayedDate = DateUtils.getUTCDate();

                    pushNotification = showNotification(context, pushNotification);

                    // Only save DisplayedMethods if pushNotification was created and displayed successfully
                    if(pushNotification != null){
                        displayed = true;

                        receivedNotification = new NotificationReceived(pushNotification.content);

                        receivedNotification.displayedLifeCycle = receivedNotification.displayedLifeCycle == null ?
                                appLifeCycle : receivedNotification.displayedLifeCycle;
                    }

                } else {
                    receivedNotification = new NotificationReceived(pushNotification.content);
                }

                return receivedNotification;
            }

        } catch (Exception e) {
            e.printStackTrace();
        }

        pushNotification = null;
        return null;
    }

    @Override
    protected void onPostExecute(NotificationReceived receivedNotification) {
        Log.d(TAG, "Notification created");

        // Only broadcast if pushNotification is valid
        if(pushNotification != null){

            if(created){
                CreatedManager.saveCreated(context, receivedNotification);
                BroadcastSender.SendBroadcastNotificationCreated(
                    context,
                    receivedNotification
                );
            }

            if(displayed){
                DisplayedManager.saveDisplayed(context, receivedNotification);
                BroadcastSender.SendBroadcastNotificationDisplayed(
                    context,
                    receivedNotification
                );
            }
        }
    }

    /// AsyncTask METHODS END *********************************

    public PushNotification showNotification(Context context, PushNotification pushNotification) {

        try {

            NotificationLifeCycle lifeCycle = AwesomeNotificationsPlugin.getApplicationLifeCycle();

            if(
                (lifeCycle == NotificationLifeCycle.AppKilled) ||
                (lifeCycle == NotificationLifeCycle.Foreground && pushNotification.content.displayOnForeground) ||
                (lifeCycle == NotificationLifeCycle.Background && pushNotification.content.displayOnBackground)
            ){
                Notification notification = notificationBuilder.createNotification(context, pushNotification);

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    NotificationManager notificationManager = (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);
                    notificationManager.notify(pushNotification.content.id, notification);
                }
                else {
                    NotificationManagerCompat notificationManagerCompat = getNotificationManager(context);
                    notificationManagerCompat.notify(pushNotification.content.id.toString(), pushNotification.content.id, notification);
                }
            }

            return pushNotification;

        } catch (Exception e) {
            e.printStackTrace();
        }
        return null;
    }

    private static NotificationManagerCompat getNotificationManager(Context context) {
        return NotificationManagerCompat.from(context);
    }

    public static void cancelNotification(Context context, Integer id) {
        if(context != null){
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                NotificationManagerCompat notificationManager = getNotificationManager(context);
                notificationManager.cancel(id.toString(), id);
                notificationManager.cancel(id);
            }

            NotificationManager notificationManager = (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);
            notificationManager.cancel(id.toString(), id);
            notificationManager.cancel(id);


            CreatedManager.cancelCreated(context, id);
            DisplayedManager.cancelDisplayed(context, id);
        }
    }

    public static boolean cancelAllNotifications(Context context) {

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationManagerCompat notificationManager = getNotificationManager(context);
            notificationManager.cancelAll();
        }
        else {
            NotificationManager notificationManager = (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);
            notificationManager.cancelAll();
        }

        CreatedManager.cancelAllCreated(context);
        DisplayedManager.cancelAllDisplayed(context);

        return true;
    }

}
