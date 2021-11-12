package me.carda.awesome_notifications.notifications.models;

import android.content.Context;

import java.util.HashMap;
import java.util.Map;

import androidx.annotation.Nullable;
import me.carda.awesome_notifications.Definitions;
import me.carda.awesome_notifications.notifications.enumerators.DefaultRingtoneType;
import me.carda.awesome_notifications.notifications.enumerators.GroupAlertBehaviour;
import me.carda.awesome_notifications.notifications.enumerators.GroupSort;
import me.carda.awesome_notifications.notifications.enumerators.MediaSource;
import me.carda.awesome_notifications.notifications.enumerators.NotificationImportance;
import me.carda.awesome_notifications.notifications.enumerators.NotificationPrivacy;
import me.carda.awesome_notifications.notifications.exceptions.AwesomeNotificationException;
import me.carda.awesome_notifications.utils.AudioUtils;
import me.carda.awesome_notifications.utils.BitmapUtils;
import me.carda.awesome_notifications.utils.BooleanUtils;
import me.carda.awesome_notifications.utils.CompareUtils;
import me.carda.awesome_notifications.utils.MediaUtils;
import me.carda.awesome_notifications.utils.StringUtils;

public class NotificationChannelGroupModel extends Model {
    public String channelGroupName;
    public String channelGroupKey;

    public NotificationChannelGroupModel(){}

    @Override
    public NotificationChannelGroupModel fromMap(Map<String, Object> arguments) {
        channelGroupName = getValueOrDefault(arguments, Definitions.NOTIFICATION_CHANNEL_GROUP_NAME, String.class);
        channelGroupKey = getValueOrDefault(arguments, Definitions.NOTIFICATION_CHANNEL_GROUP_KEY, String.class);

        return this;
    }

    public Map<String, Object> toMap(){
        Map<String, Object> returnedObject = new HashMap<>();

        returnedObject.put(Definitions.NOTIFICATION_CHANNEL_GROUP_NAME, this.channelGroupName);
        returnedObject.put(Definitions.NOTIFICATION_CHANNEL_GROUP_KEY, this.channelGroupKey);

        return returnedObject;
    }

    @Override
    public String toJson() {
        return templateToJson();
    }

    @Override
    public NotificationChannelGroupModel fromJson(String json){
        return (NotificationChannelGroupModel) super.templateFromJson(json);
    }

    @Override
    public void validate(Context context) throws AwesomeNotificationException {
        if(StringUtils.isNullOrEmpty(channelGroupName))
            throw new AwesomeNotificationException("Channel group name cannot be null or empty");

        if(StringUtils.isNullOrEmpty(channelGroupKey))
            throw new AwesomeNotificationException("Channel group key cannot be null or empty");
    }
}
