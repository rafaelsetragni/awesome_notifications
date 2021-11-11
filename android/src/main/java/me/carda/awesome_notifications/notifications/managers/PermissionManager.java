package me.carda.awesome_notifications.notifications.managers;

import android.Manifest;
import android.app.Activity;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.content.pm.PackageManager;
import android.net.Uri;
import android.provider.Settings;
import android.content.Context;
import android.content.Intent;
import android.os.Build;
import android.util.Log;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.LinkedBlockingDeque;

import androidx.annotation.NonNull;
import androidx.core.content.ContextCompat;
import androidx.core.app.NotificationManagerCompat;

import me.carda.awesome_notifications.AwesomePermissionHandler;
import me.carda.awesome_notifications.notifications.handlers.ActivityCompletionHandler;
import me.carda.awesome_notifications.notifications.handlers.PermissionCompletionHandler;
import me.carda.awesome_notifications.notifications.enumerators.NotificationImportance;
import me.carda.awesome_notifications.notifications.enumerators.NotificationPermission;
import me.carda.awesome_notifications.notifications.exceptions.AwesomeNotificationException;
import me.carda.awesome_notifications.notifications.models.NotificationChannelModel;
import me.carda.awesome_notifications.utils.StringUtils;

public class PermissionManager {

    public static final int REQUEST_CODE = 101;
    private final static String TAG = "PermissionManager";

    private static final BlockingQueue<ActivityCompletionHandler> activityQueue
            = new LinkedBlockingDeque<ActivityCompletionHandler>();

    public static List<String> arePermissionsAllowed(Activity activity, Context context, String channelKey, List<String> permissions) throws AwesomeNotificationException {
        List<String> permissionsAllowed = new ArrayList<>();

        if(!areNotificationsGloballyAllowed(context))
            return  permissionsAllowed;

        if(activity == null)
            return  permissionsAllowed;

        for (String permission : permissions) {
            NotificationPermission permissionEnum = StringUtils.getEnumFromString(NotificationPermission.class, permission);
            if(
                permissionEnum != null &&
                isSpecifiedPermissionGloballyAllowed(context, permissionEnum) &&
                (channelKey == null || isSpecifiedChannelPermissionAllowed(context, channelKey, permissionEnum))
            )
                permissionsAllowed.add(permission);
        }

        return permissionsAllowed;
    }

    public static Boolean areNotificationsGloballyAllowed(Context context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            NotificationManagerCompat manager = NotificationManagerCompat.from(context);
            return manager.areNotificationsEnabled();
        }
        return true;
    }

    public static boolean isSpecifiedPermissionGloballyAllowed(Context context, NotificationPermission permission){
        String permissionCode = getManifestPermission(permission);

        if(permissionCode == null)
            return true;

        return ContextCompat.checkSelfPermission(context, permissionCode) != PackageManager.PERMISSION_DENIED;
    }

    public static boolean isSpecifiedChannelPermissionAllowed(Context context, String channelKey, NotificationPermission permissionEnum) throws AwesomeNotificationException {

        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
            NotificationChannel channel = ChannelManager.getAndroidChannel(context, channelKey);
            if(channel == null)
                throw new AwesomeNotificationException("Channel "+channelKey+" does not exists.");

            if(channel.getImportance() != NotificationManager.IMPORTANCE_NONE){

                switch (permissionEnum){
                    case Sound:
                        return (channel.getSound() != null);

                    case PreciseAlarms:
                    case CriticalAlert:
                    default:
                        return true;
                }

            }
            return false;
        }
        else {
            NotificationChannelModel channelModel = ChannelManager.getChannelByKey(context, channelKey);
            if(channelModel == null)
                throw new AwesomeNotificationException("Channel "+channelKey+" does not exists.");

            if(channelModel.importance != NotificationImportance.None){

                switch (permissionEnum){
                    case Sound:
                        return channelModel.playSound;

                    case PreciseAlarms:
                    case CriticalAlert:
                    default:
                        return true;
                }

            }
            return false;
        }
    }

    public static void requestUserPermissions(
            Activity activity,
            Context context,
            String channelKey,
            List<String> permissions,
            PermissionCompletionHandler permissionCompletionHandler
    ) throws AwesomeNotificationException {

        if(!permissions.isEmpty()){

            if(areNotificationsGloballyAllowed(context)) {

                List<String> allowedPermissions = arePermissionsAllowed(activity, context, channelKey, permissions);

                permissions.removeAll(allowedPermissions);
                List<String> manifestPermissions = new ArrayList<>();

                for (String permissionNeeded : permissions) {
                    NotificationPermission permissionEnum = StringUtils.getEnumFromString(NotificationPermission.class, permissionNeeded);
                    String permissionCode = getManifestPermission(permissionEnum);
                    if(permissionCode != null){
                        if(activity.shouldShowRequestPermissionRationale(permissionCode))
                            throw new AwesomeNotificationException("The Requests is not granted and the app must prompt a ratinale user dialog");
                        manifestPermissions.add(permissionCode);
                    }
                }

                if(manifestPermissions.isEmpty()){
                    if(StringUtils.isNullOrEmpty(channelKey))
                        gotoAndroidNotificationConfigPage(context);
                    else
                        gotoAndroidChannelPage(context, channelKey);
                }
                else {
                    /*if(manifestPermissions.contains(getManifestPermission(NotificationPermission.PreciseAlarms)))
                        gotoPreciseAlarmPage(context);*/
                    activity.requestPermissions(manifestPermissions.toArray(new String[0]), REQUEST_CODE);
                }
            }
            else gotoAndroidNotificationConfigPage(context);
        }
        else gotoAndroidNotificationConfigPage(context);

        activityQueue.add(new ActivityCompletionHandler() {
            @Override
            public void handle() {
                try {
                    List<String> permissionsAllowed = arePermissionsAllowed(activity, context, channelKey, permissions);
                    permissionCompletionHandler.handle(permissionsAllowed);
                } catch (AwesomeNotificationException e) {
                    e.printStackTrace();
                    permissionCompletionHandler.handle(permissions);
                }
            }
        });
    }

    private static String getManifestPermission(NotificationPermission permission){

        switch (permission){

            case FullScreenIntent:
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q)
                    return Manifest.permission.USE_FULL_SCREEN_INTENT;
                return null;

            case PreciseAlarms:
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S)
                    return Manifest.permission.SCHEDULE_EXACT_ALARM;
                return null;

            case Alert:
            case Sound:
            case Badge:

            case CriticalAlert:
                // TODO implement critical alerts for Android

            case Provisional:
            case Car:

            default:
                return null;
        }
    }

    public static void showNotificationConfigPage(Context context, PermissionCompletionHandler permissionCompletionHandler){
        gotoAndroidNotificationConfigPage(context);
        activityQueue.add(() -> permissionCompletionHandler.handle(new ArrayList<>()));
    }

    public static void showChannelConfigPage(Context context, String channelKey, PermissionCompletionHandler permissionCompletionHandler){
        gotoAndroidChannelPage(context, channelKey);
        activityQueue.add(() -> permissionCompletionHandler.handle(new ArrayList<>()));
    }

    public static void showPreciseAlarmPage(Context context, PermissionCompletionHandler permissionCompletionHandler){
        gotoPreciseAlarmPage(context);
        activityQueue.add(() -> permissionCompletionHandler.handle(new ArrayList<>()));
    }

    private static void gotoAndroidNotificationConfigPage(Context context){
        final Intent intent = new Intent();
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O /*Android 8*/) {
            intent.setAction(Settings.ACTION_APP_NOTIFICATION_SETTINGS);
            intent.putExtra(Settings.EXTRA_APP_PACKAGE, context.getPackageName());
        } else
            // Android 5 (LOLLIPOP) is now the minimum required
            /* if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP)*/{
            intent.setAction("android.settings.APP_NOTIFICATION_SETTINGS");
            intent.putExtra("app_package", context.getPackageName());
            intent.putExtra("app_uid", context.getApplicationInfo().uid);
        } /*else {
            intent.addCategory(Intent.CATEGORY_DEFAULT);
            intent.setData(Uri.parse("package:" + applicationContext.getPackageName()));
        }*/
        //intent.setData(Uri.parse("package:" + context.getPackageName()));

        intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        context.startActivity(intent);
    }

    private static void gotoAndroidChannelPage(Context context, String channelKey){
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationChannel channel = ChannelManager.getAndroidChannel(context, channelKey);

            Intent intent = new Intent(Settings.ACTION_CHANNEL_NOTIFICATION_SETTINGS)
                    .putExtra(Settings.EXTRA_APP_PACKAGE, context.getPackageName())
                    .putExtra(Settings.EXTRA_CHANNEL_ID, channel.getId());

            intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            context.startActivity(intent);
        }
        else gotoAndroidNotificationConfigPage(context);
    }

    private static void gotoPreciseAlarmPage(Context context){
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S /*Android 12*/) {
            final Intent intent = new Intent();

            intent.setAction(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM);
            intent.putExtra(Settings.EXTRA_APP_PACKAGE, context.getPackageName());
            intent.setData(Uri.parse("package:" + context.getPackageName()));

            intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            context.startActivity(intent);
        }
    }

    private static void gotoBadgePage(Context context, PermissionCompletionHandler permissionCompletionHandler){
        final Intent intent = new Intent();
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O /*Android 8*/) {
            intent.setAction(Settings.ACTION_APP_NOTIFICATION_SETTINGS);
            intent.putExtra(Settings.EXTRA_APP_PACKAGE, context.getPackageName());
        } else
            // Android 5 (LOLLIPOP) is now the minimum required
            /* if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP)*/{
            intent.setAction("android.settings.APP_NOTIFICATION_SETTINGS");
            intent.putExtra("app_package", context.getPackageName());
            intent.putExtra("app_uid", context.getApplicationInfo().uid);
        } /*else {
            intent.addCategory(Intent.CATEGORY_DEFAULT);
            intent.setData(Uri.parse("package:" + applicationContext.getPackageName()));
        }*/
        //intent.setData(Uri.parse("package:" + context.getPackageName()));

        intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        context.startActivity(intent);
    }

    public static boolean handlePermissionResult(final int requestCode, @NonNull final String[] permissions, @NonNull final int[] grantResults) {
        if(requestCode != REQUEST_CODE)
            return false;

        fireActivityCompletionHandle();
        return true;
    }

    public static boolean handleActivityResult(int requestCode, int resultCode, Intent data) {
        if(requestCode != REQUEST_CODE)
            return false;

        fireActivityCompletionHandle();
        return false;
    }

    private static void fireActivityCompletionHandle(){
        while(!activityQueue.isEmpty()){
            try {
                ActivityCompletionHandler completionHandler = activityQueue.take();
                completionHandler.handle();
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        }
    }
}
