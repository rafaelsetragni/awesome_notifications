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

import javax.annotation.Nullable;

import androidx.core.content.ContextCompat;
import androidx.core.app.NotificationManagerCompat;

import me.carda.awesome_notifications.notifications.NotificationBuilder;
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

    public static Boolean areNotificationsGloballyAllowed(Context context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N /*Android 7*/) {
            NotificationManagerCompat manager = NotificationManagerCompat.from(context);
            return manager.areNotificationsEnabled();
        }
        return true;
    }

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
            ) {
                permissionsAllowed.add(permission);
            }
        }

        return permissionsAllowed;
    }

    public static boolean isSpecifiedPermissionGloballyAllowed(Context context, NotificationPermission permission){

        switch (permission){

            case PreciseAlarms:
                return ScheduleManager.isPreciseAlarmGloballyAllowed(context);

            case CriticalAlert:
                return NotificationBuilder.isCriticalAlertsGloballyAllowed(context);

            case Badge:
                return BadgeManager.isBadgeGloballyAllowed(context);

            case OverrideDnD:
                return NotificationBuilder.isDndOverrideAllowed(context);

            case Sound:
                if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.N /*Android 7*/)
                    return NotificationBuilder.isNotificationSoundGloballyAllowed(context);
                break;

            case FullScreenIntent:
                // check in android manifest

            case Alert:
            case Vibration:
            case Light:

            case Provisional:
            case Car:
            default:
                break;
        }

        String permissionCode = getManifestPermissionCode(permission);

        if(permissionCode == null)
            return true;

        return ContextCompat.checkSelfPermission(context, permissionCode) == PackageManager.PERMISSION_GRANTED;
    }

    public static boolean isSpecifiedChannelPermissionAllowed(Context context, String channelKey, NotificationPermission permissionEnum) throws AwesomeNotificationException {

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O /*Android 8*/) {
            NotificationChannel channel = ChannelManager.getAndroidChannel(context, channelKey);
            if(channel == null)
                throw new AwesomeNotificationException("Channel "+channelKey+" does not exist.");

            if(channel.getImportance() != NotificationManager.IMPORTANCE_NONE){

                switch (permissionEnum){

                    case Alert:
                        return channel.getImportance() >= NotificationManager.IMPORTANCE_HIGH;

                    case Sound:
                        return (channel.getSound() != null);

                    case Light:
                        return channel.shouldShowLights();

                    case Vibration:
                        return channel.shouldVibrate();

                    case Badge:
                        return channel.canShowBadge();

                    case CriticalAlert:
                        return channel.canBypassDnd();

                    case PreciseAlarms:
                    default:
                        return true;
                }

            }
        }
        else {
            NotificationChannelModel channelModel = ChannelManager.getChannelByKey(context, channelKey);
            if(channelModel == null)
                throw new AwesomeNotificationException("Channel "+channelKey+" does not exist.");

            if(channelModel.importance != NotificationImportance.None){

                switch (permissionEnum){

                    case Alert:
                        return channelModel.importance.ordinal() >= NotificationImportance.High.ordinal();

                    case Sound:
                        return channelModel.playSound;

                    case Light:
                        return channelModel.enableLights;

                    case Vibration:
                        return channelModel.enableVibration;

                    case Badge:
                        return channelModel.channelShowBadge;

                    case CriticalAlert:
                        return channelModel.criticalAlerts;

                    case PreciseAlarms:
                    default:
                        return true;
                }

            }
        }
        return false;
    }

    public static void requestUserPermissions(
            Activity activity,
            Context context,
            String channelKey,
            List<String> permissions,
            PermissionCompletionHandler permissionCompletionHandler
    ) throws AwesomeNotificationException {

        if(!permissions.isEmpty()){

            if(!areNotificationsGloballyAllowed(context)){
                shouldShowRationalePage(
                        activity,
                        context,
                        channelKey,
                        null,
                        permissions,
                        permissionCompletionHandler);
                return;
            }

            List<String> allowedPermissions = arePermissionsAllowed(activity, context, channelKey, permissions);

            permissions.removeAll(allowedPermissions);
            List<String> manifestPermissions = new ArrayList<>();

            for (String permissionNeeded : permissions) {
                NotificationPermission permissionEnum = StringUtils.getEnumFromString(NotificationPermission.class, permissionNeeded);
                String permissionCode = getManifestPermissionCode(permissionEnum);

                if(permissionCode == null || activity.shouldShowRequestPermissionRationale(permissionCode)) {
                    shouldShowRationalePage(
                            activity,
                            context,
                            channelKey,
                            permissionEnum,
                            permissions,
                            permissionCompletionHandler);
                    return;
                }
                else manifestPermissions.add(permissionCode);
            }

            // System will prompt a standard dialog
            if(!manifestPermissions.isEmpty()){
                shouldShowAndroidRequestDialog(
                        activity,
                        context,
                        channelKey,
                        permissions,
                        manifestPermissions,
                        permissionCompletionHandler);
                return;
            }
        }

        refreshReturnedPermissions(activity, context, channelKey, permissions, permissionCompletionHandler);
    }

    private static void shouldShowAndroidRequestDialog(
            Activity activity,
            Context context,
            String channelKey,
            List<String> permissions,
            List<String> manifestPermissions,
            PermissionCompletionHandler permissionCompletionHandler
    ) throws AwesomeNotificationException {

        activity.requestPermissions(manifestPermissions.toArray(new String[0]), REQUEST_CODE);
        activityQueue.add(new ActivityCompletionHandler() {
            @Override
            public void handle() {
                refreshReturnedPermissions(activity, context, channelKey, permissions, permissionCompletionHandler);
            }
        });
    }

    private static void shouldShowRationalePage(
            Activity activity,
            Context context,
            String channelKey,
            @Nullable NotificationPermission permissionEnum,
            List<String> permissions,
            PermissionCompletionHandler permissionCompletionHandler
    ) throws AwesomeNotificationException {

        boolean success;

        if(permissionEnum == null)
            success = gotoAndroidAppNotificationPage(context);
        else
            switch (permissionEnum){

                case PreciseAlarms:
                    success = gotoPreciseAlarmPage(context);
                    break;

                case OverrideDnD:
                    success = gotoControlsDnDPage(context);
                    break;

                case Badge:
                case Alert:
                case Sound:
                case Light:
                case Vibration:
                case CriticalAlert:
                    success = gotoAndroidChannelPage(context, channelKey);
                    break;

                case FullScreenIntent:
                case Car:
                default:
                    success = gotoAndroidAppNotificationPage(context);
            }

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
    ){
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

    private static String getManifestPermissionCode(NotificationPermission permission){

        switch (permission){

            case FullScreenIntent:
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q /*Android 10*/)
                    return Manifest.permission.USE_FULL_SCREEN_INTENT;
                return null;

            case PreciseAlarms:
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S /*Android 12*/)
                    return Manifest.permission.SCHEDULE_EXACT_ALARM;
                return null;

            case OverrideDnD:
                // For permission testing purposes only
                // return Manifest.permission.READ_EXTERNAL_STORAGE;
                // Does not call any Android dialog until version 12
                // return Manifest.permission.ACCESS_NOTIFICATION_POLICY;

            case Badge:
            case Alert:
            case Sound:
            case CriticalAlert:
            case Provisional:
            case Car:

            default:
                return null;
        }
    }

    public static void showNotificationConfigPage(Context context, PermissionCompletionHandler permissionCompletionHandler){
        if (gotoAndroidAppNotificationPage(context))
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

    public static void showDnDGlobalOverridingPage(Context context, PermissionCompletionHandler permissionCompletionHandler){
        if (gotoControlsDnDPage(context))
            activityQueue.add(() -> permissionCompletionHandler.handle(new ArrayList<>()));
        else permissionCompletionHandler.handle(new ArrayList<>());
    }

    private static boolean gotoAndroidGlobalNotificationsPage(Context context){
        final Intent intent = new Intent();

        // TODO missing action link to global notifications page
        intent.setAction(Settings.ACTION_APPLICATION_DETAILS_SETTINGS);
        intent.setData(Uri.parse("package:" + context.getPackageName()));

        intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        return startTestedActivity(context, intent);
    }

    private static boolean gotoAndroidAppNotificationPage(Context context){
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
        else return gotoAndroidAppNotificationPage(context);
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
        return gotoAndroidAppNotificationPage(context);
    }

    private static boolean gotoControlsDnDPage(Context context){
        final Intent intent = new Intent(
                android.provider.Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS);
        intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        return startTestedActivity(context, intent);
    }

    public static boolean handlePermissionResult(final int requestCode, final String[] permissions, final int[] grantResults) {
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
