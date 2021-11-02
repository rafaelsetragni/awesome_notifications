package me.carda.awesome_notifications;

import android.app.Application;
import android.app.Application.ActivityLifecycleCallbacks;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.os.Build;
import android.os.Bundle;
import android.provider.Settings;
import android.support.v4.media.session.MediaSessionCompat;

import io.flutter.Log;

//import com.google.android.gms.tasks.OnCompleteListener;
//import com.google.android.gms.tasks.Task;
//import com.google.firebase.FirebaseApp;
//import com.google.firebase.messaging.FirebaseMessaging;

import java.io.Serializable;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.Date;
import java.util.List;
import java.util.Map;

import androidx.annotation.NonNull;
import androidx.core.app.NotificationManagerCompat;
import androidx.lifecycle.*;
import androidx.localbroadcastmanager.content.LocalBroadcastManager;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugin.common.PluginRegistry.Registrar;

import android.app.Activity;

import me.carda.awesome_notifications.notifications.BitmapResourceDecoder;
import me.carda.awesome_notifications.notifications.models.DefaultsModel;
import me.carda.awesome_notifications.notifications.models.NotificationCalendarModel;
import me.carda.awesome_notifications.notifications.models.NotificationIntervalModel;
import me.carda.awesome_notifications.notifications.models.NotificationScheduleModel;
import me.carda.awesome_notifications.notifications.models.NotificationModel;
import me.carda.awesome_notifications.notifications.enumerators.MediaSource;
import me.carda.awesome_notifications.notifications.enumerators.NotificationLifeCycle;
import me.carda.awesome_notifications.notifications.enumerators.NotificationSource;
import me.carda.awesome_notifications.notifications.exceptions.AwesomeNotificationException;

import me.carda.awesome_notifications.notifications.NotificationBuilder;

import me.carda.awesome_notifications.notifications.managers.ChannelManager;
import me.carda.awesome_notifications.notifications.managers.CreatedManager;
import me.carda.awesome_notifications.notifications.managers.DefaultsManager;
import me.carda.awesome_notifications.notifications.managers.DismissedManager;
import me.carda.awesome_notifications.notifications.managers.DisplayedManager;

import me.carda.awesome_notifications.notifications.managers.ScheduleManager;
import me.carda.awesome_notifications.notifications.models.NotificationChannelModel;
import me.carda.awesome_notifications.notifications.models.returnedData.ActionReceived;
import me.carda.awesome_notifications.notifications.models.returnedData.NotificationReceived;

import me.carda.awesome_notifications.notifications.NotificationSender;
import me.carda.awesome_notifications.notifications.NotificationScheduler;

import me.carda.awesome_notifications.utils.BooleanUtils;
import me.carda.awesome_notifications.utils.DateUtils;
import me.carda.awesome_notifications.utils.JsonUtils;
import me.carda.awesome_notifications.utils.ListUtils;
import me.carda.awesome_notifications.utils.MapUtils;
import me.carda.awesome_notifications.utils.MediaUtils;
import me.carda.awesome_notifications.utils.StringUtils;


import me.carda.awesome_notifications.services.ForegroundService;

/**
 * AwesomeNotificationsPlugin
 **/
public class AwesomeNotificationsPlugin
        extends BroadcastReceiver
        implements FlutterPlugin, MethodCallHandler, PluginRegistry.NewIntentListener, ActivityAware, ActivityLifecycleCallbacks {

    public static Boolean debug = false;

    public static Result pendingAuthorizationReturn;
    public static Boolean hasGoneToAuthorizationPage = false;

    public static Boolean hasGooglePlayServices;
    private static String mainTargetClassName;
    public static NotificationLifeCycle appLifeCycle = NotificationLifeCycle.AppKilled;

    private static final String TAG = "AwesomeNotificationsPlugin";

    private Activity initialActivity;
    private MethodChannel pluginChannel;
    private Context applicationContext;

    public static MediaSessionCompat mediaSession;

    public static String getMainTargetClassName() {
        return mainTargetClassName;
    }


    private boolean checkGooglePlayServices() {
        // TODO MISSING IMPLEMENTATION. FIREBASE SERVICES DEMANDS GOOGLE PLAY SERVICES.
        /*
        final int status = GooglePlayServicesUtil.isGooglePlayServicesAvailable(this);
        if (status != ConnectionResult.SUCCESS) {
            Log.e(TAG, GooglePlayServicesUtil.getErrorString(status));

            // ask user to update google play services.
            Dialog dialog = GooglePlayServicesUtil.getErrorDialog(status, this, 1);

            return false;
        } else {
            Log.i(TAG, GooglePlayServicesUtil.getErrorString(status));
            // google play services is updated.
            //your code goes here...
            return true;
        }*/

        /// Firebase services depends on Google Play services
        return false;
    }

    @Override
    public boolean onNewIntent(Intent intent) {
        //Log.d(TAG, "onNewIntent called");
        return receiveNotificationAction(intent);
    }

    // https://flutter.dev/docs/development/packages-and-plugins/plugin-api-migration
    // FOR OLDER FLUTTER VERSIONS (1.11 releases and bellow)
    public static void registerWith(Registrar registrar) {
        AwesomeNotificationsPlugin awesomeNotificationsPlugin = new AwesomeNotificationsPlugin();

        awesomeNotificationsPlugin.initialActivity = registrar.activity();

        awesomeNotificationsPlugin.AttachAwesomeNotificationsPlugin(
                registrar.context(),
                new MethodChannel(
                        registrar.messenger(),
                        Definitions.CHANNEL_FLUTTER_PLUGIN
                )
        );
    }

    // FOR NEWER FLUTTER VERSIONS (1.12 releases and above)
    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {

        AttachAwesomeNotificationsPlugin(
                flutterPluginBinding.getApplicationContext(),
                new MethodChannel(
                        flutterPluginBinding.getBinaryMessenger(),
                        Definitions.CHANNEL_FLUTTER_PLUGIN
                )
        );
    }

    private void AttachAwesomeNotificationsPlugin(Context context, MethodChannel channel) {

        this.applicationContext = context;
        pluginChannel = channel;

        pluginChannel.setMethodCallHandler(this);

        hasGooglePlayServices = checkGooglePlayServices();

        IntentFilter intentFilter = new IntentFilter();

        intentFilter.addAction(Definitions.EXTRA_BROADCAST_FCM_TOKEN);
        intentFilter.addAction(Definitions.BROADCAST_CREATED_NOTIFICATION);
        intentFilter.addAction(Definitions.BROADCAST_DISPLAYED_NOTIFICATION);
        intentFilter.addAction(Definitions.BROADCAST_DISMISSED_NOTIFICATION);
        intentFilter.addAction(Definitions.BROADCAST_KEEP_ON_TOP);
        intentFilter.addAction(Definitions.BROADCAST_MEDIA_BUTTON);

        LocalBroadcastManager manager = LocalBroadcastManager.getInstance(applicationContext);
        manager.registerReceiver(this, intentFilter);

        mediaSession = new MediaSessionCompat(applicationContext, "PUSH_MEDIA");

        getApplicationLifeCycle();

        if (AwesomeNotificationsPlugin.debug)
            Log.d(TAG, "Awesome Notifications attached for Android " + Build.VERSION.SDK_INT);

        NotificationScheduler.refreshScheduleNotifications(context);
        // enableFirebase(context);
    }

    @Override
    public void onAttachedToActivity(ActivityPluginBinding activityPluginBinding) {
        initialActivity = activityPluginBinding.getActivity();
        activityPluginBinding.addOnNewIntentListener(this);
        getApplicationLifeCycle();

        Application application = initialActivity.getApplication();
        application.registerActivityLifecycleCallbacks(this);

        Intent intent = initialActivity.getIntent();
        mainTargetClassName = intent.getComponent().getClassName();

        if (AwesomeNotificationsPlugin.debug)
            Log.d(TAG, "Notification Lifecycle: (onAttachedToActivity)" + appLifeCycle.toString());
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        pluginChannel.setMethodCallHandler(null);
        getApplicationLifeCycle();

        if (AwesomeNotificationsPlugin.debug)
            Log.d(TAG, "Notification Lifecycle: (onDetachedFromEngine)" + appLifeCycle.toString());
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {
        getApplicationLifeCycle();

        if (AwesomeNotificationsPlugin.debug)
            Log.d(TAG, "Notification Lifecycle: (onDetachedFromActivityForConfigChanges)" + appLifeCycle.toString());
    }

    @Override
    public void onReattachedToActivityForConfigChanges(ActivityPluginBinding activityPluginBinding) {
        getApplicationLifeCycle();

        if (AwesomeNotificationsPlugin.debug)
            Log.d(TAG, "Notification Lifecycle: (onReattachedToActivityForConfigChanges)" + appLifeCycle.toString());
    }

    @Override
    public void onDetachedFromActivity() {
        getApplicationLifeCycle();

        if (AwesomeNotificationsPlugin.debug)
            Log.d(TAG, "Notification Lifecycle: (onDetachedFromActivity)" + appLifeCycle.toString());
    }

    // BroadcastReceiver by other classes.
    @Override
    public void onReceive(Context context, Intent intent) {
        getApplicationLifeCycle();

        String action = intent.getAction();
        switch (action) {

            case Definitions.BROADCAST_CREATED_NOTIFICATION:
                onBroadcastNotificationCreated(intent);
                return;

            case Definitions.BROADCAST_DISPLAYED_NOTIFICATION:
                onBroadcastNotificationDisplayed(intent);
                return;

            case Definitions.BROADCAST_DISMISSED_NOTIFICATION:
                onBroadcastNotificationDismissed(intent);
                return;

            case Definitions.BROADCAST_KEEP_ON_TOP:
                onBroadcastKeepOnTopActionNotification(intent);
                return;

            case Definitions.BROADCAST_MEDIA_BUTTON:
                onBroadcastMediaButton(intent);
                return;

            default:
                if (AwesomeNotificationsPlugin.debug)
                    Log.d(TAG, "Received unknown action: " + (
                            StringUtils.isNullOrEmpty(action) ? "empty" : action));
        }
    }

    private void onBroadcastNotificationCreated(Intent intent) {

        try {
            Serializable serializable = intent.getSerializableExtra(Definitions.EXTRA_BROADCAST_MESSAGE);

            @SuppressWarnings("unchecked")
            Map<String, Object> content = (serializable instanceof Map ? (Map<String, Object>) serializable : null);
            if (content == null) return;

            NotificationReceived received = new NotificationReceived().fromMap(content);
            received.validate(applicationContext);

            CreatedManager.removeCreated(applicationContext, received.id);
            CreatedManager.commitChanges(applicationContext);

            pluginChannel.invokeMethod(Definitions.CHANNEL_METHOD_NOTIFICATION_CREATED, content);

            if (AwesomeNotificationsPlugin.debug)
                Log.d(TAG, "Notification created");

        } catch (Exception e) {
            if (AwesomeNotificationsPlugin.debug)
                Log.d(TAG, e.getMessage());
            e.printStackTrace();
        }
    }

    private void onBroadcastKeepOnTopActionNotification(Intent intent) {
        try {

            Serializable serializable = intent.getSerializableExtra(Definitions.EXTRA_BROADCAST_MESSAGE);
            pluginChannel.invokeMethod(Definitions.CHANNEL_METHOD_RECEIVED_ACTION, serializable);

            if (AwesomeNotificationsPlugin.debug)
                Log.d(TAG, "Notification action received");

        } catch (Exception e) {
            if (AwesomeNotificationsPlugin.debug)
                Log.d(TAG, e.getMessage());
            e.printStackTrace();
        }
    }

    private void onBroadcastMediaButton(Intent intent) {
        try {

            Serializable serializable = intent.getSerializableExtra(Definitions.EXTRA_BROADCAST_MESSAGE);
            pluginChannel.invokeMethod(Definitions.CHANNEL_METHOD_MEDIA_BUTTON, serializable);

            if (AwesomeNotificationsPlugin.debug)
                Log.d(TAG, "Notification action received");

        } catch (Exception e) {
            if (AwesomeNotificationsPlugin.debug)
                Log.d(TAG, e.getMessage());
            e.printStackTrace();
        }
    }

    private void onBroadcastNotificationDisplayed(Intent intent) {
        try {

            Serializable serializable = intent.getSerializableExtra(Definitions.EXTRA_BROADCAST_MESSAGE);

            @SuppressWarnings("unchecked")
            Map<String, Object> content = (serializable instanceof Map ? (Map<String, Object>) serializable : null);
            if (content == null) return;

            NotificationReceived received = new NotificationReceived().fromMap(content);
            received.validate(applicationContext);

            DisplayedManager.removeDisplayed(applicationContext, received.id);
            DisplayedManager.commitChanges(applicationContext);

            pluginChannel.invokeMethod(Definitions.CHANNEL_METHOD_NOTIFICATION_DISPLAYED, content);

            if (AwesomeNotificationsPlugin.debug)
                Log.d(TAG, "Notification displayed");

        } catch (Exception e) {
            if (AwesomeNotificationsPlugin.debug)
                Log.d(TAG, e.getMessage());
            e.printStackTrace();
        }
    }

    private void onBroadcastNotificationDismissed(Intent intent) {
        try {

            Serializable serializable = intent.getSerializableExtra(Definitions.EXTRA_BROADCAST_MESSAGE);

            @SuppressWarnings("unchecked")
            Map<String, Object> content = (serializable instanceof Map ? (Map<String, Object>) serializable : null);
            if (content == null) return;

            ActionReceived received = new ActionReceived().fromMap(content);
            received.validate(applicationContext);

            DismissedManager.removeDismissed(applicationContext, received.id);
            DisplayedManager.commitChanges(applicationContext);

            pluginChannel.invokeMethod(Definitions.CHANNEL_METHOD_NOTIFICATION_DISMISSED, content);

            if (AwesomeNotificationsPlugin.debug)
                Log.d(TAG, "Notification dismissed");

        } catch (Exception e) {
            if (AwesomeNotificationsPlugin.debug)
                Log.d(TAG, e.getMessage());
            e.printStackTrace();
        }
    }

    private void recoverNotificationCreated(Context context) {
        List<NotificationReceived> lostCreated = CreatedManager.listCreated(context);

        if (lostCreated != null) {
            for (NotificationReceived created : lostCreated) {
                try {

                    created.validate(applicationContext);
                    pluginChannel.invokeMethod(Definitions.CHANNEL_METHOD_NOTIFICATION_CREATED, created.toMap());
                    CreatedManager.removeCreated(context, created.id);
                    CreatedManager.commitChanges(context);

                } catch (AwesomeNotificationException e) {
                    if (AwesomeNotificationsPlugin.debug)
                        Log.d(TAG, e.getMessage());
                    e.printStackTrace();
                }
            }
        }
    }

    private void recoverNotificationDisplayed(Context context) {
        List<NotificationReceived> lostDisplayed = DisplayedManager.listDisplayed(context);

        if (lostDisplayed != null) {
            for (NotificationReceived displayed : lostDisplayed) {
                try {

                    displayed.validate(applicationContext);
                    pluginChannel.invokeMethod(Definitions.CHANNEL_METHOD_NOTIFICATION_DISPLAYED, displayed.toMap());
                    DisplayedManager.removeDisplayed(context, displayed.id);
                    DisplayedManager.commitChanges(context);

                } catch (AwesomeNotificationException e) {
                    if (AwesomeNotificationsPlugin.debug)
                        Log.d(TAG, e.getMessage());
                    e.printStackTrace();
                }
            }
        }
    }

    private void recoverNotificationDismissed(Context context) {
        List<ActionReceived> lostDismissed = DismissedManager.listDismissed(context);

        if (lostDismissed != null) {
            for (ActionReceived received : lostDismissed) {
                try {

                    received.validate(applicationContext);
                    pluginChannel.invokeMethod(Definitions.CHANNEL_METHOD_NOTIFICATION_DISMISSED, received.toMap());
                    DismissedManager.removeDismissed(context, received.id);
                    DismissedManager.commitChanges(context);

                } catch (AwesomeNotificationException e) {
                    if (AwesomeNotificationsPlugin.debug)
                        Log.d(TAG, e.getMessage());
                    e.printStackTrace();
                }
            }
        }
    }

    @Override
    public void onMethodCall(final MethodCall call, final Result result) {

        getApplicationLifeCycle();

        try {

            switch (call.method) {

                case Definitions.CHANNEL_METHOD_INITIALIZE:
                    channelMethodInitialize(call, result);
                    return;

                case Definitions.CHANNEL_METHOD_GET_DRAWABLE_DATA:
                    channelMethodGetDrawableData(call, result);
                    return;

                case Definitions.CHANNEL_METHOD_IS_NOTIFICATION_ALLOWED:
                    channelIsNotificationAllowed(call, result);
                    return;

                case Definitions.CHANNEL_METHOD_SHOW_NOTIFICATION_PAGE:
                    channelShowNotificationPage(call, result);
                    return;

                case Definitions.CHANNEL_METHOD_REQUEST_NOTIFICATIONS:
                    channelRequestNotification(call, result);
                    return;

                case Definitions.CHANNEL_METHOD_CREATE_NOTIFICATION:
                    channelMethodCreateNotification(call, result);
                    return;

                case Definitions.CHANNEL_METHOD_LIST_ALL_SCHEDULES:
                    channelMethodListAllSchedules(call, result);
                    return;

                case Definitions.CHANNEL_METHOD_GET_NEXT_DATE:
                    channelMethodGetNextDate(call, result);
                    return;

                case Definitions.CHANNEL_METHOD_GET_LOCAL_TIMEZONE_IDENTIFIER:
                    channelMethodGetLocalTimeZone(call, result);
                    return;

                case Definitions.CHANNEL_METHOD_GET_UTC_TIMEZONE_IDENTIFIER:
                    channelMethodGetUtcTimeZone(call, result);
                    return;

                case Definitions.CHANNEL_METHOD_SET_NOTIFICATION_CHANNEL:
                    channelMethodSetChannel(call, result);
                    return;

                case Definitions.CHANNEL_METHOD_REMOVE_NOTIFICATION_CHANNEL:
                    channelMethodRemoveChannel(call, result);
                    return;

                case Definitions.CHANNEL_METHOD_GET_BADGE_COUNT:
                    channelMethodGetBadgeCounter(call, result);
                    return;

                case Definitions.CHANNEL_METHOD_SET_BADGE_COUNT:
                    channelMethodSetBadgeCounter(call, result);
                    return;

                case Definitions.CHANNEL_METHOD_INCREMENT_BADGE_COUNT:
                    channelMethodIncrementBadge(call, result);
                    return;

                case Definitions.CHANNEL_METHOD_DECREMENT_BADGE_COUNT:
                    channelMethodDecrementBadge(call, result);
                    return;

                case Definitions.CHANNEL_METHOD_RESET_BADGE:
                    channelMethodResetBadge(call, result);
                    return;

                case Definitions.CHANNEL_METHOD_DISMISS_NOTIFICATION:
                    channelMethodDismissNotification(call, result);
                    return;

                case Definitions.CHANNEL_METHOD_CANCEL_NOTIFICATION:
                    channelMethodCancelNotification(call, result);
                    return;

                case Definitions.CHANNEL_METHOD_CANCEL_SCHEDULE:
                    channelMethodCancelSchedule(call, result);
                    return;

                case Definitions.CHANNEL_METHOD_DISMISS_NOTIFICATIONS_BY_CHANNEL_KEY:
                    channelMethodDismissNotificationsByChannelKey(call, result);
                    return;

                case Definitions.CHANNEL_METHOD_CANCEL_SCHEDULES_BY_CHANNEL_KEY:
                    channelMethodCancelSchedulesByChannelKey(call, result);
                    return;

                case Definitions.CHANNEL_METHOD_CANCEL_NOTIFICATIONS_BY_CHANNEL_KEY:
                    channelMethodCancelNotificationsByChannelKey(call, result);
                    return;

                case Definitions.CHANNEL_METHOD_DISMISS_NOTIFICATIONS_BY_GROUP_KEY:
                    channelMethodDismissNotificationsByGroupKey(call, result);
                    return;

                case Definitions.CHANNEL_METHOD_CANCEL_SCHEDULES_BY_GROUP_KEY:
                    channelMethodCancelSchedulesByGroupKey(call, result);
                    return;

                case Definitions.CHANNEL_METHOD_CANCEL_NOTIFICATIONS_BY_GROUP_KEY:
                    channelMethodCancelNotificationsByGroupKey(call, result);
                    return;

                case Definitions.CHANNEL_METHOD_DISMISS_ALL_NOTIFICATIONS:
                    channelMethodDismissAllNotifications(call, result);
                    return;

                case Definitions.CHANNEL_METHOD_CANCEL_ALL_SCHEDULES:
                    channelMethodCancelAllSchedules(call, result);
                    return;

                case Definitions.CHANNEL_METHOD_CANCEL_ALL_NOTIFICATIONS:
                    channelMethodCancelAllNotifications(call, result);
                    return;

                case Definitions.CHANNEL_METHOD_START_FOREGROUND:
                    channelMethodStartForeground(call, result);
                    return;

                case Definitions.CHANNEL_METHOD_STOP_FOREGROUND:
                    channelMethodStopForeground(call, result);
                    return;

                default:
                    result.notImplemented();
            }

        } catch (Exception e) {
            if (AwesomeNotificationsPlugin.debug)
                Log.d(TAG, e.getMessage());

            result.error(call.method, e.getMessage(), e);
            e.printStackTrace();
        }
    }

    private void channelMethodStartForeground(MethodCall call, Result result) throws Exception {
        // We don't do any checks here if the notification channel belonging to the notification is disabled
        // because for an foreground service, it doesn't matter
        Map<String, Object> notificationData = call.<Map<String, Object>>argument("notificationData");
        Integer startType = call.<Integer>argument("startType");
        Boolean hasForegroundServiceType = call.<Boolean>argument("hasForegroundServiceType");
        Integer foregroundServiceType = call.<Integer>argument("foregroundServiceType");
        if (notificationData != null && startType != null && hasForegroundServiceType != null && foregroundServiceType != null) {
            ForegroundService.StartParameter parameter =
                    new ForegroundService.StartParameter(notificationData, startType, hasForegroundServiceType, foregroundServiceType);
            Intent intent = new Intent(applicationContext, ForegroundService.class);
            intent.putExtra(ForegroundService.StartParameter.EXTRA, parameter);
            if (Build.VERSION.SDK_INT >=  Build.VERSION_CODES.O /*Android 8*/) {
                applicationContext.startForegroundService(intent);
            } else {
                applicationContext.startService(intent);
            }
            result.success(null);
        } else {
            throw new IllegalArgumentException("An argument passed to startForeground was null!");
        }
    }

    private void channelMethodStopForeground(MethodCall call, Result result) {
        applicationContext.stopService(new Intent(applicationContext, ForegroundService.class));
        result.success(null);
    }

    private void channelMethodGetDrawableData(MethodCall call, Result result) throws Exception {

        String bitmapReference = call.arguments();

        BitmapResourceDecoder bitmapResourceDecoder = new BitmapResourceDecoder(
                applicationContext,
                result,
                bitmapReference
        );

        bitmapResourceDecoder.execute();
    }

    private void channelMethodListAllSchedules(MethodCall call, Result result) throws Exception {
        List<NotificationModel> activeSchedules = ScheduleManager.listSchedules(applicationContext);
        List<Map<String, Object>> listSerialized = new ArrayList<>();

        if (activeSchedules != null) {
            for (NotificationModel notificationModel : activeSchedules) {
                Map<String, Object> serialized = notificationModel.toMap();
                listSerialized.add(serialized);
            }
        }

        result.success(listSerialized);
    }

    private void channelMethodGetNextDate(MethodCall call, Result result) throws Exception {

        @SuppressWarnings("unchecked")
        Map<String, Object> data = MapUtils.extractArgument(call.arguments(), Map.class).orNull();

        assert data != null;

        @SuppressWarnings("unchecked")
        Map<String, Object> scheduleData = (Map<String, Object>) data.get(Definitions.NOTIFICATION_MODEL_SCHEDULE);
        String fixedDateString = (String) data.get(Definitions.NOTIFICATION_INITIAL_FIXED_DATE);

        if (scheduleData == null)
            throw new AwesomeNotificationException("Schedule data is invalid");

        NotificationScheduleModel scheduleModel = NotificationScheduleModel.getScheduleModelFromMap(scheduleData);

        if (scheduleModel == null)
            throw new AwesomeNotificationException("Schedule data is invalid");

        Date fixedDate = null;

        if (!StringUtils.isNullOrEmpty(fixedDateString))
            fixedDate = DateUtils.stringToDate(fixedDateString, scheduleModel.timeZone);

        Calendar nextValidDate = scheduleModel.getNextValidDate(fixedDate);

        String finalValidDateString = null;
        if (nextValidDate != null)
            finalValidDateString = DateUtils.dateToString(nextValidDate.getTime(), scheduleModel.timeZone);

        result.success(finalValidDateString);
        return;
    }

    private void channelMethodGetLocalTimeZone(MethodCall call, Result result) throws Exception {
        result.success(DateUtils.localTimeZone.getID());
    }

    private void channelMethodGetUtcTimeZone(MethodCall call, Result result) throws Exception {
        result.success(DateUtils.utcTimeZone.getID());
    }

    private void channelMethodSetChannel(MethodCall call, Result result) throws Exception {

        @SuppressWarnings("unchecked")
        Map<String, Object> channelData = MapUtils.extractArgument(call.arguments(), Map.class).orNull();
        assert channelData != null;

        NotificationChannelModel channelModel = new NotificationChannelModel().fromMap(channelData);
        Boolean forceUpdate = BooleanUtils.getValue((Boolean) channelData.get(Definitions.CHANNEL_FORCE_UPDATE));

        if (channelModel == null) {
            throw new AwesomeNotificationException("Channel is invalid");
        } else {

            ChannelManager.saveChannel(applicationContext, channelModel, forceUpdate);
            result.success(true);

            ChannelManager.commitChanges(applicationContext);
        }
    }

    private void channelMethodRemoveChannel(MethodCall call, Result result) throws Exception {
        String channelKey = call.arguments();

        if (StringUtils.isNullOrEmpty(channelKey)) {
            throw new AwesomeNotificationException("Empty channel key");
        } else {
            Boolean removed = ChannelManager.removeChannel(applicationContext, channelKey);

            if (removed) {
                if (AwesomeNotificationsPlugin.debug)
                    Log.d(TAG, "Channel removed");
                result.success(true);
            } else {
                if (AwesomeNotificationsPlugin.debug)
                    Log.d(TAG, "Channel '" + channelKey + "' not found");
                result.success(false);
            }

            ChannelManager.commitChanges(applicationContext);
        }
    }

    private void channelMethodGetBadgeCounter(MethodCall call, Result result) throws Exception {
        Integer badgeCount = NotificationBuilder.getGlobalBadgeCounter(applicationContext);
        // Android resets badges automatically when all notifications are cleared
        result.success(badgeCount);
    }

    private void channelMethodSetBadgeCounter(MethodCall call, Result result) throws Exception {
        @SuppressWarnings("unchecked")
        Integer count = MapUtils.extractArgument(call.arguments(), Integer.class).orNull();

        if (count == null || count < 0)
            throw new AwesomeNotificationException("Invalid Badge value");

        // Android resets badges automatically when all notifications are cleared
        NotificationBuilder.setGlobalBadgeCounter(applicationContext, count);
        result.success(true);
    }

    private void channelMethodResetBadge(MethodCall call, Result result) throws Exception {
        NotificationBuilder.resetGlobalBadgeCounter(applicationContext);
        result.success(null);
    }

    private void channelMethodIncrementBadge(MethodCall call, Result result) throws Exception {
        Integer badgeCount = NotificationBuilder.incrementGlobalBadgeCounter(applicationContext);
        result.success(badgeCount);
    }

    private void channelMethodDecrementBadge(MethodCall call, Result result) throws Exception {
        Integer badgeCount = NotificationBuilder.decrementGlobalBadgeCounter(applicationContext);
        result.success(badgeCount);
    }

    private void channelMethodCancelSchedule(MethodCall call, Result result) throws Exception {

        Integer notificationId = call.arguments();
        if (notificationId == null || notificationId < 0)
            throw new AwesomeNotificationException("Invalid notification id");

        NotificationScheduler.cancelSchedule(applicationContext, notificationId);

        if (AwesomeNotificationsPlugin.debug)
            Log.d(TAG, "Schedule id " + notificationId + " cancelled");

        result.success(true);
    }

    private void channelMethodDismissNotificationsByChannelKey(@NonNull MethodCall call, Result result) throws Exception {

        String channelKey = call.arguments();
        if(StringUtils.isNullOrEmpty(channelKey))
            throw new AwesomeNotificationException("Invalid channel key");

        NotificationSender.dismissNotificationsByChannelKey(applicationContext, channelKey);

        if(AwesomeNotificationsPlugin.debug)
            Log.d(TAG, "Notifications from channel "+channelKey+" dismissed");

        result.success(true);
    }

    private void channelMethodCancelSchedulesByChannelKey(@NonNull MethodCall call, Result result) throws Exception {

        String channelKey = call.arguments();
        if(StringUtils.isNullOrEmpty(channelKey))
            throw new AwesomeNotificationException("Invalid channel key");

        NotificationScheduler.cancelSchedulesByChannelKey(applicationContext, channelKey);

        if(AwesomeNotificationsPlugin.debug)
            Log.d(TAG, "Scheduled Notifications from channel "+channelKey+" canceled");

        result.success(true);
    }

    private void channelMethodCancelNotificationsByChannelKey(@NonNull MethodCall call, Result result) throws Exception {

        String channelKey = call.arguments();
        if(StringUtils.isNullOrEmpty(channelKey))
            throw new AwesomeNotificationException("Invalid channel key");

        NotificationSender.dismissNotificationsByChannelKey(applicationContext, channelKey);
        NotificationScheduler.cancelSchedulesByChannelKey(applicationContext, channelKey);

        if(AwesomeNotificationsPlugin.debug)
            Log.d(TAG, "Notifications and schedules from channel "+channelKey+" canceled");

        result.success(true);
    }

    private void channelMethodDismissNotificationsByGroupKey(@NonNull MethodCall call, Result result) throws Exception {

        String groupKey = call.arguments();
        if(StringUtils.isNullOrEmpty(groupKey))
            throw new AwesomeNotificationException("Invalid group key");

        NotificationSender.dismissNotificationsByGroupKey(applicationContext, groupKey);

        if(AwesomeNotificationsPlugin.debug)
            Log.d(TAG, "Notifications from group "+groupKey+" dismissed");

        result.success(true);
    }

    private void channelMethodCancelSchedulesByGroupKey(@NonNull MethodCall call, Result result) throws Exception {

        String groupKey = call.arguments();
        if(StringUtils.isNullOrEmpty(groupKey))
            throw new AwesomeNotificationException("Invalid group key");

        NotificationScheduler.cancelSchedulesByGroupKey(applicationContext, groupKey);

        if(AwesomeNotificationsPlugin.debug)
            Log.d(TAG, "Scheduled Notifications from group "+groupKey+" canceled");

        result.success(true);
    }

    private void channelMethodCancelNotificationsByGroupKey(@NonNull MethodCall call, Result result) throws Exception {

        String groupKey = call.arguments();
        if(StringUtils.isNullOrEmpty(groupKey))
            throw new AwesomeNotificationException("Invalid group key");

        NotificationSender.dismissNotificationsByGroupKey(applicationContext, groupKey);
        NotificationScheduler.cancelSchedulesByGroupKey(applicationContext, groupKey);

        if(AwesomeNotificationsPlugin.debug)
            Log.d(TAG, "Notifications and schedules from group "+groupKey+" canceled");

        result.success(true);
    }

    private void channelMethodCancelAllSchedules(MethodCall call, Result result) throws Exception {

        NotificationScheduler.cancelAllSchedules(applicationContext);
        if (AwesomeNotificationsPlugin.debug)
            Log.d(TAG, "All notifications scheduled was cancelled");

        result.success(true);
    }

    private void channelMethodDismissNotification(MethodCall call, Result result) throws Exception {

        Integer notificationId = call.arguments();
        if (notificationId == null || notificationId < 0)
            throw new AwesomeNotificationException("Invalid notification id");

        NotificationSender.dismissNotification(applicationContext, notificationId);

        if (AwesomeNotificationsPlugin.debug)
            Log.d(TAG, "Notification id " + notificationId + " dismissed");

        result.success(true);
    }

    private void channelMethodCancelNotification(MethodCall call, Result result) throws Exception {

        Integer notificationId = call.arguments();
        if (notificationId == null || notificationId < 0)
            throw new AwesomeNotificationException("Invalid notification id");

        NotificationScheduler.cancelSchedule(applicationContext, notificationId);
        NotificationSender.dismissNotification(applicationContext, notificationId);

        if (AwesomeNotificationsPlugin.debug)
            Log.d(TAG, "Notification id " + notificationId + " cancelled");

        result.success(true);
    }

    private void channelMethodDismissAllNotifications(MethodCall call, Result result) throws Exception {

        NotificationSender.dismissAllNotifications(applicationContext);
        if (AwesomeNotificationsPlugin.debug)
            Log.d(TAG, "All notifications was dismissed");

        result.success(true);
    }


    private void channelMethodCancelAllNotifications(MethodCall call, Result result) throws Exception {

        NotificationScheduler.cancelAllSchedules(applicationContext);
        NotificationSender.dismissAllNotifications(applicationContext);

        if (AwesomeNotificationsPlugin.debug)
            Log.d(TAG, "All notifications was cancelled");

        result.success(true);
    }

    private void channelIsNotificationAllowed(MethodCall call, Result result) throws Exception {
        result.success(NotificationBuilder.isNotificationEnabled(applicationContext));
    }

    private void channelShowNotificationPage(MethodCall call, @NonNull Result result) throws Exception {
        NotificationBuilder.showNotificationConfigPage(applicationContext);
        saveReturnPageParameters(result);
    }

    private void channelRequestNotification(MethodCall call, Result result) throws Exception {

        if (NotificationBuilder.isNotificationEnabled(applicationContext)){
            result.success(true);
            return;
        }
        else {
            saveReturnPageParameters(result);
            NotificationBuilder.showNotificationConfigPage(applicationContext);
        }
    }

    private void saveReturnPageParameters(Result result){
        // Necessary to return the call only after the app goes to foreground on next time
        pendingAuthorizationReturn = result;
        hasGoneToAuthorizationPage = true;
    }

    private void channelMethodCreateNotification(MethodCall call, Result result) throws Exception {

        Map<String, Object> pushData = call.arguments();
        NotificationModel notificationModel = new NotificationModel().fromMap(pushData);

        if (notificationModel == null) {
            throw new AwesomeNotificationException("Invalid parameters");
        }

        if (!NotificationBuilder.isNotificationEnabled(applicationContext)) {
            throw new AwesomeNotificationException("Notifications are disabled");
        }

        if (notificationModel.schedule == null) {

            NotificationSender.send(
                    applicationContext,
                    NotificationSource.Local,
                    notificationModel
            );
        } else {

            NotificationScheduler.schedule(
                    applicationContext,
                    NotificationSource.Schedule,
                    notificationModel
            );
        }

        result.success(true);
    }

    @SuppressWarnings("unchecked")
    private void channelMethodInitialize(MethodCall call, Result result) throws Exception {
        List<Object> channelsData;

        Map<String, Object> platformParameters = call.arguments();

        debug = (Boolean) platformParameters.get(Definitions.INITIALIZE_DEBUG_MODE);
        debug = debug != null && debug;

        String defaultIconPath = (String) platformParameters.get(Definitions.INITIALIZE_DEFAULT_ICON);
        channelsData = (List<Object>) platformParameters.get(Definitions.INITIALIZE_CHANNELS);

        setDefaultConfigurations(
                applicationContext,
                defaultIconPath,
                channelsData
        );

        if (AwesomeNotificationsPlugin.debug)
            Log.d(TAG, "Awesome Notifications service initialized");

        result.success(true);
    }

    private boolean setDefaultConfigurations(Context context, String defaultIcon, List<Object> channelsData) throws Exception {

        setDefaults(context, defaultIcon);

        setChannels(context, channelsData);

        recoverNotificationCreated(context);
        recoverNotificationDisplayed(context);
        recoverNotificationDismissed(context);

        captureNotificationActionOnLaunch();
        return true;
    }

    private void setChannels(Context context, List<Object> channelsData) throws Exception {
        if (ListUtils.isNullOrEmpty(channelsData)) return;

        List<NotificationChannelModel> channels = new ArrayList<>();
        boolean forceUpdate = false;

        for (Object channelDataObject : channelsData) {
            if (channelDataObject instanceof Map<?, ?>) {
                @SuppressWarnings("unchecked")
                Map<String, Object> channelData = (Map<String, Object>) channelDataObject;
                NotificationChannelModel channelModel = new NotificationChannelModel().fromMap(channelData);
                forceUpdate = BooleanUtils.getValue((Boolean) channelData.get(Definitions.CHANNEL_FORCE_UPDATE));

                if (channelModel != null) {
                    channels.add(channelModel);
                } else {
                    throw new AwesomeNotificationException("Invalid channel: " + JsonUtils.toJson(channelData));
                }
            }
        }

        for (NotificationChannelModel channelModel : channels) {
            ChannelManager.saveChannel(context, channelModel, forceUpdate);
        }

        ChannelManager.commitChanges(context);
    }

    private void setDefaults(Context context, String defaultIcon) {

        if (MediaUtils.getMediaSourceType(defaultIcon) != MediaSource.Resource) {
            defaultIcon = null;
        }

        DefaultsManager.saveDefault(context, new DefaultsModel(defaultIcon));
        DefaultsManager.commitChanges(context);
    }

    public static NotificationLifeCycle getApplicationLifeCycle() {

        Lifecycle.State state = ProcessLifecycleOwner.get().getLifecycle().getCurrentState();

        if (state == Lifecycle.State.RESUMED) {
            appLifeCycle = NotificationLifeCycle.Foreground;
        } else if (state == Lifecycle.State.CREATED) {
            appLifeCycle = NotificationLifeCycle.Background;
        } else {
            appLifeCycle = NotificationLifeCycle.AppKilled;
        }

        return appLifeCycle;
    }

    private void captureNotificationActionOnLaunch() {

        if (initialActivity == null) {
            return;
        }

        Intent intent = initialActivity.getIntent();
        if (intent == null) {
            return;
        }

        String actionName = intent.getAction();
        if (actionName != null) {

            Boolean isStandardAction = Definitions.SELECT_NOTIFICATION.equals(actionName);
            Boolean isButtonAction = actionName.startsWith(Definitions.NOTIFICATION_BUTTON_ACTION_PREFIX);

            if (isStandardAction || isButtonAction) {
                receiveNotificationAction(intent, NotificationLifeCycle.AppKilled);
            }
        }
    }

    private Boolean receiveNotificationAction(Intent intent) {
        return receiveNotificationAction(intent, getApplicationLifeCycle());
    }

    private Boolean receiveNotificationAction(Intent intent, NotificationLifeCycle appLifeCycle) {

        ActionReceived actionModel = NotificationBuilder.buildNotificationActionFromIntent(applicationContext, intent);

        if (actionModel != null) {

            actionModel.actionDate = DateUtils.getUTCDate();
            actionModel.actionLifeCycle = appLifeCycle;

            Map<String, Object> returnObject = actionModel.toMap();

            pluginChannel.invokeMethod(Definitions.CHANNEL_METHOD_RECEIVED_ACTION, returnObject);

            if (AwesomeNotificationsPlugin.debug)
                Log.d(TAG, "Notification action received");
        }
        return true;
    }

    @Override
    public void onActivityCreated(Activity activity, Bundle bundle) {

    }

    @Override
    public void onActivityStarted(Activity activity) {

    }

    @Override
    public void onActivityResumed(Activity activity) {
        if(hasGoneToAuthorizationPage){
            hasGoneToAuthorizationPage = false;
            pendingAuthorizationReturn.success(
                    NotificationBuilder.isNotificationEnabled(applicationContext));
        }
    }

    @Override
    public void onActivityPaused(Activity activity) {

    }

    @Override
    public void onActivityStopped(Activity activity) {

    }

    @Override
    public void onActivitySaveInstanceState(Activity activity, Bundle bundle) {

    }

    @Override
    public void onActivityDestroyed(Activity activity) {

    }
}
