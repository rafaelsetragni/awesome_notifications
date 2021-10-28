package me.carda.awesome_notifications.notifications;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;

import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.graphics.Bitmap;
import android.graphics.Color;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.preference.PreferenceManager;
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
import me.carda.awesome_notifications.AwesomeNotificationsPlugin;
import me.carda.awesome_notifications.Definitions;
import me.carda.awesome_notifications.notifications.broadcastReceivers.DismissedNotificationReceiver;
import me.carda.awesome_notifications.notifications.broadcastReceivers.KeepOnTopActionReceiver;
import me.carda.awesome_notifications.notifications.enumerators.ActionButtonType;
import me.carda.awesome_notifications.notifications.enumerators.GroupSort;
import me.carda.awesome_notifications.notifications.enumerators.NotificationLayout;
import me.carda.awesome_notifications.notifications.enumerators.NotificationPrivacy;
import me.carda.awesome_notifications.notifications.exceptions.AwesomeNotificationException;
import me.carda.awesome_notifications.notifications.managers.ChannelManager;
import me.carda.awesome_notifications.notifications.managers.DefaultsManager;
import me.carda.awesome_notifications.notifications.models.NotificationButtonModel;
import me.carda.awesome_notifications.notifications.models.NotificationChannelModel;
import me.carda.awesome_notifications.notifications.models.NotificationContentModel;
import me.carda.awesome_notifications.notifications.models.NotificationMessageModel;
import me.carda.awesome_notifications.notifications.models.PushNotification;
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

public class NotificationBuilder {

    public static String TAG = "NotificationBuilder";

    public Notification createNotification(Context context, PushNotification pushNotification) throws AwesomeNotificationException {
        return createNotification(context, pushNotification, false);
    }

    @SuppressWarnings("unchecked")
    public Notification createNotification(Context context, PushNotification pushNotification, boolean isSummary) throws AwesomeNotificationException {

        NotificationChannelModel channelModel = ChannelManager.getChannelByKey(context, pushNotification.content.channelKey);
        if(channelModel == null)
            throw new AwesomeNotificationException("Channel '"+ pushNotification.content.channelKey +"' does not exist or is disabled");

        pushNotification.content.groupKey = getGroupKey(pushNotification.content, channelModel);

        Intent intent = buildNotificationIntentFromModel(
                context,
                Definitions.SELECT_NOTIFICATION,
                pushNotification,
                channelModel
        );

        Intent deleteIntent = buildNotificationIntentFromModel(
                context,
                Definitions.DISMISSED_NOTIFICATION,
                pushNotification,
                channelModel,
                DismissedNotificationReceiver.class
        );

        PendingIntent pendingIntent = PendingIntent.getActivity(
                context,
                pushNotification.content.id,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT
        );

        PendingIntent pendingDeleteIntent = PendingIntent.getBroadcast(
                context,
                pushNotification.content.id,
                deleteIntent,
                PendingIntent.FLAG_CANCEL_CURRENT
        );

        Notification finalNotification = getNotificationBuilderFromModel(context, pushNotification, pendingIntent, pendingDeleteIntent, isSummary);

        finalNotification.extras.putInt(
                Definitions.NOTIFICATION_ID,
                pushNotification.content.id);

        finalNotification.extras.putString(
                Definitions.NOTIFICATION_CHANNEL_KEY,
                StringUtils.digestString(pushNotification.content.channelKey));

        finalNotification.extras.putString(
                Definitions.NOTIFICATION_LAYOUT,
                StringUtils.digestString(pushNotification.content.notificationLayout.toString()));

        if(!ListUtils.isNullOrEmpty(pushNotification.content.messages)) {
            Map<String, Object> contentData = pushNotification.content.toMap();
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
            PushNotification pushNotification,
            NotificationChannelModel channel
    ) {
        Class<?> targetClass = getTargetClass(context);
        return buildNotificationIntentFromModel(
                context,
                actionReference,
                pushNotification,
                channel,
                targetClass);
    }

    public Intent buildNotificationIntentFromModel(
            Context context,
            String ActionReference,
            PushNotification pushNotification,
            NotificationChannelModel channel,
            Class<?> targetAction
    ) {
        Intent intent = new Intent(context, targetAction);

        intent.setAction(ActionReference);

        Bundle extras = intent.getExtras();
        if(extras == null)
            extras = new Bundle();

        String jsonData = pushNotification.toJson();
        extras.putString(Definitions.NOTIFICATION_JSON, jsonData);

        updateTrackingExtras(pushNotification, channel, extras);
        intent.putExtras(extras);

        return intent;
    }

    private static void updateTrackingExtras(PushNotification pushNotification, NotificationChannelModel channel, Bundle extras) {
        String groupKey = getGroupKey(pushNotification.content, channel);

        extras.putInt(Definitions.NOTIFICATION_ID, pushNotification.content.id);
        extras.putString(Definitions.NOTIFICATION_CHANNEL_KEY, StringUtils.digestString(pushNotification.content.channelKey));
        extras.putString(Definitions.NOTIFICATION_GROUP_KEY, StringUtils.digestString(groupKey));
        extras.putBoolean(Definitions.NOTIFICATION_AUTO_CANCEL, pushNotification.content.autoCancel);
    }

    public static ActionReceived buildNotificationActionFromIntent(Context context, Intent intent) {
        String buttonKeyPressed = intent.getAction();

        if (buttonKeyPressed == null) return null;

        Boolean isNormalAction = Definitions.SELECT_NOTIFICATION.equals(buttonKeyPressed) || Definitions.DISMISSED_NOTIFICATION.equals(buttonKeyPressed);
        Boolean isButtonAction = buttonKeyPressed.startsWith(Definitions.NOTIFICATION_BUTTON_ACTION_PREFIX);

        if (isNormalAction || isButtonAction) {

            Integer notificationId = intent.getIntExtra(Definitions.NOTIFICATION_ID, -1);
            String notificationJson = intent.getStringExtra(Definitions.NOTIFICATION_JSON);

            PushNotification pushNotification = new PushNotification().fromJson(notificationJson);
            if (pushNotification == null) return null;

            ActionReceived actionModel = new ActionReceived(pushNotification.content);

            actionModel.actionLifeCycle = AwesomeNotificationsPlugin.appLifeCycle;

            if (isButtonAction) {
                actionModel.buttonKeyPressed = intent.getStringExtra(Definitions.NOTIFICATION_BUTTON_KEY);
                if (intent.getStringExtra(Definitions.NOTIFICATION_BUTTON_TYPE).equals(ActionButtonType.InputField.toString())) {
                    actionModel.buttonKeyInput = getButtonInputText(intent, intent.getStringExtra(Definitions.NOTIFICATION_BUTTON_KEY));
                }

                if(Build.VERSION.SDK_INT >= Build.VERSION_CODES.P /*Android 9*/) {
                    try {
                        pushNotification.remoteHistory = actionModel.buttonKeyInput;
                        pushNotification.content.isRefreshNotification = true;
                        NotificationSender.send(context, pushNotification);
                    } catch (Exception e) {
                        e.printStackTrace();
                    }
                }
            }

            if (intent.getBooleanExtra(Definitions.NOTIFICATION_AUTO_CANCEL, notificationId >= 0)) {
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
        if(context != null && android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M){

            NotificationManager manager = (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);
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
        if(context != null && !StringUtils.isNullOrEmpty(channelKey) && android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M){

            NotificationManager manager = (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);
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
        if(context != null && !StringUtils.isNullOrEmpty(groupKey) && android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M){

            NotificationManager manager = (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);
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

    private static String getButtonInputText(Intent intent, String buttonKey) {
        Bundle remoteInput = RemoteInput.getResultsFromIntent(intent);
        if (remoteInput != null) {
            return remoteInput.getCharSequence(buttonKey).toString();
        }
        return null;
    }

    private Notification getNotificationBuilderFromModel(Context context, PushNotification pushNotification, PendingIntent pendingIntent, PendingIntent deleteIntent, boolean isSummary) throws AwesomeNotificationException {

        if (!ChannelManager.isChannelEnabled(context, pushNotification.content.channelKey))
            throw new AwesomeNotificationException("Channel '" + pushNotification.content.channelKey + "' does not exist or is disabled");

        NotificationChannelModel channel = ChannelManager.getChannelByKey(context, pushNotification.content.channelKey);

        NotificationCompat.Builder builder = new NotificationCompat.Builder(context, pushNotification.content.channelKey);

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O /*Android 8*/){
            NotificationChannel androidChannel = ChannelManager.getAndroidChannel(context, channel.channelKey);
            builder.setChannelId(androidChannel.getId());
        }

        setSmallIcon(context, pushNotification, channel, builder);

        // Crashing on Android 11+
        //setRemoteHistory(notificationModel, builder);

        setGrouping(context, pushNotification, channel, builder);

        setVisibility(context, pushNotification, channel, builder);
        setShowWhen(pushNotification, builder);

        setLayout(context, pushNotification, channel, builder);

        createActionButtons(context, pushNotification, channel, builder);

        setTitle(pushNotification, channel, builder);
        setBody(pushNotification, builder);

        setAutoCancel(pushNotification, builder);
        setTicker(pushNotification, builder);
        setOnlyAlertOnce(pushNotification, channel, builder);

        setLockedNotification(pushNotification, channel, builder);
        setImportance(channel, builder);

        setSound(context, pushNotification, channel, builder);
        setVibrationPattern(channel, builder);
        setLights(channel, builder);

        setSmallIcon(context, pushNotification, channel, builder);
        setLargeIcon(context, pushNotification, builder);
        setLayoutColor(context, pushNotification, channel, builder);

        if(!isSummary)
            setBadge(context, channel, builder);

        builder.setContentIntent(pendingIntent);
        if(!isSummary)
            builder.setDeleteIntent(deleteIntent);

        Notification androidNotification = builder.build();
        if(androidNotification.extras == null)
            androidNotification.extras = new Bundle();

        updateTrackingExtras(pushNotification, channel, androidNotification.extras);

        return androidNotification;
    }

    private void setShowWhen(PushNotification pushNotification, NotificationCompat.Builder builder) {
        builder.setShowWhen(BooleanUtils.getValueOrDefault(pushNotification.content.showWhen, true));
    }

    private Integer getBackgroundColor(PushNotification pushNotification, NotificationChannelModel channel, NotificationCompat.Builder builder) {
        Integer bgColorValue;
        bgColorValue = IntegerUtils.extractInteger(pushNotification.content.backgroundColor, null);
        if (bgColorValue != null) {
            builder.setColorized(true);
        } else {
            bgColorValue = getLayoutColor(pushNotification, channel);
        }
        return bgColorValue;
    }

    private Integer getLayoutColor(PushNotification pushNotification, NotificationChannelModel channel) {
        Integer layoutColorValue;
        layoutColorValue = IntegerUtils.extractInteger(pushNotification.content.color, channel.defaultColor);
        layoutColorValue = IntegerUtils.extractInteger(layoutColorValue, Color.BLACK);
        return layoutColorValue;
    }

    private void setImportance(NotificationChannelModel channel, NotificationCompat.Builder builder) {
        // Conversion to Priority
        int priorityValue = Math.min(Math.max(IntegerUtils.extractInteger(channel.importance) - 2, -2), 2);
        builder.setPriority(priorityValue);
    }

    private void setOnlyAlertOnce(PushNotification pushNotification, NotificationChannelModel channel, NotificationCompat.Builder builder) {
        Boolean onlyAlertOnceValue = BooleanUtils.getValue(pushNotification.content.notificationLayout == NotificationLayout.ProgressBar ? true : channel.onlyAlertOnce);
        builder.setOnlyAlertOnce(onlyAlertOnceValue);
    }

    private static void setRemoteHistory(PushNotification pushNotification, NotificationCompat.Builder builder) {
        if(!StringUtils.isNullOrEmpty(pushNotification.remoteHistory)) {
            builder.setRemoteInputHistory(new CharSequence[]{pushNotification.remoteHistory});
        }
    }

    private void setLockedNotification(PushNotification pushNotification, NotificationChannelModel channel, NotificationCompat.Builder builder) {
        Boolean contentLocked = BooleanUtils.getValue(pushNotification.content.locked);
        Boolean channelLocked = BooleanUtils.getValue(channel.locked);

        if (contentLocked) {
            builder.setOngoing(true);
        } else if (channelLocked) {
            Boolean lockedValue = BooleanUtils.getValueOrDefault(pushNotification.content.locked, true) && channelLocked;
            builder.setOngoing(lockedValue);
        }
    }

    private void setTicker(PushNotification pushNotification, NotificationCompat.Builder builder) {
        String tickerValue;
        tickerValue = StringUtils.getValueOrDefault(pushNotification.content.ticker, null);
        tickerValue = StringUtils.getValueOrDefault(tickerValue, pushNotification.content.summary);
        tickerValue = StringUtils.getValueOrDefault(tickerValue, pushNotification.content.body);
        builder.setTicker(tickerValue);
    }

    private void setBadge(Context context, NotificationChannelModel channelModel, NotificationCompat.Builder builder) {
        if (BooleanUtils.getValue(channelModel.channelShowBadge)) {
            incrementGlobalBadgeCounter(context);
            builder.setNumber(1);
        }
    }

    private void setAutoCancel(PushNotification pushNotification, NotificationCompat.Builder builder) {
        builder.setAutoCancel(BooleanUtils.getValueOrDefault(pushNotification.content.autoCancel, true));
    }

    private void setBody(PushNotification pushNotification, NotificationCompat.Builder builder) {
        builder.setContentText(HtmlUtils.fromHtml(pushNotification.content.body));
    }

    private void setTitle(PushNotification pushNotification, NotificationChannelModel channelModel, NotificationCompat.Builder builder) {
        if (pushNotification.content.title != null) {
            builder.setContentTitle(HtmlUtils.fromHtml(pushNotification.content.title));
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

    private void setVisibility(Context context, PushNotification pushNotification, NotificationChannelModel channelModel, NotificationCompat.Builder builder) {

        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.LOLLIPOP) {

            Integer visibilityIndex;
            visibilityIndex = IntegerUtils.extractInteger(pushNotification.content.privacy, channelModel.defaultPrivacy.ordinal());
            visibilityIndex = IntegerUtils.extractInteger(visibilityIndex, NotificationPrivacy.Public);

            builder.setVisibility(visibilityIndex - 1);
        }
    }

    private void setLayoutColor(Context context, PushNotification pushNotification, NotificationChannelModel channelModel, NotificationCompat.Builder builder) {

        if (pushNotification.content.backgroundColor == null) {
            builder.setColor(getLayoutColor(pushNotification, channelModel));
        } else {
            builder.setColor(getBackgroundColor(pushNotification, channelModel, builder));
        }
    }

    private void setLargeIcon(Context context, PushNotification pushNotification, NotificationCompat.Builder builder) {
        if (!StringUtils.isNullOrEmpty(pushNotification.content.largeIcon)) {
            Bitmap largeIcon = BitmapUtils.getBitmapFromSource(context, pushNotification.content.largeIcon);
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
    public void createActionButtons(Context context, PushNotification pushNotification, NotificationChannelModel channel, NotificationCompat.Builder builder) {

        if (ListUtils.isNullOrEmpty(pushNotification.actionButtons)) return;

        for (NotificationButtonModel buttonProperties : pushNotification.actionButtons) {

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
                    pushNotification,
                    channel,
                    (buttonProperties.buttonType == ActionButtonType.DisabledAction) ? AwesomeNotificationsPlugin.class :
                            (buttonProperties.buttonType == ActionButtonType.KeepOnTop) ?
                                    KeepOnTopActionReceiver.class : getNotificationTargetActivityClass(context)
            );

            actionIntent.putExtra(Definitions.NOTIFICATION_AUTO_CANCEL, buttonProperties.autoCancel);
            actionIntent.putExtra(Definitions.NOTIFICATION_SHOW_IN_COMPACT_VIEW, buttonProperties.showInCompactView);
            actionIntent.putExtra(Definitions.NOTIFICATION_ENABLED, buttonProperties.enabled);
            actionIntent.putExtra(Definitions.NOTIFICATION_BUTTON_TYPE, buttonProperties.buttonType.toString());
            actionIntent.putExtra(Definitions.NOTIFICATION_BUTTON_KEY, buttonProperties.key);

            PendingIntent actionPendingIntent = null;

            if (buttonProperties.enabled) {

                if (buttonProperties.buttonType == ActionButtonType.KeepOnTop) {

                    actionPendingIntent = PendingIntent.getBroadcast(
                            context,
                            pushNotification.content.id,
                            actionIntent,
                            PendingIntent.FLAG_UPDATE_CURRENT
                    );

                } else if (buttonProperties.buttonType == ActionButtonType.DisabledAction) {

                    actionPendingIntent = PendingIntent.getActivity(
                            context,
                            pushNotification.content.id,
                            actionIntent,
                            0
                    );

                } else {

                    actionPendingIntent = PendingIntent.getActivity(
                            context,
                            pushNotification.content.id,
                            actionIntent,
                            PendingIntent.FLAG_UPDATE_CURRENT
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

                builder.addAction(iconResource, buttonProperties.label, actionPendingIntent);
            }
        }
    }

    private void setSound(Context context, PushNotification pushNotification, NotificationChannelModel channelModel, NotificationCompat.Builder builder) {

        Uri uri = null;

        if (!pushNotification.content.isRefreshNotification && BooleanUtils.getValue(channelModel.playSound)) {
            uri = ChannelManager.retrieveSoundResourceUri(context, channelModel.defaultRingtoneType, channelModel.soundSource);
        }

        builder.setSound(uri);
    }

    private void setSmallIcon(Context context, PushNotification pushNotification, NotificationChannelModel channelModel, NotificationCompat.Builder builder) {
        if (!StringUtils.isNullOrEmpty(pushNotification.content.icon)) {
            builder.setSmallIcon(BitmapUtils.getDrawableResourceId(context, pushNotification.content.icon));
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

    private void setGrouping(Context context, PushNotification pushNotification, NotificationChannelModel channelModel, NotificationCompat.Builder builder) {

        if(android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M){
            if( // Grouping key is reserved to arrange messaging and messaging group layouts
                    pushNotification.content.notificationLayout == NotificationLayout.Messaging ||
                            pushNotification.content.notificationLayout == NotificationLayout.MessagingGroup
            ){
                return;
            }
        }

        String groupKey = getGroupKey(pushNotification.content, channelModel);

        if (!StringUtils.isNullOrEmpty(groupKey)) {
            builder.setGroup(groupKey);

            if(pushNotification.groupSummary) {
                builder.setGroupSummary(true);
            }
            else {
                boolean grouped = true;
                if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {

                    NotificationManager manager = (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);
                    StatusBarNotification[] currentActiveNotifications = manager.getActiveNotifications();

                    for (StatusBarNotification activeNotification : currentActiveNotifications) {
                        if (activeNotification.getGroupKey().contains("g:"+groupKey)) {
                            grouped = false;
                            break;
                        }
                    }
                }

                if (grouped) {
                    pushNotification.groupSummary = true;
                }
            }

            String idText = pushNotification.content.id.toString();
            String sortKey = Long.toString(
                    (channelModel.groupSort == GroupSort.Asc ? System.currentTimeMillis() : Long.MAX_VALUE - System.currentTimeMillis())
            );

            builder.setSortKey(sortKey + idText);

            builder.setGroupAlertBehavior(channelModel.groupAlertBehavior.ordinal());
        }
        else {
            // Prevent Android auto channel grouping for 4+ ungroupded notifications
            builder.setGroup(pushNotification.content.id.toString());
        }
    }

    private void setLayout(Context context, PushNotification pushNotification, NotificationChannelModel channelModel, NotificationCompat.Builder builder) throws AwesomeNotificationException {

        switch (pushNotification.content.notificationLayout) {

            case BigPicture:
                if (setBigPictureLayout(context, pushNotification.content, builder)) return;
                break;

            case BigText:
                if (setBigTextStyle(context, pushNotification.content, builder)) return;
                break;

            case Inbox:
                if (setInboxLayout(context, pushNotification.content, builder)) return;
                break;

            case Messaging:
                if (setMessagingLayout(context, false, pushNotification.content, channelModel, builder)) return;
                break;

            case MessagingGroup:
                if(setMessagingLayout(context, true, pushNotification.content, channelModel, builder)) return;
                break;

            case MediaPlayer:
                if (setMediaPlayerLayout(context, pushNotification.content, pushNotification.actionButtons, builder)) return;
                break;

            case ProgressBar:
                setProgressLayout(pushNotification, builder);
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

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N /*Android 7*/) {

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
        }
        else {
            if(StringUtils.isNullOrEmpty(groupKey)){
                builder.setGroup("Messaging."+groupKey);
            }
        }

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

    private void setProgressLayout(PushNotification pushNotification, NotificationCompat.Builder builder) {
        builder.setProgress(
                100,
                Math.max(0, Math.min(100, IntegerUtils.extractInteger(pushNotification.content.progress, 0))),
                pushNotification.content.progress == null
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
