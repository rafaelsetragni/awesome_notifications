package me.carda.awesome_notifications;

import android.content.Context;
import android.content.Intent;
import android.os.Build;

import java.util.ArrayList;
import java.util.Calendar;
import java.util.List;
import java.util.Map;

import androidx.annotation.NonNull;

import io.flutter.embedding.engine.plugins.FlutterPlugin;

import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugin.common.PluginRegistry.Registrar;

import me.carda.awesome_notifications.core.AwesomeNotifications;
import me.carda.awesome_notifications.core.AwesomeNotificationsExtension;
import me.carda.awesome_notifications.core.background.BackgroundExecutor;
import me.carda.awesome_notifications.core.completion_handlers.NotificationThreadCompletionHandler;
import me.carda.awesome_notifications.core.enumerators.ForegroundServiceType;
import me.carda.awesome_notifications.core.enumerators.ForegroundStartMode;
import me.carda.awesome_notifications.core.exceptions.ExceptionCode;
import me.carda.awesome_notifications.core.exceptions.ExceptionFactory;
import me.carda.awesome_notifications.core.listeners.AwesomeEventListener;
import me.carda.awesome_notifications.core.Definitions;
import me.carda.awesome_notifications.core.logs.Logger;
import me.carda.awesome_notifications.core.completion_handlers.BitmapCompletionHandler;
import me.carda.awesome_notifications.core.completion_handlers.PermissionCompletionHandler;
import me.carda.awesome_notifications.core.models.NotificationModel;
import me.carda.awesome_notifications.core.models.NotificationScheduleModel;
import me.carda.awesome_notifications.core.exceptions.AwesomeNotificationsException;

import me.carda.awesome_notifications.core.models.NotificationChannelModel;

import me.carda.awesome_notifications.core.utils.BooleanUtils;
import me.carda.awesome_notifications.core.utils.CalendarUtils;
import me.carda.awesome_notifications.core.utils.ListUtils;
import me.carda.awesome_notifications.core.utils.MapUtils;
import me.carda.awesome_notifications.core.utils.StringUtils;

/**
 * AwesomeNotificationsPlugin
 **/
public class AwesomeNotificationsPlugin
        extends
            AwesomeNotificationsExtension
        implements
            FlutterPlugin,
            MethodCallHandler,
            AwesomeEventListener,
            PluginRegistry.NewIntentListener,
            ActivityAware
{
    private static final String TAG = "AwesomeNotificationsPlugin";

    private MethodChannel pluginChannel;
    private AwesomeNotifications awesomeNotifications;

    private final StringUtils stringUtils = StringUtils.getInstance();

    @Override
    public void loadExternalExtensions(Context context) {
        FlutterBitmapUtils.extendCapabilities();
        BackgroundExecutor.setBackgroundExecutorClass(DartBackgroundExecutor.class);
    }

    // https://flutter.dev/docs/development/packages-and-plugins/plugin-api-migration
    // FOR OLDER FLUTTER VERSIONS (1.11 releases and bellow)
    public static void registerWith(Registrar registrar) {

        AwesomeNotificationsPlugin awesomeNotificationsPlugin
                = new AwesomeNotificationsPlugin();

        awesomeNotificationsPlugin.AttachAwesomeNotificationsPlugin(
                registrar.context(),
                new MethodChannel(
                        registrar.messenger(),
                        Definitions.CHANNEL_FLUTTER_PLUGIN
                ));
    }

    // FOR NEWER FLUTTER VERSIONS (1.12 releases and above)
    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {

        AttachAwesomeNotificationsPlugin(
                flutterPluginBinding.getApplicationContext(),
                new MethodChannel(
                    flutterPluginBinding.getBinaryMessenger(),
                    Definitions.CHANNEL_FLUTTER_PLUGIN
                ));

        if (AwesomeNotifications.debug)
            Logger.d(TAG, "Awesome Notifications attached to engine for Android " + Build.VERSION.SDK_INT);
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        detachAwesomeNotificationsPlugin(
                binding.getApplicationContext());
    }

    private void AttachAwesomeNotificationsPlugin(Context applicationContext, MethodChannel channel) {
        pluginChannel = channel;
        pluginChannel.setMethodCallHandler(this);

        try {
            awesomeNotifications =
                    new AwesomeNotifications(
                            applicationContext,
                            this);

            if (AwesomeNotifications.debug)
                Logger.d(TAG, "Awesome Notifications plugin attached to Android " + Build.VERSION.SDK_INT);

        } catch (AwesomeNotificationsException ignored) {
        } catch (Exception exception) {
            ExceptionFactory
                .getInstance()
                .registerNewAwesomeException(
                        TAG,
                        ExceptionCode.CODE_UNKNOWN_EXCEPTION,
                        "An exception was found while attaching awesome notifications plugin",
                        exception);
        }
    }

    private void detachAwesomeNotificationsPlugin(Context applicationContext) {
        pluginChannel.setMethodCallHandler(null);
        pluginChannel = null;

        if (awesomeNotifications != null) {
            awesomeNotifications.detachAsMainInstance(this);
            awesomeNotifications.dispose();
            awesomeNotifications = null;
        }

        if (AwesomeNotifications.debug)
            Logger.d(TAG, "Awesome Notifications plugin detached from Android " + Build.VERSION.SDK_INT);
    }

    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
        try {
            Intent launchIntent = binding.getActivity().getIntent();
            awesomeNotifications.captureNotificationActionFromIntent(launchIntent);
            binding.addOnNewIntentListener(this);
        } catch(Exception exception) {
            ExceptionFactory
                    .getInstance()
                    .registerNewAwesomeException(
                            TAG,
                            ExceptionCode.CODE_UNKNOWN_EXCEPTION,
                            ExceptionCode.DETAILED_UNEXPECTED_ERROR+".fcm."+exception.getClass().getSimpleName(),
                            exception);
        }
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {
    }

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
        binding.addOnNewIntentListener(this);
    }

    @Override
    public void onDetachedFromActivity() {
    }

    @Override
    public boolean onNewIntent(Intent intent) {
        try{
            return awesomeNotifications
                    .captureNotificationActionFromIntent(intent);
        } catch (Exception exception) {
            ExceptionFactory
                    .getInstance()
                    .registerNewAwesomeException(
                            TAG,
                            ExceptionCode.CODE_UNKNOWN_EXCEPTION,
                            ExceptionCode.DETAILED_UNEXPECTED_ERROR+".fcm."+exception.getClass().getSimpleName(),
                            exception);
            return false;
        }
    }

    @Override
    public void onNewAwesomeEvent(String eventType, Map<String, Object> content) {
        if (pluginChannel != null){
            if(Definitions.EVENT_SILENT_ACTION.equals(eventType)){
                try {
                    content.put(Definitions.ACTION_HANDLE, awesomeNotifications.getActionHandle());
                } catch (AwesomeNotificationsException ignore) {
                }
            }
            pluginChannel.invokeMethod(eventType, content);
        }
    }

    @Override
    public void onMethodCall(@NonNull final MethodCall call, @NonNull final Result result) {

        if (awesomeNotifications == null) {
            AwesomeNotificationsException awesomeException =
                    ExceptionFactory
                        .getInstance()
                        .createNewAwesomeException(
                                TAG,
                                ExceptionCode.CODE_INITIALIZATION_EXCEPTION,
                                "Awesome notifications is currently not available",
                                ExceptionCode.DETAILED_INITIALIZATION_FAILED+".awesomeNotifications.core");
            result.error(
                    awesomeException.getCode(),
                    awesomeException.getMessage(),
                    awesomeException.getDetailedCode());
            return;
        }

        try {

            switch (call.method) {

                case Definitions.CHANNEL_METHOD_INITIALIZE:
                    channelMethodInitialize(call, result);
                    return;

                case Definitions.CHANNEL_METHOD_SET_ACTION_HANDLE:
                    channelMethodSetActionHandle(call, result);
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

                case Definitions.CHANNEL_METHOD_SHOW_ALARM_PAGE:
                    channelShowAlarmPage(call, result);
                    return;

                case Definitions.CHANNEL_METHOD_SHOW_GLOBAL_DND_PAGE:
                    channelShowGlobalDndPage(call, result);
                    return;

                case Definitions.CHANNEL_METHOD_CHECK_PERMISSIONS:
                    channelMethodCheckPermissions(call, result);
                    return;

                case Definitions.CHANNEL_METHOD_SHOULD_SHOW_RATIONALE:
                    channelMethodShouldShowRationale(call, result);
                    return;

                case Definitions.CHANNEL_METHOD_REQUEST_NOTIFICATIONS:
                    channelRequestUserPermissions(call, result);
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

        } catch (AwesomeNotificationsException awesomeException) {
            result.error(
                    awesomeException.getCode(),
                    awesomeException.getMessage(),
                    awesomeException.getDetailedCode());

        } catch (Exception exception) {
            AwesomeNotificationsException awesomeException =
                    ExceptionFactory
                        .getInstance()
                        .createNewAwesomeException(
                                TAG,
                                ExceptionCode.CODE_UNKNOWN_EXCEPTION,
                                ExceptionCode.DETAILED_UNEXPECTED_ERROR+"."+exception.getClass().getSimpleName(),
                                exception);

            result.error(
                    awesomeException.getCode(),
                    awesomeException.getMessage(),
                    awesomeException.getDetailedCode());
        }
    }

    @SuppressWarnings("unchecked")
    private void channelMethodStartForeground(
            @NonNull final MethodCall call,
            @NonNull final Result result
    ) throws AwesomeNotificationsException {

        Map<String, Object> arguments = MapUtils.extractArgument(call.arguments(), Map.class).orNull();
        if(arguments == null)
            throw ExceptionFactory
                    .getInstance()
                    .createNewAwesomeException(
                            TAG,
                            ExceptionCode.CODE_MISSING_ARGUMENTS,
                            "Arguments are missing",
                            ExceptionCode.DETAILED_REQUIRED_ARGUMENTS);

        NotificationModel notificationModel = new NotificationModel().fromMap(
                (Map<String, Object>) arguments.get(Definitions.NOTIFICATION_MODEL));

        ForegroundStartMode foregroundStartMode =
                NotificationModel.getEnumValueOrDefault(arguments, Definitions.NOTIFICATION_SERVICE_START_MODE,
                        ForegroundStartMode.class, ForegroundStartMode.values());

        ForegroundServiceType foregroundServiceType =
                NotificationModel.getEnumValueOrDefault(arguments, Definitions.NOTIFICATION_FOREGROUND_SERVICE_TYPE,
                        ForegroundServiceType.class, ForegroundServiceType.values());


        if(notificationModel == null)
            throw ExceptionFactory
                    .getInstance()
                    .createNewAwesomeException(
                            TAG,
                            ExceptionCode.CODE_INVALID_ARGUMENTS,
                            "Foreground notification is invalid",
                            ExceptionCode.DETAILED_INVALID_ARGUMENTS+".notificationModel");

        if(foregroundStartMode == null)
            throw ExceptionFactory
                    .getInstance()
                    .createNewAwesomeException(
                            TAG,
                            ExceptionCode.CODE_INVALID_ARGUMENTS,
                            "Foreground start type is required",
                            ExceptionCode.DETAILED_INVALID_ARGUMENTS+".foreground.startType");

        if(foregroundServiceType == null)
            throw ExceptionFactory
                    .getInstance()
                    .createNewAwesomeException(
                            TAG,
                            ExceptionCode.CODE_INVALID_ARGUMENTS,
                            "foregroundServiceType is required",
                            ExceptionCode.DETAILED_INVALID_ARGUMENTS+".foreground.serviceType");

        awesomeNotifications.startForegroundService(
            notificationModel,
            foregroundStartMode,
            foregroundServiceType);
    }

    private void channelMethodStopForeground(
            @NonNull final MethodCall call,
            @NonNull final Result result
    ) throws AwesomeNotificationsException {

        Integer notificationId = call.<Integer>argument(Definitions.NOTIFICATION_ID);
        awesomeNotifications.stopForegroundService(notificationId);
        result.success(null);
    }

    private void channelMethodGetDrawableData(
            @NonNull final MethodCall call,
            @NonNull final Result result
    ) throws AwesomeNotificationsException {

        String bitmapReference = call.arguments();
        if(bitmapReference == null)
            throw ExceptionFactory
                    .getInstance()
                    .createNewAwesomeException(
                            TAG,
                            ExceptionCode.CODE_INVALID_ARGUMENTS,
                            "Bitmap reference is required",
                            ExceptionCode.DETAILED_INVALID_ARGUMENTS+".bitmapReference");

        awesomeNotifications
                .getDrawableData(
                    bitmapReference,
                    new BitmapCompletionHandler() {
                        @Override
                        public void handle(byte[] byteArray, AwesomeNotificationsException exception) {
                            if(exception != null)
                                result.error(
                                        exception.getCode(),
                                        exception.getMessage(),
                                        exception.getDetailedCode());
                            else
                                result.success(byteArray);
                        }
                    });
    }

    @SuppressWarnings("unchecked")
    private void channelMethodSetChannel(
            @NonNull final MethodCall call,
            @NonNull final Result result
    ) throws AwesomeNotificationsException {

        Map<String, Object> channelData = MapUtils.extractArgument(call.arguments(), Map.class).orNull();
        if (channelData == null)
            throw ExceptionFactory
                    .getInstance()
                    .createNewAwesomeException(
                            TAG,
                            ExceptionCode.CODE_INVALID_ARGUMENTS,
                            "Channel data is missing",
                            ExceptionCode.DETAILED_INVALID_ARGUMENTS+".channel.data");

        NotificationChannelModel channelModel = new NotificationChannelModel().fromMap(channelData);
        if (channelModel == null)
            throw ExceptionFactory
                    .getInstance()
                    .createNewAwesomeException(
                            TAG,
                            ExceptionCode.CODE_INVALID_ARGUMENTS,
                            "Channel data is invalid",
                            ExceptionCode.DETAILED_INVALID_ARGUMENTS+".channel.data");

        boolean forceUpdate = BooleanUtils.getInstance().getValue((Boolean) channelData.get(Definitions.CHANNEL_FORCE_UPDATE));

        boolean channelSaved =
                awesomeNotifications
                        .setChannel(channelModel, forceUpdate);

        result.success(channelSaved);
    }

    private void channelMethodRemoveChannel(
            @NonNull final MethodCall call,
            @NonNull final Result result
    ) throws AwesomeNotificationsException {

        String channelKey = call.arguments();
        if (stringUtils.isNullOrEmpty(channelKey))
            throw ExceptionFactory
                    .getInstance()
                    .createNewAwesomeException(
                            TAG,
                            ExceptionCode.CODE_INVALID_ARGUMENTS,
                            "Empty channel key",
                            ExceptionCode.DETAILED_INVALID_ARGUMENTS+".channel.key");

        boolean removed =
                awesomeNotifications
                        .removeChannel(channelKey);

        if (AwesomeNotifications.debug)
            Logger.d(TAG, removed ?
                    "Channel removed" :
                    "Channel '" + channelKey + "' not found");

        result.success(removed);
    }

    private void channelMethodGetBadgeCounter(
            @NonNull final MethodCall call,
            @NonNull final Result result
    ) throws AwesomeNotificationsException {
        Integer badgeCount =
                awesomeNotifications
                        .getGlobalBadgeCounter();

        result.success(badgeCount);
    }

    private void channelMethodSetBadgeCounter(
            @NonNull final MethodCall call,
            @NonNull final Result result
    ) throws AwesomeNotificationsException {

        int count = MapUtils.extractArgument(call.arguments(), Integer.class).or(-1);
        if (count < 0)
            throw ExceptionFactory
                    .getInstance()
                    .createNewAwesomeException(
                            TAG,
                            ExceptionCode.CODE_INVALID_ARGUMENTS,
                            "Invalid Badge value",
                            ExceptionCode.DETAILED_INVALID_ARGUMENTS+".badge.value");

        awesomeNotifications.setGlobalBadgeCounter(count);
        result.success(true);
    }

    private void channelMethodResetBadge(
            @NonNull final MethodCall call,
            @NonNull final Result result
    ) throws AwesomeNotificationsException {
        awesomeNotifications.resetGlobalBadgeCounter();
        result.success(null);
    }

    private void channelMethodIncrementBadge(
            @NonNull final MethodCall call,
            @NonNull final Result result
    ) throws AwesomeNotificationsException {
        int badgeCount = awesomeNotifications.incrementGlobalBadgeCounter();
        result.success(badgeCount);
    }

    private void channelMethodDecrementBadge(
            @NonNull final MethodCall call,
            @NonNull final Result result
    ) throws AwesomeNotificationsException {
        int badgeCount = awesomeNotifications.decrementGlobalBadgeCounter();
        result.success(badgeCount);
    }

    private void channelMethodDismissNotification(
            @NonNull final MethodCall call,
            @NonNull final Result result
    ) throws AwesomeNotificationsException {

        Integer notificationId = call.arguments();
        if (notificationId == null || notificationId < 0)
            throw ExceptionFactory
                    .getInstance()
                    .createNewAwesomeException(
                            TAG,
                            ExceptionCode.CODE_INVALID_ARGUMENTS,
                            "Invalid id value",
                            ExceptionCode.DETAILED_INVALID_ARGUMENTS+".dismiss.id");

        boolean dismissed = awesomeNotifications.dismissNotification(notificationId);

        if (AwesomeNotifications.debug)
            Logger.d(TAG, dismissed ?
                    "Notification " + notificationId + " dismissed" :
                    "Notification " + notificationId + " was not found");

        result.success(dismissed);
    }

    private void channelMethodCancelSchedule(
            @NonNull final MethodCall call,
            @NonNull final Result result
    ) throws AwesomeNotificationsException {

        Integer notificationId = call.arguments();
        if (notificationId == null || notificationId < 0)
            throw ExceptionFactory
                    .getInstance()
                    .createNewAwesomeException(
                            TAG,
                            ExceptionCode.CODE_INVALID_ARGUMENTS,
                            "Invalid id value",
                            ExceptionCode.DETAILED_INVALID_ARGUMENTS+".dismiss.id");

        boolean canceled = awesomeNotifications.cancelSchedule(notificationId);

        if (AwesomeNotifications.debug)
            Logger.d(TAG, canceled ?
                    "Schedule " + notificationId + " cancelled" :
                    "Schedule " + notificationId + " was not found");

        result.success(canceled);
    }

    private void channelMethodCancelNotification(
            @NonNull final MethodCall call,
            @NonNull final Result result
    ) throws AwesomeNotificationsException {

        Integer notificationId = call.arguments();
        if (notificationId == null || notificationId < 0)
            throw ExceptionFactory
                    .getInstance()
                    .createNewAwesomeException(
                            TAG,
                            ExceptionCode.CODE_INVALID_ARGUMENTS,
                            "Invalid id value",
                            ExceptionCode.DETAILED_INVALID_ARGUMENTS+".dismiss.id");

        boolean canceled = awesomeNotifications.cancelNotification(notificationId);

        if (AwesomeNotifications.debug)
            Logger.d(TAG, canceled ?
                    "Notification " + notificationId + " cancelled" :
                    "Notification " + notificationId + " was not found");

        result.success(canceled);
    }

    private void channelMethodDismissNotificationsByChannelKey(
            @NonNull final MethodCall call,
            @NonNull final Result result
    ) throws AwesomeNotificationsException {

        String channelKey = call.arguments();
        if (stringUtils.isNullOrEmpty(channelKey))
            throw ExceptionFactory
                    .getInstance()
                    .createNewAwesomeException(
                            TAG,
                            ExceptionCode.CODE_INVALID_ARGUMENTS,
                            "Invalid channel Key value",
                            ExceptionCode.DETAILED_INVALID_ARGUMENTS+".dismiss.channelKey");

        boolean dismissed = awesomeNotifications.dismissNotificationsByChannelKey(channelKey);

        if(AwesomeNotifications.debug)
            Logger.d(TAG, dismissed ?
                    "Notifications from channel " + channelKey + " dismissed" :
                    "Notifications from channel " + channelKey + " not found");

        result.success(dismissed);
    }

    private void channelMethodCancelSchedulesByChannelKey(
            @NonNull final MethodCall call,
            @NonNull final Result result
    ) throws AwesomeNotificationsException {

        String channelKey = call.arguments();
        if (stringUtils.isNullOrEmpty(channelKey))
            throw ExceptionFactory
                    .getInstance()
                    .createNewAwesomeException(
                            TAG,
                            ExceptionCode.CODE_INVALID_ARGUMENTS,
                            "Invalid channel Key value",
                            ExceptionCode.DETAILED_INVALID_ARGUMENTS+".dismiss.channelKey");

        boolean canceled = awesomeNotifications.cancelSchedulesByChannelKey(channelKey);

        if(AwesomeNotifications.debug)
            Logger.d(TAG, canceled ?
                    "Scheduled Notifications from channel " + channelKey + " canceled" :
                    "Scheduled Notifications from channel " + channelKey + " not found");

        result.success(canceled);
    }

    private void channelMethodCancelNotificationsByChannelKey(
            @NonNull final MethodCall call,
            @NonNull final Result result
    ) throws AwesomeNotificationsException {

        String channelKey = call.arguments();
        if (stringUtils.isNullOrEmpty(channelKey))
            throw ExceptionFactory
                    .getInstance()
                    .createNewAwesomeException(
                            TAG,
                            ExceptionCode.CODE_INVALID_ARGUMENTS,
                            "Invalid channel Key value",
                            ExceptionCode.DETAILED_INVALID_ARGUMENTS+".dismiss.channelKey");

        boolean canceled = awesomeNotifications.cancelNotificationsByChannelKey(channelKey);

        if(AwesomeNotifications.debug)
            Logger.d(TAG, canceled ?
                    "Notifications and schedules from channel " + channelKey + " canceled" :
                    "Notifications and schedules from channel " + channelKey + " not found");

        result.success(canceled);
    }

    private void channelMethodDismissNotificationsByGroupKey(
            @NonNull final MethodCall call,
            @NonNull final Result result
    ) throws AwesomeNotificationsException {

        String groupKey = call.arguments();
        if (stringUtils.isNullOrEmpty(groupKey))
            throw ExceptionFactory
                    .getInstance()
                    .createNewAwesomeException(
                            TAG,
                            ExceptionCode.CODE_INVALID_ARGUMENTS,
                            "Invalid groupKey value",
                            ExceptionCode.DETAILED_INVALID_ARGUMENTS+".dismiss.groupKey");

        boolean dismissed = awesomeNotifications.dismissNotificationsByGroupKey(groupKey);

        if(AwesomeNotifications.debug)
            Logger.d(TAG, dismissed ?
                    "Notifications from group " + groupKey + " dismissed" :
                    "Notifications from group " + groupKey + " not found");

        result.success(dismissed);
    }

    private void channelMethodCancelSchedulesByGroupKey(
            @NonNull final MethodCall call,
            @NonNull final Result result
    ) throws AwesomeNotificationsException {

        String groupKey = call.arguments();
        if (stringUtils.isNullOrEmpty(groupKey))
            throw ExceptionFactory
                    .getInstance()
                    .createNewAwesomeException(
                            TAG,
                            ExceptionCode.CODE_INVALID_ARGUMENTS,
                            "Invalid groupKey value",
                            ExceptionCode.DETAILED_INVALID_ARGUMENTS+".dismiss.groupKey");

        boolean canceled = awesomeNotifications.cancelSchedulesByGroupKey(groupKey);

        if(AwesomeNotifications.debug)
            Logger.d(TAG, canceled ?
                    "Scheduled Notifications from group " + groupKey + " canceled" :
                    "Scheduled Notifications from group " + groupKey + " not found");

        result.success(canceled);
    }

    private void channelMethodCancelNotificationsByGroupKey(
            @NonNull final MethodCall call,
            @NonNull final Result result
    ) throws AwesomeNotificationsException {

        String groupKey = call.arguments();
        if (stringUtils.isNullOrEmpty(groupKey))
            throw ExceptionFactory
                    .getInstance()
                    .createNewAwesomeException(
                            TAG,
                            ExceptionCode.CODE_INVALID_ARGUMENTS,
                            "Invalid groupKey value",
                            ExceptionCode.DETAILED_INVALID_ARGUMENTS+".dismiss.groupKey");

        boolean canceled = awesomeNotifications.cancelNotificationsByGroupKey(groupKey);

        if(AwesomeNotifications.debug)
            Logger.d(TAG, canceled ?
                    "Notifications and schedules from group " + groupKey + " canceled" :
                    "Notifications and schedules from group " + groupKey + " not found to be");

        result.success(canceled);
    }

    private void channelMethodDismissAllNotifications(
            @NonNull final MethodCall call,
            @NonNull final Result result
    ) throws AwesomeNotificationsException {

        awesomeNotifications.dismissAllNotifications();

        if (AwesomeNotifications.debug)
            Logger.d(TAG, "All notifications was dismissed");

        result.success(true);
    }

    private void channelMethodCancelAllSchedules(
            @NonNull final MethodCall call,
            @NonNull final Result result
    ) throws AwesomeNotificationsException {

        awesomeNotifications.cancelAllSchedules();

        if (AwesomeNotifications.debug)
            Logger.d(TAG, "All notifications scheduled was cancelled");

        result.success(true);
    }

    private void channelMethodCancelAllNotifications(
            @NonNull final MethodCall call,
            @NonNull final Result result
    ) throws AwesomeNotificationsException {

        awesomeNotifications.cancelAllNotifications();

        if (AwesomeNotifications.debug)
            Logger.d(TAG, "All notifications was cancelled");

        result.success(true);
    }

    private void channelMethodListAllSchedules(
            @NonNull final MethodCall call,
            @NonNull final Result result
    ) throws AwesomeNotificationsException {
        List<NotificationModel> activeSchedules =
                awesomeNotifications.listAllPendingSchedules();

        List<Map<String, Object>> listSerialized = new ArrayList<>();

        if (activeSchedules != null)
            for (NotificationModel notificationModel : activeSchedules) {
                Map<String, Object> serialized = notificationModel.toMap();
                listSerialized.add(serialized);
            }

        result.success(listSerialized);
    }

    @SuppressWarnings("unchecked")
    private void channelMethodGetNextDate(
            @NonNull final MethodCall call,
            @NonNull final Result result
    ) throws AwesomeNotificationsException {

        Map<String, Object> data = MapUtils.extractArgument(call.arguments(), Map.class).orNull();
        if (data == null)
            throw ExceptionFactory
                    .getInstance()
                    .createNewAwesomeException(
                            TAG,
                            ExceptionCode.CODE_INVALID_ARGUMENTS,
                            "Schedule data is invalid",
                            ExceptionCode.DETAILED_INVALID_ARGUMENTS+".schedule.data");

        Map<String, Object> scheduleData =
                MapUtils.extractValue(data, Definitions.NOTIFICATION_MODEL_SCHEDULE, Map.class)
                    .orNull();

        if (scheduleData == null)
            throw ExceptionFactory
                    .getInstance()
                    .createNewAwesomeException(
                            TAG,
                            ExceptionCode.CODE_INVALID_ARGUMENTS,
                            "Schedule data is invalid",
                            ExceptionCode.DETAILED_INVALID_ARGUMENTS+".schedule.data");

        NotificationScheduleModel scheduleModel =
                NotificationScheduleModel
                        .getScheduleModelFromMap(scheduleData);

        if (scheduleModel == null)
            throw ExceptionFactory
                    .getInstance()
                    .createNewAwesomeException(
                            TAG,
                            ExceptionCode.CODE_INVALID_ARGUMENTS,
                            "Schedule data is invalid",
                            ExceptionCode.DETAILED_INVALID_ARGUMENTS+".schedule.data");

        Calendar fixedDate =
                MapUtils.extractValue(data, Definitions.NOTIFICATION_INITIAL_FIXED_DATE, Calendar.class)
                            .or(CalendarUtils.getInstance().getCurrentCalendar());

        Calendar nextValidDate =
                awesomeNotifications
                        .getNextValidDate(scheduleModel, fixedDate);

        String finalValidDateString =
                (nextValidDate == null) ? null :
                CalendarUtils
                    .getInstance()
                    .calendarToString(nextValidDate);

        result.success(finalValidDateString);
    }

    private void channelMethodGetLocalTimeZone(
            @NonNull final MethodCall call,
            @NonNull final Result result
    ) throws AwesomeNotificationsException {
        result.success(
                awesomeNotifications
                        .getLocalTimeZone());
    }

    private void channelMethodGetUtcTimeZone(
            @NonNull final MethodCall call,
            @NonNull final Result result
    ) throws AwesomeNotificationsException {
        result.success(
                awesomeNotifications
                        .getUtcTimeZone());
    }

    private void channelIsNotificationAllowed(
            @NonNull final MethodCall call,
            @NonNull final Result result
    ) throws AwesomeNotificationsException {
        result.success(
                awesomeNotifications
                        .areNotificationsGloballyAllowed());
    }

    private void channelShowNotificationPage(
            @NonNull final MethodCall call,
            @NonNull final Result result
    ) throws AwesomeNotificationsException {
        String channelKey = call.arguments();

        awesomeNotifications
                .showNotificationPage(
                    channelKey,
                    new PermissionCompletionHandler() {
                        @Override
                        public void handle(List<String> missingPermissions) {
                            result.success(missingPermissions);
                        }
                    }
                );
    }

    private void channelShowAlarmPage(
            @NonNull final MethodCall call,
            @NonNull final Result result
    ) throws AwesomeNotificationsException {
        awesomeNotifications
                .showPreciseAlarmPage(
                    new PermissionCompletionHandler() {
                        @Override
                        public void handle(List<String> missingPermissions) {
                            result.success(missingPermissions);
                        }
                    }
                );
    }

    private void channelShowGlobalDndPage(
            @NonNull final MethodCall call,
            @NonNull final Result result
    ) throws AwesomeNotificationsException {
        awesomeNotifications
                .showDnDGlobalOverridingPage(
                        new PermissionCompletionHandler() {
                            @Override
                            public void handle(List<String> missingPermissions) {
                                result.success(missingPermissions);
                            }
                        }
                );
    }

    @SuppressWarnings("unchecked")
    private void channelMethodCheckPermissions(
            @NonNull final MethodCall call,
            @NonNull final Result result
    ) throws AwesomeNotificationsException {

        Map<String, Object> arguments = MapUtils.extractArgument(call.arguments(), Map.class).orNull();
        if(arguments == null)
            throw ExceptionFactory
                    .getInstance()
                    .createNewAwesomeException(
                            TAG,
                            ExceptionCode.CODE_MISSING_ARGUMENTS,
                            "Arguments are missing",
                            ExceptionCode.DETAILED_REQUIRED_ARGUMENTS);

        String channelKey = (String) arguments.get(Definitions.NOTIFICATION_CHANNEL_KEY);

        List<String> permissions = (List<String>) arguments.get(Definitions.NOTIFICATION_PERMISSIONS);
        if(ListUtils.isNullOrEmpty(permissions))
            throw ExceptionFactory
                    .getInstance()
                    .createNewAwesomeException(
                            TAG,
                            ExceptionCode.CODE_INVALID_ARGUMENTS,
                            "Permission list is required",
                            ExceptionCode.DETAILED_REQUIRED_ARGUMENTS+".permissionList");

        permissions = awesomeNotifications
                        .arePermissionsAllowed(
                                channelKey,
                                permissions);

        result.success(permissions);
    }

    @SuppressWarnings("unchecked")
    private void channelMethodShouldShowRationale(
            @NonNull final MethodCall call,
            @NonNull final Result result
    ) throws Exception {

        Map<String, Object> arguments = MapUtils.extractArgument(call.arguments(), Map.class).orNull();
        if(arguments == null)
            throw ExceptionFactory
                    .getInstance()
                    .createNewAwesomeException(
                            TAG,
                            ExceptionCode.CODE_MISSING_ARGUMENTS,
                            "Arguments are missing",
                            ExceptionCode.DETAILED_REQUIRED_ARGUMENTS);

        String channelKey = (String) arguments.get(Definitions.NOTIFICATION_CHANNEL_KEY);
        List<String> permissions = (List<String>) arguments.get(Definitions.NOTIFICATION_PERMISSIONS);

        if(permissions == null)
            throw ExceptionFactory
                    .getInstance()
                    .createNewAwesomeException(
                            TAG,
                            ExceptionCode.CODE_INVALID_ARGUMENTS,
                            "Permission list is required",
                            ExceptionCode.DETAILED_REQUIRED_ARGUMENTS+".permissionList");

        if(permissions.isEmpty())
            throw ExceptionFactory
                    .getInstance()
                    .createNewAwesomeException(
                            TAG,
                            ExceptionCode.CODE_INVALID_ARGUMENTS,
                            "Permission list cannot be empty",
                            ExceptionCode.DETAILED_REQUIRED_ARGUMENTS+".permissionList");

        permissions = awesomeNotifications.shouldShowRationale(
                        channelKey,
                        permissions);

        result.success(permissions);
    }

    @SuppressWarnings("unchecked")
    private void channelRequestUserPermissions(
            @NonNull final MethodCall call,
            @NonNull final Result result
    ) throws Exception {

        Map<String, Object> arguments = MapUtils.extractArgument(call.arguments(), Map.class).orNull();
        if(arguments == null)
            throw ExceptionFactory
                    .getInstance()
                    .createNewAwesomeException(
                            TAG,
                            ExceptionCode.CODE_MISSING_ARGUMENTS,
                            "Arguments are missing",
                            ExceptionCode.DETAILED_REQUIRED_ARGUMENTS);

        if(!arguments.containsKey(Definitions.NOTIFICATION_PERMISSIONS))
            throw ExceptionFactory
                    .getInstance()
                    .createNewAwesomeException(
                            TAG,
                            ExceptionCode.CODE_INVALID_ARGUMENTS,
                            "Permission list is required",
                            ExceptionCode.DETAILED_REQUIRED_ARGUMENTS+".permissionList");

        String channelKey = (String) arguments.get(Definitions.NOTIFICATION_CHANNEL_KEY);
        List<String> permissions = (List<String>) arguments.get(Definitions.NOTIFICATION_PERMISSIONS);

        if(ListUtils.isNullOrEmpty(permissions))
            throw ExceptionFactory
                    .getInstance()
                    .createNewAwesomeException(
                            TAG,
                            ExceptionCode.CODE_INVALID_ARGUMENTS,
                            "Permission list is required",
                            ExceptionCode.DETAILED_REQUIRED_ARGUMENTS+".permissionList");

        awesomeNotifications
                .requestUserPermissions(
                    channelKey,
                    permissions,
                    new PermissionCompletionHandler() {
                        @Override
                        public void handle(List<String> missingPermissions) {
                            result.success(missingPermissions);
                        }
                    });
    }

    private void channelMethodCreateNotification(
            @NonNull final MethodCall call,
            @NonNull final Result result
    ) throws Exception {

        Map<String, Object> arguments = call.arguments();
        if(arguments == null)
            throw ExceptionFactory
                    .getInstance()
                    .createNewAwesomeException(
                            TAG,
                            ExceptionCode.CODE_MISSING_ARGUMENTS,
                            "Arguments are missing",
                            ExceptionCode.DETAILED_REQUIRED_ARGUMENTS);

        NotificationModel notificationModel = new NotificationModel().fromMap(arguments);

        if (notificationModel == null)
            throw ExceptionFactory
                    .getInstance()
                    .createNewAwesomeException(
                            TAG,
                            ExceptionCode.CODE_INVALID_ARGUMENTS,
                            "Notification content is invalid",
                            ExceptionCode.DETAILED_REQUIRED_ARGUMENTS+".notificationModel.data");

        awesomeNotifications.createNotification(
                notificationModel,
                new NotificationThreadCompletionHandler() {
                    @Override
                    public void handle(boolean success, AwesomeNotificationsException exception) {
                        if (exception != null)
                            result.error(
                                    exception.getCode(),
                                    exception.getLocalizedMessage(),
                                    exception.getDetailedCode());
                        else
                            result.success(success);
                    }
                });
    }

    @SuppressWarnings("unchecked")
    private void channelMethodInitialize(
            @NonNull final MethodCall call,
            @NonNull final Result result
    ) throws Exception {

        Map<String, Object> arguments = call.arguments();
        if(arguments == null)
            throw ExceptionFactory
                    .getInstance()
                    .createNewAwesomeException(
                            TAG,
                            ExceptionCode.CODE_MISSING_ARGUMENTS,
                            "Arguments are missing",
                            ExceptionCode.DETAILED_REQUIRED_ARGUMENTS);

        String defaultIconPath = (String) arguments.get(Definitions.INITIALIZE_DEFAULT_ICON);

        List<Object> channelsData = (List<Object>) arguments.get(Definitions.INITIALIZE_CHANNELS);
        List<Object> channelGroupsData = (List<Object>) arguments.get(Definitions.INITIALIZE_CHANNEL_GROUPS);

        Boolean debug = (Boolean) arguments.get(Definitions.INITIALIZE_DEBUG_MODE);
        debug = debug != null && debug;

        Object backgroundCallbackObj = arguments.get(Definitions.BACKGROUND_HANDLE);
        Long backgroundCallback = backgroundCallbackObj == null ? 0L :(Long) backgroundCallbackObj;

        awesomeNotifications.initialize(
                defaultIconPath,
                channelsData,
                channelGroupsData,
                backgroundCallback,
                debug);

        if (AwesomeNotifications.debug)
            Logger.d(TAG, "Awesome Notifications Flutter plugin initialized");

        result.success(true);
    }

    @SuppressWarnings("unchecked")
    private void channelMethodSetActionHandle(
            @NonNull final MethodCall call,
            @NonNull final Result result
    ) throws Exception {

        Map<String, Object> arguments = call.arguments();
        if(arguments == null)
            throw ExceptionFactory
                    .getInstance()
                    .createNewAwesomeException(
                            TAG,
                            ExceptionCode.CODE_MISSING_ARGUMENTS,
                            "Arguments are missing",
                            ExceptionCode.DETAILED_REQUIRED_ARGUMENTS);

        Object callbackActionObj = arguments.get(Definitions.ACTION_HANDLE);

        long silentCallback = callbackActionObj == null ? 0L : (Long) callbackActionObj;

        awesomeNotifications.attachAsMainInstance(this);
        awesomeNotifications.setActionHandle(silentCallback);

        boolean success = silentCallback != 0L;
        if(!success)
            Logger.w(
                    TAG,
                    "Attention: there is no valid static" +
                            " method to receive notification actions in background");

        result.success(success);
    }
}
