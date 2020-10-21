package me.carda.awesome_notifications;

import android.Manifest;
import android.app.AppOpsManager;
import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.graphics.Bitmap;
import android.net.Uri;
import android.os.Build;
import android.provider.Settings;
import android.support.v4.media.session.MediaSessionCompat;
import android.util.Log;

import com.google.android.gms.tasks.OnCompleteListener;
import com.google.android.gms.tasks.Task;
import com.google.firebase.FirebaseApp;
import com.google.firebase.iid.FirebaseInstanceId;
import com.google.firebase.iid.InstanceIdResult;

import java.io.ByteArrayOutputStream;
import java.io.Serializable;
import java.lang.reflect.Field;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import androidx.annotation.NonNull;
import androidx.annotation.RequiresApi;
import androidx.core.app.ActivityCompat;
import androidx.core.app.NotificationManagerCompat;
import androidx.core.content.ContextCompat;
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

import me.carda.awesome_notifications.notifications.PushNotification;
import me.carda.awesome_notifications.notifications.enumeratos.MediaSource;
import me.carda.awesome_notifications.notifications.enumeratos.NotificationLifeCycle;
import me.carda.awesome_notifications.notifications.enumeratos.NotificationSource;
import me.carda.awesome_notifications.notifications.exceptions.PushNotificationException;

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

import me.carda.awesome_notifications.utils.BitmapUtils;
import me.carda.awesome_notifications.utils.DateUtils;
import me.carda.awesome_notifications.utils.JsonUtils;
import me.carda.awesome_notifications.utils.ListUtils;
import me.carda.awesome_notifications.utils.MapUtils;
import me.carda.awesome_notifications.utils.MediaUtils;
import me.carda.awesome_notifications.utils.StringUtils;

/** AwesomeNotificationsPlugin **/
public class AwesomeNotificationsPlugin extends BroadcastReceiver implements FlutterPlugin, MethodCallHandler, PluginRegistry.NewIntentListener, ActivityAware {

    public static boolean hasGooglePlayServices;

    public static NotificationLifeCycle appLifeCycle = NotificationLifeCycle.AppKilled;

    private static final String TAG = "PushNotificationsPlugin";

    private Activity initialActivity;
    private MethodChannel pluginChannel;
    private Context applicationContext;

    public static MediaSessionCompat mediaSession;

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
        return true;
    }

    @Override
    public boolean onNewIntent(Intent intent){
        Log.d(TAG, "onNewIntent called");
        return receiveNotificationAction(intent);
    }

    // https://flutter.dev/docs/development/packages-and-plugins/plugin-api-migration
    // FOR OLDER FLUTTER VERSIONS (1.11 releases and bellow)
    public static void registerWith(Registrar registrar) {
        AwesomeNotificationsPlugin awesomeNotificationsPlugin = new AwesomeNotificationsPlugin();

        awesomeNotificationsPlugin.initialActivity = registrar.activity();

        awesomeNotificationsPlugin.initializeFlutterPlugin(
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

        initializeFlutterPlugin(
            flutterPluginBinding.getApplicationContext(),
            new MethodChannel(
                flutterPluginBinding.getBinaryMessenger(),
                Definitions.CHANNEL_FLUTTER_PLUGIN
            )
        );
    }

    private void initializeFlutterPlugin(Context context, MethodChannel channel) {

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

        LocalBroadcastManager manager = LocalBroadcastManager.getInstance(applicationContext);
        manager.registerReceiver(this, intentFilter);

        mediaSession = new MediaSessionCompat(applicationContext, "PUSH_MEDIA");

        getApplicationLifeCycle();

        FirebaseApp.initializeApp(context);
    }

    @Override
    public void onAttachedToActivity(ActivityPluginBinding activityPluginBinding) {
        initialActivity = activityPluginBinding.getActivity();
        activityPluginBinding.addOnNewIntentListener(this);
        getApplicationLifeCycle();
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        pluginChannel.setMethodCallHandler(null);
        getApplicationLifeCycle();
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {
        getApplicationLifeCycle();
    }

    @Override
    public void onReattachedToActivityForConfigChanges(ActivityPluginBinding activityPluginBinding) {
        getApplicationLifeCycle();
    }

    @Override
    public void onDetachedFromActivity() {
        getApplicationLifeCycle();
    }

    // BroadcastReceiver by other classes.
    @Override
    public void onReceive(Context context, Intent intent) {
        getApplicationLifeCycle();

        Log.d(TAG, "Broadcast received by flutter plugin");
        String action = intent.getAction();

        if(action == null) return;

        switch (action){

            case Definitions.BROADCAST_FCM_TOKEN:
                onBroadcastNewFcmToken(intent);
                return;

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

            default:
                Log.d(TAG, action);
                return;
        }
    }

    private void onBroadcastNewFcmToken(Intent intent) {
        String token = intent.getStringExtra(Definitions.EXTRA_BROADCAST_FCM_TOKEN);
        pluginChannel.invokeMethod(Definitions.CHANNEL_METHOD_NEW_FCM_TOKEN, token);
    }

    private void onBroadcastNotificationCreated(Intent intent) {

        try {
            Serializable serializable = intent.getSerializableExtra(Definitions.EXTRA_BROADCAST_MESSAGE);

            @SuppressWarnings("unchecked")
            Map<String, Object> content = (serializable instanceof Map ? (Map<String, Object>)serializable : null);
            if(content == null) return;

            NotificationReceived received = NotificationReceived.fromMap(content);
            received.validate(applicationContext);

            CreatedManager.removeCreated(applicationContext, received.id);

            pluginChannel.invokeMethod(Definitions.CHANNEL_METHOD_NOTIFICATION_CREATED, content);

        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void onBroadcastKeepOnTopActionNotification(Intent intent) {
        try {

            Serializable serializable = intent.getSerializableExtra(Definitions.EXTRA_BROADCAST_MESSAGE);
            pluginChannel.invokeMethod(Definitions.CHANNEL_METHOD_RECEIVED_ACTION, serializable);

        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void onBroadcastNotificationDisplayed(Intent intent) {
        try {

            Serializable serializable = intent.getSerializableExtra(Definitions.EXTRA_BROADCAST_MESSAGE);

            @SuppressWarnings("unchecked")
            Map<String, Object> content = (serializable instanceof Map ? (Map<String, Object>)serializable : null);
            if(content == null) return;

            NotificationReceived received = NotificationReceived.fromMap(content);
            received.validate(applicationContext);

            DisplayedManager.removeDisplayed(applicationContext, received.id);

            pluginChannel.invokeMethod(Definitions.CHANNEL_METHOD_NOTIFICATION_DISPLAYED, content);

        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void onBroadcastNotificationDismissed(Intent intent) {
        try {

            Serializable serializable = intent.getSerializableExtra(Definitions.EXTRA_BROADCAST_MESSAGE);

            @SuppressWarnings("unchecked")
            Map<String, Object> content = (serializable instanceof Map ? (Map<String, Object>)serializable : null);
            if(content == null) return;

            ActionReceived received = (ActionReceived) ActionReceived.fromMap(content);
            received.validate(applicationContext);

            DismissedManager.removeDismissed(applicationContext, received.id);

            pluginChannel.invokeMethod(Definitions.CHANNEL_METHOD_NOTIFICATION_DISMISSED, content);

        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void recoverNotificationCreated(Context context) {
        List<NotificationReceived> lostCreated = CreatedManager.listCreated(context);

        if(lostCreated != null) {
            for (NotificationReceived created : lostCreated) {
                try {

                    created.validate(applicationContext);
                    pluginChannel.invokeMethod(Definitions.CHANNEL_METHOD_NOTIFICATION_CREATED, created.toMap());
                    CreatedManager.removeCreated(context, created.id);

                } catch (PushNotificationException e) {
                    e.printStackTrace();
                }
            }
        }
    }

    private void recoverNotificationDisplayed(Context context) {
        List<NotificationReceived> lostDisplayed = DisplayedManager.listDisplayed(context);

        if(lostDisplayed != null) {
            for (NotificationReceived displayed : lostDisplayed) {
                try {

                    displayed.validate(applicationContext);
                    pluginChannel.invokeMethod(Definitions.CHANNEL_METHOD_NOTIFICATION_DISPLAYED, displayed.toMap());
                    DisplayedManager.removeDisplayed(context, displayed.id);

                } catch (PushNotificationException e) {
                    e.printStackTrace();
                }
            }
        }
    }

    private void recoverNotificationDismissed(Context context) {
        List<ActionReceived> lostDismissed = DismissedManager.listDismissed(context);

        if(lostDismissed != null) {
            for (ActionReceived received : lostDismissed) {
                try {

                    received.validate(applicationContext);
                    pluginChannel.invokeMethod(Definitions.CHANNEL_METHOD_NOTIFICATION_DISMISSED, received.toMap());
                    DismissedManager.removeDismissed(context, received.id);

                } catch (PushNotificationException e) {
                    e.printStackTrace();
                }
            }
        }
    }

    @Override
    public void onMethodCall(final MethodCall call, final Result result) {
        NotificationLifeCycle appLifeCycle = getApplicationLifeCycle();

        switch (call.method){

            case Definitions.CHANNEL_METHOD_INITIALIZE:
                channelMethodInitialize(call, result);
                return;

            case Definitions.CHANNEL_METHOD_GET_DRAWABLE_DATA:
                channelMethodGetDrawableData(call, result);
                return;

            case Definitions.CHANNEL_METHOD_GET_FCM_TOKEN:
                channelMethodGetFcmToken(call, result);
                return;

            case Definitions.CHANNEL_METHOD_IS_FCM_AVAILABLE:
                channelMethodIsFcmAvailable(call, result);
                return;

            case Definitions.CHANNEL_METHOD_IS_NOTIFICATION_ALLOWED:
                channelIsNotificationAllowed(call, result);
                return;

            case Definitions.CHANNEL_METHOD_REQUEST_NOTIFICATIONS:
                channelRequestNotification(call, result);
                return;

            case Definitions.CHANNEL_METHOD_CREATE_NOTIFICATION:
                channelMethodCreateNotification(call, result, appLifeCycle);
                return;

            case Definitions.CHANNEL_METHOD_LIST_ALL_SCHEDULES:
                channelMethodListAllSchedules(call, result);
                return;

            case Definitions.CHANNEL_METHOD_SET_NOTIFICATION_CHANNEL:
                channelMethodSetChannel(call, result);
                return;

            case Definitions.CHANNEL_METHOD_REMOVE_NOTIFICATION_CHANNEL:
                channelMethodRemoveChannel(call, result);
                return;

            case Definitions.CHANNEL_METHOD_GET_BADGE_COUNT:
                channelMethodGetBadgeCount(call, result);
                return;

            case Definitions.CHANNEL_METHOD_SET_BADGE_COUNT:
                channelMethodSetBadgeCount(call, result);
                return;

            case Definitions.CHANNEL_METHOD_RESET_BADGE:
                channelMethodResetBadge(call, result);
                return;

            case Definitions.CHANNEL_METHOD_CANCEL_NOTIFICATION:
                channelMethodCancelNotification(call, result);
                return;

            case Definitions.CHANNEL_METHOD_CANCEL_SCHEDULE:
                channelMethodCancelSchedule(call, result);
                return;

            case Definitions.CHANNEL_METHOD_CANCEL_ALL_SCHEDULES:
                channelMethodCancelAllSchedules(call, result);
                return;

            case Definitions.CHANNEL_METHOD_CANCEL_ALL_NOTIFICATIONS:
                channelMethodCancelAllNotifications(call, result);
                return;
        }

        result.notImplemented();
    }

    private void channelMethodGetDrawableData(MethodCall call, Result result) {

        String bitmapReference = call.arguments();

        Bitmap bitmap = BitmapUtils.getBitmapFromResource(applicationContext, bitmapReference);

        ByteArrayOutputStream stream = new ByteArrayOutputStream();
        bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream);
        byte[] byteArray = stream.toByteArray();
        bitmap.recycle();

        result.success(byteArray);
/*
        int size = bitmap.getRowBytes() * bitmap.getHeight();
        ByteBuffer byteBuffer = ByteBuffer.allocate(size);
        bitmap.copyPixelsToBuffer(byteBuffer);
        byte[] byteArray = byteBuffer.array();

        result.success(byteArray);*/
    }

    private void channelMethodListAllSchedules(MethodCall call, Result result) {
        List<PushNotification> activeSchedules = ScheduleManager.listSchedules(applicationContext);
        List<Map<String, Object>> serializeds = new ArrayList<>();

        if(activeSchedules != null){
            for(PushNotification pushNotification : activeSchedules){
                Map<String, Object> serialized = pushNotification.toMap();
                serializeds.add(serialized);
            }
        }

        result.success(serializeds);
    }

    private void channelMethodSetChannel(MethodCall call, Result result) {
        try {

            @SuppressWarnings("unchecked")
            Map<String, Object> channelData = MapUtils.extractArgument(call.arguments(), Map.class).orNull();
            NotificationChannelModel channelModel = NotificationChannelModel.fromMap(channelData);

            if(channelModel == null){
                result.error("Invalid channel", "Channel is invalid", "null");
            } else {
                ChannelManager.saveChannel(applicationContext, channelModel);
                result.success(true);
                return;
            }
        } catch (Exception e){
            e.printStackTrace();
            result.error("Invalid channel", e.getMessage(), e);
            return;
        }
        result.success(false);
    }

    private void channelMethodRemoveChannel(MethodCall call, Result result) {
        String channelKey = call.arguments();

        if(StringUtils.isNullOrEmpty(channelKey)){
            result.error("Empty channel key", "Empty key", channelKey);
            result.success(false);
        } else {
            Boolean removed = ChannelManager.removeChannel(applicationContext, channelKey);
            result.success(removed);
        }
    }

    private void channelMethodSetBadgeCount(MethodCall call, Result result) {
        @SuppressWarnings("unchecked")
        Map<String, Object> data = MapUtils.extractArgument(call.arguments(), Map.class).orNull();
        Integer count = (Integer) data.get(Definitions.NOTIFICATION_CHANNEL_SHOW_BADGE);
        String channelKey = (String) data.get(Definitions.NOTIFICATION_CHANNEL_KEY);

        // Android resets badges automatically when all notifications are cleared
        NotificationBuilder.setBadgeCount(applicationContext, count, channelKey);
        result.success(true);
    }

    private void channelMethodGetBadgeCount(MethodCall call, Result result) {
        String channelKey = call.arguments();
        Integer badgeCount = NotificationBuilder.getBadgeCount(applicationContext, channelKey);

        // Android resets badges automatically when all notifications are cleared
        result.success(badgeCount);
    }

    private void channelMethodResetBadge(MethodCall call, Result result) {
        String channelKey = call.arguments();
        NotificationBuilder.resetBadgeCount(applicationContext, channelKey);
        result.success(null);
    }

    private void channelMethodCancelSchedule(MethodCall call, Result result) {
        try {

            int notificationId = call.arguments();

            NotificationScheduler.cancelNotification(applicationContext, notificationId);

            result.success(true);

        } catch (Exception e) {
            e.printStackTrace();
            result.error("Notifications not cancelled", e.getMessage(), e);
        }
    }

    private void channelMethodCancelAllSchedules(MethodCall call, Result result) {
        try {

            NotificationScheduler.cancelAllNotifications(applicationContext);
            result.success(true);

        } catch (Exception e) {
            e.printStackTrace();
            result.error("Notifications not cancelled", e.getMessage(), e);
        }
    }

    private void channelMethodCancelNotification(MethodCall call, Result result) {
        try {

            int notificationId = call.arguments();

            NotificationScheduler.cancelNotification(applicationContext, notificationId);
            NotificationSender.cancelNotification(applicationContext, notificationId);

            result.success(true);

        } catch (Exception e) {
            e.printStackTrace();
            result.error("Notification not cancelled", e.getMessage(), e);
        }
    }

    private void channelMethodCancelAllNotifications(MethodCall call, Result result) {
        try {

            NotificationScheduler.cancelAllNotifications(applicationContext);
            NotificationSender.cancelAllNotifications(applicationContext);
            result.success(true);

        } catch (Exception e) {
            e.printStackTrace();
            result.error("Notifications not cancelled", e.getMessage(), e);
        }
    }

    private void channelIsNotificationAllowed(MethodCall call, Result result){
        result.success(isNotificationEnabled(applicationContext, null));
    }

    private void channelRequestNotification(MethodCall call, Result result){
        final Intent intent = new Intent();

        intent.setAction(Settings.ACTION_APP_NOTIFICATION_SETTINGS);

        //for Android 5-7
        intent.putExtra("app_package", applicationContext.getPackageName());
        intent.putExtra("app_uid", applicationContext.getApplicationInfo().uid);

        // for Android 8 and above
        intent.putExtra("android.provider.extra.APP_PACKAGE", applicationContext.getPackageName());

        intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);

        applicationContext.startActivity(intent);
    }

    private void channelMethodCreateNotification(MethodCall call, Result result, NotificationLifeCycle appLifeCycle) {
        try {
            Map<String, Object> pushData = call.arguments();
            PushNotification pushNotification = PushNotification.fromMap(pushData);
            if(pushNotification == null){
                result.error("Invalid parameters", "null", "null");
                return;
            }

            if(!isNotificationEnabled(applicationContext, pushNotification.content.channelKey)){
                result.error("Notifications are disabled", "null", "null");
                return;
            }

            if(pushNotification.schedule == null){

                NotificationSender.send(
                        applicationContext,
                        NotificationSource.Local,
                        pushNotification
                );
            }
            else {

                NotificationScheduler.schedule(
                        applicationContext,
                        NotificationSource.Schedule,
                        pushNotification
                );
            }

            result.success(true);

        } catch (Exception e) {
            result.error("Notification not created", e.getMessage(), e);
            e.printStackTrace();
        }
    }

    private void channelMethodIsFcmAvailable(MethodCall call, Result result) {
        try {
            result.success(hasGooglePlayServices && FirebaseInstanceId.getInstance().getInstanceId() != null);
        } catch (Exception e) {
            result.success(false);
        }
    }

    private void channelMethodGetFcmToken(MethodCall call, final Result result) {

        if(!hasGooglePlayServices){
            result.notImplemented();
            return;
        }

        try {

            FirebaseInstanceId
                    .getInstance()
                    .getInstanceId()
                    .addOnCompleteListener(
                            new OnCompleteListener<InstanceIdResult>() {
                                @Override
                                public void onComplete(@NonNull Task<InstanceIdResult> task) {
                                    if (!task.isSuccessful()) {
                                        Exception e = task.getException();
                                        Log.w(TAG, "getFirebaseToken could not fetch instanceIDD: ", e);
                                        result.error("getFirebaseToken could not fetch instanceID", e.getMessage(), e);
                                        return;
                                    }

                                    result.success(task.getResult().getToken());
                                }
                            });

        } catch (Exception e){
            result.error("Firebase service not available (check if you have google-services.json file)", e.getMessage(), e);
        }
    }


    public static Boolean isNotificationEnabled(Context context, String channelKey){

        NotificationManagerCompat manager = NotificationManagerCompat.from(context);

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            if (!manager.areNotificationsEnabled()) {
                return false;
            }
            if(!StringUtils.isNullOrEmpty(channelKey)){
                NotificationChannel channel = manager.getNotificationChannel(channelKey);
                if (channel.getImportance() == NotificationManager.IMPORTANCE_NONE) {
                    return false;
                }
            }
            return true;
        } else {
            return manager.areNotificationsEnabled();
        }
    }

    @SuppressWarnings("unchecked")
    private void channelMethodInitialize(MethodCall call, Result result) {
        List<Object> channelsData;

        try {

            Map<String, Object> platformParameters = call.arguments();
            String defaultIconPath = (String) platformParameters.get(Definitions.DEFAULT_ICON);
            channelsData = (List<Object>) platformParameters.get(Definitions.INITIALIZE_CHANNELS);

            setDefaultConfigurations(
                applicationContext,
                defaultIconPath,
                channelsData
            );

            if(!isNotificationEnabled(applicationContext, null)){

            }

            Log.d(TAG, "Push notification service initialized");
            result.success(true);

        } catch (Exception e){
            result.error("getFirebaseToken could not fetch instanceID", e.getMessage(), e);
            e.printStackTrace();
        }
    }

    private boolean setDefaultConfigurations(Context context, String defaultIcon, List<Object> channelsData) throws PushNotificationException {

        setDefaultIcon(context, defaultIcon);
        setChannels(context, channelsData);

        recoverNotificationCreated(context);
        recoverNotificationDisplayed(context);
        recoverNotificationDismissed(context);

        captureNotificationActionOnLaunch();
        return true;
    }

    private void setChannels(Context context, List<Object> channelsData) throws PushNotificationException {
        if(ListUtils.isNullOrEmpty(channelsData)) return;

        List<NotificationChannelModel> channels = new ArrayList<>();

        for(Object channelDataObject : channelsData){
            if(channelDataObject instanceof Map<?,?>){
                @SuppressWarnings("unchecked")
                Map<String, Object> channelData = (Map<String, Object>) channelDataObject;
                NotificationChannelModel channelModel = NotificationChannelModel.fromMap(channelData);

                if(channelModel != null){
                    channels.add(channelModel);
                } else {
                    throw new PushNotificationException("Invalid channel: "+JsonUtils.toJson(channelData));
                }
            }
        }

        for(NotificationChannelModel channelModel : channels){
            ChannelManager.saveChannel(context, channelModel);
        }
    }

    private void setDefaultIcon(Context context, String defaultIcon) {
        if (MediaUtils.getMediaSourceType(defaultIcon) != MediaSource.Resource) {
            defaultIcon = null;
        }

        DefaultsManager.saveDefault(context, "defaultIcon", defaultIcon);
    }

    public static NotificationLifeCycle getApplicationLifeCycle(){

        Lifecycle.State state = ProcessLifecycleOwner.get().getLifecycle().getCurrentState();
        //Log.d(TAG, "ProcessLifecycleOwner: " + state.toString());

        if(state == Lifecycle.State.RESUMED){
            appLifeCycle = NotificationLifeCycle.Foreground;
        } else
        if(state == Lifecycle.State.CREATED){
            appLifeCycle = NotificationLifeCycle.Background;
        } else {
            appLifeCycle = NotificationLifeCycle.AppKilled;
        }
        return appLifeCycle;
    }

    private void captureNotificationActionOnLaunch() {

        if(initialActivity == null){ return; }

        Intent intent = initialActivity.getIntent();
        if(intent == null){ return; }

        String actionName = intent.getAction();
        if(actionName != null){

            Boolean isStandardAction = Definitions.SELECT_NOTIFICATION.equals(actionName);
            Boolean isButtonAction = actionName.startsWith(Definitions.NOTIFICATION_BUTTON_ACTION_PREFIX);

            if(isStandardAction || isButtonAction){
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
        }
        return true;
    }

}
