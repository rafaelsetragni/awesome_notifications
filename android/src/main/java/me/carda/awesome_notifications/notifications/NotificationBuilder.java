package me.carda.awesome_notifications.notifications;

import android.app.Activity;
import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;

import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.pm.ApplicationInfo;
import android.graphics.Bitmap;
import android.graphics.Color;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.PowerManager;
import android.preference.PreferenceManager;
import android.provider.Settings;
import android.service.notification.StatusBarNotification;


import java.io.Serializable;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

import androidx.annotation.NonNull;
import androidx.core.app.NotificationCompat;
import androidx.core.app.NotificationManagerCompat;
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
import me.carda.awesome_notifications.notifications.enumerators.NotificationPrivacy;
import me.carda.awesome_notifications.notifications.enumerators.NotificationPermission;
import me.carda.awesome_notifications.notifications.exceptions.AwesomeNotificationException;
import me.carda.awesome_notifications.notifications.managers.ChannelManager;
import me.carda.awesome_notifications.notifications.managers.DefaultsManager;
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
import me.leolin.shortcutbadger.ShortcutBadger;

import static android.app.NotificationManager.Policy.PRIORITY_CATEGORY_ALARMS;
import static android.content.Context.NOTIFICATION_SERVICE;

public class NotificationBuilder {

    public static String TAG = "NotificationBuilder";

    public Notification createNotification(Context context, NotificationModel notificationModel) throws AwesomeNotificationException {
        return createNotification(context, notificationModel, false);
    }

    @SuppressWarnings("unchecked")
    public Notification createNotification(Context context, NotificationModel notificationModel, boolean isSummary) throws AwesomeNotificationException {

        NotificationChannelModel channelModel = ChannelManager.getChannelByKey(context, notificationModel.content.channelKey);
        if(channelModel == null)
            throw new AwesomeNotificationException("Channel '"+ notificationModel.content.channelKey +"' does not exist or is disabled");

        if (notificationModel.content.id == null || notificationModel.content.id < 0)
            notificationModel.content.id = IntegerUtils.generateNextRandomId();

        notificationModel.content.groupKey = getGroupKey(notificationModel.content, channelModel);

        Intent intent = buildNotificationIntentFromModel(
                context,
                Definitions.SELECT_NOTIFICATION,
                notificationModel,
                channelModel
        );

        Intent deleteIntent = buildNotificationIntentFromModel(
                context,
                Definitions.DISMISSED_NOTIFICATION,
                notificationModel,
                channelModel,
                DismissedNotificationReceiver.class
        );

        PendingIntent pendingIntent = PendingIntent.getActivity(
                context,
                notificationModel.content.id,
                intent,
                PendingIntent.FLAG_MUTABLE | PendingIntent.FLAG_UPDATE_CURRENT
        );

        PendingIntent pendingDeleteIntent = PendingIntent.getBroadcast(
                context,
                notificationModel.content.id,
                deleteIntent,
                PendingIntent.FLAG_MUTABLE | PendingIntent.FLAG_UPDATE_CURRENT
        );

        Notification finalNotification = getNotificationBuilderFromModel(context, notificationModel, pendingIntent, pendingDeleteIntent, isSummary);

        finalNotification.extras.putInt(
                Definitions.NOTIFICATION_ID,
                notificationModel.content.id);

        finalNotification.extras.putString(
                Definitions.NOTIFICATION_CHANNEL_KEY,
                StringUtils.digestString(notificationModel.content.channelKey));

        finalNotification.extras.putString(
                Definitions.NOTIFICATION_LAYOUT,
                StringUtils.digestString(notificationModel.content.notificationLayout.toString()));

        if(!ListUtils.isNullOrEmpty(notificationModel.content.messages)) {
            Map<String, Object> contentData = notificationModel.content.toMap();
            List<Map> contentMessageData = null;
            if(contentData.get(Definitions.NOTIFICATION_MESSAGES) instanceof List) {
                contentMessageData = (List) contentData.get(Definitions.NOTIFICATION_MESSAGES);
            }
            if(contentMessageData != null)
                finalNotification.extras.putSerializable(
                    Definitions.NOTIFICATION_MESSAGES,
                    (Serializable) contentMessageData);
        }

        return finalNotification;
    }

    private static Class<?> getTargetClass(Context context){
        return getNotificationTargetActivityClass(context);
    }

    public Intent buildNotificationIntentFromModel(
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

    public Intent buildNotificationIntentFromModel(
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

    private static void updateTrackingExtras(NotificationModel notificationModel, NotificationChannelModel channel, Bundle extras) {
        String groupKey = getGroupKey(notificationModel.content, channel);

        extras.putInt(Definitions.NOTIFICATION_ID, notificationModel.content.id);
        extras.putString(Definitions.NOTIFICATION_CHANNEL_KEY, StringUtils.digestString(notificationModel.content.channelKey));
        extras.putString(Definitions.NOTIFICATION_GROUP_KEY, StringUtils.digestString(groupKey));
        extras.putBoolean(Definitions.NOTIFICATION_AUTO_DISMISSIBLE, notificationModel.content.autoDismissible);
    }

    public static ActionReceived buildNotificationActionFromIntent(Context context, Intent intent) {
        String buttonKeyPressed = intent.getAction();

        if (buttonKeyPressed == null) return null;

        Boolean isNormalAction = Definitions.SELECT_NOTIFICATION.equals(buttonKeyPressed) || Definitions.DISMISSED_NOTIFICATION.equals(buttonKeyPressed);
        Boolean isButtonAction = buttonKeyPressed.startsWith(Definitions.NOTIFICATION_BUTTON_ACTION_PREFIX);

        if (isNormalAction || isButtonAction) {

            Integer notificationId = intent.getIntExtra(Definitions.NOTIFICATION_ID, -1);
            String notificationJson = intent.getStringExtra(Definitions.NOTIFICATION_JSON);

            NotificationModel notificationModel = new NotificationModel().fromJson(notificationJson);
            if (notificationModel == null) return null;

            ActionReceived actionModel = new ActionReceived(notificationModel.content);

            actionModel.actionLifeCycle = AwesomeNotificationsPlugin.appLifeCycle;

            if (isButtonAction) {
                actionModel.buttonKeyPressed = intent.getStringExtra(Definitions.NOTIFICATION_BUTTON_KEY);
                if (intent.getStringExtra(Definitions.NOTIFICATION_BUTTON_TYPE).equals(ActionButtonType.InputField.toString())) {
                    actionModel.buttonKeyInput = getButtonInputText(intent, intent.getStringExtra(Definitions.NOTIFICATION_BUTTON_KEY));
                }

                if(!StringUtils.isNullOrEmpty(actionModel.buttonKeyInput) && Build.VERSION.SDK_INT >= Build.VERSION_CODES.P /*Android 9*/) {
                    try {
                        notificationModel.remoteHistory = actionModel.buttonKeyInput;
                        notificationModel.content.isRefreshNotification = true;
                        NotificationSender.send(context, notificationModel);
                    } catch (Exception e) {
                        e.printStackTrace();
                    }
                }
            }

            if (intent.getBooleanExtra(Definitions.NOTIFICATION_AUTO_DISMISSIBLE, notificationId >= 0)) {
                NotificationSender.dismissNotification(context, notificationId);
            }

            if (StringUtils.isNullOrEmpty(actionModel.displayedDate)) {
                actionModel.displayedDate = DateUtils.getUTCDate();
            }
            actionModel.actionDate = DateUtils.getUTCDate();

            if (isButtonAction && intent.getStringExtra(Definitions.NOTIFICATION_BUTTON_TYPE).equals(ActionButtonType.DisabledAction.toString())) {
                return null;
            }

            return actionModel;
        }
        return null;
    }

    public static Notification getAndroidNotificationById(Context context, int id){
        if(context != null){

            NotificationManager manager = (NotificationManager) context.getSystemService(NOTIFICATION_SERVICE);
            StatusBarNotification[] currentActiveNotifications = manager.getActiveNotifications();

            if(currentActiveNotifications != null){
                for (StatusBarNotification activeNotification : currentActiveNotifications) {
                    if(activeNotification.getId() == id){
                        return activeNotification.getNotification();
                    }
                }
            }
        }
        return null;
    }

    public static List<Notification> getAllAndroidActiveNotificationsByChannelKey(Context context, String channelKey){
        List<Notification> notifications = new ArrayList<>();
        if(context != null && !StringUtils.isNullOrEmpty(channelKey)){

            NotificationManager manager = (NotificationManager) context.getSystemService(NOTIFICATION_SERVICE);
            StatusBarNotification[] currentActiveNotifications = manager.getActiveNotifications();

            String hashedKey = StringUtils.digestString(channelKey);

            if(currentActiveNotifications != null){
                for (StatusBarNotification activeNotification : currentActiveNotifications) {

                    Notification notification = activeNotification.getNotification();

                    String notificationChannelKey = notification.extras
                            .getString(Definitions.NOTIFICATION_CHANNEL_KEY);

                    if(notificationChannelKey != null && notificationChannelKey.equals(hashedKey)){
                        notifications.add(notification);
                    }
                }
            }
        }
        return notifications;
    }

    public static List<Notification> getAllAndroidActiveNotificationsByGroupKey(Context context, String groupKey){
        List<Notification> notifications = new ArrayList<>();
        if(context != null && !StringUtils.isNullOrEmpty(groupKey)){

            NotificationManager manager = (NotificationManager) context.getSystemService(NOTIFICATION_SERVICE);
            StatusBarNotification[] currentActiveNotifications = manager.getActiveNotifications();

            String hashedKey = StringUtils.digestString(groupKey);

            if(currentActiveNotifications != null){
                for (StatusBarNotification activeNotification : currentActiveNotifications) {

                    Notification notification = activeNotification.getNotification();

                    String notificationGroupKey = notification.extras
                            .getString(Definitions.NOTIFICATION_GROUP_KEY);

                    if(notificationGroupKey != null && notificationGroupKey.equals(hashedKey)){
                        notifications.add(notification);
                    }
                }
            }
        }
        return notifications;
    }

    public static String getAppName(Context context){
        ApplicationInfo applicationInfo = context.getApplicationInfo();
        int stringId = applicationInfo.labelRes;
        return stringId == 0 ? applicationInfo.nonLocalizedLabel.toString() : context.getString(stringId);
    }

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
        }
    }

    public static void activateCritialAlert(Context context) throws AwesomeNotificationException {

        // TODO implement critical alerts for Android
        NotificationManager notificationManager = (NotificationManager) context.getSystemService(NOTIFICATION_SERVICE);
        if (notificationManager.isNotificationPolicyAccessGranted()) {
            notificationManager.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_PRIORITY);
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P /*Android 9*/) {
                NotificationManager.Policy policy = new NotificationManager.Policy(PRIORITY_CATEGORY_ALARMS, 0, 0);
                notificationManager.setNotificationPolicy(policy);
            }
        } else {
            throw new AwesomeNotificationException("Critical Alert mode is not enable");
        }
    }

    public static void requestCriticalAlerts(Context context){

        // TODO implement critical alerts for Android
        NotificationManager notificationManager = (NotificationManager) context.getSystemService(NOTIFICATION_SERVICE);

        if (!notificationManager.isNotificationPolicyAccessGranted()) {
            Intent intent = new Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS);
            Activity activity = (Activity) context;
            activity.startActivity(intent);
        }
    }

    private static String getButtonInputText(Intent intent, String buttonKey) {
        Bundle remoteInput = RemoteInput.getResultsFromIntent(intent);
        if (remoteInput != null) {
            return remoteInput.getCharSequence(buttonKey).toString();
        }
        return null;
    }

    private Notification getNotificationBuilderFromModel(Context context, NotificationModel notificationModel, PendingIntent pendingIntent, PendingIntent deleteIntent, boolean isSummary) throws AwesomeNotificationException {

        if (!ChannelManager.isChannelEnabled(context, notificationModel.content.channelKey))
            throw new AwesomeNotificationException("Channel '" + notificationModel.content.channelKey + "' does not exist or is disabled");

        NotificationChannelModel channel = ChannelManager.getChannelByKey(context, notificationModel.content.channelKey);

        NotificationCompat.Builder builder = new NotificationCompat.Builder(context, notificationModel.content.channelKey);

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O /*Android 8*/){
            NotificationChannel androidChannel = ChannelManager.getAndroidChannel(context, channel.channelKey);
            builder.setChannelId(androidChannel.getId());
        }

        setSmallIcon(context, notificationModel, channel, builder);

        // Crashing on Android 11+
        //setRemoteHistory(notificationModel, builder);

        setGrouping(context, notificationModel, channel, builder);

        setVisibility(context, notificationModel, channel, builder);
        setShowWhen(notificationModel, builder);

        setLayout(context, notificationModel, channel, builder);

        createActionButtons(context, notificationModel, channel, builder);

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

        setFullScreenIntent(context, pendingIntent, notificationModel, builder);

        if(!isSummary)
            setBadge(context, channel, builder);

        builder.setContentIntent(pendingIntent);
        if(!isSummary)
            builder.setDeleteIntent(deleteIntent);

        Notification androidNotification = builder.build();
        if(androidNotification.extras == null)
            androidNotification.extras = new Bundle();

        updateTrackingExtras(notificationModel, channel, androidNotification.extras);

        setWakeUpScreen(context, notificationModel);
        setCriticalAlert(context, notificationModel);

        return androidNotification;
    }

    private void setWakeUpScreen(Context context, NotificationModel notificationModel) {
        if (notificationModel.content.wakeUpScreen)
            wakeUpScreen(context);
    }

    private void setCriticalAlert(Context context, NotificationModel notificationModel) throws AwesomeNotificationException {
        if (notificationModel.content.criticalAlert)
            activateCritialAlert(context);
    }

    private void setFullScreenIntent(Context context, PendingIntent pendingIntent, NotificationModel notificationModel, NotificationCompat.Builder builder) {
        if (BooleanUtils.getValue(notificationModel.content.fullScreenIntent)) {
            builder.setFullScreenIntent(pendingIntent, true);
        }
    }

    private void setShowWhen(NotificationModel notificationModel, NotificationCompat.Builder builder) {
        builder.setShowWhen(BooleanUtils.getValueOrDefault(notificationModel.content.showWhen, true));
    }

    private Integer getBackgroundColor(NotificationModel notificationModel, NotificationChannelModel channel, NotificationCompat.Builder builder) {
        Integer bgColorValue;
        bgColorValue = IntegerUtils.extractInteger(notificationModel.content.backgroundColor, null);
        if (bgColorValue != null) {
            builder.setColorized(true);
        } else {
            bgColorValue = getLayoutColor(notificationModel, channel);
        }
        return bgColorValue;
    }

    private Integer getLayoutColor(NotificationModel notificationModel, NotificationChannelModel channel) {
        Integer layoutColorValue;
        layoutColorValue = IntegerUtils.extractInteger(notificationModel.content.color, channel.defaultColor);
        layoutColorValue = IntegerUtils.extractInteger(layoutColorValue, Color.BLACK);
        return layoutColorValue;
    }

    private void setImportance(NotificationChannelModel channel, NotificationCompat.Builder builder) {
        // Conversion to Priority
        int priorityValue = Math.min(Math.max(IntegerUtils.extractInteger(channel.importance) - 2, -2), 2);
        builder.setPriority(priorityValue);
    }

    private void setCategory(NotificationModel notificationModel, NotificationCompat.Builder builder){
        if(notificationModel.content.category != null)
            builder.setCategory(notificationModel.content.category.rawValue);
    }

    private void setOnlyAlertOnce(NotificationModel notificationModel, NotificationChannelModel channel, NotificationCompat.Builder builder) {
        Boolean onlyAlertOnceValue = BooleanUtils.getValue(notificationModel.content.notificationLayout == NotificationLayout.ProgressBar ? true : channel.onlyAlertOnce);
        builder.setOnlyAlertOnce(onlyAlertOnceValue);
    }

    private static void setRemoteHistory(NotificationModel notificationModel, NotificationCompat.Builder builder) {
        if(!StringUtils.isNullOrEmpty(notificationModel.remoteHistory)) {
            builder.setRemoteInputHistory(new CharSequence[]{notificationModel.remoteHistory});
        }
    }

    private void setLockedNotification(NotificationModel notificationModel, NotificationChannelModel channel, NotificationCompat.Builder builder) {
        Boolean contentLocked = BooleanUtils.getValue(notificationModel.content.locked);
        Boolean channelLocked = BooleanUtils.getValue(channel.locked);

        if (contentLocked) {
            builder.setOngoing(true);
        } else if (channelLocked) {
            Boolean lockedValue = BooleanUtils.getValueOrDefault(notificationModel.content.locked, true) && channelLocked;
            builder.setOngoing(lockedValue);
        }
    }

    private void setTicker(NotificationModel notificationModel, NotificationCompat.Builder builder) {
        String tickerValue;
        tickerValue = StringUtils.getValueOrDefault(notificationModel.content.ticker, null);
        tickerValue = StringUtils.getValueOrDefault(tickerValue, notificationModel.content.summary);
        tickerValue = StringUtils.getValueOrDefault(tickerValue, notificationModel.content.body);
        builder.setTicker(tickerValue);
    }

    private void setBadge(Context context, NotificationChannelModel channelModel, NotificationCompat.Builder builder) {
        if (BooleanUtils.getValue(channelModel.channelShowBadge)) {
            incrementGlobalBadgeCounter(context);
            builder.setNumber(1);
        }
    }

    private void setAutoCancel(NotificationModel notificationModel, NotificationCompat.Builder builder) {
        builder.setAutoCancel(BooleanUtils.getValueOrDefault(notificationModel.content.autoDismissible, true));
    }

    private void setBody(NotificationModel notificationModel, NotificationCompat.Builder builder) {
        builder.setContentText(HtmlUtils.fromHtml(notificationModel.content.body));
    }

    private void setTitle(NotificationModel notificationModel, NotificationChannelModel channelModel, NotificationCompat.Builder builder) {
        if (notificationModel.content.title != null) {
            builder.setContentTitle(HtmlUtils.fromHtml(notificationModel.content.title));
        }
    }

    private void setVibrationPattern(NotificationChannelModel channelModel, NotificationCompat.Builder builder) {
        if (BooleanUtils.getValue(channelModel.enableVibration)) {
            if (channelModel.vibrationPattern != null && channelModel.vibrationPattern.length > 0) {
                builder.setVibrate(channelModel.vibrationPattern);
            }
        } else {
            builder.setVibrate(new long[]{0});
        }
    }

    private void setLights(NotificationChannelModel channelModel, NotificationCompat.Builder builder) {
        if (BooleanUtils.getValue(channelModel.enableLights)) {
            Integer ledColorValue = IntegerUtils.extractInteger(channelModel.ledColor, Color.WHITE);
            Integer ledOnMsValue = IntegerUtils.extractInteger(channelModel.ledOnMs, 300);
            Integer ledOffMsValue = IntegerUtils.extractInteger(channelModel.ledOffMs, 700);
            builder.setLights(ledColorValue, ledOnMsValue, ledOffMsValue);
        }
    }

    private void setVisibility(Context context, NotificationModel notificationModel, NotificationChannelModel channelModel, NotificationCompat.Builder builder) {

        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.LOLLIPOP) {

            Integer visibilityIndex;
            visibilityIndex = IntegerUtils.extractInteger(notificationModel.content.privacy, channelModel.defaultPrivacy.ordinal());
            visibilityIndex = IntegerUtils.extractInteger(visibilityIndex, NotificationPrivacy.Public);

            builder.setVisibility(visibilityIndex - 1);
        }
    }

    private void setLayoutColor(Context context, NotificationModel notificationModel, NotificationChannelModel channelModel, NotificationCompat.Builder builder) {

        if (notificationModel.content.backgroundColor == null) {
            builder.setColor(getLayoutColor(notificationModel, channelModel));
        } else {
            builder.setColor(getBackgroundColor(notificationModel, channelModel, builder));
        }
    }

    private void setLargeIcon(Context context, NotificationModel notificationModel, NotificationCompat.Builder builder) {
        if (!StringUtils.isNullOrEmpty(notificationModel.content.largeIcon)) {
            Bitmap largeIcon = BitmapUtils.getBitmapFromSource(context, notificationModel.content.largeIcon);
            if (largeIcon != null) {
                builder.setLargeIcon(largeIcon);
            }
        }
    }

    public static int getGlobalBadgeCounter(Context context) {
        SharedPreferences prefs = PreferenceManager.getDefaultSharedPreferences(context);
        // Read previous value. If not found, use 0 as default value.
        return prefs.getInt(Definitions.BADGE_COUNT, 0);
    }

    public static void setGlobalBadgeCounter(Context context, int count) {
        SharedPreferences prefs = PreferenceManager.getDefaultSharedPreferences(context);
        SharedPreferences.Editor editor = prefs.edit();

        editor.putInt(Definitions.BADGE_COUNT, count);
        ShortcutBadger.applyCount(context, count);

        editor.apply();
    }

    public static void resetGlobalBadgeCounter(Context context) {
        setGlobalBadgeCounter(context, 0);
    }

    public static int incrementGlobalBadgeCounter(Context context) {

        int totalAmount = getGlobalBadgeCounter(context);
        setGlobalBadgeCounter(context, ++totalAmount);
        return totalAmount;
    }

    public static int decrementGlobalBadgeCounter(Context context) {

        int totalAmount = Math.max(getGlobalBadgeCounter(context)-1, 0);
        setGlobalBadgeCounter(context, totalAmount);
        return totalAmount;
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
    public void createActionButtons(Context context, NotificationModel notificationModel, NotificationChannelModel channel, NotificationCompat.Builder builder) {

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
                    (buttonProperties.buttonType == ActionButtonType.DisabledAction) ? AwesomeNotificationsPlugin.class :
                            (buttonProperties.buttonType == ActionButtonType.KeepOnTop) ?
                                    KeepOnTopActionReceiver.class : getNotificationTargetActivityClass(context)
            );

            actionIntent.putExtra(Definitions.NOTIFICATION_AUTO_DISMISSIBLE, buttonProperties.autoDismissible);
            actionIntent.putExtra(Definitions.NOTIFICATION_SHOW_IN_COMPACT_VIEW, buttonProperties.showInCompactView);
            actionIntent.putExtra(Definitions.NOTIFICATION_ENABLED, buttonProperties.enabled);
            actionIntent.putExtra(Definitions.NOTIFICATION_BUTTON_TYPE, buttonProperties.buttonType.toString());
            actionIntent.putExtra(Definitions.NOTIFICATION_BUTTON_KEY, buttonProperties.key);

            PendingIntent actionPendingIntent = null;

            if (buttonProperties.enabled) {

                if (buttonProperties.buttonType == ActionButtonType.KeepOnTop) {

                    actionPendingIntent = PendingIntent.getBroadcast(
                            context,
                            notificationModel.content.id,
                            actionIntent,
                            PendingIntent.FLAG_MUTABLE | PendingIntent.FLAG_UPDATE_CURRENT
                    );

                } else if (buttonProperties.buttonType == ActionButtonType.DisabledAction) {

                    actionPendingIntent = PendingIntent.getActivity(
                            context,
                            notificationModel.content.id,
                            actionIntent,
                            0
                    );

                } else {

                    actionPendingIntent = PendingIntent.getActivity(
                            context,
                            notificationModel.content.id,
                            actionIntent,
                            PendingIntent.FLAG_MUTABLE | PendingIntent.FLAG_UPDATE_CURRENT
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

    private void setSound(Context context, NotificationModel notificationModel, NotificationChannelModel channelModel, NotificationCompat.Builder builder) {

        Uri uri = null;

        if (!notificationModel.content.isRefreshNotification && BooleanUtils.getValue(channelModel.playSound)) {
            uri = ChannelManager.retrieveSoundResourceUri(context, channelModel.defaultRingtoneType, channelModel.soundSource);
        }

        builder.setSound(uri);
    }

    private void setSmallIcon(Context context, NotificationModel notificationModel, NotificationChannelModel channelModel, NotificationCompat.Builder builder) {
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

    private void setGrouping(Context context, NotificationModel notificationModel, NotificationChannelModel channelModel, NotificationCompat.Builder builder) {

        if( // Grouping key is reserved to arrange messaging and messaging group layouts
            notificationModel.content.notificationLayout == NotificationLayout.Messaging ||
            notificationModel.content.notificationLayout == NotificationLayout.MessagingGroup
        ){
            return;
        }

        String groupKey = getGroupKey(notificationModel.content, channelModel);

        if (!StringUtils.isNullOrEmpty(groupKey)) {
            builder.setGroup(groupKey);

            if(notificationModel.groupSummary) {
                builder.setGroupSummary(true);
            }
            else {
                boolean grouped = true;

                NotificationManager manager = (NotificationManager) context.getSystemService(NOTIFICATION_SERVICE);
                StatusBarNotification[] currentActiveNotifications = manager.getActiveNotifications();

                for (StatusBarNotification activeNotification : currentActiveNotifications) {
                    if (activeNotification.getGroupKey().contains("g:"+groupKey)) {
                        grouped = false;
                        break;
                    }
                }

                if (grouped) {
                    notificationModel.groupSummary = true;
                }
            }

            String idText = notificationModel.content.id.toString();
            String sortKey = Long.toString(
                    (channelModel.groupSort == GroupSort.Asc ? System.currentTimeMillis() : Long.MAX_VALUE - System.currentTimeMillis())
            );

            builder.setSortKey(sortKey + idText);

            builder.setGroupAlertBehavior(channelModel.groupAlertBehavior.ordinal());
        }
        else {
            // Prevent Android auto channel grouping for 4+ ungroupded notifications
            builder.setGroup(notificationModel.content.id.toString());
        }
    }

    private void setLayout(Context context, NotificationModel notificationModel, NotificationChannelModel channelModel, NotificationCompat.Builder builder) throws AwesomeNotificationException {

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

    private Boolean setBigPictureLayout(Context context, NotificationContentModel contentModel, NotificationCompat.Builder builder) {

        Bitmap bigPicture = null, largeIcon = null;

        if (!StringUtils.isNullOrEmpty(contentModel.largeIcon)) {
            largeIcon = BitmapUtils.getBitmapFromSource(context, contentModel.largeIcon);
        }

        if (!StringUtils.isNullOrEmpty(contentModel.bigPicture)) {
            bigPicture = BitmapUtils.getBitmapFromSource(context, contentModel.bigPicture);
        }

        if (bigPicture == null) {
            return false;
        }

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

    private Boolean setBigTextStyle(Context context, NotificationContentModel contentModel, NotificationCompat.Builder builder) {

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

    private Boolean setInboxLayout(Context context, NotificationContentModel contentModel, NotificationCompat.Builder builder) {

        // TODO THIS LAYOUT NEEDS TO BE IMPROVED

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

    private static final ConcurrentHashMap<String, NotificationContentModel> messagingQueue = new ConcurrentHashMap<String, NotificationContentModel>();

    @SuppressWarnings("unchecked")
    private static Boolean setMessagingLayout(Context context, boolean isGrouping, NotificationContentModel contentModel, NotificationChannelModel channelModel, NotificationCompat.Builder builder) throws AwesomeNotificationException {
        String groupKey = getGroupKey(contentModel, channelModel);

        //if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M /*Android 6*/) {

            Notification currentNotification = null;
            if(!contentModel.isRefreshNotification){
                String messageQueueKey = groupKey + (isGrouping ? ".Gr" : "");

                List<Notification> notifications = getAllAndroidActiveNotificationsByGroupKey(context, groupKey);

                int messagingNotificationId = -1;
                String digestedGroupKey = StringUtils.digestString(groupKey);
                String digestedLayout = StringUtils.digestString(NotificationLayout.Messaging.toString());

                for (Notification notification : notifications) {
                    String layout = notification.extras.getString(Definitions.NOTIFICATION_LAYOUT);
                    if(digestedLayout.equals(layout)){
                        String extraGroupKey = notification.extras.getString(Definitions.NOTIFICATION_GROUP_KEY);
                        if(digestedGroupKey.equals(extraGroupKey)){
                            currentNotification = notification;
                            messagingNotificationId = notification.extras.getInt(
                                    Definitions.NOTIFICATION_ID);
                            break;
                        }
                    }
                }

                if(messagingNotificationId < 0){
                    messagingQueue.remove(messageQueueKey);
                }
                // For terminated app cases
                else if(!messagingQueue.containsKey(messageQueueKey) && currentNotification != null){
                    Serializable messagesData = currentNotification.extras.getSerializable(
                            Definitions.NOTIFICATION_MESSAGES);
                    if(messagesData != null ){
                        contentModel.messages = NotificationContentModel.mapToMessages((List<Map>) messagesData);
                    } else {
                        contentModel.messages = new ArrayList<>();
                    }
                    contentModel.id = currentNotification.extras.getInt(
                            Definitions.NOTIFICATION_ID);
                    messagingQueue.put(messageQueueKey, contentModel);
                }

                NotificationMessageModel currentMessage = new NotificationMessageModel(
                        contentModel.title,
                        contentModel.body,
                        contentModel.largeIcon
                );

                if(messagingQueue.containsKey(messageQueueKey)){
                    NotificationContentModel firstModel = messagingQueue.get(messageQueueKey);

                    contentModel.id = firstModel.id;
                    contentModel.messages = firstModel.messages;
                }

                if(contentModel.messages == null){
                    contentModel.messages = new ArrayList<>();
                }

                contentModel.messages.add(currentMessage);
                messagingQueue.put(messageQueueKey, contentModel);
            }

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

    private Boolean setMediaPlayerLayout(Context context, NotificationContentModel contentModel, List<NotificationButtonModel> actionButtons, NotificationCompat.Builder builder) {

        ArrayList<Integer> indexes = new ArrayList<>();
        for (int i = 0; i < actionButtons.size(); i++) {
            NotificationButtonModel b = actionButtons.get(i);
            if (b.showInCompactView) indexes.add(i);
        }

        int[] showInCompactView = toIntArray(indexes);

        builder.setStyle(
                new androidx.media.app.NotificationCompat.MediaStyle()
                        .setShowActionsInCompactView(showInCompactView)
                        .setShowCancelButton(true)
                        .setMediaSession(AwesomeNotificationsPlugin.mediaSession.getSessionToken())
        );

        if (!StringUtils.isNullOrEmpty(contentModel.summary)) {
            builder.setSubText(contentModel.summary);
        }

        builder.setShowWhen(false);

        return true;
    }

    private void setProgressLayout(NotificationModel notificationModel, NotificationCompat.Builder builder) {
        builder.setProgress(
                100,
                Math.max(0, Math.min(100, IntegerUtils.extractInteger(notificationModel.content.progress, 0))),
                notificationModel.content.progress == null
        );
    }

    private int[] toIntArray(ArrayList<Integer> list) {
        if (list == null || list.size() <= 0) return new int[0];

        int[] result = new int[list.size()];
        for (int i = 0; i < list.size(); i++) {
            result[i] = list.get(i);
        }

        return result;
    }
}
