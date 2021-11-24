package me.carda.awesome_notifications.notifications.models;

import android.content.Context;

import java.util.HashMap;
import java.util.Map;

import androidx.annotation.Nullable;
import me.carda.awesome_notifications.Definitions;
import me.carda.awesome_notifications.notifications.enumerators.DefaultRingtoneType;
import me.carda.awesome_notifications.notifications.enumerators.GroupSort;
import me.carda.awesome_notifications.notifications.enumerators.MediaSource;
import me.carda.awesome_notifications.notifications.enumerators.GroupAlertBehaviour;
import me.carda.awesome_notifications.notifications.enumerators.NotificationImportance;
import me.carda.awesome_notifications.notifications.enumerators.NotificationPrivacy;
import me.carda.awesome_notifications.notifications.exceptions.AwesomeNotificationException;
import me.carda.awesome_notifications.utils.AudioUtils;
import me.carda.awesome_notifications.utils.BitmapUtils;
import me.carda.awesome_notifications.utils.BooleanUtils;
import me.carda.awesome_notifications.utils.CompareUtils;
import me.carda.awesome_notifications.utils.MediaUtils;
import me.carda.awesome_notifications.utils.StringUtils;

public class NotificationChannelModel extends AbstractModel {

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

    public NotificationChannelModel(){}

    public void refreshIconResource(Context context){
        if(iconResourceId == null && icon != null){
            if(MediaUtils.getMediaSourceType(icon) == MediaSource.Resource) {

                int resourceIndex = BitmapUtils.getDrawableResourceId(context, icon);
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
            return StringUtils.digestString(jsonData);
        }

        NotificationChannelModel channelCopied = this.clone();
        channelCopied.channelName = "";
        channelCopied.channelDescription = "";
        channelCopied.groupKey = null;

        String jsonData = channelCopied.toJson();
        return channelKey + "_" + StringUtils.digestString(jsonData);
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

        iconResourceId = getValueOrDefault(arguments, Definitions.NOTIFICATION_ICON_RESOURCE_ID, Integer.class);
        icon           = getValueOrDefault(arguments, Definitions.NOTIFICATION_ICON, String.class);

        if(icon != null){
            if(MediaUtils.getMediaSourceType(icon) != MediaSource.Resource){
                icon = null;
            }
        }

        defaultColor = getValueOrDefault(arguments, Definitions.NOTIFICATION_DEFAULT_COLOR, Long.class);

        channelKey         = getValueOrDefault(arguments, Definitions.NOTIFICATION_CHANNEL_KEY, String.class);
        channelName        = getValueOrDefault(arguments, Definitions.NOTIFICATION_CHANNEL_NAME, String.class);
        channelDescription = getValueOrDefault(arguments, Definitions.NOTIFICATION_CHANNEL_DESCRIPTION, String.class);
        channelShowBadge   = getValueOrDefault(arguments, Definitions.NOTIFICATION_CHANNEL_SHOW_BADGE, Boolean.class);

        channelGroupKey    = getValueOrDefault(arguments, Definitions.NOTIFICATION_CHANNEL_GROUP_KEY, String.class);

        playSound = getValueOrDefault(arguments, Definitions.NOTIFICATION_PLAY_SOUND, Boolean.class);
        soundSource = getValueOrDefault(arguments, Definitions.NOTIFICATION_SOUND_SOURCE, String.class);

        criticalAlerts   = getValueOrDefault(arguments, Definitions.NOTIFICATION_CHANNEL_CRITICAL_ALERTS, Boolean.class);

        enableVibration  = getValueOrDefault(arguments, Definitions.NOTIFICATION_ENABLE_VIBRATION, Boolean.class);
        vibrationPattern = getValueOrDefault(arguments, Definitions.NOTIFICATION_VIBRATION_PATTERN, long[].class);

        ledColor     = getValueOrDefault(arguments, Definitions.NOTIFICATION_LED_COLOR, Integer.class);
        enableLights = getValueOrDefault(arguments, Definitions.NOTIFICATION_ENABLE_LIGHTS, Boolean.class);
        ledOnMs      = getValueOrDefault(arguments, Definitions.NOTIFICATION_LED_ON_MS, Integer.class);
        ledOffMs     = getValueOrDefault(arguments, Definitions.NOTIFICATION_LED_OFF_MS, Integer.class);

        importance =
                getEnumValueOrDefault(arguments, Definitions.NOTIFICATION_IMPORTANCE, NotificationImportance.class, NotificationImportance.values());

        groupSort =
                getEnumValueOrDefault(arguments, Definitions.NOTIFICATION_GROUP_SORT, GroupSort.class, GroupSort.values());

        groupAlertBehavior =
                getEnumValueOrDefault(arguments, Definitions.NOTIFICATION_GROUP_ALERT_BEHAVIOR, GroupAlertBehaviour.class, GroupAlertBehaviour.values());

        defaultPrivacy =
                getEnumValueOrDefault(arguments, Definitions.NOTIFICATION_DEFAULT_PRIVACY, NotificationPrivacy.class, NotificationPrivacy.values());

        defaultRingtoneType =
                getEnumValueOrDefault(arguments, Definitions.NOTIFICATION_DEFAULT_RINGTONE_TYPE, DefaultRingtoneType.class, DefaultRingtoneType.values());

        groupKey = getValueOrDefault(arguments, Definitions.NOTIFICATION_GROUP_KEY, String.class);

        locked = getValueOrDefault(arguments, Definitions.NOTIFICATION_LOCKED, Boolean.class);
        onlyAlertOnce = getValueOrDefault(arguments, Definitions.NOTIFICATION_ONLY_ALERT_ONCE, Boolean.class);

        return this;
    }

    public Map<String, Object> toMap(){
        Map<String, Object> returnedObject = new HashMap<>();

        returnedObject.put(Definitions.NOTIFICATION_ICON_RESOURCE_ID, this.iconResourceId);

        returnedObject.put(Definitions.NOTIFICATION_ICON, this.icon);

        returnedObject.put(Definitions.NOTIFICATION_DEFAULT_COLOR, this.defaultColor);
            returnedObject.put(Definitions.NOTIFICATION_CHANNEL_KEY, this.channelKey);
            returnedObject.put(Definitions.NOTIFICATION_CHANNEL_NAME, this.channelName);
            returnedObject.put(Definitions.NOTIFICATION_CHANNEL_DESCRIPTION, this.channelDescription);
        if(this.channelShowBadge != null)
            returnedObject.put(Definitions.NOTIFICATION_CHANNEL_SHOW_BADGE, this.channelShowBadge);

        if(this.channelGroupKey != null)
            returnedObject.put(Definitions.NOTIFICATION_CHANNEL_GROUP_KEY, this.channelGroupKey);

        if(this.playSound != null)
            returnedObject.put(Definitions.NOTIFICATION_PLAY_SOUND, this.playSound);
        if(this.soundSource != null)
            returnedObject.put(Definitions.NOTIFICATION_SOUND_SOURCE, this.soundSource);

        if(this.enableVibration != null)
            returnedObject.put(Definitions.NOTIFICATION_ENABLE_VIBRATION, this.enableVibration);
        if(this.vibrationPattern != null)
            returnedObject.put(Definitions.NOTIFICATION_VIBRATION_PATTERN, this.vibrationPattern);

        if(this.enableLights != null)
            returnedObject.put(Definitions.NOTIFICATION_ENABLE_LIGHTS, this.enableLights);
        if(this.ledColor != null)
            returnedObject.put(Definitions.NOTIFICATION_LED_COLOR, this.ledColor);
        if(this.ledOnMs != null)
            returnedObject.put(Definitions.NOTIFICATION_LED_ON_MS, this.ledOnMs);
        if(this.ledOffMs != null)
            returnedObject.put(Definitions.NOTIFICATION_LED_OFF_MS, this.ledOffMs);

        if(this.groupKey != null)
            returnedObject.put(Definitions.NOTIFICATION_GROUP_KEY, this.groupKey);

        if(this.groupSort != null)
            returnedObject.put(Definitions.NOTIFICATION_GROUP_SORT, this.groupSort.toString());

        if(this.importance != null)
            returnedObject.put(Definitions.NOTIFICATION_IMPORTANCE, this.importance.toString());

        if(this.groupAlertBehavior != null)
            returnedObject.put(Definitions.NOTIFICATION_GROUP_ALERT_BEHAVIOR, this.groupAlertBehavior.toString());

        if(this.defaultPrivacy != null)
            returnedObject.put(Definitions.NOTIFICATION_DEFAULT_PRIVACY, this.defaultPrivacy.toString());

        if(this.defaultRingtoneType != null)
            returnedObject.put(Definitions.NOTIFICATION_DEFAULT_RINGTONE_TYPE, this.defaultRingtoneType.toString());

        if(this.locked != null)
            returnedObject.put(Definitions.NOTIFICATION_LOCKED, this.locked);
        if(this.onlyAlertOnce != null)
            returnedObject.put(Definitions.NOTIFICATION_ONLY_ALERT_ONCE, this.onlyAlertOnce);

        if(this.criticalAlerts != null && this.criticalAlerts)
            returnedObject.put(Definitions.NOTIFICATION_CHANNEL_CRITICAL_ALERTS, this.criticalAlerts);

        return returnedObject;
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
    public void validate(Context context) throws AwesomeNotificationException {
        if(StringUtils.isNullOrEmpty(channelKey))
            throw new AwesomeNotificationException("Channel key cannot be null or empty");

        if(StringUtils.isNullOrEmpty(channelName))
            throw new AwesomeNotificationException("Channel name cannot be null or empty");

        if(StringUtils.isNullOrEmpty(channelDescription))
            throw new AwesomeNotificationException("Channel description cannot be null or empty");

        if(playSound == null)
            throw new AwesomeNotificationException("Play sound selector cannot be null or empty");

        if (ledColor != null && (ledOnMs == null || ledOffMs == null)) {
            throw new AwesomeNotificationException("Standard led on and off times cannot be null or empty");
        }

        if(BooleanUtils.getValue(playSound) && !StringUtils.isNullOrEmpty(soundSource))
            if(!AudioUtils.isValidAudio(context, soundSource))
                throw new AwesomeNotificationException("Audio media is not valid");
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
