package me.carda.awesome_notifications.notifications;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;

import android.content.Context;
import android.content.Intent;
import android.content.pm.ApplicationInfo;
import android.graphics.Bitmap;
import android.graphics.Color;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.PowerManager;
import android.widget.RemoteViews;
import android.support.v4.media.MediaMetadataCompat;

import java.io.Serializable;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

import androidx.annotation.NonNull;
import androidx.annotation.RequiresApi;
import androidx.core.app.NotificationCompat;
import androidx.core.app.Person;
import androidx.core.app.RemoteInput;

import androidx.core.graphics.drawable.IconCompat;
import androidx.core.text.HtmlCompat;
import me.carda.awesome_notifications.AwesomeNotificationsPlugin;
import me.carda.awesome_notifications.Definitions;
import me.carda.awesome_notifications.notifications.broadcastReceivers.DismissedNotificationReceiver;
import me.carda.awesome_notifications.notifications.broadcastReceivers.KeepOnTopActionReceiver;
import me.carda.awesome_notifications.notifications.enumerators.ActionButtonType;
import me.carda.awesome_notifications.notifications.enumerators.GroupSort;
import me.carda.awesome_notifications.notifications.enumerators.NotificationImportance;
import me.carda.awesome_notifications.notifications.enumerators.NotificationLayout;
import me.carda.awesome_notifications.notifications.enumerators.NotificationLifeCycle;
import me.carda.awesome_notifications.notifications.enumerators.NotificationPermission;
import me.carda.awesome_notifications.notifications.enumerators.NotificationPrivacy;
import me.carda.awesome_notifications.notifications.exceptions.AwesomeNotificationException;
import me.carda.awesome_notifications.notifications.managers.BadgeManager;
import me.carda.awesome_notifications.notifications.managers.StatusBarManager;
import me.carda.awesome_notifications.notifications.managers.ChannelManager;
import me.carda.awesome_notifications.notifications.managers.DefaultsManager;
import me.carda.awesome_notifications.notifications.managers.PermissionManager;
import me.carda.awesome_notifications.notifications.models.NotificationButtonModel;
import me.carda.awesome_notifications.notifications.models.NotificationChannelModel;
import me.carda.awesome_notifications.notifications.models.NotificationContentModel;
import me.carda.awesome_notifications.notifications.models.NotificationMessageModel;
import me.carda.awesome_notifications.notifications.models.NotificationModel;
import me.carda.awesome_notifications.notifications.models.returnedData.ActionReceived;
import me.carda.awesome_notifications.utils.BitmapUtils;
import me.carda.awesome_notifications.utils.BooleanUtils;
import me.carda.awesome_notifications.utils.DateUtils;
import me.carda.awesome_notifications.utils.HtmlUtils;
import me.carda.awesome_notifications.utils.IntegerUtils;
import me.carda.awesome_notifications.utils.ListUtils;
import me.carda.awesome_notifications.utils.StringUtils;

//badges

import static android.app.NotificationManager.Policy.PRIORITY_CATEGORY_ALARMS;
import static android.content.Context.NOTIFICATION_SERVICE;

public class NotificationBuilder {

    public static String TAG = "NotificationBuilder";

    public static ActionReceived receiveNotificationAction(Context context, Intent intent, NotificationLifeCycle appLifeCycle) {

        ActionReceived actionReceived
            = NotificationBuilder
                .buildNotificationActionFromIntent(context, intent, appLifeCycle);

        if (actionReceived != null) {
            if (NotificationBuilder.notificationActionShouldAutoDismiss(actionReceived))
                StatusBarManager
                        .getInstance(context)
                        .dismissNotification(actionReceived.id);

            if (actionReceived.actionButtonType == ActionButtonType.DisabledAction)
                return null;
        }

        return actionReceived;
    }

    public static boolean notificationActionShouldAutoDismiss(ActionReceived actionReceived){
        return actionReceived.shouldAutoDismiss && actionReceived.autoDismissible;
    }

    @SuppressWarnings("unchecked")
    public static Notification createNotification(Context context, NotificationModel notificationModel) throws AwesomeNotificationException {

        NotificationChannelModel channelModel = ChannelManager.getChannelByKey(context, notificationModel.content.channelKey);
        if(channelModel == null)
            throw new AwesomeNotificationException("Channel '"+ notificationModel.content.channelKey +"' does not exist or is disabled");

        if (notificationModel.content.id == null || notificationModel.content.id < 0)
            notificationModel.content.id = IntegerUtils.generateNextRandomId();

        notificationModel.content.groupKey = getGroupKey(notificationModel.content, channelModel);

        return getNotificationBuilderFromModel(context, notificationModel);
    }

    public static Intent buildNotificationIntentFromModel(
            Context context,
            String ActionReference,
            NotificationModel notificationModel,
            NotificationChannelModel channel,
            Class<?> targetAction
    ) {
        Intent intent = new Intent(context, targetAction);

        intent.setAction(ActionReference);

        Bundle extras = intent.getExtras();
        if(extras == null)
            extras = new Bundle();

        String jsonData = notificationModel.toJson();
        extras.putString(Definitions.NOTIFICATION_JSON, jsonData);

        updateTrackingExtras(notificationModel, channel, extras);
        intent.putExtras(extras);

        return intent;
    }

    private static PendingIntent getPendingActionIntent(Context context, NotificationModel notificationModel, NotificationChannelModel channelModel) {
        Intent intent = buildNotificationIntentFromModel(
                context,
                Definitions.SELECT_NOTIFICATION,
                notificationModel,
                channelModel
        );

        PendingIntent pendingActionIntent = PendingIntent.getActivity(
                context,
                notificationModel.content.id,
                intent,
                PendingIntent.FLAG_IMMUTABLE | PendingIntent.FLAG_UPDATE_CURRENT
        );
        return pendingActionIntent;
    }

    private static PendingIntent getPendingDismissIntent(Context context, NotificationModel notificationModel, NotificationChannelModel channelModel) {
        Intent deleteIntent = buildNotificationIntentFromModel(
                context,
                Definitions.DISMISSED_NOTIFICATION,
                notificationModel,
                channelModel,
                DismissedNotificationReceiver.class
        );

        PendingIntent pendingDismissIntent = PendingIntent.getBroadcast(
                context,
                notificationModel.content.id,
                deleteIntent,
                PendingIntent.FLAG_IMMUTABLE | PendingIntent.FLAG_UPDATE_CURRENT
        );
        return pendingDismissIntent;
    }

    @SuppressWarnings("unchecked")
    private static void updateTrackingExtras(NotificationModel notificationModel, NotificationChannelModel channel, Bundle extras) {
        String groupKey = getGroupKey(notificationModel.content, channel);

        extras.putInt(Definitions.NOTIFICATION_ID, notificationModel.content.id);
        extras.putString(Definitions.NOTIFICATION_CHANNEL_KEY, StringUtils.digestString(notificationModel.content.channelKey));
        extras.putString(Definitions.NOTIFICATION_GROUP_KEY, StringUtils.digestString(groupKey));
        extras.putBoolean(Definitions.NOTIFICATION_AUTO_DISMISSIBLE, notificationModel.content.autoDismissible);

        if(!ListUtils.isNullOrEmpty(notificationModel.content.messages)) {
            Map<String, Object> contentData = notificationModel.content.toMap();
            List<Map> contentMessageData = null;
            if(contentData.get(Definitions.NOTIFICATION_MESSAGES) instanceof List) {
                contentMessageData = (List<Map>) contentData.get(Definitions.NOTIFICATION_MESSAGES);
            }
            if(contentMessageData != null)
                extras.putSerializable(
                        Definitions.NOTIFICATION_MESSAGES,
                        (Serializable) contentMessageData);
        }
    }

    private static Class<?> getTargetClass(Context context){
        return getNotificationTargetActivityClass(context);
    }

    public static Intent buildNotificationIntentFromModel(
            Context context,
            String actionReference,
            NotificationModel notificationModel,
            NotificationChannelModel channel
    ) {
        Class<?> targetClass = getTargetClass(context);
        return buildNotificationIntentFromModel(
                context,
                actionReference,
                notificationModel,
                channel,
                targetClass);
    }

    public static ActionReceived buildNotificationActionFromIntent(Context context, Intent intent, NotificationLifeCycle lifeCycle) {
        String buttonKeyPressed = intent.getAction();

        if (buttonKeyPressed == null) return null;

        boolean isNormalAction = Definitions.SELECT_NOTIFICATION.equals(buttonKeyPressed) || Definitions.DISMISSED_NOTIFICATION.equals(buttonKeyPressed);
        boolean isButtonAction = buttonKeyPressed.startsWith(Definitions.NOTIFICATION_BUTTON_ACTION_PREFIX);

        if (isNormalAction || isButtonAction) {

            String notificationJson = intent.getStringExtra(Definitions.NOTIFICATION_JSON);

            NotificationModel notificationModel = new NotificationModel().fromJson(notificationJson);
            if (notificationModel == null) return null;

            ActionReceived actionModel = new ActionReceived(notificationModel.content);

            actionModel.actionDate = DateUtils.getUTCDate();
            actionModel.actionLifeCycle = lifeCycle;

            if (StringUtils.isNullOrEmpty(actionModel.displayedDate))
                actionModel.displayedDate = DateUtils.getUTCDate();

            actionModel.autoDismissible = intent.getBooleanExtra(Definitions.NOTIFICATION_AUTO_DISMISSIBLE, true);
            actionModel.shouldAutoDismiss = actionModel.autoDismissible;

            if (isButtonAction) {

                actionModel.buttonKeyPressed = intent.getStringExtra(Definitions.NOTIFICATION_BUTTON_KEY);
                String NotificationButtonType = intent.getStringExtra(Definitions.NOTIFICATION_BUTTON_TYPE);

                if (NotificationButtonType.equals(ActionButtonType.InputField.toString()))
                    actionModel.buttonKeyInput = getButtonInputText(intent, intent.getStringExtra(Definitions.NOTIFICATION_BUTTON_KEY));

                if(
                    !StringUtils.isNullOrEmpty(actionModel.buttonKeyInput) &&
                    Build.VERSION.SDK_INT >= Build.VERSION_CODES.N /*Android 7*/
                ) {
                    actionModel.shouldAutoDismiss = false;

                    switch (notificationModel.content.notificationLayout){

                        case Inbox:
                        case BigText:
                        case BigPicture:
                        case ProgressBar:
                        case MediaPlayer:
                        case Default:
                            try {
                                notificationModel.remoteHistory = actionModel.buttonKeyInput;
                                NotificationSender.send(context, notificationModel);
                            } catch (Exception e) {
                                e.printStackTrace();
                            }
                            break;
                    }
                }
            }

            if (isButtonAction)
                actionModel.actionButtonType = StringUtils.getEnumFromString(ActionButtonType.class, intent.getStringExtra(Definitions.NOTIFICATION_BUTTON_TYPE));

            return actionModel;
        }
        return null;
    }

    public static String getAppName(Context context){
        ApplicationInfo applicationInfo = context.getApplicationInfo();
        int stringId = applicationInfo.labelRes;
        return stringId == 0 ? applicationInfo.nonLocalizedLabel.toString() : context.getString(stringId);
    }

    @RequiresApi(api = Build.VERSION_CODES.KITKAT_WATCH)
    public static void wakeUpScreen(Context context){

        PowerManager pm = (PowerManager)context.getSystemService(Context.POWER_SERVICE);
        boolean isScreenOn = pm.isInteractive();
        if(!isScreenOn)
        {
            String appName = NotificationBuilder.getAppName(context);

            PowerManager.WakeLock wl = pm.newWakeLock(
                    PowerManager.FULL_WAKE_LOCK |
                    PowerManager.ACQUIRE_CAUSES_WAKEUP |
                    PowerManager.ON_AFTER_RELEASE,
                    appName+":"+TAG+":WakeupLock");
            wl.acquire(10000);

            PowerManager.WakeLock wl_cpu = pm.newWakeLock(
                    PowerManager.PARTIAL_WAKE_LOCK,
                    appName+":"+TAG+":WakeupCpuLock");
            wl_cpu.acquire(10000);
            wl_cpu.acquire(10000);
        }
    }

    public static void ensureCriticalAlert(Context context) throws AwesomeNotificationException {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            NotificationManager notificationManager = (NotificationManager) context.getSystemService(NOTIFICATION_SERVICE);
            if (isDndOverrideAllowed(context, notificationManager)) {
                if (!PermissionManager.isSpecifiedPermissionGloballyAllowed(context, NotificationPermission.CriticalAlert)){
                    notificationManager.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_PRIORITY);
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P /*Android 9*/) {
                        NotificationManager.Policy policy = new NotificationManager.Policy(PRIORITY_CATEGORY_ALARMS, 0, 0);
                        notificationManager.setNotificationPolicy(policy);
                    }
                }
            }
        }
    }

    public static NotificationManager getAndroidNotificationManager(Context context){
        return  (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);
    }

    public static boolean isDndOverrideAllowed(Context context){
        NotificationManager notificationManager = (NotificationManager) context.getSystemService(NOTIFICATION_SERVICE);
        return isDndOverrideAllowed(context, notificationManager);
    }

    public static boolean isCriticalAlertsGloballyAllowed(Context context){
        NotificationManager notificationManager = getAndroidNotificationManager(context);

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M /*Android 6*/) {
            return notificationManager.getCurrentInterruptionFilter() != NotificationManager.INTERRUPTION_FILTER_NONE;
        }

        // Critical alerts until Android 6 are "Treat as priority" or "Priority"
//            return (notificationManager.getNotificationPolicy().state
//                    & NotificationManager.Policy.STATE_CHANNELS_BYPASSING_DND) == 1;
            // TODO read "Treat as priority" or "Priority" property on notifications page
        return true;
    }

    @RequiresApi(api = Build.VERSION_CODES.N)
    public static boolean isNotificationSoundGloballyAllowed(Context context){
        NotificationManager manager = (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);
        int importance = manager.getImportance();
        return importance < 0 || importance >= NotificationManager.IMPORTANCE_DEFAULT;
    }

    public static boolean isDndOverrideAllowed(Context context, NotificationManager notificationManager){
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            return notificationManager.isNotificationPolicyAccessGranted();
        }
        return true;
    }

    private static String getButtonInputText(Intent intent, String buttonKey) {
        Bundle remoteInput = RemoteInput.getResultsFromIntent(intent);
        if (remoteInput != null) {
            return remoteInput.getCharSequence(buttonKey).toString();
        }
        return null;
    }

    private static Notification getNotificationBuilderFromModel(Context context, NotificationModel notificationModel) throws AwesomeNotificationException {

        NotificationChannelModel channel = ChannelManager.getChannelByKey(context, notificationModel.content.channelKey);

        if (channel == null || !ChannelManager.isChannelEnabled(context, notificationModel.content.channelKey))
            throw new AwesomeNotificationException("Channel '" + notificationModel.content.channelKey + "' does not exist or is disabled");

        NotificationCompat.Builder builder = new NotificationCompat.Builder(context, notificationModel.content.channelKey);

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O /*Android 8*/){
            NotificationChannel androidChannel = ChannelManager.getAndroidChannel(context, channel.channelKey);
            builder.setChannelId(androidChannel.getId());
        }

        setSmallIcon(context, notificationModel, channel, builder);

        setRemoteHistory(notificationModel, builder);

        setGrouping(context, notificationModel, channel, builder);

        setVisibility(context, notificationModel, channel, builder);
        setShowWhen(notificationModel, builder);

        setLayout(context, notificationModel, channel, builder);

        setTitle(notificationModel, channel, builder);
        setBody(notificationModel, builder);

        setAutoCancel(notificationModel, builder);
        setTicker(notificationModel, builder);
        setOnlyAlertOnce(notificationModel, channel, builder);

        setLockedNotification(notificationModel, channel, builder);
        setImportance(channel, builder);
        setCategory(notificationModel, builder);

        setSound(context, notificationModel, channel, builder);
        setVibrationPattern(channel, builder);
        setLights(channel, builder);

        setSmallIcon(context, notificationModel, channel, builder);
        setLargeIcon(context, notificationModel, builder);
        setLayoutColor(context, notificationModel, channel, builder);

        createActionButtons(context, notificationModel, channel, builder);

        PendingIntent pendingActionIntent = getPendingActionIntent(context, notificationModel, channel);
        PendingIntent pendingDismissIntent = getPendingDismissIntent(context, notificationModel, channel);

        setFullScreenIntent(context, pendingActionIntent, notificationModel, builder);

        setBadge(context, notificationModel, channel, builder);

        setNotificationPendingIntents(notificationModel, pendingActionIntent, pendingDismissIntent, builder);

        Notification androidNotification = builder.build();
        if(androidNotification.extras == null)
            androidNotification.extras = new Bundle();

        updateTrackingExtras(notificationModel, channel, androidNotification.extras);

        setWakeUpScreen(context, notificationModel);
        setCriticalAlert(context, channel);
        setCategoryFlags(context, notificationModel, androidNotification);

        return androidNotification;
    }

    private static void setCategoryFlags(Context context, NotificationModel notificationModel, Notification androidNotification) {

        if(notificationModel.content.category != null)
            switch (notificationModel.content.category){

                case Alarm:
                    androidNotification.flags |= Notification.FLAG_INSISTENT;
                    androidNotification.flags |= Notification.FLAG_NO_CLEAR;
                    break;

                case Call:
                    androidNotification.flags |= Notification.FLAG_INSISTENT;
                    androidNotification.flags |= Notification.FLAG_HIGH_PRIORITY;
                    androidNotification.flags |= Notification.FLAG_NO_CLEAR;
                    break;
            }
    }

    private static void setNotificationPendingIntents(NotificationModel notificationModel, PendingIntent pendingActionIntent, PendingIntent pendingDismissIntent, NotificationCompat.Builder builder) {
        builder.setContentIntent(pendingActionIntent);
        if(!notificationModel.groupSummary)
            builder.setDeleteIntent(pendingDismissIntent);
    }

    private static void setWakeUpScreen(Context context, NotificationModel notificationModel) {
        if (notificationModel.content.wakeUpScreen)
//            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT_WATCH)
                wakeUpScreen(context);
    }

    private static void setCriticalAlert(Context context, NotificationChannelModel channel) throws AwesomeNotificationException {
        if (channel.criticalAlerts)
            ensureCriticalAlert(context);
    }

    private static void setFullScreenIntent(Context context, PendingIntent pendingIntent, NotificationModel notificationModel, NotificationCompat.Builder builder) {
        if (BooleanUtils.getValue(notificationModel.content.fullScreenIntent)) {
            builder.setFullScreenIntent(pendingIntent, true);
        }
    }

    private static void setShowWhen(NotificationModel notificationModel, NotificationCompat.Builder builder) {
        builder.setShowWhen(BooleanUtils.getValueOrDefault(notificationModel.content.showWhen, true));
    }

    private static Integer getBackgroundColor(NotificationModel notificationModel, NotificationChannelModel channel, NotificationCompat.Builder builder) {
        Integer bgColorValue;
        bgColorValue = IntegerUtils.extractInteger(notificationModel.content.backgroundColor, null);
        if (bgColorValue != null) {
            builder.setColorized(true);
        } else {
            bgColorValue = getLayoutColor(notificationModel, channel);
        }
        return bgColorValue;
    }

    private static Integer getLayoutColor(NotificationModel notificationModel, NotificationChannelModel channel) {
        Integer layoutColorValue;
        layoutColorValue = IntegerUtils.extractInteger(notificationModel.content.color, channel.defaultColor);
        layoutColorValue = IntegerUtils.extractInteger(layoutColorValue, Color.BLACK);
        return layoutColorValue;
    }

    private static void setImportance(NotificationChannelModel channel, NotificationCompat.Builder builder) {
        builder.setPriority(NotificationImportance.toAndroidPriority(channel.importance));
    }

    private static void setCategory(NotificationModel notificationModel, NotificationCompat.Builder builder){
        if(notificationModel.content.category != null)
            builder.setCategory(notificationModel.content.category.rawValue);
    }

    private static void setOnlyAlertOnce(NotificationModel notificationModel, NotificationChannelModel channel, NotificationCompat.Builder builder) {
        boolean onlyAlertOnceValue = BooleanUtils.getValue(notificationModel.content.notificationLayout == NotificationLayout.ProgressBar || channel.onlyAlertOnce);
        builder.setOnlyAlertOnce(onlyAlertOnceValue);
    }

    private static void setRemoteHistory(NotificationModel notificationModel, NotificationCompat.Builder builder) {
        if(!StringUtils.isNullOrEmpty(notificationModel.remoteHistory) && notificationModel.content.notificationLayout == NotificationLayout.Default)
            builder.setRemoteInputHistory(new CharSequence[]{notificationModel.remoteHistory});
    }

    private static void setLockedNotification(NotificationModel notificationModel, NotificationChannelModel channel, NotificationCompat.Builder builder) {
        boolean contentLocked = BooleanUtils.getValue(notificationModel.content.locked);
        boolean channelLocked = BooleanUtils.getValue(channel.locked);

        if (contentLocked) {
            builder.setOngoing(true);
        } else if (channelLocked) {
            boolean lockedValue = BooleanUtils.getValueOrDefault(notificationModel.content.locked, true);
            builder.setOngoing(lockedValue);
        }
    }

    private static void setTicker(NotificationModel notificationModel, NotificationCompat.Builder builder) {
        String tickerValue;
        tickerValue = StringUtils.getValueOrDefault(notificationModel.content.ticker, null);
        tickerValue = StringUtils.getValueOrDefault(tickerValue, notificationModel.content.summary);
        tickerValue = StringUtils.getValueOrDefault(tickerValue, notificationModel.content.body);
        builder.setTicker(tickerValue);
    }

    private static void setBadge(Context context, NotificationModel notificationModel, NotificationChannelModel channelModel, NotificationCompat.Builder builder) {
        if (!notificationModel.groupSummary && BooleanUtils.getValue(channelModel.channelShowBadge)) {
            BadgeManager.incrementGlobalBadgeCounter(context);
            builder.setNumber(1);
        }
    }

    private static void setAutoCancel(NotificationModel notificationModel, NotificationCompat.Builder builder) {
        builder.setAutoCancel(BooleanUtils.getValueOrDefault(notificationModel.content.autoDismissible, true));
    }

    private static void setBody(NotificationModel notificationModel, NotificationCompat.Builder builder) {
        builder.setContentText(HtmlUtils.fromHtml(notificationModel.content.body));
    }

    private static void setTitle(NotificationModel notificationModel, NotificationChannelModel channelModel, NotificationCompat.Builder builder) {
        if (notificationModel.content.title != null) {
            builder.setContentTitle(HtmlUtils.fromHtml(notificationModel.content.title));
        }
    }

    private static void setVibrationPattern(NotificationChannelModel channelModel, NotificationCompat.Builder builder) {
        if (BooleanUtils.getValue(channelModel.enableVibration)) {
            if (channelModel.vibrationPattern != null && channelModel.vibrationPattern.length > 0) {
                builder.setVibrate(channelModel.vibrationPattern);
            }
        } else {
            builder.setVibrate(new long[]{0});
        }
    }

    private static void setLights(NotificationChannelModel channelModel, NotificationCompat.Builder builder) {
        if (BooleanUtils.getValue(channelModel.enableLights)) {
            Integer ledColorValue = IntegerUtils.extractInteger(channelModel.ledColor, Color.WHITE);
            Integer ledOnMsValue = IntegerUtils.extractInteger(channelModel.ledOnMs, 300);
            Integer ledOffMsValue = IntegerUtils.extractInteger(channelModel.ledOffMs, 700);
            builder.setLights(ledColorValue, ledOnMsValue, ledOffMsValue);
        }
    }

    private static void setVisibility(Context context, NotificationModel notificationModel, NotificationChannelModel channelModel, NotificationCompat.Builder builder) {

//        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.LOLLIPOP) {
//
            Integer visibilityIndex;
            visibilityIndex = IntegerUtils.extractInteger(notificationModel.content.privacy, channelModel.defaultPrivacy.ordinal());
            visibilityIndex = IntegerUtils.extractInteger(visibilityIndex, NotificationPrivacy.Public);

            builder.setVisibility(visibilityIndex - 1);
//        }
    }

    private static void setLayoutColor(Context context, NotificationModel notificationModel, NotificationChannelModel channelModel, NotificationCompat.Builder builder) {

        if (notificationModel.content.backgroundColor == null) {
            builder.setColor(getLayoutColor(notificationModel, channelModel));
        } else {
            builder.setColor(getBackgroundColor(notificationModel, channelModel, builder));
        }
    }

    private static void setLargeIcon(Context context, NotificationModel notificationModel, NotificationCompat.Builder builder) {
        if (notificationModel.content.notificationLayout != NotificationLayout.BigPicture)
            if (!StringUtils.isNullOrEmpty(notificationModel.content.largeIcon)) {
                Bitmap largeIcon = BitmapUtils.getBitmapFromSource(context, notificationModel.content.largeIcon);
                if (largeIcon != null)
                    builder.setLargeIcon(largeIcon);
            }
    }

    // https://github.com/rafaelsetragni/awesome_notifications/issues/191
    public static Class getNotificationTargetActivityClass(Context context) {

        String packageName = context.getPackageName();
        Intent launchIntent = context.getPackageManager().getLaunchIntentForPackage(packageName);
        String className =
                launchIntent == null ?
                        AwesomeNotificationsPlugin.getMainTargetClassName() :
                        launchIntent.getComponent().getClassName();
        try {
            return Class.forName(className);
        } catch (ClassNotFoundException e) {
            e.printStackTrace();
            return null;
        }
    }

    @NonNull
    public static void createActionButtons(Context context, NotificationModel notificationModel, NotificationChannelModel channel, NotificationCompat.Builder builder) {

        if (ListUtils.isNullOrEmpty(notificationModel.actionButtons)) return;

        for (NotificationButtonModel buttonProperties : notificationModel.actionButtons) {

            // If reply is not available, do not show it
            if (
                android.os.Build.VERSION.SDK_INT < Build.VERSION_CODES.N &&
                buttonProperties.buttonType == ActionButtonType.InputField
            ){
                continue;
            }

            Intent actionIntent = buildNotificationIntentFromModel(
                    context,
                    Definitions.NOTIFICATION_BUTTON_ACTION_PREFIX + "_" + buttonProperties.key,
                    notificationModel,
                    channel,
                    buttonProperties.buttonType == ActionButtonType.DisabledAction ||
                    buttonProperties.buttonType == ActionButtonType.KeepOnTop ?
                                    KeepOnTopActionReceiver.class : getNotificationTargetActivityClass(context)
            );

            actionIntent.putExtra(Definitions.NOTIFICATION_AUTO_DISMISSIBLE, buttonProperties.autoDismissible);
            actionIntent.putExtra(Definitions.NOTIFICATION_SHOW_IN_COMPACT_VIEW, buttonProperties.showInCompactView);
            actionIntent.putExtra(Definitions.NOTIFICATION_ENABLED, buttonProperties.enabled);
            actionIntent.putExtra(Definitions.NOTIFICATION_BUTTON_TYPE, buttonProperties.buttonType.toString());
            actionIntent.putExtra(Definitions.NOTIFICATION_BUTTON_KEY, buttonProperties.key);

            PendingIntent actionPendingIntent = null;

            if (buttonProperties.enabled) {

                if (
                    buttonProperties.buttonType == ActionButtonType.KeepOnTop ||
                    buttonProperties.buttonType == ActionButtonType.DisabledAction
                ) {

                    actionPendingIntent = PendingIntent.getBroadcast(
                            context,
                            notificationModel.content.id,
                            actionIntent,
                            PendingIntent.FLAG_IMMUTABLE | PendingIntent.FLAG_UPDATE_CURRENT
                    );

                } /*else if (buttonProperties.buttonType == ActionButtonType.DisabledAction) {

                    actionPendingIntent = PendingIntent.getActivity(
                            context,
                            notificationModel.content.id,
                            actionIntent,
                            PendingIntent.FLAG_IMMUTABLE
                    );

                }*/ else {

                    actionPendingIntent = PendingIntent.getActivity(
                            context,
                            notificationModel.content.id,
                            actionIntent,
                            PendingIntent.FLAG_IMMUTABLE | PendingIntent.FLAG_UPDATE_CURRENT
                    );
                }
            }

            int iconResource = 0;
            if (!StringUtils.isNullOrEmpty(buttonProperties.icon)) {
                iconResource = BitmapUtils.getDrawableResourceId(context, buttonProperties.icon);
            }

            if (
                buttonProperties.buttonType == ActionButtonType.InputField
            ){

                RemoteInput remoteInput = new RemoteInput.Builder(buttonProperties.key)
                        .setLabel(buttonProperties.label)
                        .build();

                NotificationCompat.Action replyAction = new NotificationCompat.Action.Builder(
                        iconResource, buttonProperties.label, actionPendingIntent)
                        .addRemoteInput(remoteInput)
                        .build();

                builder.addAction(replyAction);

            } else {

                builder.addAction(
                    iconResource,
                    HtmlCompat.fromHtml(
                        buttonProperties.isDangerousOption ?
                            "<font color=\"16711680\">" + buttonProperties.label + "</font>" :
                            (
                                buttonProperties.color != null ?
                                    "<font color=\"" + buttonProperties.color.toString() + "\">" + buttonProperties.label + "</font>":
                                    buttonProperties.label
                            ),
                        HtmlCompat.FROM_HTML_MODE_LEGACY
                    ),
                    actionPendingIntent);
            }
        }
    }

    private static void setSound(Context context, NotificationModel notificationModel, NotificationChannelModel channelModel, NotificationCompat.Builder builder) {

        Uri uri = null;

        if (!notificationModel.content.isRefreshNotification && BooleanUtils.getValue(channelModel.playSound)) {
            uri = ChannelManager.retrieveSoundResourceUri(context, channelModel.defaultRingtoneType, channelModel.soundSource);
        }

        builder.setSound(uri);
    }

    private static void setSmallIcon(Context context, NotificationModel notificationModel, NotificationChannelModel channelModel, NotificationCompat.Builder builder) {
        if (!StringUtils.isNullOrEmpty(notificationModel.content.icon)) {
            builder.setSmallIcon(BitmapUtils.getDrawableResourceId(context, notificationModel.content.icon));
        } else if (!StringUtils.isNullOrEmpty(channelModel.icon)) {
            builder.setSmallIcon(BitmapUtils.getDrawableResourceId(context, channelModel.icon));
        } else {
            String defaultIcon = DefaultsManager.getDefaultIconByKey(context);

            if (StringUtils.isNullOrEmpty(defaultIcon)) {

                // for backwards compatibility: this is for handling the old way references to the icon used to be kept but should be removed in future
                if (channelModel.iconResourceId != null) {
                    builder.setSmallIcon(channelModel.iconResourceId);
                } else {
                    int defaultResource = context.getResources().getIdentifier(
                            "ic_launcher",
                            "mipmap",
                            context.getPackageName()
                    );

                    if (defaultResource > 0) {
                        builder.setSmallIcon(defaultResource);
                    }
                }
            } else {
                int resourceIndex = BitmapUtils.getDrawableResourceId(context, defaultIcon);
                if (resourceIndex > 0) {
                    builder.setSmallIcon(resourceIndex);
                }
            }
        }
    }

    private static void setGrouping(Context context, NotificationModel notificationModel, NotificationChannelModel channelModel, NotificationCompat.Builder builder) {

        if( // Grouping key is reserved to arrange messaging and messaging group layouts
            notificationModel.content.notificationLayout == NotificationLayout.Messaging ||
            notificationModel.content.notificationLayout == NotificationLayout.MessagingGroup
        ) return;

        String groupKey = getGroupKey(notificationModel.content, channelModel);

        if (!StringUtils.isNullOrEmpty(groupKey)) {
            builder.setGroup(groupKey);

            if(notificationModel.groupSummary)
                builder.setGroupSummary(true);

            String idText = notificationModel.content.id.toString();
            String sortKey = Long.toString(
                    (channelModel.groupSort == GroupSort.Asc ? System.currentTimeMillis() : Long.MAX_VALUE - System.currentTimeMillis())
            );

            builder.setSortKey(sortKey + idText);

            builder.setGroupAlertBehavior(channelModel.groupAlertBehavior.ordinal());
        }
    }

    private static void setLayout(Context context, NotificationModel notificationModel, NotificationChannelModel channelModel, NotificationCompat.Builder builder) throws AwesomeNotificationException {

        switch (notificationModel.content.notificationLayout) {

            case BigPicture:
                if (setBigPictureLayout(context, notificationModel.content, builder)) return;
                break;

            case BigText:
                if (setBigTextStyle(context, notificationModel.content, builder)) return;
                break;

            case Inbox:
                if (setInboxLayout(context, notificationModel.content, builder)) return;
                break;

            case Messaging:
                if (setMessagingLayout(context, false, notificationModel.content, channelModel, builder)) return;
                break;

            case MessagingGroup:
                if(setMessagingLayout(context, true, notificationModel.content, channelModel, builder)) return;
                break;

            case PhoneCall:
                setPhoneCallLayout(context, notificationModel, builder);
                break;

            case MediaPlayer:
                if (setMediaPlayerLayout(context, notificationModel.content, notificationModel.actionButtons, builder)) return;
                break;

            case ProgressBar:
                setProgressLayout(notificationModel, builder);
                break;

            case Default:
            default:
                break;
        }
    }

    private static Boolean setBigPictureLayout(Context context, NotificationContentModel contentModel, NotificationCompat.Builder builder) {

        Bitmap bigPicture = null, largeIcon = null;

        if (!StringUtils.isNullOrEmpty(contentModel.bigPicture))
            bigPicture = BitmapUtils.getBitmapFromSource(context, contentModel.bigPicture);

        if (contentModel.hideLargeIconOnExpand)
            largeIcon = bigPicture != null ?
                bigPicture : (!StringUtils.isNullOrEmpty(contentModel.largeIcon) ?
                    BitmapUtils.getBitmapFromSource(context, contentModel.largeIcon) : null);
        else {
            boolean areEqual =
                    !StringUtils.isNullOrEmpty(contentModel.largeIcon) &&
                            contentModel.largeIcon.equals(contentModel.bigPicture);

            if(areEqual)
                largeIcon = bigPicture;
            else if(!StringUtils.isNullOrEmpty(contentModel.largeIcon))
                largeIcon =
                        BitmapUtils.getBitmapFromSource(context, contentModel.largeIcon);
        }

        if (largeIcon != null)
            builder.setLargeIcon(largeIcon);

        if (bigPicture == null)
            return false;

        NotificationCompat.BigPictureStyle bigPictureStyle = new NotificationCompat.BigPictureStyle();

        bigPictureStyle.bigPicture(bigPicture);
        bigPictureStyle.bigLargeIcon(contentModel.hideLargeIconOnExpand ? null : largeIcon);

        if (!StringUtils.isNullOrEmpty(contentModel.title)) {
            CharSequence contentTitle = HtmlUtils.fromHtml(contentModel.title);
            bigPictureStyle.setBigContentTitle(contentTitle);
        }

        if (!StringUtils.isNullOrEmpty(contentModel.body)) {
            CharSequence summaryText = HtmlUtils.fromHtml(contentModel.body);
            bigPictureStyle.setSummaryText(summaryText);
        }

        builder.setStyle(bigPictureStyle);

        return true;
    }

    private static Boolean setBigTextStyle(Context context, NotificationContentModel contentModel, NotificationCompat.Builder builder) {

        NotificationCompat.BigTextStyle bigTextStyle = new NotificationCompat.BigTextStyle();

        if (StringUtils.isNullOrEmpty(contentModel.body)) return false;

        CharSequence bigBody = HtmlUtils.fromHtml(contentModel.body);
        bigTextStyle.bigText(bigBody);

        if (!StringUtils.isNullOrEmpty(contentModel.summary)) {
            CharSequence bigSummary = HtmlUtils.fromHtml(contentModel.summary);
            bigTextStyle.setSummaryText(bigSummary);
        }

        if (!StringUtils.isNullOrEmpty(contentModel.title)) {
            CharSequence bigTitle = HtmlUtils.fromHtml(contentModel.title);
            bigTextStyle.setBigContentTitle(bigTitle);
        }

        builder.setStyle(bigTextStyle);

        return true;
    }

    private static Boolean setInboxLayout(Context context, NotificationContentModel contentModel, NotificationCompat.Builder builder) {

        NotificationCompat.InboxStyle inboxStyle = new NotificationCompat.InboxStyle();

        if (StringUtils.isNullOrEmpty(contentModel.body)) return false;

        List<String> lines = new ArrayList<>(Arrays.asList(contentModel.body.split("\\r?\\n")));

        if (ListUtils.isNullOrEmpty(lines)) return false;

        CharSequence summary;
        if (StringUtils.isNullOrEmpty(contentModel.summary)) {
            summary = "+ " + lines.size() + " more";
        } else {
            summary = HtmlUtils.fromHtml(contentModel.body);
        }
        inboxStyle.setSummaryText(summary);

        if (!StringUtils.isNullOrEmpty(contentModel.title)) {
            CharSequence contentTitle = HtmlUtils.fromHtml(contentModel.title);
            inboxStyle.setBigContentTitle(contentTitle);
        }

        if (contentModel.summary != null) {
            CharSequence summaryText = HtmlUtils.fromHtml(contentModel.summary);
            inboxStyle.setSummaryText(summaryText);
        }

        for (String line : lines) {
            inboxStyle.addLine(HtmlUtils.fromHtml(line));
        }

        builder.setStyle(inboxStyle);
        return true;
    }

    public static String getGroupKey(NotificationContentModel contentModel, NotificationChannelModel channelModel){
        return !StringUtils.isNullOrEmpty(contentModel.groupKey) ?
                contentModel.groupKey : channelModel.groupKey;
    }

    public static final ConcurrentHashMap<String, List<NotificationMessageModel>> messagingQueue = new ConcurrentHashMap<String, List<NotificationMessageModel>>();

    @SuppressWarnings("unchecked")
    private static Boolean setMessagingLayout(Context context, boolean isGrouping, NotificationContentModel contentModel, NotificationChannelModel channelModel, NotificationCompat.Builder builder) throws AwesomeNotificationException {
        String groupKey = getGroupKey(contentModel, channelModel);

        //if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M /*Android 6*/) {

            String messageQueueKey = groupKey + (isGrouping ? ".Gr" : "");

            int firstNotificationId = contentModel.id;
            List<String> groupIDs = StatusBarManager
                    .getInstance(context)
                    .activeNotificationsGroup.get(groupKey);

            if(groupIDs == null || groupIDs.size() == 0)
                messagingQueue.remove(messageQueueKey);
            else
                firstNotificationId = Integer.parseInt(groupIDs.get(0));

            NotificationMessageModel currentMessage = new NotificationMessageModel(
                    (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) ?
                            contentModel.title : contentModel.summary,
                    contentModel.body,
                    contentModel.largeIcon
            );

            List<NotificationMessageModel> messages =  messagingQueue.get(messageQueueKey);

            if(messages == null)
                messages = new ArrayList<>();

            messages.add(currentMessage);
            messagingQueue.put(messageQueueKey, messages);

            contentModel.id = firstNotificationId;
            contentModel.messages = messages;

            NotificationCompat.MessagingStyle messagingStyle =
                    new NotificationCompat.MessagingStyle(contentModel.summary);

            for(NotificationMessageModel message : contentModel.messages) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P /*Android 9*/) {

                    Person.Builder personBuilder =  new Person.Builder()
                            .setName(message.title);

                    if(!StringUtils.isNullOrEmpty(contentModel.largeIcon)){
                        Bitmap largeIcon = BitmapUtils.getBitmapFromSource(
                                context,
                                contentModel.largeIcon);
                        if(largeIcon != null)
                            personBuilder.setIcon(
                                    IconCompat.createWithBitmap(largeIcon));
                    }

                    Person person = personBuilder.build();

                    messagingStyle.addMessage(
                            message.message, message.timestamp, person);
                } else {
                    messagingStyle.addMessage(
                            message.message, message.timestamp, message.title);
                }
            }

            if (
                Build.VERSION.SDK_INT >= Build.VERSION_CODES.P /*Android 9*/ &&
                !StringUtils.isNullOrEmpty(contentModel.summary)
            ){
                messagingStyle.setConversationTitle(contentModel.summary);
                messagingStyle.setGroupConversation(isGrouping);
            }

            builder.setStyle((NotificationCompat.Style) messagingStyle);
        /*}
        else {
            if(StringUtils.isNullOrEmpty(groupKey)){
                builder.setGroup("Messaging."+groupKey);
            }
        }*/

        return true;
    }

    private static Boolean setMediaPlayerLayout(Context context, NotificationContentModel contentModel, List<NotificationButtonModel> actionButtons, NotificationCompat.Builder builder) {

        ArrayList<Integer> indexes = new ArrayList<>();
        for (int i = 0; i < actionButtons.size(); i++) {
            NotificationButtonModel b = actionButtons.get(i);
            if (b.showInCompactView) indexes.add(i);
        }

        if(!StatusBarManager
                .getInstance(context)
                .isFirstActiveOnGroupKey(contentModel.groupKey)
        ){
            List<String> lastIds = StatusBarManager.getInstance(context).activeNotificationsGroup.get(contentModel.groupKey);
            if(lastIds != null && lastIds.size() > 0)
                contentModel.id = Integer.parseInt(lastIds.get(0));
        }

        int[] showInCompactView = toIntArray(indexes);

        /*
        * This fix is to show the notification in Android versions >= 11 in the QuickSettings area.
        * https://developer.android.com/guide/topics/media/media-controls
	* https://github.com/rafaelsetragni/awesome_notifications/pull/364
        */
        if(Build.VERSION.SDK_INT >= Build.VERSION_CODES.R /*Android 11*/){		
	        AwesomeNotificationsPlugin.mediaSession.setMetadata(
			        new MediaMetadataCompat.Builder()
					        .putString(MediaMetadataCompat.METADATA_KEY_TITLE, contentModel.title)
					        .putString(MediaMetadataCompat.METADATA_KEY_ARTIST, contentModel.body)
					        .build()
	        );
        }

        builder.setStyle(
                new androidx.media.app.NotificationCompat.MediaStyle()
                        .setShowActionsInCompactView(showInCompactView)
                        .setShowCancelButton(true)
                        .setMediaSession(AwesomeNotificationsPlugin.mediaSession.getSessionToken())
        );

        if (!StringUtils.isNullOrEmpty(contentModel.summary)) {
            builder.setSubText(contentModel.summary);
        }

        if(contentModel.progress != null)
            builder.setProgress(
                    100,
                    Math.max(0, Math.min(100, IntegerUtils.extractInteger(contentModel.progress, 0))),
                    contentModel.progress == null
            );

        builder.setShowWhen(false);

        return true;
    }

    private static void setProgressLayout(NotificationModel notificationModel, NotificationCompat.Builder builder) {
        builder.setProgress(
                100,
                Math.max(0, Math.min(100, IntegerUtils.extractInteger(notificationModel.content.progress, 0))),
                notificationModel.content.progress == null
        );
    }

    private static void setPhoneCallLayout(Context context, NotificationModel notificationModel, NotificationCompat.Builder builder) {
       /* RemoteViews notificationLayout = new RemoteViews(context.getPackageName(), android.R.layout.incoming_call);
        //RemoteViews notificationLayoutExpanded = new RemoteViews(context.getPackageName(), R.layout.incoming_call_large);

        builder
            .setStyle(new NotificationCompat.DecoratedCustomViewStyle())
            .setCustomContentView(notificationLayout);
            //.setCustomBigContentView(notificationLayoutExpanded);*/
    }

    private static int[] toIntArray(ArrayList<Integer> list) {
        if (list == null || list.size() <= 0) return new int[0];

        int[] result = new int[list.size()];
        for (int i = 0; i < list.size(); i++) {
            result[i] = list.get(i);
        }

        return result;
    }
}
