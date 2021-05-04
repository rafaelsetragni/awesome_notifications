package me.carda.awesome_notifications.notifications.managers;

import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.content.Context;
import android.media.AudioAttributes;
import android.media.RingtoneManager;
import android.net.Uri;
import android.os.Build;

import java.util.List;

import androidx.core.app.NotificationManagerCompat;
import me.carda.awesome_notifications.Definitions;
import me.carda.awesome_notifications.notifications.enumeratos.DefaultRingtoneType;
import me.carda.awesome_notifications.notifications.enumeratos.MediaSource;
import me.carda.awesome_notifications.notifications.exceptions.AwesomeNotificationException;
import me.carda.awesome_notifications.notifications.models.NotificationChannelModel;
import me.carda.awesome_notifications.utils.AudioUtils;
import me.carda.awesome_notifications.utils.BitmapUtils;
import me.carda.awesome_notifications.utils.BooleanUtils;
import me.carda.awesome_notifications.utils.MediaUtils;
import me.carda.awesome_notifications.utils.StringUtils;

public class ChannelManager {

    private static final SharedManager<NotificationChannelModel> shared = new SharedManager<>("ChannelManager", NotificationChannelModel.class);

    public static Boolean removeChannel(Context context, String channelKey) {

        NotificationChannelModel oldChannel = getChannelByKey(context, channelKey);

        if(oldChannel == null) return true;

        removeAndroidChannel(context, oldChannel.channelKey);
        removeAndroidChannel(context, oldChannel.getChannelKey());

        return shared.remove(context, Definitions.SHARED_CHANNELS, channelKey);
    }

    public static List<NotificationChannelModel> listChannels(Context context) {
        return shared.getAllObjects(context, Definitions.SHARED_CHANNELS);
    }

    public static void saveChannel(Context context, NotificationChannelModel channelModel, Boolean forceUpdate) {

        NotificationChannelModel oldChannel = getChannelByKey(context, channelModel.channelKey);

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            if(oldChannel != null){

                String oldKey = oldChannel.getChannelKey();

                if(!oldKey.equals(channelModel.getChannelKey()) && forceUpdate){
                    removeAndroidChannel(context, oldChannel.channelKey);
                    removeAndroidChannel(context, oldChannel.getChannelKey());
                }
            }
        }

        setAndroidChannel(context, channelModel);

        shared.set(context, Definitions.SHARED_CHANNELS, channelModel.channelKey, channelModel);
        shared.commit(context);
    }

    public static NotificationChannelModel getChannelByKey(Context context, String channelKey){
        return shared.get(context, Definitions.SHARED_CHANNELS, channelKey);
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

    private static void removeAndroidChannel(Context context, String channelKey) {
        NotificationManager notificationManager = (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            try {
                notificationManager.deleteNotificationChannel(channelKey);
            } catch ( Exception ignored) {
            }
        }
    }

    public static void setAndroidChannel(Context context, NotificationChannelModel newChannel) {

        if(newChannel.icon != null){
            if(MediaUtils.getMediaSourceType(newChannel.icon) != MediaSource.Resource){
                newChannel.icon = null;
            } else {
                int resourceIndex = BitmapUtils.getDrawableResourceId(context, newChannel.icon);
                if(resourceIndex > 0){
                    newChannel.iconResourceId = resourceIndex;
                }
                else {
                    newChannel.icon = null;
                }
            }
        }

        try {
            newChannel.validate(context);
        } catch (AwesomeNotificationException e) {
            e.printStackTrace();
            return;
        }

        // Channels are only available on Android Oreo and beyond.
        // On older versions, channel models are only used to organize notifications
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {

            NotificationManager notificationManager = (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);
            NotificationChannel newNotificationChannel = null;
            newNotificationChannel = new NotificationChannel(newChannel.getChannelKey(), newChannel.channelName, newChannel.importance.ordinal());

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

            notificationManager.createNotificationChannel(newNotificationChannel);
        }

    }

    public static boolean isNotificationChannelActive(Context context, String channelId){
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
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
