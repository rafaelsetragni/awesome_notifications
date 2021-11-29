package me.carda.awesome_notifications.notifications;

import android.annotation.SuppressLint;
import android.app.Notification;
import android.app.NotificationManager;
import android.content.Context;
import android.os.AsyncTask;
import android.os.Build;
import android.service.notification.StatusBarNotification;

import java.util.Arrays;
import java.util.List;

import androidx.annotation.RequiresApi;
import androidx.core.app.NotificationManagerCompat;

import me.carda.awesome_notifications.BroadcastSender;
import me.carda.awesome_notifications.AwesomeNotificationsPlugin;
import me.carda.awesome_notifications.notifications.enumerators.NotificationLayout;
import me.carda.awesome_notifications.notifications.enumerators.NotificationLifeCycle;
import me.carda.awesome_notifications.notifications.enumerators.NotificationSource;
import me.carda.awesome_notifications.notifications.exceptions.AwesomeNotificationException;
import me.carda.awesome_notifications.notifications.managers.StatusBarManager;
import me.carda.awesome_notifications.notifications.managers.CreatedManager;
import me.carda.awesome_notifications.notifications.managers.DismissedManager;
import me.carda.awesome_notifications.notifications.managers.DisplayedManager;
import me.carda.awesome_notifications.notifications.models.NotificationModel;
import me.carda.awesome_notifications.notifications.models.returnedData.ActionReceived;
import me.carda.awesome_notifications.notifications.models.returnedData.NotificationReceived;
import me.carda.awesome_notifications.utils.DateUtils;
import me.carda.awesome_notifications.utils.IntegerUtils;
import me.carda.awesome_notifications.utils.StringUtils;

public class NotificationSender extends AsyncTask<String, Void, NotificationReceived> {

    public static String TAG = "NotificationSender";

    @SuppressLint("StaticFieldLeak")
    private Context context;
    private NotificationSource createdSource;
    private NotificationLifeCycle appLifeCycle;
    private NotificationModel notificationModel;

    private Boolean created = false;
    private Boolean displayed = false;

    public static void send(
            Context context,
            NotificationModel notificationModel
    ) throws AwesomeNotificationException {

        NotificationSender.send(
                context,
                notificationModel.content.createdSource,
                notificationModel
        );
    }

    public static void send(
        Context context,
        NotificationSource createdSource,
        NotificationModel notificationModel
    ) throws AwesomeNotificationException {

        if (notificationModel == null ){
            throw new AwesomeNotificationException("Notification cannot be empty or null");
        }

        NotificationLifeCycle appLifeCycle;
        if(AwesomeNotificationsPlugin.appLifeCycle != NotificationLifeCycle.AppKilled){
            appLifeCycle = AwesomeNotificationsPlugin.getApplicationLifeCycle();
        }
        else {
            appLifeCycle = NotificationLifeCycle.AppKilled;
        }

        notificationModel.validate(context);

        new NotificationSender(
            context,
            appLifeCycle,
            createdSource,
            notificationModel
        ).execute();
    }

    private NotificationSender(
            Context context,
            NotificationLifeCycle appLifeCycle,
            NotificationSource createdSource,
            NotificationModel notificationModel
    ){
        this.context = context;
        this.createdSource = createdSource;
        this.appLifeCycle = appLifeCycle;
        this.notificationModel = notificationModel;
    }

    /// AsyncTask METHODS BEGIN *********************************

    @Override
    protected NotificationReceived doInBackground(String... parameters) {

        try {

            if (notificationModel != null){

                NotificationReceived receivedNotification = null;

                if(notificationModel.content.createdSource == null){
                    notificationModel.content.createdSource = createdSource;
                    created = true;
                }

                if(notificationModel.content.createdLifeCycle == null)
                    notificationModel.content.createdLifeCycle = appLifeCycle;

                if (
                    !StringUtils.isNullOrEmpty(notificationModel.content.title) ||
                    !StringUtils.isNullOrEmpty(notificationModel.content.body)
                ){

                    if(notificationModel.content.displayedLifeCycle == null)
                        notificationModel.content.displayedLifeCycle = appLifeCycle;

                    notificationModel.content.displayedDate = DateUtils.getUTCDate();

                    notificationModel = showNotification(context, notificationModel);

                    // Only save DisplayedMethods if notificationModel was created and displayed successfully
                    if(notificationModel != null){
                        displayed = true;

                        receivedNotification = new NotificationReceived(notificationModel.content);

                        receivedNotification.displayedLifeCycle = receivedNotification.displayedLifeCycle == null ?
                                appLifeCycle : receivedNotification.displayedLifeCycle;
                    }

                } else {
                    receivedNotification = new NotificationReceived(notificationModel.content);
                }

                return receivedNotification;
            }

        } catch (Exception e) {
            e.printStackTrace();
        }

        notificationModel = null;
        return null;
    }

    @Override
    protected void onPostExecute(NotificationReceived receivedNotification) {

        // Only broadcast if notificationModel is valid
        if(notificationModel != null){

            if(created){
                CreatedManager.saveCreated(context, receivedNotification);
                BroadcastSender.SendBroadcastNotificationCreated(
                    context,
                    receivedNotification
                );

                CreatedManager.commitChanges(context);
            }

            if(displayed){
                DisplayedManager.saveDisplayed(context, receivedNotification);
                BroadcastSender.SendBroadcastNotificationDisplayed(
                    context,
                    receivedNotification
                );

                DisplayedManager.commitChanges(context);
            }
        }
    }

    /// AsyncTask METHODS END *********************************

    private NotificationModel _buildSummaryGroupNotification(NotificationModel original){

        NotificationModel pushSummary = notificationModel.ClonePush();

        pushSummary.content.id = IntegerUtils.generateNextRandomId();
        pushSummary.content.notificationLayout = NotificationLayout.Default;
        pushSummary.content.largeIcon = null;
        pushSummary.content.bigPicture = null;
        pushSummary.groupSummary = true;

        return  pushSummary;
    }

    public NotificationModel showNotification(Context context, NotificationModel notificationModel) {

        try {

            NotificationLifeCycle lifeCycle = AwesomeNotificationsPlugin.getApplicationLifeCycle();

            if(
                (lifeCycle == NotificationLifeCycle.AppKilled) ||
                (lifeCycle == NotificationLifeCycle.Foreground && notificationModel.content.displayOnForeground) ||
                (lifeCycle == NotificationLifeCycle.Background && notificationModel.content.displayOnBackground)
            ){
                Notification notification = NotificationBuilder.createNotification(context, notificationModel);

                if(
                    Build.VERSION.SDK_INT >= Build.VERSION_CODES.N &&
                    notificationModel.content.notificationLayout == NotificationLayout.Default &&
                    StatusBarManager
                        .getInstance(context)
                        .isFirstActiveOnGroupKey(notificationModel.content.groupKey)
                ){
                    NotificationModel pushSummary = _buildSummaryGroupNotification(notificationModel);
                    Notification summaryNotification = NotificationBuilder.createNotification(context, pushSummary);

                    StatusBarManager
                        .getInstance(context)
                        .showNotificationOnStatusBar(pushSummary, summaryNotification);
                }

                StatusBarManager
                        .getInstance(context)
                        .showNotificationOnStatusBar(notificationModel, notification);
            }

            return notificationModel;

        } catch (Exception e) {
            e.printStackTrace();
        }
        return null;
    }

    public static void sendDismissedNotification(Context context, ActionReceived actionReceived){

        if (actionReceived != null){

            actionReceived.dismissedLifeCycle = AwesomeNotificationsPlugin.getApplicationLifeCycle();
            actionReceived.dismissedDate = DateUtils.getUTCDate();

            DismissedManager.saveDismissed(context, actionReceived);
            DismissedManager.commitChanges(context);

            try {

                BroadcastSender.SendBroadcastNotificationDismissed(
                    context,
                    actionReceived
                );

            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }

}
