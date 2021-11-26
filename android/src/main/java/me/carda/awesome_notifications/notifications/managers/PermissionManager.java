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

import androidx.annotation.NonNull;
import androidx.annotation.RequiresApi;
import androidx.core.content.ContextCompat;
import androidx.core.app.NotificationManagerCompat;

import me.carda.awesome_notifications.Definitions;
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
        NotificationManagerCompat manager = NotificationManagerCompat.from(context);
        return manager.areNotificationsEnabled();
    }

    public static List<String> arePermissionsAllowed(Context context, String channelKey, List<String> permissions) throws AwesomeNotificationException {
        List<String> permissionsAllowed = new ArrayList<String>();

        if(!areNotificationsGloballyAllowed(context))
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

    private static final List<String> oldAndroidShouldShowRationale = new ArrayList<String>(){{
        add(NotificationPermission.Sound.toString());
        add(NotificationPermission.CriticalAlert.toString());
        add(NotificationPermission.OverrideDnD.toString());
    }};

    private static final List<String> newAndroidShouldntShowRationale = new ArrayList<String>(){{
        add(NotificationPermission.FullScreenIntent.toString());
        add(NotificationPermission.Provisional.toString());
    }};

    public static List<String> shouldShowRationale(Context context, String channelKey, List<String> permissions) throws AwesomeNotificationException {

        if(!areNotificationsGloballyAllowed(context))
            return permissions;

        // Channel's permission under Android 8 special condition
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O /*Android 8*/){
            permissions.removeAll(newAndroidShouldntShowRationale);
            List<String> allowedPermissions = arePermissionsAllowed(context, channelKey, permissions);
            permissions.removeAll(allowedPermissions);
        }
        else {
            List<String> permissionsShouldShowRationale = new ArrayList<String>();
            for (String permission : oldAndroidShouldShowRationale)
                if (permissions.contains(permission))
                    permissionsShouldShowRationale.add(permission);
            permissions = permissionsShouldShowRationale;

            List<String> allowedGlobalPermissions = arePermissionsAllowed(context, null, permissions);
            permissions.removeAll(allowedGlobalPermissions);
        }

        return permissions;
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
                        return channel.getImportance() >= NotificationManager.IMPORTANCE_DEFAULT && (channel.getSound() != null);

                    case Vibration:
                        return channel.getImportance() >= NotificationManager.IMPORTANCE_DEFAULT && channel.shouldVibrate();

                    case Light:
                        return channel.shouldShowLights();

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
                        return channelModel.importance.ordinal() >= NotificationImportance.Default.ordinal() && channelModel.playSound;

                    case Vibration:
                        return channelModel.importance.ordinal() >= NotificationImportance.Default.ordinal() && channelModel.enableVibration;

                    case Light:
                        return channelModel.enableLights;

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
            final Activity activity,
            final Context context,
            final String channelKey,
            final List<String> permissions,
            final PermissionCompletionHandler permissionCompletionHandler
    ) throws AwesomeNotificationException {

        if(!permissions.isEmpty()){

            if(!areNotificationsGloballyAllowed(context)){
                shouldShowRationalePage(
                        context,
                        channelKey,
                        null,
                        permissions,
                        permissionCompletionHandler);
                return;
            }

            List<String>permissionsRequested = new ArrayList<String>(permissions);
            List<String> allowedPermissions = arePermissionsAllowed(context, channelKey, permissionsRequested);

            permissionsRequested.removeAll(allowedPermissions);
            List<String> permissionsNeedingRationale = shouldShowRationale(context, channelKey, permissionsRequested);

            List<String> manifestPermissions = new ArrayList<String>();
            for (String permissionNeeded : permissionsNeedingRationale) {
                NotificationPermission permissionEnum = StringUtils.getEnumFromString(NotificationPermission.class, permissionNeeded);
                String permissionCode = getManifestPermissionCode(permissionEnum);

                if(permissionCode == null || Build.VERSION.SDK_INT < Build.VERSION_CODES.M || activity.shouldShowRequestPermissionRationale(permissionCode)) {
                    shouldShowRationalePage(
                            context,
                            channelKey,
                            permissionEnum,
                            permissionsRequested,
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
                        permissionsRequested,
                        manifestPermissions,
                        permissionCompletionHandler);
                return;
            }
        }

        refreshReturnedPermissions(context, channelKey, permissions, permissionCompletionHandler);
    }

    @RequiresApi(api = Build.VERSION_CODES.M)
    private static void shouldShowAndroidRequestDialog(
            final Activity activity,
            final Context context,
            final String channelKey,
            final List<String> permissions,
            final List<String> manifestPermissions,
            final PermissionCompletionHandler permissionCompletionHandler
    ) throws AwesomeNotificationException {

        activity.requestPermissions(manifestPermissions.toArray(new String[0]), REQUEST_CODE);
        activityQueue.add(new ActivityCompletionHandler() {
            @Override
            public void handle() {
                refreshReturnedPermissions(context, channelKey, permissions, permissionCompletionHandler);
            }
        });
    }

    private static void shouldShowRationalePage(
            final Context context,
            final String channelKey,
            final @Nullable NotificationPermission permissionEnum,
            final List<String> permissions,
            final PermissionCompletionHandler permissionCompletionHandler
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
                    refreshReturnedPermissions(context, channelKey, permissions, permissionCompletionHandler);
                }
            });
        else
            refreshReturnedPermissions(context, channelKey, permissions, permissionCompletionHandler);
    }

    private static void refreshReturnedPermissions(
            final Context context,
            final String channelKey,
            List<String> permissionsNeeded,
            final PermissionCompletionHandler permissionCompletionHandler
    ){
        try {
            if(!permissionsNeeded.isEmpty()) {

                if (!StringUtils.isNullOrEmpty(channelKey)){
                    List<String> allowedPermissions = arePermissionsAllowed(
                            context,
                            (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O /*Android 8*/) ?
                                    channelKey : null,
                            permissionsNeeded);
                    updateChannelModelThroughPermissions(context, channelKey, allowedPermissions);
                }

                List<String> allowedPermissions = arePermissionsAllowed(context, channelKey, permissionsNeeded);
                permissionsNeeded.removeAll(allowedPermissions);
            }
        } catch (AwesomeNotificationException e) {
            e.printStackTrace();
        }
        permissionCompletionHandler.handle(permissionsNeeded);
    }

    private static void updateChannelModelThroughPermissions(final Context context, final @NonNull String channelKey, final @NonNull List<String> permissionsNeeded) {

        // For Android 8 and above, channels are updated at every load process
        if(Build.VERSION.SDK_INT >= Build.VERSION_CODES.O /*Android 8*/)
            return;

        NotificationChannelModel channelModel = ChannelManager.getChannelByKey(context, channelKey);
        if(channelModel == null) return;

        for (String permission : permissionsNeeded) {
            boolean isAllowed = isSpecifiedPermissionGloballyAllowed(context, StringUtils.getEnumFromString(NotificationPermission.class, permission));
            NotificationPermission permissionEnum = StringUtils.getEnumFromString(NotificationPermission.class, permission);
            setChannelPropertyThroughPermission(channelModel, permissionEnum, isAllowed);
        }

        try {
            ChannelManager.saveChannel(context, channelModel, false);
        } catch (AwesomeNotificationException e) {
            e.printStackTrace();
        }
    }

    private static void setChannelPropertyThroughPermission(NotificationChannelModel channelModel, NotificationPermission permission, boolean allowed){
        switch (permission) {

            case Alert:
                if (allowed) {
                    if (channelModel.importance.ordinal() < NotificationImportance.High.ordinal())
                        channelModel.importance = NotificationImportance.High;
                }
                else {
                    if (channelModel.importance.ordinal() >= NotificationImportance.High.ordinal())
                        channelModel.importance = NotificationImportance.Default;
                }
                break;

            case Sound:
                channelModel.playSound = allowed;
                break;

            case Badge:
                channelModel.channelShowBadge = allowed;
                break;

            case Vibration:
                channelModel.enableVibration = allowed;
                break;

            case Light:
                channelModel.enableLights = allowed;
                break;

            case CriticalAlert:
                channelModel.criticalAlerts = allowed;
                break;

            case OverrideDnD:
            case Provisional:
            case PreciseAlarms:
            case FullScreenIntent:
            case Car:
                break;
        }
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

    public static void showNotificationConfigPage(final Context context, final PermissionCompletionHandler permissionCompletionHandler){
        if (gotoAndroidAppNotificationPage(context))
            activityQueue.add(new ActivityCompletionHandler() {
                @Override
                public void handle() {
                    permissionCompletionHandler.handle(new ArrayList<String>());
                }
            });
        else permissionCompletionHandler.handle(new ArrayList<String>());
    }

    public static void showChannelConfigPage(final Context context, final String channelKey, final PermissionCompletionHandler permissionCompletionHandler){
        if (gotoAndroidChannelPage(context, channelKey))
            activityQueue.add(new ActivityCompletionHandler() {
                @Override
                public void handle() {
                    permissionCompletionHandler.handle(new ArrayList<String>());
                }
            });
        else permissionCompletionHandler.handle(new ArrayList<String>());
    }

    public static void showPreciseAlarmPage(final Context context, final PermissionCompletionHandler permissionCompletionHandler){
        if (gotoPreciseAlarmPage(context))
            activityQueue.add(new ActivityCompletionHandler() {
                @Override
                public void handle() {
                    permissionCompletionHandler.handle(new ArrayList<String>());
                }
            });
        else permissionCompletionHandler.handle(new ArrayList<String>());
    }

    public static void showDnDGlobalOverridingPage(final Context context, final PermissionCompletionHandler permissionCompletionHandler){
        if (gotoControlsDnDPage(context))
            activityQueue.add(new ActivityCompletionHandler() {
                @Override
                public void handle() {
                    permissionCompletionHandler.handle(new ArrayList<String>());
                }
            });
        else permissionCompletionHandler.handle(new ArrayList<String>());
    }

    private static boolean gotoAndroidGlobalNotificationsPage(final Context context){
        final Intent intent = new Intent();

        // TODO missing action link to global notifications page
        intent.setAction(Settings.ACTION_APPLICATION_DETAILS_SETTINGS);
        intent.setData(Uri.parse("package:" + context.getPackageName()));

        intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        return startTestedActivity(context, intent);
    }

    private static boolean gotoAndroidAppNotificationPage(final Context context){
        final Intent intent = new Intent();

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O /*Android 8*/) {

            intent.setAction(Settings.ACTION_APP_NOTIFICATION_SETTINGS);
            intent.putExtra(Settings.EXTRA_APP_PACKAGE, context.getPackageName());

        } else {

            intent.setAction("android.settings.APP_NOTIFICATION_SETTINGS");
            intent.putExtra("app_package", context.getPackageName());
            intent.putExtra("app_uid", context.getApplicationInfo().uid);

        }

        intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        return startTestedActivity(context, intent);
    }

    private static boolean gotoAndroidChannelPage(final Context context, final String channelKey){
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationChannel channel = ChannelManager.getAndroidChannel(context, channelKey);

            Intent intent = new Intent(Settings.ACTION_CHANNEL_NOTIFICATION_SETTINGS)
                    .putExtra(Settings.EXTRA_APP_PACKAGE, context.getPackageName())
                    .putExtra(Settings.EXTRA_CHANNEL_ID, channel.getId());

            intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            if(startTestedActivity(context, intent))
                return true;
        }
        return gotoAndroidAppNotificationPage(context);
    }

    private static boolean gotoPreciseAlarmPage(final Context context){
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S /*Android 12*/) {
            final Intent intent = new Intent();

            intent.setAction(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM);
            intent.putExtra(Settings.EXTRA_APP_PACKAGE, context.getPackageName());
            intent.setData(Uri.parse("package:" + context.getPackageName()));

            intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            if(startTestedActivity(context, intent))
                return true;
        }
        return gotoAndroidAppNotificationPage(context);
    }

    private static boolean gotoControlsDnDPage(final Context context){
        final Intent intent;
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
            intent = new Intent(
                    Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS);
            intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            if(startTestedActivity(context, intent))
                return true;
        }
        return gotoAndroidAppNotificationPage(context);
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
        if(activityQueue.isEmpty())
            return;

        int retries = 3;
        ActivityCompletionHandler completionHandler;
        do{
            completionHandler = null;
            try {
                if(!activityQueue.isEmpty())
                    completionHandler = activityQueue.take();
            } catch (InterruptedException e) {
                retries--;
            }

            if(completionHandler != null){
                completionHandler.handle();
                retries = 3;
            }
        } while (retries > 0 && completionHandler != null);
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
