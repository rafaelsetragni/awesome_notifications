package me.carda.awesome_notifications.core.managers;

import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.content.Context;
import android.media.AudioAttributes;
import android.media.RingtoneManager;
import android.net.Uri;
import android.os.Build;

import androidx.annotation.RequiresApi;

import java.util.Arrays;
import java.util.List;

import me.carda.awesome_notifications.core.AwesomeNotifications;
import me.carda.awesome_notifications.core.Definitions;
import me.carda.awesome_notifications.core.enumerators.DefaultRingtoneType;
import me.carda.awesome_notifications.core.enumerators.NotificationImportance;
import me.carda.awesome_notifications.core.enumerators.NotificationPrivacy;
import me.carda.awesome_notifications.core.exceptions.AwesomeNotificationsException;
import me.carda.awesome_notifications.core.exceptions.ExceptionCode;
import me.carda.awesome_notifications.core.exceptions.ExceptionFactory;
import me.carda.awesome_notifications.core.logs.Logger;
import me.carda.awesome_notifications.core.models.NotificationChannelGroupModel;
import me.carda.awesome_notifications.core.models.NotificationChannelModel;
import me.carda.awesome_notifications.core.utils.AudioUtils;
import me.carda.awesome_notifications.core.utils.BooleanUtils;
import me.carda.awesome_notifications.core.utils.StringUtils;

public class ChannelManager {

    private static final SharedManager<NotificationChannelModel> shared
            = new SharedManager<>(
                    StringUtils.getInstance(),
                    "ChannelManager",
                    NotificationChannelModel.class,
                    "NotificationChannelModel");
    
    private static final String TAG = "ChannelManager";


    private final StringUtils stringUtils;
    private final AudioUtils audioUtils;

    // ************** SINGLETON PATTERN ***********************

    private static ChannelManager instance;

    private ChannelManager(StringUtils stringUtils, AudioUtils audioUtils){
        this.stringUtils = stringUtils;
        this.audioUtils = audioUtils;
    }

    public static ChannelManager getInstance() {
        if (instance == null)
            instance = new ChannelManager(
                StringUtils.getInstance(),
                AudioUtils.getInstance()
            );
        return instance;
    }

    // ********************************************************

    public Boolean removeChannel(Context context, String channelKey) throws AwesomeNotificationsException {

        NotificationChannelModel channelModel = getChannelByKey(context, channelKey);

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O /*Android 8*/) {
            removeAndroidChannel(context, channelKey, channelModel != null ? channelModel.getChannelHashKey(context, false) : null);
        }

        return shared.remove(context, Definitions.SHARED_CHANNELS, channelKey);
    }

    public NotificationChannelModel getChannelByKey(Context context, String channelKey) throws AwesomeNotificationsException {

        if(stringUtils.isNullOrEmpty(channelKey)) {
            if(AwesomeNotifications.debug)
                Logger.w(TAG, "'"+channelKey+"' cannot be empty or null");
            return null;
        }

        NotificationChannelModel channelModel = shared.get(context, Definitions.SHARED_CHANNELS, channelKey);
        if(channelModel == null) {
            if(AwesomeNotifications.debug)
                Logger.w(TAG, "Channel model '"+channelKey+"' was not found");
            return null;
        }

        channelModel.refreshIconResource(context);
        if(Build.VERSION.SDK_INT >= Build.VERSION_CODES.O /*Android 8*/){

            NotificationChannel androidChannel = getAndroidChannel(context, channelKey);
            if(androidChannel == null) {
                if(AwesomeNotifications.debug)
                    Logger.w(TAG, "Android native channel '"+channelKey+"' was not found");
                return null;
            }

            if(androidChannel.getImportance() == NotificationManager.IMPORTANCE_NONE){
                if(AwesomeNotifications.debug)
                    Logger.w(TAG, "Android native channel '"+channelKey+"' is disabled");
            }

            updateChannelModelThroughAndroidChannel(channelModel, androidChannel);
        }

        return channelModel;
    }

    @RequiresApi(api = Build.VERSION_CODES.O)
    private void updateChannelModelThroughAndroidChannel(NotificationChannelModel channelModel, NotificationChannel androidChannel){
        channelModel.channelName = String.valueOf(androidChannel.getName());
        channelModel.channelDescription = androidChannel.getDescription();
        channelModel.channelShowBadge = androidChannel.canShowBadge();
        channelModel.playSound = androidChannel.getSound() != null;
        channelModel.enableLights = androidChannel.shouldShowLights();
        channelModel.enableVibration = androidChannel.shouldVibrate();
        channelModel.importance = NotificationImportance.fromAndroidImportance(androidChannel.getImportance());
    }

    public List<NotificationChannelModel> listChannels(Context context) throws AwesomeNotificationsException {
        return shared.getAllObjects(context, Definitions.SHARED_CHANNELS);
    }

    public void commitChanges(Context context) throws AwesomeNotificationsException {
        shared.commit(context);
    }

    public boolean isChannelEnabled(Context context, String channelKey) throws AwesomeNotificationsException {

        if (stringUtils.isNullOrEmpty(channelKey)) return false;

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O /*Android 8*/) {

            NotificationChannel firstAndroidChannel = getAndroidChannel(context, channelKey);
            if (firstAndroidChannel != null){
                return firstAndroidChannel.getImportance() != NotificationManager.IMPORTANCE_NONE;
            }

            NotificationChannelModel channelModel = getChannelByKey(context, channelKey);
            String awesomeHashKey = channelModel.getChannelHashKey(context, false);

            NotificationChannel forcedAndroidChannel = getAndroidChannel(context, null, awesomeHashKey);
            return (forcedAndroidChannel != null && forcedAndroidChannel.getImportance() != NotificationManager.IMPORTANCE_NONE);

        } else {

            NotificationChannelModel channelModel = getChannelByKey(context, channelKey);
            return channelModel != null && channelModel.isChannelEnabled();
        }
    }

    public ChannelManager saveChannel(Context context, NotificationChannelModel newChannel, Boolean setOnlyNew, Boolean forceUpdate) throws AwesomeNotificationsException {

        newChannel.refreshIconResource(context);
        newChannel.validate(context);

        NotificationChannelModel oldChannelModel = getChannelByKey(context, newChannel.channelKey);

        // If nothing has changed, so there is nothing to do
        if(setOnlyNew && oldChannelModel != null && !oldChannelModel.equals(newChannel))
            return this;

        // Android Channels are only available on Android Oreo and beyond.
        // On older versions, channel models are only used to organize notifications
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O /*Android 8*/) {

            // If nothing has changed, so there is nothing to do
            if(oldChannelModel != null && oldChannelModel.equals(newChannel)) return this;

            // Save into shared manager
            shared.set(context, Definitions.SHARED_CHANNELS, newChannel.channelKey, newChannel);
            shared.commit(context);

            if(AwesomeNotifications.debug)
                Logger.d(TAG, "Notification channel "+newChannel.channelName+
                    (oldChannelModel == null ? " created" : " updated"));
        }
        else {

            // Save into shared manager
            shared.set(context, Definitions.SHARED_CHANNELS, newChannel.channelKey, newChannel);
            shared.commit(context);

            saveAndroidChannel(context, oldChannelModel, newChannel, forceUpdate);
        }

        return this;
    }

    @RequiresApi(api = Build.VERSION_CODES.O /*Android 8*/)
    private void saveAndroidChannel(Context context, NotificationChannelModel oldChannelModel, NotificationChannelModel newChannel, Boolean forceUpdate) throws AwesomeNotificationsException {

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
            if(AwesomeNotifications.debug)
                Logger.d(TAG, "Notification channel "+ newChannel.channelName+" created");
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
                    if(AwesomeNotifications.debug)
                        Logger.d(TAG, "Notification channel "+ newChannel.channelName+" updated with forceUpdate");
                }
                else
                    if(androidChannelNeedsUpdate(newChannel, actualAndroidChannel)){
                        setAndroidChannel(context, newChannel, true);
                        if(AwesomeNotifications.debug)
                            Logger.d(TAG, "Notification channel "+ newChannel.channelName+" updated");
                    }
            }
            // For cases where forceUpdated was applied
            else {
                if(!currentChannelKey.equals(newHashKey) && forceUpdate){
                    removeAndroidChannel(context, currentChannelKey, newHashKey);
                    setAndroidChannel(context, newChannel, false);
                    if(AwesomeNotifications.debug)
                        Logger.d(TAG, "Notification channel "+ newChannel.channelName+" updated with forceUpdate");
                }
                else
                    if(androidChannelNeedsUpdate(newChannel, actualAndroidChannel)){
                        setAndroidChannel(context, newChannel, false);
                        if(AwesomeNotifications.debug)
                            Logger.d(TAG, "Notification channel "+ newChannel.channelName+" updated");
                    }
            }
        }
    }

    @RequiresApi(api = Build.VERSION_CODES.O /*Android 8*/)
    private boolean androidChannelNeedsUpdate(NotificationChannelModel channelModel, NotificationChannel androidChannel){
        return !(
            androidChannel.getName().equals(channelModel.channelName) &&
            androidChannel.getDescription().equals(channelModel.channelDescription)
        );
    }

    @RequiresApi(api = Build.VERSION_CODES.O /*Android 8*/)
    private boolean androidChannelNeedsForceUpdate(NotificationChannelModel channelModel, NotificationChannel androidChannel){
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

    public Uri retrieveSoundResourceUri(Context context, DefaultRingtoneType ringtoneType, String soundSource) {
        Uri uri = null;
        if (stringUtils.isNullOrEmpty(soundSource)) {

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
            int soundResourceId = audioUtils.getAudioResourceId(context, soundSource);
            if(soundResourceId > 0){
                uri = Uri.parse("android.resource://" + AwesomeNotifications.getPackageName(context) + "/" + soundResourceId);
            }
        }
        return uri;
    }

    @RequiresApi(api = Build.VERSION_CODES.O /*Android 8*/)
    public NotificationChannel getAndroidChannel(Context context, String channelKey){
        return getAndroidChannel(context, channelKey, null);
    }

    @RequiresApi(api = Build.VERSION_CODES.O /*Android 8*/)
    public NotificationChannel getAndroidChannel(Context context, String channelKey, String awesomeChannelHashKey){

        NotificationManager notificationManager = getAndroidNotificationManager(context);

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
    public void removeOldAndroidChannelStandards(Context context, String channelKey, String channelName){
        NotificationManager notificationManager = getAndroidNotificationManager(context);

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

    public NotificationManager getAndroidNotificationManager(Context context){
        return  (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);
    }

    @RequiresApi(api =  Build.VERSION_CODES.O /*Android 8*/)
    public void setAndroidChannel(Context context, NotificationChannelModel newChannel, boolean firstChannel) throws AwesomeNotificationsException {

        NotificationManager notificationManager = getAndroidNotificationManager(context);

        NotificationChannel newAndroidNotificationChannel = new NotificationChannel(
                firstChannel ?
                        newChannel.channelKey :
                        newChannel.getChannelHashKey(context, false),
                newChannel.channelName,
                newChannel.importance.ordinal()
        );

        newAndroidNotificationChannel.setDescription(newChannel.channelDescription);

        NotificationChannelGroupModel channelGroup = null;
        if (!stringUtils.isNullOrEmpty(newChannel.channelGroupKey)) {
            channelGroup = ChannelGroupManager.getChannelGroupByKey(context, newChannel.channelGroupKey);

            if(channelGroup != null)
                newAndroidNotificationChannel.setGroup(newChannel.channelGroupKey);
            else
                ExceptionFactory
                        .getInstance()
                        .registerNewAwesomeException(
                                TAG,
                                ExceptionCode.CODE_INVALID_ARGUMENTS,
                                "Channel group "+newChannel.channelGroupKey+" does not exist.",
                                ExceptionCode.DETAILED_INVALID_ARGUMENTS+".channelGroup."+newChannel.channelGroupKey);
        }

        if (channelGroup != null)
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

        newAndroidNotificationChannel.enableVibration(BooleanUtils.getInstance().getValue(newChannel.enableVibration));
        if (newChannel.vibrationPattern != null && newChannel.vibrationPattern.length > 0) {
            newAndroidNotificationChannel.setVibrationPattern(newChannel.vibrationPattern);
        }

        boolean enableLights = BooleanUtils.getInstance().getValue(newChannel.enableLights);
        newAndroidNotificationChannel.enableLights(enableLights);

        if (enableLights && newChannel.ledColor != null) {
            newAndroidNotificationChannel.setLightColor(newChannel.ledColor);
        }

        if(newChannel.criticalAlerts) {
            newAndroidNotificationChannel.setBypassDnd(true);
        }

        newAndroidNotificationChannel.setShowBadge(BooleanUtils.getInstance().getValue(newChannel.channelShowBadge));

        notificationManager.createNotificationChannel(newAndroidNotificationChannel);
    }

    @RequiresApi(api =  Build.VERSION_CODES.O /*Android 8*/)
    private void removeAndroidChannel(Context context, String channelKey, String newHashKey) {
        NotificationManager notificationManager = getAndroidNotificationManager(context);

        notificationManager.deleteNotificationChannel(channelKey);

        if(!stringUtils.isNullOrEmpty(newHashKey))
            notificationManager.deleteNotificationChannel(newHashKey);
    }
}
