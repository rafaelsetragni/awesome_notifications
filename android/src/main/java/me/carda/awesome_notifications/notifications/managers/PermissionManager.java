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
import java.util.List;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.LinkedBlockingDeque;

import androidx.annotation.NonNull;
import androidx.core.content.ContextCompat;
import androidx.core.app.NotificationManagerCompat;

import me.carda.awesome_notifications.notifications.handlers.ActivityCompletionHandler;
import me.carda.awesome_notifications.notifications.handlers.PermissionCompletionHandler;
import me.carda.awesome_notifications.notifications.enumerators.NotificationImportance;
import me.carda.awesome_notifications.notifications.enumerators.NotificationPermission;
import me.carda.awesome_notifications.notifications.exceptions.AwesomeNotificationException;
import me.carda.awesome_notifications.notifications.models.NotificationChannelModel;
import me.carda.awesome_notifications.utils.StringUtils;

public class PermissionManager {

    public static final int REQUEST_CODE = 101;
    static final int ON = 1;
    static final int OFF = 0;

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
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N /*Android 7*/) {
            NotificationManagerCompat manager = NotificationManagerCompat.from(context);
            return manager.areNotificationsEnabled();
        }
        return true;
    }

    public static boolean isSpecifiedPermissionGloballyAllowed(Context context, NotificationPermission permission){

        switch (permission){

            case CriticalAlert:
                NotificationManager notificationManager = (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);
                return notificationManager.isNotificationPolicyAccessGranted();

            case Badge:
                return checkBadgePermission(context);

            case PreciseAlarms:
                return ScheduleManager.isPreciseAlarmEnable(context);

            case Alert:
            case Sound:

            case Provisional:
            case FullScreenIntent:
            case Car:
                break;
        }

        String permissionCode = getManifestPermission(permission);

        if(permissionCode == null)
            return true;

        return ContextCompat.checkSelfPermission(context, permissionCode) == PackageManager.PERMISSION_GRANTED;
    }

    private static boolean checkBadgePermission(Context context){
        try {
            return Settings.Secure.getInt(context.getContentResolver(), "notification_badging") == ON;
        } catch (Settings.SettingNotFoundException e) {
            return true;
        }
    }

    public static boolean isSpecifiedChannelPermissionAllowed(Context context, String channelKey, NotificationPermission permissionEnum) throws AwesomeNotificationException {

        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O /*Android 8*/) {
            NotificationChannel channel = ChannelManager.getAndroidChannel(context, channelKey);
            if(channel == null)
                throw new AwesomeNotificationException("Channel "+channelKey+" does not exist.");

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
                throw new AwesomeNotificationException("Channel "+channelKey+" does not exist.");

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

        boolean success = false;
        if(!permissions.isEmpty()){

            if(areNotificationsGloballyAllowed(context)) {

                List<String> allowedPermissions = arePermissionsAllowed(activity, context, channelKey, permissions);

                permissions.removeAll(allowedPermissions);
                List<String> manifestPermissions = new ArrayList<>();

                for (String permissionNeeded : permissions) {
                    NotificationPermission permissionEnum = StringUtils.getEnumFromString(NotificationPermission.class, permissionNeeded);
                    String permissionCode = getManifestPermission(permissionEnum);
                    if(permissionCode != null){
//                        if(activity.shouldShowRequestPermissionRationale(permissionCode))
//                            throw new AwesomeNotificationException("The Requests is not granted and the app must prompt a rationale user dialog");
                        manifestPermissions.add(permissionCode);
                    }
                }

                if(manifestPermissions.isEmpty()){
                    if(StringUtils.isNullOrEmpty(channelKey))
                        success = gotoAndroidNotificationConfigPage(context);
                    else
                        success = gotoAndroidChannelPage(context, channelKey);
                }
                else {
                    /*if(manifestPermissions.contains(getManifestPermission(NotificationPermission.PreciseAlarms))){
                        gotoPreciseAlarmPage(context);
                    }
                    else {*/
                        activity.requestPermissions(manifestPermissions.toArray(new String[0]), REQUEST_CODE);
                        success = true;
                    //}
                }
            }
            else success = gotoAndroidNotificationConfigPage(context);
        }
        else success = gotoAndroidNotificationConfigPage(context);

        if(success)
            activityQueue.add(new ActivityCompletionHandler() {
                @Override
                public void handle() {
                    refreshReturnedPermissions(activity, context, channelKey, permissions, permissionCompletionHandler);
                }
            });
        else
            refreshReturnedPermissions(activity, context, channelKey, permissions, permissionCompletionHandler);
    }

    private static void refreshReturnedPermissions(
            Activity activity,
            Context context,
            String channelKey,
            List<String> permissions,
            PermissionCompletionHandler permissionCompletionHandler
    ) throws AwesomeNotificationException {
        try {
            if(!permissions.isEmpty()) {
                List<String> allowedPermissions = arePermissionsAllowed(activity, context, channelKey, permissions);
                permissions.removeAll(allowedPermissions);
            }
        } catch (AwesomeNotificationException e) {
            e.printStackTrace();
        }
        permissionCompletionHandler.handle(permissions);
    }

    private static String getManifestPermission(NotificationPermission permission){

        switch (permission){

            case FullScreenIntent:
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q /*Android 10*/)
                    return Manifest.permission.USE_FULL_SCREEN_INTENT;
                return null;

            case PreciseAlarms:
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S /*Android 12*/)
                    return Manifest.permission.SCHEDULE_EXACT_ALARM;
                return null;

            case CriticalAlert:
                return Manifest.permission.ACCESS_NOTIFICATION_POLICY;

            case Badge:
            case Alert:
            case Sound:

            case Provisional:
            case Car:

            default:
                return null;
        }
    }

    public static void showNotificationConfigPage(Context context, PermissionCompletionHandler permissionCompletionHandler){
        if (gotoAndroidNotificationConfigPage(context))
            activityQueue.add(() -> permissionCompletionHandler.handle(new ArrayList<>()));
        else permissionCompletionHandler.handle(new ArrayList<>());
    }

    public static void showChannelConfigPage(Context context, String channelKey, PermissionCompletionHandler permissionCompletionHandler){
        if (gotoAndroidChannelPage(context, channelKey))
            activityQueue.add(() -> permissionCompletionHandler.handle(new ArrayList<>()));
        else permissionCompletionHandler.handle(new ArrayList<>());
    }

    public static void showPreciseAlarmPage(Context context, PermissionCompletionHandler permissionCompletionHandler){
        if (gotoPreciseAlarmPage(context))
            activityQueue.add(() -> permissionCompletionHandler.handle(new ArrayList<>()));
        else permissionCompletionHandler.handle(new ArrayList<>());
    }

    private static boolean gotoAndroidConfigPage(Context context){
        final Intent intent = new Intent();

        intent.setAction(Settings.ACTION_APPLICATION_DETAILS_SETTINGS);
        intent.setData(Uri.parse("package:" + context.getPackageName()));

        intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        return startTestedActivity(context, intent);
    }

    private static boolean gotoAndroidNotificationConfigPage(Context context){
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
        return startTestedActivity(context, intent);
    }

    private static boolean gotoAndroidChannelPage(Context context, String channelKey){
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationChannel channel = ChannelManager.getAndroidChannel(context, channelKey);

            Intent intent = new Intent(Settings.ACTION_CHANNEL_NOTIFICATION_SETTINGS)
                    .putExtra(Settings.EXTRA_APP_PACKAGE, context.getPackageName())
                    .putExtra(Settings.EXTRA_CHANNEL_ID, channel.getId());

            intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            return startTestedActivity(context, intent);
        }
        else return gotoAndroidNotificationConfigPage(context);
    }

    private static boolean gotoPreciseAlarmPage(Context context){
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S /*Android 12*/) {
            final Intent intent = new Intent();

            intent.setAction(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM);
            intent.putExtra(Settings.EXTRA_APP_PACKAGE, context.getPackageName());
            intent.setData(Uri.parse("package:" + context.getPackageName()));

            intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            return startTestedActivity(context, intent);
        }
        return gotoAndroidNotificationConfigPage(context);
    }

    private static boolean gotoBadgePage(Context context, PermissionCompletionHandler permissionCompletionHandler){
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
        return startTestedActivity(context, intent);
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

    private static boolean startTestedActivity(Context context, Intent intent){
        PackageManager packageManager = context.getPackageManager();
        if (intent.resolveActivity(packageManager) != null) {
            context.startActivity(intent);
            return true;
        } else {
            Log.e(TAG, "Activity permission action '"+intent.getAction()+"' not found!");
            return false;
        }
    }
}
