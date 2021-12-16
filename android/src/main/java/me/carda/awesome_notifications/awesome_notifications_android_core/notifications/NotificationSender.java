package me.carda.awesome_notifications.awesome_notifications_android_core.notifications;

import android.annotation.SuppressLint;
import android.app.Notification;
import android.content.Context;
import android.os.AsyncTask;
import android.os.Build;

import me.carda.awesome_notifications.awesome_notifications_android_core.AwesomeNotifications;
import me.carda.awesome_notifications.awesome_notifications_android_core.enumerators.NotificationLayout;
import me.carda.awesome_notifications.awesome_notifications_android_core.enumerators.NotificationLifeCycle;
import me.carda.awesome_notifications.awesome_notifications_android_core.enumerators.NotificationSource;
import me.carda.awesome_notifications.awesome_notifications_android_core.exceptions.AwesomeNotificationException;
import me.carda.awesome_notifications.awesome_notifications_android_core.managers.StatusBarManager;
import me.carda.awesome_notifications.awesome_notifications_android_core.managers.CreatedManager;
import me.carda.awesome_notifications.awesome_notifications_android_core.managers.DisplayedManager;
import me.carda.awesome_notifications.awesome_notifications_android_core.models.NotificationModel;
import me.carda.awesome_notifications.awesome_notifications_android_core.models.returnedData.NotificationReceived;
import me.carda.awesome_notifications.awesome_notifications_android_core.broadcasters.senders.BroadcastSender;
import me.carda.awesome_notifications.awesome_notifications_android_core.utils.DateUtils;
import me.carda.awesome_notifications.awesome_notifications_android_core.utils.IntegerUtils;
import me.carda.awesome_notifications.awesome_notifications_android_core.utils.StringUtils;

public class NotificationSender extends AsyncTask<String, Void, NotificationReceived> {

    public static String TAG = "NotificationSender";

    @SuppressLint("StaticFieldLeak")
    private final Context context;

    private final NotificationBuilder notificationBuilder;
    private final NotificationSource createdSource;
    private final NotificationLifeCycle appLifeCycle;

    private NotificationModel notificationModel;

    private Boolean created = false;
    private Boolean displayed = false;

    public static void send(
            Context context,
            NotificationBuilder notificationBuilder,
            NotificationLifeCycle appLifeCycle,
            NotificationModel notificationModel
    ) throws AwesomeNotificationException {

        NotificationSender.send(
                context,
                notificationBuilder,
                notificationModel.content.createdSource,
                appLifeCycle,
                notificationModel
        );
    }

    public static void send(
        Context context,
        NotificationBuilder notificationBuilder,
        NotificationSource createdSource,
        NotificationLifeCycle appLifeCycle,
        NotificationModel notificationModel
    ) throws AwesomeNotificationException {

        if (notificationModel == null )
            throw new AwesomeNotificationException("Notification cannot be empty or null");

        new NotificationSender(
            context,
            notificationBuilder,
            appLifeCycle,
            createdSource,
            notificationModel
        ).execute();
    }

    private NotificationSender(
            Context context,
            NotificationBuilder notificationBuilder,
            NotificationLifeCycle appLifeCycle,
            NotificationSource createdSource,
            NotificationModel notificationModel
    ){
        this.context = context;
        this.notificationBuilder = notificationBuilder;
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
                BroadcastSender.sendBroadcastNotificationCreated(
                    context,
                    receivedNotification
                );

                CreatedManager.commitChanges(context);
            }

            if(displayed){
                DisplayedManager.saveDisplayed(context, receivedNotification);
                BroadcastSender.sendBroadcastNotificationDisplayed(
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

            NotificationLifeCycle lifeCycle = AwesomeNotifications.getApplicationLifeCycle();

            if(
                (lifeCycle == NotificationLifeCycle.AppKilled) ||
                (lifeCycle == NotificationLifeCycle.Foreground && notificationModel.content.displayOnForeground) ||
                (lifeCycle == NotificationLifeCycle.Background && notificationModel.content.displayOnBackground)
            ){
                Notification notification = notificationBuilder.createNewAndroidNotification(context, notificationModel);

                if(
                    Build.VERSION.SDK_INT >= Build.VERSION_CODES.N &&
                    notificationModel.content.notificationLayout == NotificationLayout.Default &&
                    StatusBarManager
                        .getInstance(context)
                        .isFirstActiveOnGroupKey(notificationModel.content.groupKey)
                ){
                    NotificationModel pushSummary = _buildSummaryGroupNotification(notificationModel);
                    Notification summaryNotification = notificationBuilder.createNewAndroidNotification(context, pushSummary);

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
}
