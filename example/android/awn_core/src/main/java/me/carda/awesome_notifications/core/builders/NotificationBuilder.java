package me.carda.awesome_notifications.core.builders;

import static android.app.NotificationManager.Policy.PRIORITY_CATEGORY_ALARMS;

import android.annotation.SuppressLint;
import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.content.pm.ApplicationInfo;
import android.content.pm.ResolveInfo;
import android.graphics.Bitmap;
import android.graphics.Color;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.PowerManager;
import android.support.v4.media.MediaMetadataCompat;
import android.support.v4.media.session.MediaSessionCompat;
import android.text.Spanned;

import androidx.annotation.NonNull;
import androidx.annotation.RequiresApi;
import androidx.core.app.NotificationCompat;
import androidx.media.app.NotificationCompat.MediaStyle;
import androidx.core.app.Person;
import androidx.core.app.RemoteInput;
import androidx.core.graphics.drawable.IconCompat;
import androidx.core.text.HtmlCompat;

import java.io.Serializable;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

import me.carda.awesome_notifications.core.AwesomeNotifications;
import me.carda.awesome_notifications.core.Definitions;
import me.carda.awesome_notifications.core.completion_handlers.NotificationThreadCompletionHandler;
import me.carda.awesome_notifications.core.enumerators.ActionType;
import me.carda.awesome_notifications.core.enumerators.GroupSort;
import me.carda.awesome_notifications.core.enumerators.NotificationImportance;
import me.carda.awesome_notifications.core.enumerators.NotificationLayout;
import me.carda.awesome_notifications.core.enumerators.NotificationLifeCycle;
import me.carda.awesome_notifications.core.enumerators.NotificationPermission;
import me.carda.awesome_notifications.core.enumerators.NotificationPrivacy;
import me.carda.awesome_notifications.core.exceptions.AwesomeNotificationsException;
import me.carda.awesome_notifications.core.exceptions.ExceptionCode;
import me.carda.awesome_notifications.core.exceptions.ExceptionFactory;
import me.carda.awesome_notifications.core.managers.BadgeManager;
import me.carda.awesome_notifications.core.managers.ChannelManager;
import me.carda.awesome_notifications.core.managers.DefaultsManager;
import me.carda.awesome_notifications.core.managers.PermissionManager;
import me.carda.awesome_notifications.core.managers.StatusBarManager;
import me.carda.awesome_notifications.core.models.NotificationButtonModel;
import me.carda.awesome_notifications.core.models.NotificationChannelModel;
import me.carda.awesome_notifications.core.models.NotificationContentModel;
import me.carda.awesome_notifications.core.models.NotificationMessageModel;
import me.carda.awesome_notifications.core.models.NotificationModel;
import me.carda.awesome_notifications.core.models.returnedData.ActionReceived;
import me.carda.awesome_notifications.core.threads.NotificationSender;
import me.carda.awesome_notifications.core.utils.BitmapUtils;
import me.carda.awesome_notifications.core.utils.BooleanUtils;
import me.carda.awesome_notifications.core.utils.HtmlUtils;
import me.carda.awesome_notifications.core.utils.IntegerUtils;
import me.carda.awesome_notifications.core.utils.ListUtils;
import me.carda.awesome_notifications.core.utils.StringUtils;

public class NotificationBuilder {

    public static String TAG = "NotificationBuilder";

    private static String mainTargetClassName;

    private final BitmapUtils bitmapUtils;
    private final StringUtils stringUtils;
    private final PermissionManager permissionManager;
    private static MediaSessionCompat mediaSession;

    // *************** DEPENDENCY INJECTION CONSTRUCTOR ***************

    NotificationBuilder(
            StringUtils stringUtils,
            BitmapUtils bitmapUtils,
            PermissionManager permissionManager
    ){
        this.stringUtils = stringUtils;
        this.bitmapUtils = bitmapUtils;
        this.permissionManager = permissionManager;
    }

    public static NotificationBuilder getNewBuilder() {
        return new NotificationBuilder(
                StringUtils.getInstance(),
                BitmapUtils.getInstance(),
                PermissionManager.getInstance());
    }

    // ****************************************************************

    public void forceBringAppToForeground(Context context){
        Intent startActivity = new Intent(context, getMainTargetClass(context));
        startActivity.setFlags(
                // Intent.FLAG_ACTIVITY_REORDER_TO_FRONT |
                Intent.FLAG_ACTIVITY_SINGLE_TOP |
                // Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY |
                Intent.FLAG_ACTIVITY_NEW_TASK);

        context.startActivity(startActivity);
    }

    public ActionReceived receiveNotificationActionFromIntent(
            Context context,
            Intent intent,
            NotificationLifeCycle appLifeCycle
    ) throws Exception {

        ActionReceived actionReceived
            = buildNotificationActionFromIntent(context, intent, appLifeCycle);

        if (actionReceived != null) {
            if (notificationActionShouldAutoDismiss(actionReceived))
                StatusBarManager
                        .getInstance(context)
                        .dismissNotification(context, actionReceived.id);

            if (actionReceived.actionType == ActionType.DisabledAction)
                return null;
        }

        return actionReceived;
    }

    public boolean notificationActionShouldAutoDismiss(ActionReceived actionReceived){
        if (!StringUtils.getInstance().isNullOrEmpty(actionReceived.buttonKeyInput)){
            return false;
        }
        return actionReceived.shouldAutoDismiss && actionReceived.autoDismissible;
    }

    @SuppressWarnings("unchecked")
    public Notification createNewAndroidNotification(Context context, Intent originalIntent, NotificationModel notificationModel) throws AwesomeNotificationsException {

        NotificationChannelModel channelModel =
                ChannelManager
                        .getInstance()
                        .getChannelByKey(context, notificationModel.content.channelKey);

        if (channelModel == null)
            throw ExceptionFactory
                    .getInstance()
                    .createNewAwesomeException(
                            TAG,
                            ExceptionCode.CODE_INVALID_ARGUMENTS,
                            "Channel '" + notificationModel.content.channelKey + "' does not exist",
                            ExceptionCode.DETAILED_INVALID_ARGUMENTS+".channel.notFound."+notificationModel.content.channelKey);

        if (!ChannelManager
                .getInstance()
                .isChannelEnabled(context, notificationModel.content.channelKey))
            throw ExceptionFactory
                    .getInstance()
                    .createNewAwesomeException(
                            TAG,
                            ExceptionCode.CODE_INSUFFICIENT_PERMISSIONS,
                            "Channel '" + notificationModel.content.channelKey + "' is disabled",
                            ExceptionCode.DETAILED_INSUFFICIENT_PERMISSIONS+".channel.disabled."+notificationModel.content.channelKey);

        NotificationCompat.Builder builder =
                getNotificationBuilderFromModel(
                    context,
                    originalIntent,
                    channelModel,
                    notificationModel);

        Notification androidNotification = builder.build();
        if(androidNotification.extras == null)
            androidNotification.extras = new Bundle();

        updateTrackingExtras(notificationModel, channelModel, androidNotification.extras);

        setWakeUpScreen(context, notificationModel);
        setCriticalAlert(context, channelModel);
        setCategoryFlags(context, notificationModel, androidNotification);

        setBadge(context, notificationModel, channelModel, builder);

        return androidNotification;
    }

    public Intent buildNotificationIntentFromNotificationModel(
            Context context,
            Intent originalIntent,
            String ActionReference,
            NotificationModel notificationModel,
            NotificationChannelModel channel,
            ActionType actionType,
            Class targetClass
    ) {
        Intent intent = new Intent(context, targetClass);

        // Preserves analytics extras
        if(originalIntent != null)
            intent.putExtras(originalIntent.getExtras());

        intent.setAction(ActionReference);

        if(actionType == ActionType.Default)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);

        Bundle extras = intent.getExtras();
        if(extras == null)
            extras = new Bundle();

        String jsonData = notificationModel.toJson();
        extras.putString(Definitions.NOTIFICATION_JSON, jsonData);

        updateTrackingExtras(notificationModel, channel, extras);
        intent.putExtras(extras);

        return intent;
    }

    public Intent buildNotificationIntentFromActionModel(
            Context context,
            Intent originalIntent,
            String ActionReference,
            ActionReceived actionReceived,
            Class<?> targetAction
    ) {
        Intent intent = new Intent(context, targetAction);

        // Preserves analytics extras
        if(originalIntent != null)
            intent.putExtras(originalIntent.getExtras());

        intent.setAction(ActionReference);

        Bundle extras = intent.getExtras();
        if(extras == null)
            extras = new Bundle();

        String jsonData = actionReceived.toJson();
        extras.putString(Definitions.NOTIFICATION_ACTION_JSON, jsonData);
        intent.putExtras(extras);

        return intent;
    }

    private PendingIntent getPendingActionIntent(
            Context context,
            Intent originalIntent,
            NotificationModel notificationModel,
            NotificationChannelModel channelModel
    ){
        ActionType actionType = notificationModel.content.actionType;

        Intent actionIntent = buildNotificationIntentFromNotificationModel(
                context,
                originalIntent,
                Definitions.SELECT_NOTIFICATION,
                notificationModel,
                channelModel,
                actionType,
                actionType == ActionType.Default ?
                    getMainTargetClass(context) :
                    AwesomeNotifications.actionReceiverClass
        );

        if(actionType == ActionType.Default)
            actionIntent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP);

        return actionType == ActionType.Default ?
                PendingIntent.getActivity(
                            context,
                            notificationModel.content.id,
                            actionIntent,
                            (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) ?
                                    PendingIntent.FLAG_MUTABLE | PendingIntent.FLAG_UPDATE_CURRENT :
                                    PendingIntent.FLAG_UPDATE_CURRENT)
                :
                PendingIntent.getBroadcast(
                            context,
                            notificationModel.content.id,
                            actionIntent,
                            (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) ?
                                    PendingIntent.FLAG_MUTABLE | PendingIntent.FLAG_UPDATE_CURRENT :
                                    PendingIntent.FLAG_UPDATE_CURRENT);
    }

    private PendingIntent getPendingDismissIntent(
            Context context,
            Intent originalIntent,
            NotificationModel notificationModel,
            NotificationChannelModel channelModel
    ){
        Intent deleteIntent = buildNotificationIntentFromNotificationModel(
                context,
                originalIntent,
                Definitions.DISMISSED_NOTIFICATION,
                notificationModel,
                channelModel,
                notificationModel.content.actionType,
                AwesomeNotifications.dismissReceiverClass
        );

        return PendingIntent.getBroadcast(
                context,
                notificationModel.content.id,
                deleteIntent,
                (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) ?
                        PendingIntent.FLAG_MUTABLE | PendingIntent.FLAG_UPDATE_CURRENT :
                        PendingIntent.FLAG_UPDATE_CURRENT
        );
    }

    @SuppressWarnings("unchecked")
    private void updateTrackingExtras(NotificationModel notificationModel, NotificationChannelModel channel, Bundle extras) {
        String groupKey = getGroupKey(notificationModel.content, channel);

        extras.putInt(Definitions.NOTIFICATION_ID, notificationModel.content.id);
        extras.putString(Definitions.NOTIFICATION_CHANNEL_KEY, stringUtils.digestString(notificationModel.content.channelKey));
        extras.putString(Definitions.NOTIFICATION_GROUP_KEY, stringUtils.digestString(groupKey));
        extras.putBoolean(Definitions.NOTIFICATION_AUTO_DISMISSIBLE, notificationModel.content.autoDismissible);
        extras.putString(Definitions.NOTIFICATION_ACTION_TYPE,
                notificationModel.content.actionType != null ?
                    notificationModel.content.actionType.toString() : ActionType.Default.toString());

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

    private Class tryResolveClassName(String className){
        try {
            return Class.forName(className);
        } catch (ClassNotFoundException e) {
            ExceptionFactory
                    .getInstance()
                    .registerNewAwesomeException(
                            TAG,
                            ExceptionCode.CODE_CLASS_NOT_FOUND,
                            "Was not possible to resolve the class named '"+className+"'",
                            ExceptionCode.DETAILED_CLASS_NOT_FOUND+"."+className);
            return null;
        }
    }

    public Class getMainTargetClass(
            Context applicationContext
    ){
        if(mainTargetClassName == null)
            updateMainTargetClassName(applicationContext);

        if(mainTargetClassName == null)
            mainTargetClassName = AwesomeNotifications.getPackageName(applicationContext) + ".MainActivity";

        Class clazz = tryResolveClassName(mainTargetClassName);
        if(clazz != null) return clazz;

        return tryResolveClassName("MainActivity");
    }

    public NotificationBuilder updateMainTargetClassName(Context applicationContext) {

        String packageName = AwesomeNotifications.getPackageName(applicationContext);
        Intent intent = new Intent();
        intent.setPackage(packageName);
        intent.addCategory(Intent.CATEGORY_LAUNCHER);

        List<ResolveInfo> resolveInfoList =
                applicationContext
                        .getPackageManager()
                        .queryIntentActivities(intent, 0);

        if(resolveInfoList.size() > 0)
            mainTargetClassName = resolveInfoList.get(0).activityInfo.name;

        return this;
    }

    public NotificationBuilder setMediaSession(MediaSessionCompat mediaSession) {
        NotificationBuilder.mediaSession = mediaSession;
        return this;
    }

    public Intent getLaunchIntent(Context applicationContext){
        String packageName = AwesomeNotifications.getPackageName(applicationContext);
        return applicationContext.getPackageManager().getLaunchIntentForPackage(packageName);
    }

    public ActionReceived buildNotificationActionFromIntent(Context context, Intent intent, NotificationLifeCycle lifeCycle) throws AwesomeNotificationsException {
        String buttonKeyPressed = intent.getAction();

        if (buttonKeyPressed == null) return null;

        boolean isNormalAction =
                Definitions.SELECT_NOTIFICATION.equals(buttonKeyPressed) ||
                Definitions.DISMISSED_NOTIFICATION.equals(buttonKeyPressed);

        boolean isButtonAction =
                buttonKeyPressed
                    .startsWith(Definitions.NOTIFICATION_BUTTON_ACTION_PREFIX);

        if (isNormalAction || isButtonAction) {

            String notificationActionJson = intent.getStringExtra(Definitions.NOTIFICATION_ACTION_JSON);
            if(!stringUtils.isNullOrEmpty(notificationActionJson)){
                ActionReceived actionModel = new ActionReceived().fromJson(notificationActionJson);
                if (actionModel != null) return actionModel;
            }

            String notificationJson = intent.getStringExtra(Definitions.NOTIFICATION_JSON);

            NotificationModel notificationModel = new NotificationModel().fromJson(notificationJson);
            if (notificationModel == null) return null;

            ActionReceived actionModel =
                    new ActionReceived(
                        notificationModel.content,
                        intent);

            actionModel.registerUserActionEvent(lifeCycle);

            if (actionModel.displayedDate == null)
                actionModel.registerDisplayedEvent(lifeCycle);

            actionModel.autoDismissible = intent.getBooleanExtra(Definitions.NOTIFICATION_AUTO_DISMISSIBLE, true);
            actionModel.shouldAutoDismiss = actionModel.autoDismissible;

            actionModel.actionType =
                    stringUtils.getEnumFromString(
                            ActionType.class,
                            intent.getStringExtra(Definitions.NOTIFICATION_ACTION_TYPE));

            if (isButtonAction) {

                actionModel.buttonKeyPressed = intent.getStringExtra(Definitions.NOTIFICATION_BUTTON_KEY);

                Bundle remoteInput = RemoteInput.getResultsFromIntent(intent);
                if (remoteInput != null)
                    actionModel.buttonKeyInput = remoteInput.getCharSequence(
                            actionModel.buttonKeyPressed).toString();
                else
                    actionModel.buttonKeyInput = "";

                if (
                    !stringUtils.isNullOrEmpty(actionModel.buttonKeyInput)
                )
                    updateRemoteHistoryOnActiveNotification(
                            context,
                            notificationModel,
                            actionModel,
                            null);
            }

            return actionModel;
        }
        return null;
    }

    public void updateRemoteHistoryOnActiveNotification(
            Context context,
            NotificationModel notificationModel,
            ActionReceived actionModel,
            NotificationThreadCompletionHandler completionHandler
    ) throws AwesomeNotificationsException {
        if(
            !stringUtils.isNullOrEmpty(actionModel.buttonKeyInput) &&
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
                    notificationModel.remoteHistory = actionModel.buttonKeyInput;
                    NotificationSender
                        .send(
                            context,
                            this,
                            notificationModel.content.displayedLifeCycle,
                            notificationModel,
                            completionHandler);
                    break;
            }
        }
    }

    public String getAppName(Context context){
        ApplicationInfo applicationInfo = context.getApplicationInfo();
        int stringId = applicationInfo.labelRes;
        return stringId == 0 ? applicationInfo.nonLocalizedLabel.toString() : context.getString(stringId);
    }

    @RequiresApi(api = Build.VERSION_CODES.KITKAT_WATCH)
    public void wakeUpScreen(Context context){

        String appName = getAppName(context);
        PowerManager pm = (PowerManager) context.getSystemService(Context.POWER_SERVICE);

        boolean isScreenOn = Build.VERSION.SDK_INT >= 20 ? pm.isInteractive() : pm.isScreenOn(); // check if screen is on
        if (!isScreenOn) {
            PowerManager.WakeLock wl =
                pm.newWakeLock(
                    PowerManager.SCREEN_BRIGHT_WAKE_LOCK | PowerManager.ACQUIRE_CAUSES_WAKEUP,
                        appName+":"+TAG+":WakeupLock");

            wl.acquire(3000); //set your time in milliseconds
        }
        /*
        PowerManager pm = (PowerManager)context.getSystemService(Context.POWER_SERVICE);
        boolean isScreenOn = pm.isInteractive();
        if(!isScreenOn)
        {
            String appName = getAppName(context);

            PowerManager.WakeLock wl = pm.newWakeLock(
                    PowerManager.PARTIAL_WAKE_LOCK |
                    PowerManager.ACQUIRE_CAUSES_WAKEUP |
                    PowerManager.ON_AFTER_RELEASE,
                    appName+":"+TAG+":WakeupLock");
            wl.acquire(10000);

            PowerManager.WakeLock wl_cpu = pm.newWakeLock(
                    PowerManager.PARTIAL_WAKE_LOCK,
                    appName+":"+TAG+":WakeupCpuLock");
            wl_cpu.acquire(10000);
            wl_cpu.acquire(10000);
        }*/
    }

    public void ensureCriticalAlert(Context context) throws AwesomeNotificationsException {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            NotificationManager notificationManager = (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);
            if (PermissionManager.getInstance().isDndOverrideAllowed(context)) {
                if (!permissionManager.isSpecifiedPermissionGloballyAllowed(context, NotificationPermission.CriticalAlert)){
                    notificationManager.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_PRIORITY);
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P /*Android 9*/) {
                        NotificationManager.Policy policy = new NotificationManager.Policy(PRIORITY_CATEGORY_ALARMS, 0, 0);
                        notificationManager.setNotificationPolicy(policy);
                    }
                }
            }
        }
    }

    private NotificationCompat.Builder getNotificationBuilderFromModel(
            Context context,
            Intent originalIntent,
            NotificationChannelModel channel,
            NotificationModel notificationModel
    ) throws AwesomeNotificationsException {

        NotificationCompat.Builder builder =
                new NotificationCompat.Builder(
                        context,
                        notificationModel.content.channelKey);

        setChannelKey(context, channel, builder);
        setNotificationId(notificationModel);
        setTitle(notificationModel, channel, builder);
        setBody(notificationModel, builder);

        setGroupKey(notificationModel, channel);
        setSmallIcon(context, notificationModel, channel, builder);
        setRemoteHistory(notificationModel, builder);
        setGrouping(context, notificationModel, channel, builder);
        setVisibility(context, notificationModel, channel, builder);
        setShowWhen(notificationModel, builder);
        setLayout(context, notificationModel, channel, builder);
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

        PendingIntent pendingActionIntent =
                getPendingActionIntent(context, originalIntent, notificationModel, channel);
        PendingIntent pendingDismissIntent =
                getPendingDismissIntent(context, originalIntent, notificationModel, channel);

        setFullScreenIntent(context, pendingActionIntent, notificationModel, builder);

        setNotificationPendingIntents(notificationModel, pendingActionIntent, pendingDismissIntent, builder);
        createActionButtons(context, originalIntent, notificationModel, channel, builder);

        return builder;
    }

    private void setChannelKey(Context context, NotificationChannelModel channel, NotificationCompat.Builder builder) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O /*Android 8*/){
            NotificationChannel androidChannel =
                    ChannelManager
                    .getInstance()
                    .getAndroidChannel(context, channel.channelKey);

            builder.setChannelId(androidChannel.getId());
        }
    }

    private void setNotificationId(NotificationModel notificationModel) {
        if (notificationModel.content.id == null || notificationModel.content.id < 0)
            notificationModel.content.id = IntegerUtils.generateNextRandomId();
    }

    private void setGroupKey(NotificationModel notificationModel, NotificationChannelModel channel) {
        notificationModel.content.groupKey = getGroupKey(notificationModel.content, channel);
    }

    private void setCategoryFlags(Context context, NotificationModel notificationModel, Notification androidNotification) {

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

    private void setNotificationPendingIntents(NotificationModel notificationModel, PendingIntent pendingActionIntent, PendingIntent pendingDismissIntent, NotificationCompat.Builder builder) {
        builder.setContentIntent(pendingActionIntent);
        if(!notificationModel.groupSummary)
            builder.setDeleteIntent(pendingDismissIntent);
    }

    private void setWakeUpScreen(Context context, NotificationModel notificationModel) {
        if (notificationModel.content.wakeUpScreen)
//            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT_WATCH)
                wakeUpScreen(context);
    }

    private void setCriticalAlert(Context context, NotificationChannelModel channel) throws AwesomeNotificationsException {
        if (channel.criticalAlerts)
            ensureCriticalAlert(context);
    }

    private void setFullScreenIntent(Context context, PendingIntent pendingIntent, NotificationModel notificationModel, NotificationCompat.Builder builder) {
        if (BooleanUtils.getInstance().getValue(notificationModel.content.fullScreenIntent)) {
            builder.setFullScreenIntent(pendingIntent, true);
        }
    }

    private void setShowWhen(NotificationModel notificationModel, NotificationCompat.Builder builder) {
        builder.setShowWhen(BooleanUtils.getInstance().getValueOrDefault(notificationModel.content.showWhen, true));
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
        builder.setPriority(NotificationImportance.toAndroidPriority(channel.importance));
    }

    private void setCategory(NotificationModel notificationModel, NotificationCompat.Builder builder){
        if(notificationModel.content.category != null)
            builder.setCategory(notificationModel.content.category.rawValue);
    }

    private void setOnlyAlertOnce(NotificationModel notificationModel, NotificationChannelModel channel, NotificationCompat.Builder builder) {
        boolean onlyAlertOnceValue = BooleanUtils.getInstance().getValue(notificationModel.content.notificationLayout == NotificationLayout.ProgressBar || channel.onlyAlertOnce);
        builder.setOnlyAlertOnce(onlyAlertOnceValue);
    }

    private void setRemoteHistory(NotificationModel notificationModel, NotificationCompat.Builder builder) {
        if(!stringUtils.isNullOrEmpty(notificationModel.remoteHistory) && notificationModel.content.notificationLayout == NotificationLayout.Default)
            builder.setRemoteInputHistory(new CharSequence[]{notificationModel.remoteHistory});
    }

    private void setLockedNotification(NotificationModel notificationModel, NotificationChannelModel channel, NotificationCompat.Builder builder) {
        boolean contentLocked = BooleanUtils.getInstance().getValue(notificationModel.content.locked);
        boolean channelLocked = BooleanUtils.getInstance().getValue(channel.locked);

        if (contentLocked) {
            builder.setOngoing(true);
        } else if (channelLocked) {
            boolean lockedValue = BooleanUtils.getInstance().getValueOrDefault(notificationModel.content.locked, true);
            builder.setOngoing(lockedValue);
        }
    }

    private void setTicker(NotificationModel notificationModel, NotificationCompat.Builder builder) {
        String tickerValue;
        tickerValue = stringUtils.getValueOrDefault(notificationModel.content.ticker, "");
        tickerValue = stringUtils.getValueOrDefault(tickerValue, notificationModel.content.summary);
        tickerValue = stringUtils.getValueOrDefault(tickerValue, notificationModel.content.body);
        tickerValue = stringUtils.getValueOrDefault(tickerValue, notificationModel.content.title);
        builder.setTicker(tickerValue);
    }

    private void setBadge(Context context, NotificationModel notificationModel, NotificationChannelModel channelModel, NotificationCompat.Builder builder) {
        if (notificationModel.content.badge != null){
            BadgeManager.getInstance().setGlobalBadgeCounter(context, notificationModel.content.badge);
            return;
        }
        if (!notificationModel.groupSummary && BooleanUtils.getInstance().getValue(channelModel.channelShowBadge)) {
            BadgeManager.getInstance().incrementGlobalBadgeCounter(context);
            builder.setNumber(1);
        }
    }

    private void setAutoCancel(NotificationModel notificationModel, NotificationCompat.Builder builder) {
        builder.setAutoCancel(BooleanUtils.getInstance().getValueOrDefault(notificationModel.content.autoDismissible, true));
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
        if (BooleanUtils.getInstance().getValue(channelModel.enableVibration)) {
            if (channelModel.vibrationPattern != null && channelModel.vibrationPattern.length > 0) {
                builder.setVibrate(channelModel.vibrationPattern);
            }
        } else {
            builder.setVibrate(new long[]{0});
        }
    }

    private void setLights(NotificationChannelModel channelModel, NotificationCompat.Builder builder) {
        if (BooleanUtils.getInstance().getValue(channelModel.enableLights)) {
            Integer ledColorValue = IntegerUtils.extractInteger(channelModel.ledColor, Color.WHITE);
            Integer ledOnMsValue = IntegerUtils.extractInteger(channelModel.ledOnMs, 300);
            Integer ledOffMsValue = IntegerUtils.extractInteger(channelModel.ledOffMs, 700);
            builder.setLights(ledColorValue, ledOnMsValue, ledOffMsValue);
        }
    }

    private void setVisibility(Context context, NotificationModel notificationModel, NotificationChannelModel channelModel, NotificationCompat.Builder builder) {

//        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.LOLLIPOP) {
            NotificationPrivacy privacy =
                notificationModel.content.privacy != null ?
                        notificationModel.content.privacy :
                        channelModel.defaultPrivacy;

            builder.setVisibility(NotificationPrivacy.toAndroidPrivacy(privacy));
//        }
    }

    private void setLayoutColor(Context context, NotificationModel notificationModel, NotificationChannelModel channelModel, NotificationCompat.Builder builder) {

        if (notificationModel.content.backgroundColor == null) {
            builder.setColor(getLayoutColor(notificationModel, channelModel));
        } else {
            builder.setColor(getBackgroundColor(notificationModel, channelModel, builder));
        }
    }

    private void setLargeIcon(Context context, NotificationModel notificationModel, NotificationCompat.Builder builder) {
        if (notificationModel.content.notificationLayout != NotificationLayout.BigPicture)
            if (!stringUtils.isNullOrEmpty(notificationModel.content.largeIcon)) {
                Bitmap largeIcon = bitmapUtils.getBitmapFromSource(
                        context,
                        notificationModel.content.largeIcon,
                        notificationModel.content.roundedLargeIcon);
                if (largeIcon != null)
                    builder.setLargeIcon(largeIcon);
            }
    }

    @SuppressLint("WrongConstant")
    @NonNull
    public void createActionButtons(
            Context context,
            Intent originalIntent,
            NotificationModel notificationModel,
            NotificationChannelModel channel,
            NotificationCompat.Builder builder
    ){
        if (ListUtils.isNullOrEmpty(notificationModel.actionButtons)) return;

        for (NotificationButtonModel buttonProperties : notificationModel.actionButtons) {

            // If reply is not available, do not show it
            if (
                Build.VERSION.SDK_INT < Build.VERSION_CODES.N /*Android 7*/ &&
                buttonProperties.requireInputText
            ){
                continue;
            }

            ActionType actionType = buttonProperties.actionType;

            Intent actionIntent = buildNotificationIntentFromNotificationModel(
                context,
                originalIntent,
                Definitions.NOTIFICATION_BUTTON_ACTION_PREFIX + "_" + buttonProperties.key,
                notificationModel,
                channel,
                buttonProperties.actionType,
                actionType == ActionType.Default ?
                    getMainTargetClass(context):
                    AwesomeNotifications.actionReceiverClass
            );

            if(buttonProperties.actionType == ActionType.Default)
                    actionIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);

            actionIntent.putExtra(Definitions.NOTIFICATION_AUTO_DISMISSIBLE, buttonProperties.autoDismissible);
            actionIntent.putExtra(Definitions.NOTIFICATION_SHOW_IN_COMPACT_VIEW, buttonProperties.showInCompactView);
            actionIntent.putExtra(Definitions.NOTIFICATION_ENABLED, buttonProperties.enabled);
            actionIntent.putExtra(Definitions.NOTIFICATION_BUTTON_KEY, buttonProperties.key);
            actionIntent.putExtra(Definitions.NOTIFICATION_ACTION_TYPE,
                    buttonProperties.actionType != null ?
                            buttonProperties.actionType.toString() : ActionType.Default.toString());

            PendingIntent actionPendingIntent = null;
            if (buttonProperties.enabled) {

                actionPendingIntent =
                    actionType == ActionType.Default ?
                        PendingIntent.getActivity(
                                context,
                                notificationModel.content.id,
                                actionIntent,
                                (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) ?
                                        PendingIntent.FLAG_MUTABLE | PendingIntent.FLAG_UPDATE_CURRENT :
                                        PendingIntent.FLAG_UPDATE_CURRENT)
                            :
                        PendingIntent.getBroadcast(
                                context,
                                notificationModel.content.id,
                                actionIntent,
                                (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) ?
                                        PendingIntent.FLAG_MUTABLE | PendingIntent.FLAG_UPDATE_CURRENT :
                                        PendingIntent.FLAG_UPDATE_CURRENT);
            }

            int iconResource = 0;
            if (!stringUtils.isNullOrEmpty(buttonProperties.icon)) {
                iconResource = bitmapUtils.getDrawableResourceId(context, buttonProperties.icon);
            }

            Spanned htmlLabel =
                HtmlCompat.fromHtml(
                        buttonProperties.isDangerousOption ?
                                "<font color=\"16711680\">" + buttonProperties.label + "</font>" :
                                (
                                        buttonProperties.color != null ?
                                                "<font color=\"" + buttonProperties.color.toString() + "\">" + buttonProperties.label + "</font>":
                                                buttonProperties.label
                                ),
                        HtmlCompat.FROM_HTML_MODE_LEGACY
                );

            if ( buttonProperties.requireInputText != null && buttonProperties.requireInputText ){

                RemoteInput remoteInput =
                    new RemoteInput
                        .Builder(buttonProperties.key)
                        .setLabel(buttonProperties.label)
                        .build();

                NotificationCompat.Action replyAction =
                    new NotificationCompat.Action
                        .Builder(
                            iconResource,
                            htmlLabel,
                            actionPendingIntent)
                        .addRemoteInput(remoteInput)
                        .build();

                builder.addAction(replyAction);

            } else {

                builder.addAction(
                    iconResource,
                    htmlLabel,
                    actionPendingIntent);
            }
        }
    }

    private void setSound(Context context, NotificationModel notificationModel, NotificationChannelModel channelModel, NotificationCompat.Builder builder) {

        Uri uri = null;

        if (
            !notificationModel.content.isRefreshNotification &&
            notificationModel.remoteHistory == null &&
            BooleanUtils.getInstance().getValue(channelModel.playSound)
        ) {
            String soundSource = stringUtils.isNullOrEmpty(notificationModel.content.customSound) ? channelModel.soundSource : notificationModel.content.customSound;
            uri = ChannelManager
                    .getInstance()
                    .retrieveSoundResourceUri(context, channelModel.defaultRingtoneType, soundSource);
        }

        builder.setSound(uri);
    }

    private void setSmallIcon(Context context, NotificationModel notificationModel, NotificationChannelModel channelModel, NotificationCompat.Builder builder) throws AwesomeNotificationsException {
        if (!stringUtils.isNullOrEmpty(notificationModel.content.icon)) {
            builder.setSmallIcon(bitmapUtils.getDrawableResourceId(context, notificationModel.content.icon));
        } else if (!stringUtils.isNullOrEmpty(channelModel.icon)) {
            builder.setSmallIcon(bitmapUtils.getDrawableResourceId(context, channelModel.icon));
        } else {
            String defaultIcon = DefaultsManager.getDefaultIcon(context);

            if (stringUtils.isNullOrEmpty(defaultIcon)) {

                // for backwards compatibility: this is for handling the old way references to the icon used to be kept but should be removed in future
                if (channelModel.iconResourceId != null) {
                    builder.setSmallIcon(channelModel.iconResourceId);
                } else {
                    try {
                        int defaultResource = context.getResources().getIdentifier(
                            "ic_launcher",
                            "mipmap",
                            AwesomeNotifications.getPackageName(context)
                        );

                        if (defaultResource > 0) {
                            builder.setSmallIcon(defaultResource);
                        }
                    } catch (Exception e){
                        e.printStackTrace();
                    }
                }
            } else {
                int resourceIndex = bitmapUtils.getDrawableResourceId(context, defaultIcon);
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
        ) return;

        String groupKey = getGroupKey(notificationModel.content, channelModel);

        if (!stringUtils.isNullOrEmpty(groupKey)) {
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

    private void setLayout(
            Context context,
            NotificationModel notificationModel,
            NotificationChannelModel channelModel,
            NotificationCompat.Builder builder
    ) throws AwesomeNotificationsException {
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

        if (!stringUtils.isNullOrEmpty(contentModel.bigPicture))
            bigPicture = bitmapUtils.getBitmapFromSource(context, contentModel.bigPicture, contentModel.roundedBigPicture);

        if (contentModel.hideLargeIconOnExpand)
            largeIcon = bigPicture != null ?
                bigPicture : (!stringUtils.isNullOrEmpty(contentModel.largeIcon) ?
                    bitmapUtils.getBitmapFromSource(
                            context,
                            contentModel.largeIcon,
                            contentModel.roundedLargeIcon || contentModel.roundedBigPicture) : null);
        else {
            boolean areEqual =
                    !stringUtils.isNullOrEmpty(contentModel.largeIcon) &&
                            contentModel.largeIcon.equals(contentModel.bigPicture);

            if(areEqual)
                largeIcon = bigPicture;
            else if(!stringUtils.isNullOrEmpty(contentModel.largeIcon))
                largeIcon =
                        bitmapUtils.getBitmapFromSource(context, contentModel.largeIcon, contentModel.roundedLargeIcon);
        }

        if (largeIcon != null)
            builder.setLargeIcon(largeIcon);

        if (bigPicture == null)
            return false;

        NotificationCompat.BigPictureStyle bigPictureStyle = new NotificationCompat.BigPictureStyle();

        bigPictureStyle.bigPicture(bigPicture);
        bigPictureStyle.bigLargeIcon(contentModel.hideLargeIconOnExpand ? null : largeIcon);

        if (!stringUtils.isNullOrEmpty(contentModel.title)) {
            CharSequence contentTitle = HtmlUtils.fromHtml(contentModel.title);
            bigPictureStyle.setBigContentTitle(contentTitle);
        }

        if (!stringUtils.isNullOrEmpty(contentModel.body)) {
            CharSequence summaryText = HtmlUtils.fromHtml(contentModel.body);
            bigPictureStyle.setSummaryText(summaryText);
        }

        builder.setStyle(bigPictureStyle);

        return true;
    }

    private Boolean setBigTextStyle(Context context, NotificationContentModel contentModel, NotificationCompat.Builder builder) {

        NotificationCompat.BigTextStyle bigTextStyle = new NotificationCompat.BigTextStyle();

        if (stringUtils.isNullOrEmpty(contentModel.body)) return false;

        CharSequence bigBody = HtmlUtils.fromHtml(contentModel.body);
        bigTextStyle.bigText(bigBody);

        if (!stringUtils.isNullOrEmpty(contentModel.summary)) {
            CharSequence bigSummary = HtmlUtils.fromHtml(contentModel.summary);
            bigTextStyle.setSummaryText(bigSummary);
        }

        if (!stringUtils.isNullOrEmpty(contentModel.title)) {
            CharSequence bigTitle = HtmlUtils.fromHtml(contentModel.title);
            bigTextStyle.setBigContentTitle(bigTitle);
        }

        builder.setStyle(bigTextStyle);

        return true;
    }

    private Boolean setInboxLayout(Context context, NotificationContentModel contentModel, NotificationCompat.Builder builder) {

        NotificationCompat.InboxStyle inboxStyle = new NotificationCompat.InboxStyle();

        if (stringUtils.isNullOrEmpty(contentModel.body)) return false;

        List<String> lines = new ArrayList<>(Arrays.asList(contentModel.body.split("\\r?\\n")));

        if (ListUtils.isNullOrEmpty(lines)) return false;

        CharSequence summary;
        if (stringUtils.isNullOrEmpty(contentModel.summary)) {
            summary = "+ " + lines.size() + " more";
        } else {
            summary = HtmlUtils.fromHtml(contentModel.body);
        }
        inboxStyle.setSummaryText(summary);

        if (!stringUtils.isNullOrEmpty(contentModel.title)) {
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

    public String getGroupKey(NotificationContentModel contentModel, NotificationChannelModel channelModel){
        return !stringUtils.isNullOrEmpty(contentModel.groupKey) ?
                contentModel.groupKey : channelModel.groupKey;
    }

    public static final ConcurrentHashMap<String, List<NotificationMessageModel>> messagingQueue = new ConcurrentHashMap<String, List<NotificationMessageModel>>();

    @SuppressWarnings("unchecked")
    private Boolean setMessagingLayout(Context context, boolean isGrouping, NotificationContentModel contentModel, NotificationChannelModel channelModel, NotificationCompat.Builder builder) throws AwesomeNotificationsException {
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
                (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) ?
                        contentModel.title : contentModel.summary,
                contentModel.body,
                contentModel.largeIcon
        );

        List<NotificationMessageModel> messages = contentModel.messages;
        if(ListUtils.isNullOrEmpty(messages)) {
            messages = messagingQueue.get(messageQueueKey);
            if (messages == null)
                messages = new ArrayList<>();
        }

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

                String personIcon = message.largeIcon != null? message.largeIcon :contentModel.largeIcon;
                if(!stringUtils.isNullOrEmpty(personIcon)){
                    Bitmap largeIcon = bitmapUtils.getBitmapFromSource(
                            context,
                            personIcon,
                            contentModel.roundedLargeIcon);
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
            !stringUtils.isNullOrEmpty(contentModel.summary)
        ){
            messagingStyle.setConversationTitle(contentModel.summary);
            messagingStyle.setGroupConversation(isGrouping);
        }

        builder.setStyle((NotificationCompat.Style) messagingStyle);
        /*}
        else {
            if(stringUtils.isNullOrEmpty(groupKey)){
                builder.setGroup("Messaging."+groupKey);
            }
        }*/

        return true;
    }

    private Boolean setMediaPlayerLayout(Context context, NotificationContentModel contentModel, List<NotificationButtonModel> actionButtons, NotificationCompat.Builder builder) throws AwesomeNotificationsException {

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

            if(mediaSession == null)
                throw ExceptionFactory
                        .getInstance()
                        .createNewAwesomeException(
                                TAG,
                                ExceptionCode.CODE_INITIALIZATION_EXCEPTION,
                                "There is no valid media session available",
                                ExceptionCode.DETAILED_INSUFFICIENT_REQUIREMENTS);

            mediaSession.setMetadata(
                    new MediaMetadataCompat.Builder()
                            .putString(MediaMetadataCompat.METADATA_KEY_TITLE, contentModel.title)
                            .putString(MediaMetadataCompat.METADATA_KEY_ARTIST, contentModel.body)
                            .build());
        }

        builder.setStyle(
                new MediaStyle()
                        .setMediaSession(mediaSession.getSessionToken())
                        .setShowActionsInCompactView(showInCompactView)
                        .setShowCancelButton(true));

        if (!stringUtils.isNullOrEmpty(contentModel.summary))
            builder.setSubText(contentModel.summary);

        if(contentModel.progress != null && IntegerUtils.isBetween(contentModel.progress, 0, 100))
            builder.setProgress(
                100,
                Math.max(0, Math.min(100, IntegerUtils.extractInteger(contentModel.progress, 0))),
                contentModel.progress == null);

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
