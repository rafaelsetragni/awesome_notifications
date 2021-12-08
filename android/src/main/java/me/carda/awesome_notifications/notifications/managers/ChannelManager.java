package me.carda.awesome_notifications.notifications.managers;

import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.content.Context;
import android.media.AudioAttributes;
import android.media.RingtoneManager;
import android.net.Uri;
import android.os.Build;
import android.util.Log;

import java.util.Arrays;
import java.util.List;

import androidx.annotation.RequiresApi;
import me.carda.awesome_notifications.AwesomeNotificationsPlugin;
import me.carda.awesome_notifications.Definitions;
import me.carda.awesome_notifications.notifications.NotificationBuilder;
import me.carda.awesome_notifications.notifications.enumerators.DefaultRingtoneType;
import me.carda.awesome_notifications.notifications.enumerators.NotificationImportance;
import me.carda.awesome_notifications.notifications.enumerators.NotificationPrivacy;
import me.carda.awesome_notifications.notifications.exceptions.AwesomeNotificationException;
import me.carda.awesome_notifications.notifications.models.NotificationChannelGroupModel;
import me.carda.awesome_notifications.notifications.models.NotificationChannelModel;
import me.carda.awesome_notifications.utils.AudioUtils;
import me.carda.awesome_notifications.utils.BooleanUtils;
import me.carda.awesome_notifications.utils.StringUtils;

public class ChannelManager {

    private static final SharedManager<NotificationChannelModel> shared
            = new SharedManager<>(
                    "ChannelManager",
                    NotificationChannelModel.class,
                    "NotificationChannelModel");
    
    private static final String TAG = "ChannelManager";

    public static Boolean removeChannel(Context context, String channelKey) {

        NotificationChannelModel channelModel = getChannelByKey(context, channelKey);

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O /*Android 8*/) {
            removeAndroidChannel(context, channelKey, channelModel != null ? channelModel.getChannelHashKey(context, false) : null);
        }

        return shared.remove(context, Definitions.SHARED_CHANNELS, channelKey);
    }

    public static NotificationChannelModel getChannelByKey(Context context, String channelKey){

        if(StringUtils.isNullOrEmpty(channelKey)) {
            if(AwesomeNotificationsPlugin.debug)
                Log.e(TAG, "'"+channelKey+"' cannot be empty or null");
            return null;
        }

        NotificationChannelModel channelModel = shared.get(context, Definitions.SHARED_CHANNELS, channelKey);
        if(channelModel == null) {
            if(AwesomeNotificationsPlugin.debug)
                Log.e(TAG, "Channel model '"+channelKey+"' was not found");
            return null;
        }

        channelModel.refreshIconResource(context);
        if(Build.VERSION.SDK_INT >= Build.VERSION_CODES.O /*Android 8*/){

            NotificationChannel androidChannel = getAndroidChannel(context, channelKey);
            if(androidChannel == null) {
                if(AwesomeNotificationsPlugin.debug)
                    Log.e(TAG, "Android native channel '"+channelKey+"' was not found");
                return null;
            }

            if(androidChannel.getImportance() == NotificationManager.IMPORTANCE_NONE){
                if(AwesomeNotificationsPlugin.debug)
                    Log.e(TAG, "Android native channel '"+channelKey+"' is disabled");
            }

            updateChannelModelThroughAndroidChannel(channelModel, androidChannel);
        }

        return channelModel;
    }

    @RequiresApi(api = Build.VERSION_CODES.O)
    private static void updateChannelModelThroughAndroidChannel(NotificationChannelModel channelModel, NotificationChannel androidChannel){
        channelModel.channelName = String.valueOf(androidChannel.getName());
        channelModel.channelDescription = androidChannel.getDescription();
        channelModel.channelShowBadge = androidChannel.canShowBadge();
        channelModel.playSound = androidChannel.canShowBadge();
        channelModel.enableLights = androidChannel.shouldShowLights();
        channelModel.enableVibration = androidChannel.shouldVibrate();
        channelModel.importance = NotificationImportance.fromAndroidImportance(androidChannel.getImportance());
    }

    public static List<NotificationChannelModel> listChannels(Context context) {
        return shared.getAllObjects(context, Definitions.SHARED_CHANNELS);
    }

    public static void commitChanges(Context context){
        shared.commit(context);
    }

    public static boolean isChannelEnabled(Context context, String channelKey){

        if (StringUtils.isNullOrEmpty(channelKey)) return false;

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O /*Android 8*/) {

            NotificationChannel firstAndroidChannel = ChannelManager.getAndroidChannel(context, channelKey);
            if (firstAndroidChannel != null){
                return firstAndroidChannel.getImportance() != NotificationManager.IMPORTANCE_NONE;
            }

            NotificationChannelModel channelModel = getChannelByKey(context, channelKey);
            String awesomeHashKey = channelModel.getChannelHashKey(context, false);

            NotificationChannel forcedAndroidChannel = ChannelManager.getAndroidChannel(context, null, awesomeHashKey);
            return (forcedAndroidChannel != null && forcedAndroidChannel.getImportance() != NotificationManager.IMPORTANCE_NONE);

        } else {

            NotificationChannelModel channelModel = ChannelManager.getChannelByKey(context, channelKey);
            return channelModel != null && channelModel.isChannelEnabled();
        }
    }

    public static void saveChannel(Context context, NotificationChannelModel newChannel, Boolean forceUpdate) throws AwesomeNotificationException {
        saveChannel(context, newChannel, true, forceUpdate);
    }

    public static void saveChannel(Context context, NotificationChannelModel newChannel, Boolean allowUpdates, Boolean forceUpdate) throws AwesomeNotificationException {

        newChannel.refreshIconResource(context);
        newChannel.validate(context);

        NotificationChannelModel oldChannelModel = ChannelManager.getChannelByKey(context, newChannel.channelKey);

        // If nothing has changed, so there is nothing to do
        if(!allowUpdates && oldChannelModel != null && !oldChannelModel.equals(newChannel))
            return;

        // Android Channels are only available on Android Oreo and beyond.
        // On older versions, channel models are only used to organize notifications
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O /*Android 8*/) {

            // If nothing has changed, so there is nothing to do
            if(oldChannelModel != null && oldChannelModel.equals(newChannel)) return;

            // Save into shared manager
            shared.set(context, Definitions.SHARED_CHANNELS, newChannel.channelKey, newChannel);
            shared.commit(context);

            if(AwesomeNotificationsPlugin.debug)
                Log.d(TAG, "Notification channel "+newChannel.channelName+
                    (oldChannelModel == null ? " created" : " updated"));
        }
        else {

            // Save into shared manager
            shared.set(context, Definitions.SHARED_CHANNELS, newChannel.channelKey, newChannel);
            shared.commit(context);

            saveAndroidChannel(context, oldChannelModel, newChannel, forceUpdate);
        }
    }

    @RequiresApi(api = Build.VERSION_CODES.O /*Android 8*/)
    private static void saveAndroidChannel(Context context, NotificationChannelModel oldChannelModel, NotificationChannelModel newChannel, Boolean forceUpdate) {

        String newHashKey = newChannel.getChannelHashKey(context, false);

        NotificationChannel actualAndroidChannel = getAndroidChannel(
                context,
                newChannel.channelKey,
                newHashKey);

        // created
        if(actualAndroidChannel == null){

            if(oldChannelModel != null){
                // Ensure that the previous standards will be updated
                removeOldAndroidChannelStandards(context, oldChannelModel.channelKey, oldChannelModel.channelName);
            }

            setAndroidChannel(context, newChannel, true);
            if(AwesomeNotificationsPlugin.debug)
                Log.d(TAG, "Notification channel "+ newChannel.channelName+" created");
        }
        // updated
        else {
            String currentChannelKey = actualAndroidChannel.getId();

            // Only first channels have the channel key equals to the originals
            if(newChannel.channelKey.equals(currentChannelKey)){

                if(forceUpdate && androidChannelNeedsForceUpdate(newChannel, actualAndroidChannel)){

                    // From this point on, the android channel needs to be slight different from the originals
                    removeAndroidChannel(context, currentChannelKey, null);
                    setAndroidChannel(context, newChannel, false);
                    if(AwesomeNotificationsPlugin.debug)
                        Log.d(TAG, "Notification channel "+ newChannel.channelName+" updated with forceUpdate");
                }
                else
                    if(androidChannelNeedsUpdate(newChannel, actualAndroidChannel)){
                        setAndroidChannel(context, newChannel, true);
                        if(AwesomeNotificationsPlugin.debug)
                            Log.d(TAG, "Notification channel "+ newChannel.channelName+" updated");
                    }
            }
            // For cases where forceUpdated was applied
            else {
                if(!currentChannelKey.equals(newHashKey) && forceUpdate){
                    removeAndroidChannel(context, currentChannelKey, newHashKey);
                    setAndroidChannel(context, newChannel, false);
                    if(AwesomeNotificationsPlugin.debug)
                        Log.d(TAG, "Notification channel "+ newChannel.channelName+" updated with forceUpdate");
                }
                else
                    if(androidChannelNeedsUpdate(newChannel, actualAndroidChannel)){
                        setAndroidChannel(context, newChannel, false);
                        if(AwesomeNotificationsPlugin.debug)
                            Log.d(TAG, "Notification channel "+ newChannel.channelName+" updated");
                    }
            }
        }
    }

    @RequiresApi(api = Build.VERSION_CODES.O /*Android 8*/)
    private static boolean androidChannelNeedsUpdate(NotificationChannelModel channelModel, NotificationChannel androidChannel){
        return !(
            androidChannel.getName().equals(channelModel.channelName) &&
            androidChannel.getDescription().equals(channelModel.channelDescription)
        );
    }

    @RequiresApi(api = Build.VERSION_CODES.O /*Android 8*/)
    private static boolean androidChannelNeedsForceUpdate(NotificationChannelModel channelModel, NotificationChannel androidChannel){
        Uri uriSound = androidChannel.getSound();
        return !(
            (Arrays.equals(channelModel.vibrationPattern, androidChannel.getVibrationPattern())) &&
            java.util.Objects.equals(channelModel.groupKey, androidChannel.getGroup()) &&
            (channelModel.channelShowBadge == androidChannel.canShowBadge()) &&
            (channelModel.ledColor == null || channelModel.ledColor == androidChannel.getLightColor()) &&
            (channelModel.defaultPrivacy == NotificationPrivacy.values()[androidChannel.getLockscreenVisibility()]) &&
            (channelModel.importance == NotificationImportance.values()[androidChannel.getImportance()]) &&
            (!channelModel.playSound && uriSound == null || uriSound.getPath().contains(channelModel.soundSource))
        );
    }

    public static Uri retrieveSoundResourceUri(Context context, DefaultRingtoneType ringtoneType, String soundSource) {
        Uri uri = null;
        if (StringUtils.isNullOrEmpty(soundSource)) {

            int defaultRingtoneKey;
            switch (ringtoneType){

                case Ringtone:
                    defaultRingtoneKey = RingtoneManager.TYPE_RINGTONE;
                    break;

                case Alarm:
                    defaultRingtoneKey = RingtoneManager.TYPE_ALARM;
                    break;

                case Notification:
                default:
                    defaultRingtoneKey = RingtoneManager.TYPE_NOTIFICATION;
                    break;
            }
            uri = RingtoneManager.getDefaultUri(defaultRingtoneKey);

        } else {
            int soundResourceId = AudioUtils.getAudioResourceId(context, soundSource);
            if(soundResourceId > 0){
                uri = Uri.parse("android.resource://" + context.getPackageName() + "/" + soundResourceId);
            }
        }
        return uri;
    }

    @RequiresApi(api = Build.VERSION_CODES.O /*Android 8*/)
    public static NotificationChannel getAndroidChannel(Context context, String channelKey){
        return getAndroidChannel(context, channelKey, null);
    }

    @RequiresApi(api = Build.VERSION_CODES.O /*Android 8*/)
    public static NotificationChannel getAndroidChannel(Context context, String channelKey, String awesomeChannelHashKey){

        NotificationManager notificationManager = NotificationBuilder.getAndroidNotificationManager(context);

        // Returns channel from another packages with same name43
        if(channelKey != null){
            NotificationChannel standardAndroidChannel = notificationManager.getNotificationChannel(channelKey);
            if(standardAndroidChannel != null){
                return standardAndroidChannel;
            }
        }

        // Try to search for a forcedUpdatedChannel
        List<NotificationChannel> notificationChannels = notificationManager.getNotificationChannels();
        for(NotificationChannel currentAndroidChannel : notificationChannels){
            String androidChannelKey = currentAndroidChannel.getId();
            if(androidChannelKey.startsWith(channelKey + "_"))
                return currentAndroidChannel;
        }

        // If hash key was not defined, so there is nothing more to do
        if(awesomeChannelHashKey == null) return null;
        return notificationManager.getNotificationChannel(awesomeChannelHashKey);
    }

    @RequiresApi(api =  Build.VERSION_CODES.O /*Android 8*/)
    public static void removeOldAndroidChannelStandards(Context context, String channelKey, String channelName){
        NotificationManager notificationManager = NotificationBuilder.getAndroidNotificationManager(context);

        List<NotificationChannel> notificationChannels = notificationManager.getNotificationChannels();
        for(NotificationChannel currentAndroidChannel : notificationChannels){
            String androidChannelKey = currentAndroidChannel.getId();
            if( // delete channels with older standards
                (!androidChannelKey.equals(channelKey)) &&
                (androidChannelKey.length() == 32) &&
                (currentAndroidChannel.getName().equals(channelName))
            ){
                notificationManager.deleteNotificationChannel(androidChannelKey);
            }
        }
    }

    @RequiresApi(api =  Build.VERSION_CODES.O /*Android 8*/)
    public static void setAndroidChannel(Context context, NotificationChannelModel newChannel, boolean firstChannel) {

        NotificationManager notificationManager = NotificationBuilder.getAndroidNotificationManager(context);

        NotificationChannel newAndroidNotificationChannel = new NotificationChannel(
                firstChannel ?
                        newChannel.channelKey :
                        newChannel.getChannelHashKey(context, false),
                newChannel.channelName,
                newChannel.importance.ordinal()
        );

        newAndroidNotificationChannel.setDescription(newChannel.channelDescription);

        NotificationChannelGroupModel channelGroup = null;
        if(!StringUtils.isNullOrEmpty(newChannel.channelGroupKey)){
            channelGroup = ChannelGroupManager.getChannelGroupByKey(context, newChannel.channelGroupKey);

            if(channelGroup != null)
                newAndroidNotificationChannel.setGroup(newChannel.channelGroupKey);
            else
                Log.e(TAG, "Channel group "+newChannel.channelGroupKey+" does not exist.");
        }

        if(channelGroup != null)
            newAndroidNotificationChannel.setGroup(newChannel.channelGroupKey);

        if (newChannel.playSound) {

            /// TODO NEED TO IMPROVE AUDIO RESOURCES TO BE MORE VERSATILE, SUCH AS BITMAP ONES
            AudioAttributes audioAttributes = new AudioAttributes.Builder()
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .setUsage(AudioAttributes.USAGE_NOTIFICATION)
                    .build();

            Uri uri = retrieveSoundResourceUri(context, newChannel.defaultRingtoneType, newChannel.soundSource);
            newAndroidNotificationChannel.setSound(uri, audioAttributes);

        } else {
            newAndroidNotificationChannel.setSound(null, null);
        }

        newAndroidNotificationChannel.enableVibration(BooleanUtils.getValue(newChannel.enableVibration));
        if (newChannel.vibrationPattern != null && newChannel.vibrationPattern.length > 0) {
            newAndroidNotificationChannel.setVibrationPattern(newChannel.vibrationPattern);
        }

        boolean enableLights = BooleanUtils.getValue(newChannel.enableLights);
        newAndroidNotificationChannel.enableLights(enableLights);

        if (enableLights && newChannel.ledColor != null) {
            newAndroidNotificationChannel.setLightColor(newChannel.ledColor);
        }

        if(newChannel.criticalAlerts) {
            newAndroidNotificationChannel.setBypassDnd(true);
        }

        newAndroidNotificationChannel.setShowBadge(BooleanUtils.getValue(newChannel.channelShowBadge));

        notificationManager.createNotificationChannel(newAndroidNotificationChannel);
    }

    @RequiresApi(api =  Build.VERSION_CODES.O /*Android 8*/)
    private static void removeAndroidChannel(Context context, String channelKey, String newHashKey) {
        NotificationManager notificationManager = NotificationBuilder.getAndroidNotificationManager(context);

        notificationManager.deleteNotificationChannel(channelKey);

        if(!StringUtils.isNullOrEmpty(newHashKey))
            notificationManager.deleteNotificationChannel(newHashKey);
    }
}
