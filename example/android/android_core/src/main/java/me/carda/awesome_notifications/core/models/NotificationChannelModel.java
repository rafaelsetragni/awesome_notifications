package me.carda.awesome_notifications.core.models;

import android.content.Context;

import androidx.annotation.Nullable;

import java.util.HashMap;
import java.util.Map;

import me.carda.awesome_notifications.core.Definitions;
import me.carda.awesome_notifications.core.enumerators.DefaultRingtoneType;
import me.carda.awesome_notifications.core.enumerators.GroupAlertBehaviour;
import me.carda.awesome_notifications.core.enumerators.GroupSort;
import me.carda.awesome_notifications.core.enumerators.MediaSource;
import me.carda.awesome_notifications.core.enumerators.NotificationImportance;
import me.carda.awesome_notifications.core.enumerators.NotificationPrivacy;
import me.carda.awesome_notifications.core.exceptions.AwesomeNotificationsException;
import me.carda.awesome_notifications.core.exceptions.ExceptionCode;
import me.carda.awesome_notifications.core.exceptions.ExceptionFactory;
import me.carda.awesome_notifications.core.utils.AudioUtils;
import me.carda.awesome_notifications.core.utils.BitmapUtils;
import me.carda.awesome_notifications.core.utils.BooleanUtils;
import me.carda.awesome_notifications.core.utils.CompareUtils;

public class NotificationChannelModel extends AbstractModel {

    private static final String TAG = "NotificationChannelModel";

    public String channelKey;
    public String channelName;
    public String channelDescription;
    public Boolean channelShowBadge;

    public String channelGroupKey;

    public NotificationImportance importance;

    public Boolean playSound;
    public String soundSource;
    public DefaultRingtoneType defaultRingtoneType;

    public Boolean enableVibration;
    public long[] vibrationPattern;

    public Boolean enableLights;
    public Integer ledColor;
    public Integer ledOnMs;
    public Integer ledOffMs;

    public String  groupKey;
    public GroupSort groupSort;
    public GroupAlertBehaviour groupAlertBehavior;

    // Note: this is set on the Android to save details about the icon that should be used when re-hydrating delayed notifications when a device has been restarted.
    public Integer iconResourceId;

    public String  icon;
    public Long defaultColor;

    public Boolean locked;
    public Boolean onlyAlertOnce;

    public Boolean criticalAlerts;

    public NotificationPrivacy defaultPrivacy;

    public void refreshIconResource(Context context){
        if(iconResourceId == null && icon != null){
            if(BitmapUtils.getInstance().getMediaSourceType(icon) == MediaSource.Resource) {

                int resourceIndex = BitmapUtils.getInstance().getDrawableResourceId(context, icon);
                if (resourceIndex > 0) {
                    iconResourceId = resourceIndex;
                } else {
                    iconResourceId = null;
                }
            }
        }
    }

    public boolean isChannelEnabled(){
        return importance != null && importance != NotificationImportance.None;
    }

    public String getChannelHashKey(Context context, boolean fullHashObject){

        refreshIconResource(context);

        if(fullHashObject){
            String jsonData = this.toJson();
            return stringUtils.digestString(jsonData);
        }

        NotificationChannelModel channelCopied = this.clone();
        channelCopied.channelName = "";
        channelCopied.channelDescription = "";
        channelCopied.groupKey = null;

        String jsonData = channelCopied.toJson();
        return channelKey + "_" + stringUtils.digestString(jsonData);
    }

    @Override
    public boolean equals(@Nullable Object obj) {
        if(super.equals(obj)) return true;
        if(!(obj instanceof NotificationChannelModel)) return false;
        NotificationChannelModel other = (NotificationChannelModel) obj;

        return
            CompareUtils.assertEqualObjects(other.iconResourceId, this.iconResourceId) &&
            CompareUtils.assertEqualObjects(other.defaultColor, this.defaultColor) &&
            CompareUtils.assertEqualObjects(other.channelKey, this.channelKey) &&
            CompareUtils.assertEqualObjects(other.channelName, this.channelName) &&
            CompareUtils.assertEqualObjects(other.channelDescription, this.channelDescription) &&
            CompareUtils.assertEqualObjects(other.channelShowBadge, this.channelShowBadge) &&
            CompareUtils.assertEqualObjects(other.importance, this.importance) &&
            CompareUtils.assertEqualObjects(other.playSound, this.playSound) &&
            CompareUtils.assertEqualObjects(other.soundSource, this.soundSource) &&
            CompareUtils.assertEqualObjects(other.enableVibration, this.enableVibration) &&
            CompareUtils.assertEqualObjects(other.vibrationPattern, this.vibrationPattern) &&
            CompareUtils.assertEqualObjects(other.enableLights, this.enableLights) &&
            CompareUtils.assertEqualObjects(other.ledColor, this.ledColor) &&
            CompareUtils.assertEqualObjects(other.ledOnMs, this.ledOnMs) &&
            CompareUtils.assertEqualObjects(other.ledOffMs, this.ledOffMs) &&
            CompareUtils.assertEqualObjects(other.groupKey, this.groupKey) &&
            CompareUtils.assertEqualObjects(other.locked, this.locked) &&
            CompareUtils.assertEqualObjects(other.criticalAlerts, this.criticalAlerts) &&
            CompareUtils.assertEqualObjects(other.onlyAlertOnce, this.onlyAlertOnce) &&
            CompareUtils.assertEqualObjects(other.defaultPrivacy, this.defaultPrivacy) &&
            CompareUtils.assertEqualObjects(other.defaultRingtoneType, this.defaultRingtoneType) &&
            CompareUtils.assertEqualObjects(other.groupSort, this.groupSort) &&
            CompareUtils.assertEqualObjects(other.groupAlertBehavior, this.groupAlertBehavior);
    }

    @Override
    public NotificationChannelModel fromMap(Map<String, Object> arguments) {

        iconResourceId      = getValueOrDefault(arguments, Definitions.NOTIFICATION_ICON_RESOURCE_ID, Integer.class, null);
        icon                = getValueOrDefault(arguments, Definitions.NOTIFICATION_ICON, String.class, null);
        defaultColor        = getValueOrDefault(arguments, Definitions.NOTIFICATION_DEFAULT_COLOR, Long.class, 0xFF000000L);
        channelKey          = getValueOrDefault(arguments, Definitions.NOTIFICATION_CHANNEL_KEY, String.class, "miscellaneous");
        channelName         = getValueOrDefault(arguments, Definitions.NOTIFICATION_CHANNEL_NAME, String.class, "Notifications");
        channelDescription  = getValueOrDefault(arguments, Definitions.NOTIFICATION_CHANNEL_DESCRIPTION, String.class, "Notifications");
        channelShowBadge    = getValueOrDefault(arguments, Definitions.NOTIFICATION_CHANNEL_SHOW_BADGE, Boolean.class, false);
        channelGroupKey     = getValueOrDefault(arguments, Definitions.NOTIFICATION_CHANNEL_GROUP_KEY, String.class, null);
        playSound           = getValueOrDefault(arguments, Definitions.NOTIFICATION_PLAY_SOUND, Boolean.class, true);
        soundSource         = getValueOrDefault(arguments, Definitions.NOTIFICATION_SOUND_SOURCE, String.class, null);
        criticalAlerts      = getValueOrDefault(arguments, Definitions.NOTIFICATION_CHANNEL_CRITICAL_ALERTS, Boolean.class, false);
        enableVibration     = getValueOrDefault(arguments, Definitions.NOTIFICATION_ENABLE_VIBRATION, Boolean.class, true);
        vibrationPattern    = getValueOrDefault(arguments, Definitions.NOTIFICATION_VIBRATION_PATTERN, long[].class, null);
        ledColor            = getValueOrDefault(arguments, Definitions.NOTIFICATION_LED_COLOR, Integer.class, 0xFFFFFFFF);
        enableLights        = getValueOrDefault(arguments, Definitions.NOTIFICATION_ENABLE_LIGHTS, Boolean.class, true);
        ledOnMs             = getValueOrDefault(arguments, Definitions.NOTIFICATION_LED_ON_MS, Integer.class, 300);
        ledOffMs            = getValueOrDefault(arguments, Definitions.NOTIFICATION_LED_OFF_MS, Integer.class, 700);
        importance          = getValueOrDefault(arguments, Definitions.NOTIFICATION_IMPORTANCE, NotificationImportance.class, NotificationImportance.Default);
        groupSort           = getValueOrDefault(arguments, Definitions.NOTIFICATION_GROUP_SORT, GroupSort.class, GroupSort.Desc);
        groupAlertBehavior  = getValueOrDefault(arguments, Definitions.NOTIFICATION_GROUP_ALERT_BEHAVIOR, GroupAlertBehaviour.class, GroupAlertBehaviour.All);
        defaultPrivacy      = getValueOrDefault(arguments, Definitions.NOTIFICATION_DEFAULT_PRIVACY, NotificationPrivacy.class, NotificationPrivacy.Private);
        defaultRingtoneType = getValueOrDefault(arguments, Definitions.NOTIFICATION_DEFAULT_RINGTONE_TYPE, DefaultRingtoneType.class, DefaultRingtoneType.Notification);
        groupKey            = getValueOrDefault(arguments, Definitions.NOTIFICATION_GROUP_KEY, String.class, null);
        locked              = getValueOrDefault(arguments, Definitions.NOTIFICATION_LOCKED, Boolean.class, false);
        onlyAlertOnce       = getValueOrDefault(arguments, Definitions.NOTIFICATION_ONLY_ALERT_ONCE, Boolean.class, false);

        return this;
    }

    public Map<String, Object> toMap(){
        Map<String, Object> dataMap = new HashMap<>();

        putDataOnSerializedMap(Definitions.NOTIFICATION_ICON_RESOURCE_ID, dataMap, this.iconResourceId);
        putDataOnSerializedMap(Definitions.NOTIFICATION_ICON, dataMap, this.icon);
        putDataOnSerializedMap(Definitions.NOTIFICATION_DEFAULT_COLOR, dataMap, this.defaultColor);
        putDataOnSerializedMap(Definitions.NOTIFICATION_CHANNEL_KEY, dataMap, this.channelKey);
        putDataOnSerializedMap(Definitions.NOTIFICATION_CHANNEL_NAME, dataMap, this.channelName);
        putDataOnSerializedMap(Definitions.NOTIFICATION_CHANNEL_DESCRIPTION, dataMap, this.channelDescription);
        putDataOnSerializedMap(Definitions.NOTIFICATION_CHANNEL_SHOW_BADGE, dataMap, this.channelShowBadge);
        putDataOnSerializedMap(Definitions.NOTIFICATION_CHANNEL_GROUP_KEY, dataMap, this.channelGroupKey);
        putDataOnSerializedMap(Definitions.NOTIFICATION_PLAY_SOUND, dataMap, this.playSound);
        putDataOnSerializedMap(Definitions.NOTIFICATION_SOUND_SOURCE, dataMap, this.soundSource);
        putDataOnSerializedMap(Definitions.NOTIFICATION_ENABLE_VIBRATION, dataMap, this.enableVibration);
        putDataOnSerializedMap(Definitions.NOTIFICATION_VIBRATION_PATTERN, dataMap, this.vibrationPattern);
        putDataOnSerializedMap(Definitions.NOTIFICATION_ENABLE_LIGHTS, dataMap, this.enableLights);
        putDataOnSerializedMap(Definitions.NOTIFICATION_LED_COLOR, dataMap, this.ledColor);
        putDataOnSerializedMap(Definitions.NOTIFICATION_LED_ON_MS, dataMap, this.ledOnMs);
        putDataOnSerializedMap(Definitions.NOTIFICATION_LED_OFF_MS, dataMap, this.ledOffMs);
        putDataOnSerializedMap(Definitions.NOTIFICATION_GROUP_KEY, dataMap, this.groupKey);
        putDataOnSerializedMap(Definitions.NOTIFICATION_GROUP_SORT, dataMap, this.groupSort);
        putDataOnSerializedMap(Definitions.NOTIFICATION_IMPORTANCE, dataMap, this.importance);
        putDataOnSerializedMap(Definitions.NOTIFICATION_GROUP_ALERT_BEHAVIOR, dataMap, this.groupAlertBehavior);
        putDataOnSerializedMap(Definitions.NOTIFICATION_DEFAULT_PRIVACY, dataMap, this.defaultPrivacy);
        putDataOnSerializedMap(Definitions.NOTIFICATION_DEFAULT_RINGTONE_TYPE, dataMap, this.defaultRingtoneType);
        putDataOnSerializedMap(Definitions.NOTIFICATION_LOCKED, dataMap, this.locked);
        putDataOnSerializedMap(Definitions.NOTIFICATION_ONLY_ALERT_ONCE, dataMap, this.onlyAlertOnce);
        putDataOnSerializedMap(Definitions.NOTIFICATION_CHANNEL_CRITICAL_ALERTS, dataMap, this.criticalAlerts);

        return dataMap;
    }

    @Override
    public String toJson() {
        return templateToJson();
    }

    @Override
    public NotificationChannelModel fromJson(String json){
        return (NotificationChannelModel) super.templateFromJson(json);
    }

    @Override
    public void validate(Context context) throws AwesomeNotificationsException {

        if(icon != null)
            if(BitmapUtils.getInstance().getMediaSourceType(icon) != MediaSource.Resource)
                throw ExceptionFactory
                        .getInstance()
                        .createNewAwesomeException(
                                TAG,
                                ExceptionCode.CODE_INVALID_ARGUMENTS,
                                "Icon is not a Resource media type",
                                ExceptionCode.DETAILED_INVALID_ARGUMENTS+".notificationContent");

        if(stringUtils.isNullOrEmpty(channelKey))
            throw ExceptionFactory
                    .getInstance()
                    .createNewAwesomeException(
                            TAG,
                            ExceptionCode.CODE_INVALID_ARGUMENTS,
                            "Channel key cannot be null or empty",
                            ExceptionCode.DETAILED_INVALID_ARGUMENTS+".channel.key");

        if(stringUtils.isNullOrEmpty(channelName))
            throw ExceptionFactory
                    .getInstance()
                    .createNewAwesomeException(
                            TAG,
                            ExceptionCode.CODE_INVALID_ARGUMENTS,
                            "Channel name cannot be null or empty",
                            ExceptionCode.DETAILED_INVALID_ARGUMENTS+".channel.name");

        if(stringUtils.isNullOrEmpty(channelDescription))
            throw ExceptionFactory
                    .getInstance()
                    .createNewAwesomeException(
                            TAG,
                            ExceptionCode.CODE_INVALID_ARGUMENTS,
                            "Channel description cannot be null or empty",
                            ExceptionCode.DETAILED_INVALID_ARGUMENTS+".channel.description");

        if(playSound == null)
            throw ExceptionFactory
                    .getInstance()
                    .createNewAwesomeException(
                            TAG,
                            ExceptionCode.CODE_INVALID_ARGUMENTS,
                            "Play sound selector cannot be null or empty",
                            ExceptionCode.DETAILED_INVALID_ARGUMENTS+".channel.playSound");

        if (ledColor != null && (ledOnMs == null || ledOffMs == null)) {
            throw ExceptionFactory
                    .getInstance()
                    .createNewAwesomeException(
                            TAG,
                            ExceptionCode.CODE_INVALID_ARGUMENTS,
                            "Standard led on and off times cannot be null or empty",
                            ExceptionCode.DETAILED_INVALID_ARGUMENTS+".channel.led");
        }

        if(BooleanUtils.getInstance().getValue(playSound) && !stringUtils.isNullOrEmpty(soundSource))
            if(!AudioUtils.getInstance().isValidAudio(context, soundSource))
                throw ExceptionFactory
                        .getInstance()
                        .createNewAwesomeException(
                                TAG,
                                ExceptionCode.CODE_INVALID_ARGUMENTS,
                                "Audio media is not valid",
                                ExceptionCode.DETAILED_INVALID_ARGUMENTS+".channel.sound");
    }

    public NotificationChannelModel clone() {
        NotificationChannelModel cloned = new NotificationChannelModel();

        cloned.iconResourceId = this.iconResourceId;
        cloned.defaultColor = this.defaultColor;
        cloned.channelKey = this.channelKey;
        cloned.channelName = this.channelName;
        cloned.channelDescription = this.channelDescription;
        cloned.channelShowBadge = this.channelShowBadge;
        cloned.importance = this.importance;
        cloned.playSound = this.playSound;
        cloned.soundSource = this.soundSource;
        cloned.enableVibration = this.enableVibration;
        cloned.vibrationPattern = this.vibrationPattern;
        cloned.enableLights = this.enableLights;
        cloned.ledColor = this.ledColor;
        cloned.ledOnMs = this.ledOnMs;
        cloned.ledOffMs = this.ledOffMs;
        cloned.groupKey = this.groupKey;
        cloned.locked = this.locked;
        cloned.onlyAlertOnce = this.onlyAlertOnce;
        cloned.defaultPrivacy = this.defaultPrivacy;
        cloned.defaultRingtoneType = this.defaultRingtoneType;
        cloned.groupSort = this.groupSort;
        cloned.groupAlertBehavior = this.groupAlertBehavior;
        cloned.criticalAlerts = this.criticalAlerts;

        return cloned;
    }
}
