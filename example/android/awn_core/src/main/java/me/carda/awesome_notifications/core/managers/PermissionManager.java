package me.carda.awesome_notifications.core.managers;

import android.Manifest;
import android.app.Activity;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.net.Uri;
import android.os.Build;
import android.provider.Settings;

import androidx.annotation.NonNull;
import androidx.annotation.RequiresApi;
import androidx.core.app.ActivityCompat;
import androidx.core.app.NotificationManagerCompat;
import androidx.core.content.ContextCompat;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.LinkedBlockingDeque;

import javax.annotation.Nullable;

import me.carda.awesome_notifications.core.AwesomeNotifications;
import me.carda.awesome_notifications.core.completion_handlers.ActivityCompletionHandler;
import me.carda.awesome_notifications.core.completion_handlers.PermissionCompletionHandler;
import me.carda.awesome_notifications.core.enumerators.NotificationImportance;
import me.carda.awesome_notifications.core.enumerators.NotificationPermission;
import me.carda.awesome_notifications.core.exceptions.AwesomeNotificationsException;
import me.carda.awesome_notifications.core.exceptions.ExceptionCode;
import me.carda.awesome_notifications.core.exceptions.ExceptionFactory;
import me.carda.awesome_notifications.core.logs.Logger;
import me.carda.awesome_notifications.core.models.NotificationChannelModel;
import me.carda.awesome_notifications.core.utils.StringUtils;

public class PermissionManager {

    public static final int REQUEST_CODE = 101;
    final static int ON = 1;
    final static int OFF = 0;

    private final String TAG = "PermissionManager";

    private final StringUtils stringUtils;

    // ************** SINGLETON PATTERN ***********************

    private static PermissionManager instance;

    private PermissionManager(StringUtils stringUtils){
        this.stringUtils = stringUtils;
    }

    public static PermissionManager getInstance() {
        if (instance == null)
            instance = new PermissionManager(
                StringUtils.getInstance()
            );
        return instance;
    }

    // ********************************************************

    private final BlockingQueue<ActivityCompletionHandler> activityQueue
            = new LinkedBlockingDeque<ActivityCompletionHandler>();

    public Boolean areNotificationsGloballyAllowed(Context context) {
        NotificationManagerCompat manager = NotificationManagerCompat.from(context);
        return manager.areNotificationsEnabled();
    }

    public List<String> arePermissionsAllowed(Context context, String channelKey, List<String> permissions) throws AwesomeNotificationsException {
        List<String> permissionsAllowed = new ArrayList<String>();

        if(!areNotificationsGloballyAllowed(context))
            return  permissionsAllowed;

        for (String permission : permissions) {
            NotificationPermission permissionEnum = stringUtils.getEnumFromString(NotificationPermission.class, permission);
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

    private final List<String> oldAndroidShouldShowRationale = new ArrayList<String>(){{
        add(NotificationPermission.Sound.toString());
        add(NotificationPermission.CriticalAlert.toString());
        add(NotificationPermission.OverrideDnD.toString());
    }};

    private final List<String> newAndroidShouldntShowRationale = new ArrayList<String>(){{
        add(NotificationPermission.FullScreenIntent.toString());
        add(NotificationPermission.Provisional.toString());
    }};

    public List<String> shouldShowRationale(Context context, String channelKey, List<String> permissions) throws AwesomeNotificationsException {

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

    public boolean isSpecifiedPermissionGloballyAllowed(Context context, NotificationPermission permission){

        switch (permission){

            case PreciseAlarms:
                return ScheduleManager.isPreciseAlarmGloballyAllowed(context);

            case CriticalAlert:
                return isCriticalAlertsGloballyAllowed(context);

            case Badge:
                return BadgeManager.getInstance().getInstance().isBadgeGloballyAllowed(context);

            case OverrideDnD:
                return isDndOverrideAllowed(context);

            case Sound:
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N /*Android 7*/)
                    return isNotificationSoundGloballyAllowed(context);
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

    @RequiresApi(api = Build.VERSION_CODES.N)
    public boolean isNotificationSoundGloballyAllowed(Context context){
        NotificationManager manager = (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);
        int importance = manager.getImportance();
        return importance < 0 || importance >= NotificationManager.IMPORTANCE_DEFAULT;
    }

    public boolean isCriticalAlertsGloballyAllowed(Context context){
        NotificationManager notificationManager =
                ChannelManager
                        .getInstance()
                        .getAndroidNotificationManager(context);

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M /*Android 6*/) {
            return notificationManager.getCurrentInterruptionFilter() != NotificationManager.INTERRUPTION_FILTER_NONE;
        }

        // Critical alerts until Android 6 are "Treat as priority" or "Priority"
//            return (notificationManager.getNotificationPolicy().state
//                    & NotificationManager.Policy.STATE_CHANNELS_BYPASSING_DND) == 1;
        // TODO read "Treat as priority" or "Priority" property on notifications page
        return true;
    }

    public boolean isDndOverrideAllowed(Context context){
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            NotificationManager notificationManager = null;
            notificationManager = (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);
            return notificationManager.isNotificationPolicyAccessGranted();
        }
        return true;
    }

    public boolean isSpecifiedChannelPermissionAllowed(
            Context context,
            String channelKey,
            NotificationPermission permissionEnum
    ) throws AwesomeNotificationsException {

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O /*Android 8*/) {
            NotificationChannel channel =
                    ChannelManager
                            .getInstance()
                            .getAndroidChannel(context, channelKey);

            if(channel == null)
                throw ExceptionFactory
                        .getInstance()
                        .createNewAwesomeException(
                                TAG,
                                ExceptionCode.CODE_INVALID_ARGUMENTS,
                                "Channel "+channelKey+" does not exist.",
                                ExceptionCode.DETAILED_INVALID_ARGUMENTS+".channel.key");

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
            NotificationChannelModel channelModel =
                    ChannelManager
                            .getInstance()
                            .getChannelByKey(context, channelKey);

            if(channelModel == null)
                throw ExceptionFactory
                        .getInstance()
                        .createNewAwesomeException(
                                TAG,
                                ExceptionCode.CODE_INVALID_ARGUMENTS,
                                "Channel "+channelKey+" does not exist.",
                                ExceptionCode.DETAILED_INVALID_ARGUMENTS+".channel.key");

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

    public void requestUserPermissions(
            final Activity activity,
            final Context context,
            final String channelKey,
            final List<String> permissions,
            final PermissionCompletionHandler permissionCompletionHandler
    ) throws AwesomeNotificationsException {

        if(!permissions.isEmpty()){

            if(!areNotificationsGloballyAllowed(context)){
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {

                    String globalNotificationsPermissionCode = getManifestPermissionCode(null);
                    boolean requestAlreadyDenied =
                        activity
                            .shouldShowRequestPermissionRationale(globalNotificationsPermissionCode);

                    if(!requestAlreadyDenied){
                        shouldShowAndroidRequestDialog(
                                activity,
                                context,
                                channelKey,
                                permissions,
                                Collections.singletonList(globalNotificationsPermissionCode),
                                permissionCompletionHandler);
                        return;
                    }
                }

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
                NotificationPermission permissionEnum = stringUtils.getEnumFromString(NotificationPermission.class, permissionNeeded);
                String permissionCode = getManifestPermissionCode(permissionEnum);

                if(
                    permissionCode == null ||
                    Build.VERSION.SDK_INT < Build.VERSION_CODES.M ||
                    activity != null && activity.shouldShowRequestPermissionRationale(permissionCode)
                ){
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
            if(activity != null && !manifestPermissions.isEmpty()){
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
    private void shouldShowAndroidRequestDialog(
            final Activity activity,
            final Context context,
            final String channelKey,
            final List<String> permissions,
            final List<String> manifestPermissions,
            final PermissionCompletionHandler permissionCompletionHandler
    ) throws AwesomeNotificationsException {
        activity.requestPermissions(manifestPermissions.toArray(new String[0]), REQUEST_CODE);
        activityQueue.add(new ActivityCompletionHandler() {
            @Override
            public void handle() {
                refreshReturnedPermissions(context, channelKey, permissions, permissionCompletionHandler);
            }
        });
    }

    private void shouldShowRationalePage(
            final Context context,
            final String channelKey,
            final @Nullable NotificationPermission permissionEnum,
            final List<String> permissions,
            final PermissionCompletionHandler permissionCompletionHandler
    ) throws AwesomeNotificationsException {

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

    private void refreshReturnedPermissions(
            final Context context,
            final String channelKey,
            List<String> permissionsNeeded,
            final PermissionCompletionHandler permissionCompletionHandler
    ){
        try {
            if(!permissionsNeeded.isEmpty()) {

                if (!stringUtils.isNullOrEmpty(channelKey)){
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
        } catch (AwesomeNotificationsException e) {
            e.printStackTrace();
        }
        permissionCompletionHandler.handle(permissionsNeeded);
    }

    private void updateChannelModelThroughPermissions(
            final Context context,
            final @NonNull String channelKey,
            final @NonNull List<String> permissionsNeeded
    ) throws AwesomeNotificationsException {

        // For Android 8 and above, channels are updated at every load process
        if(Build.VERSION.SDK_INT >= Build.VERSION_CODES.O /*Android 8*/)
            return;

        NotificationChannelModel channelModel =
                ChannelManager
                        .getInstance()
                        .getChannelByKey(context, channelKey);

        if(channelModel == null) return;

        for (String permission : permissionsNeeded) {
            boolean isAllowed = isSpecifiedPermissionGloballyAllowed(context, stringUtils.getEnumFromString(NotificationPermission.class, permission));
            NotificationPermission permissionEnum = stringUtils.getEnumFromString(NotificationPermission.class, permission);
            setChannelPropertyThroughPermission(channelModel, permissionEnum, isAllowed);
        }

        try {
            ChannelManager
                    .getInstance()
                    .saveChannel(context, channelModel, false,false);
        } catch (AwesomeNotificationsException e) {
            e.printStackTrace();
        }
    }

    private void setChannelPropertyThroughPermission(NotificationChannelModel channelModel, NotificationPermission permission, boolean allowed){
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

    private String getManifestPermissionCode(@Nullable NotificationPermission permission){

        if (permission == null) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU /*Android 10*/)
                return Manifest.permission.POST_NOTIFICATIONS;
            return null;
        }

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

    public void showNotificationConfigPage(final Context context, final PermissionCompletionHandler permissionCompletionHandler){
        if (gotoAndroidAppNotificationPage(context))
            activityQueue.add(new ActivityCompletionHandler() {
                @Override
                public void handle() {
                    permissionCompletionHandler.handle(new ArrayList<String>());
                }
            });
        else permissionCompletionHandler.handle(new ArrayList<String>());
    }

    public void showChannelConfigPage(final Context context, final String channelKey, final PermissionCompletionHandler permissionCompletionHandler){
        if (gotoAndroidChannelPage(context, channelKey))
            activityQueue.add(new ActivityCompletionHandler() {
                @Override
                public void handle() {
                    permissionCompletionHandler.handle(new ArrayList<String>());
                }
            });
        else permissionCompletionHandler.handle(new ArrayList<String>());
    }

    public void showPreciseAlarmPage(final Context context, final PermissionCompletionHandler permissionCompletionHandler){
        if (gotoPreciseAlarmPage(context))
            activityQueue.add(new ActivityCompletionHandler() {
                @Override
                public void handle() {
                    permissionCompletionHandler.handle(new ArrayList<String>());
                }
            });
        else permissionCompletionHandler.handle(new ArrayList<String>());
    }

    public void showDnDGlobalOverridingPage(final Context context, final PermissionCompletionHandler permissionCompletionHandler){
        if (gotoControlsDnDPage(context))
            activityQueue.add(new ActivityCompletionHandler() {
                @Override
                public void handle() {
                    permissionCompletionHandler.handle(new ArrayList<String>());
                }
            });
        else permissionCompletionHandler.handle(new ArrayList<String>());
    }

    private boolean gotoAndroidGlobalNotificationsPage(final Context context){
        final Intent intent = new Intent();

        // TODO missing action link to global notifications page
        intent.setAction(Settings.ACTION_APPLICATION_DETAILS_SETTINGS);
        intent.setData(Uri.parse("package:" + AwesomeNotifications.getPackageName(context)));

        intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        return startVerifiedActivity(context, intent);
    }

    private boolean gotoAndroidAppNotificationPage(final Context context){
        final Intent intent = new Intent();

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O /*Android 8*/) {

            intent.setAction(Settings.ACTION_APP_NOTIFICATION_SETTINGS);
            intent.putExtra(Settings.EXTRA_APP_PACKAGE, AwesomeNotifications.getPackageName(context));

        } else {

            intent.setAction("android.settings.APP_NOTIFICATION_SETTINGS");
            intent.putExtra("app_package", AwesomeNotifications.getPackageName(context));
            intent.putExtra("app_uid", context.getApplicationInfo().uid);

        }

        intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        return startVerifiedActivity(context, intent);
    }

    private boolean gotoAndroidChannelPage(
            @NonNull final Context context,
            @NonNull final String channelKey
    ){
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationChannel channel =
                    ChannelManager
                            .getInstance()
                            .getAndroidChannel(context, channelKey);

            Intent intent = new Intent(Settings.ACTION_CHANNEL_NOTIFICATION_SETTINGS)
                    .putExtra(Settings.EXTRA_APP_PACKAGE, AwesomeNotifications.getPackageName(context));

            if(channel != null)
                intent.putExtra(Settings.EXTRA_CHANNEL_ID, channel.getId());
            else if (!stringUtils.isNullOrEmpty(channelKey))
                intent.putExtra(Settings.EXTRA_CHANNEL_ID, channelKey);

            intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            if(startVerifiedActivity(context, intent))
                return true;
        }
        return gotoAndroidAppNotificationPage(context);
    }

    private boolean gotoPreciseAlarmPage(
            @NonNull final Context context
    ){
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S /*Android 12*/) {
            final Intent intent = new Intent();

            intent.setAction(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM);
            intent.putExtra(Settings.EXTRA_APP_PACKAGE, AwesomeNotifications.getPackageName(context));
            intent.setData(Uri.parse("package:" + AwesomeNotifications.getPackageName(context)));

            intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            if(startVerifiedActivity(context, intent))
                return true;
        }
        return gotoAndroidAppNotificationPage(context);
    }

    private boolean gotoControlsDnDPage(
            @NonNull final Context context
    ){
        final Intent intent;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            intent = new Intent(
                    Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS);
            intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            if(startVerifiedActivity(context, intent))
                return true;
        }
        return gotoAndroidAppNotificationPage(context);
    }

    public boolean handlePermissionResult(
            final int requestCode,
            final String[] permissions,
            final int[] grantResults
    ) {
        if(requestCode != REQUEST_CODE)
            return false;

        fireActivityCompletionHandle();
        return true;
    }

    public boolean handleActivityResult(int requestCode, int resultCode, Intent data) {
        if(requestCode != REQUEST_CODE)
            return false;

        fireActivityCompletionHandle();
        return false;
    }

    private void fireActivityCompletionHandle(){
        if(activityQueue.isEmpty())
            return;

        if(AwesomeNotifications.debug)
            Logger.d(TAG, "New permissions request found waiting for user response");

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

    private boolean startVerifiedActivity(Context context, Intent intent){
        PackageManager packageManager = context.getPackageManager();
        if (intent.resolveActivity(packageManager) != null) {
            context.startActivity(intent);
            return true;
        } else {
            ExceptionFactory
                    .getInstance()
                    .registerNewAwesomeException(
                            TAG,
                            ExceptionCode.CODE_PAGE_NOT_FOUND,
                            "Activity permission action '"+intent.getAction()+"' not found!",
                            ExceptionCode.DETAILED_PAGE_NOT_FOUND+".permissionPage."+intent.getAction());
            return false;
        }
    }
}
