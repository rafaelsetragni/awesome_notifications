package me.carda.awesome_notifications.core.models;

import android.content.Context;

import java.util.HashMap;
import java.util.Map;

import me.carda.awesome_notifications.core.Definitions;
import me.carda.awesome_notifications.core.exceptions.AwesomeNotificationsException;
import me.carda.awesome_notifications.core.exceptions.ExceptionCode;
import me.carda.awesome_notifications.core.exceptions.ExceptionFactory;

public class NotificationChannelGroupModel extends AbstractModel {

    private static final String TAG = "NotificationChannelGroupModel";

    public String channelGroupName;
    public String channelGroupKey;

    @Override
    public NotificationChannelGroupModel fromMap(Map<String, Object> arguments) {
        channelGroupName = getValueOrDefault(arguments, Definitions.NOTIFICATION_CHANNEL_GROUP_NAME, String.class, null);
        channelGroupKey  = getValueOrDefault(arguments, Definitions.NOTIFICATION_CHANNEL_GROUP_KEY, String.class, null);

        return this;
    }

    public Map<String, Object> toMap(){
        Map<String, Object> dataMap = new HashMap<>();

        putDataOnSerializedMap(Definitions.NOTIFICATION_CHANNEL_GROUP_NAME, dataMap, this.channelGroupName);
        putDataOnSerializedMap(Definitions.NOTIFICATION_CHANNEL_GROUP_KEY, dataMap, this.channelGroupKey);

        return dataMap;
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
    public void validate(Context context) throws AwesomeNotificationsException {
        if(stringUtils.isNullOrEmpty(channelGroupName))
            throw ExceptionFactory
                    .getInstance()
                    .createNewAwesomeException(
                            TAG,
                            ExceptionCode.CODE_INVALID_ARGUMENTS,
                            "Channel group name cannot be null or empty",
                            ExceptionCode.DETAILED_INVALID_ARGUMENTS+".channelGroup.name");

        if(stringUtils.isNullOrEmpty(channelGroupKey))
            throw ExceptionFactory
                    .getInstance()
                    .createNewAwesomeException(
                            TAG,
                            ExceptionCode.CODE_INVALID_ARGUMENTS,
                            "Channel group key cannot be null or empty",
                            ExceptionCode.DETAILED_INVALID_ARGUMENTS+".channelGroup.key");
    }
}
