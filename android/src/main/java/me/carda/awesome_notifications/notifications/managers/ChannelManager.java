package me.carda.awesome_notifications.notifications.managers;

import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.content.Context;
import android.media.AudioAttributes;
import android.media.RingtoneManager;
import android.net.Uri;
import android.os.Build;
import android.util.Log;

import java.util.ArrayList;
import java.util.List;

import androidx.annotation.RequiresApi;
import androidx.core.app.NotificationManagerCompat;
import me.carda.awesome_notifications.AwesomeNotificationsPlugin;
import me.carda.awesome_notifications.Definitions;
import me.carda.awesome_notifications.notifications.enumerators.DefaultRingtoneType;
import me.carda.awesome_notifications.notifications.enumerators.MediaSource;
import me.carda.awesome_notifications.notifications.exceptions.AwesomeNotificationException;
import me.carda.awesome_notifications.notifications.models.NotificationChannelModel;
import me.carda.awesome_notifications.utils.AudioUtils;
import me.carda.awesome_notifications.utils.BitmapUtils;
import me.carda.awesome_notifications.utils.BooleanUtils;
import me.carda.awesome_notifications.utils.MediaUtils;
import me.carda.awesome_notifications.utils.StringUtils;

public class ChannelManager {

    private static final SharedManager<NotificationChannelModel> shared
            = new SharedManager<>(
                    "ChannelManager",
                    NotificationChannelModel.class,
                    "NotificationChannelModel");
    
    private static final String TAG = "ChannelManager";

    public static Boolean removeChannel(Context context, String channelKey) {

        NotificationChannelModel oldChannel = getChannelByKey(context, channelKey);

        if(oldChannel == null) return true;

        // Ensures the removal of any possible standard
        removeAndroidChannel(context, oldChannel.channelKey);
        removeAndroidChannel(context, oldChannel.getChannelHashKey(context, false));
        removeAndroidChannel(context, oldChannel.getChannelHashKey(context, true));

        return shared.remove(context, Definitions.SHARED_CHANNELS, channelKey);
    }

    public static List<NotificationChannelModel> listChannels(Context context) {
        return shared.getAllObjects(context, Definitions.SHARED_CHANNELS);
    }

    public static void saveChannel(Context context, NotificationChannelModel channelModel, Boolean forceUpdate) {

        channelModel.refreshIconResource(context);

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O /*Android 8*/) {

            NotificationChannel androidChannel = getAndroidChannel(context, channelModel);
            if(androidChannel != null){

                String currentChannelKey = androidChannel.getId();

                if(currentChannelKey != null)
                    if(currentChannelKey.equals(channelModel.channelKey)){
                        eraseOldAndroidChannels(context, channelModel);
                        if(AwesomeNotificationsPlugin.debug)
                            Log.d(TAG, "Incompatible notification channel "+currentChannelKey+" erased");
                    }
                    else {
                        String newHashKey = channelModel.getChannelHashKey(context, false);
                        if(!currentChannelKey.equals(newHashKey) && forceUpdate) {
                            // Ensures the removal of previous channel to enable force update
                            eraseOldAndroidChannels(context, channelModel);
                            if(AwesomeNotificationsPlugin.debug)
                                Log.d(TAG, "Notification channel "+channelModel.channelName+" updated with forceUpdate");
                        }
                    }
            }
            setAndroidChannel(context, channelModel);

            if(AwesomeNotificationsPlugin.debug)
                Log.d(TAG, "Notification channel "+channelModel.channelName+
                        " ("+channelModel.channelKey+") "+
                        ( (androidChannel != null) ? "updated" : "created"));
        }

        shared.set(context, Definitions.SHARED_CHANNELS, channelModel.channelKey, channelModel);
        shared.commit(context);
    }

    public static NotificationChannelModel getChannelByKey(Context context, String channelKey){

        NotificationChannelModel channelModel = shared.get(context, Definitions.SHARED_CHANNELS, channelKey);
        if(channelModel != null){
            channelModel.refreshIconResource(context);
        }

        return channelModel;
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

    public static void commitChanges(Context context){
        shared.commit(context);
    }

    @RequiresApi(api = Build.VERSION_CODES.O /*Android 8*/)
    public static NotificationChannel getAndroidChannel(Context context, NotificationChannelModel referenceChannel){

        NotificationManager notificationManager = (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);

        // Returns channel from another packages with same name
        NotificationChannel standardAndroidChannel = notificationManager.getNotificationChannel(referenceChannel.channelKey);
        if(standardAndroidChannel != null){
            return standardAndroidChannel;
        }

        String newAwesomeChannelKey = referenceChannel.getChannelHashKey(context, false);
        NotificationChannel forceUpdatedAndroidChannel = null;

        // Search by channel name, preferentially previous versions
        List<NotificationChannel> notificationChannels = notificationManager.getNotificationChannels();
        for(NotificationChannel currentAndroidChannel : notificationChannels){
            CharSequence channelName = currentAndroidChannel.getName();
            if(channelName != null && channelName.toString().equals(referenceChannel.channelName)){
                String channelKey = currentAndroidChannel.getId();
                if(newAwesomeChannelKey.equals(channelKey))
                    forceUpdatedAndroidChannel = currentAndroidChannel;
                else
                    return currentAndroidChannel;
            }
        }

        // Returns forceUpdate standard
        return forceUpdatedAndroidChannel;
    }

    @RequiresApi(api = Build.VERSION_CODES.O /*Android 8*/)
    public static void eraseOldAndroidChannels(Context context, NotificationChannelModel referenceChannel){

        NotificationManager notificationManager = (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);
        String newAwesomeChannelKey = referenceChannel.getChannelHashKey(context, false);

        // Search by channel name
        List<NotificationChannel> notificationChannels = notificationManager.getNotificationChannels();
        for(NotificationChannel currentAndroidChannel : notificationChannels){
            CharSequence channelName = currentAndroidChannel.getName();
            if(channelName != null && channelName.toString().equals(referenceChannel.channelName)) {
                String channelKey = currentAndroidChannel.getId();
                if (channelKey.equals(newAwesomeChannelKey)) {
                    notificationManager.deleteNotificationChannel(channelKey);
                    if(AwesomeNotificationsPlugin.debug)
                        Log.d(TAG, "Old notification channel "+channelName+" ("+channelKey+") erased");
                }
            }
        }
    }

    @RequiresApi(api = Build.VERSION_CODES.O)
    public static NotificationChannel getAndroidChannel(Context context, NotificationChannelModel referenceChannel, boolean eraseOldChannels){

        NotificationManager notificationManager = (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);

        // Returns channel from another packages with same name
        NotificationChannel standardAndroidChannel = notificationManager.getNotificationChannel(referenceChannel.channelKey);
        if(standardAndroidChannel != null){
            return standardAndroidChannel;
        }

        String newAwesomeChannelKey = referenceChannel.getChannelHashKey(context, false);

        // Search by channel name
        List<NotificationChannel> notificationChannels = notificationManager.getNotificationChannels();
        for(NotificationChannel currentAndroidChannel : notificationChannels){
            CharSequence channelName = currentAndroidChannel.getName();
            if(channelName != null && channelName.toString().equals(referenceChannel.channelName)){
                if(eraseOldChannels){

                }
                else {
                    return currentAndroidChannel;
                }
            }
        }

        // Returns forceUpdate standard
        return notificationManager.getNotificationChannel(newAwesomeChannelKey);
    }

    private static void removeAndroidChannel(Context context, String channelId) {
        NotificationManager notificationManager = (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O /*Android 8*/) {
            try {
                notificationManager.deleteNotificationChannel(channelId);
            } catch ( Exception ignored) {
            }
        }
    }

    public static void setAndroidChannel(Context context, NotificationChannelModel newChannel) {

        newChannel.refreshIconResource(context);

        try {
            newChannel.validate(context);
        } catch (AwesomeNotificationException e) {
            e.printStackTrace();
            return;
        }

        // Channels are only available on Android Oreo and beyond.
        // On older versions, channel models are only used to organize notifications
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O /*Android 8*/) {

            NotificationManager notificationManager = (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);

            NotificationChannel newNotificationChannel = new NotificationChannel(newChannel.getChannelHashKey(context, false), newChannel.channelName, newChannel.importance.ordinal());
            newNotificationChannel.setDescription(newChannel.channelDescription);

            if (newChannel.playSound) {

                /// TODO NEED TO IMPROVE AUDIO RESOURCES TO BE MORE VERSATILE, SUCH AS BITMAP ONES
                AudioAttributes audioAttributes = null;
                audioAttributes = new AudioAttributes.Builder()
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .setUsage(AudioAttributes.USAGE_NOTIFICATION)
                        .build();

                Uri uri = retrieveSoundResourceUri(context, newChannel.defaultRingtoneType, newChannel.soundSource);
                newNotificationChannel.setSound(uri, audioAttributes);

            } else {
                newNotificationChannel.setSound(null, null);
            }

            newNotificationChannel.enableVibration(BooleanUtils.getValue(newChannel.enableVibration));
            if (newChannel.vibrationPattern != null && newChannel.vibrationPattern.length > 0) {
                newNotificationChannel.setVibrationPattern(newChannel.vibrationPattern);
            }

            boolean enableLights = BooleanUtils.getValue(newChannel.enableLights);
            newNotificationChannel.enableLights(enableLights);

            if (enableLights && newChannel.ledColor != null) {
                newNotificationChannel.setLightColor(newChannel.ledColor);
            }

            newNotificationChannel.setShowBadge(BooleanUtils.getValue(newChannel.channelShowBadge));

            // Removes the old standard before apply the new one
            String oldAwesomeChannelKey = newChannel.getChannelHashKey(context, true);
            NotificationChannel oldAwesomeAndroidChannel = notificationManager.getNotificationChannel(oldAwesomeChannelKey);
            if(oldAwesomeAndroidChannel != null){
                notificationManager.deleteNotificationChannel(oldAwesomeAndroidChannel.getId());
            }

            notificationManager.createNotificationChannel(newNotificationChannel);
        }

    }

    public static boolean isNotificationChannelActive(Context context, String channelId){
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O /*Android 8*/) {
            if(!StringUtils.isNullOrEmpty(channelId)) {
                NotificationManager manager = (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);
                NotificationChannel channel = manager.getNotificationChannel(channelId);
                return channel != null && channel.getImportance() != NotificationManager.IMPORTANCE_NONE;
            }
            return false;
        } else {
            return NotificationManagerCompat.from(context).areNotificationsEnabled();
        }
    }
}
