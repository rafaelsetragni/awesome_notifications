package me.carda.awesome_notifications.awesome_notifications_core.models;

import android.content.Context;

import java.util.HashMap;
import java.util.Map;

import me.carda.awesome_notifications.awesome_notifications_core.Definitions;
import me.carda.awesome_notifications.awesome_notifications_core.exceptions.AwesomeNotificationsException;
import me.carda.awesome_notifications.awesome_notifications_core.exceptions.ExceptionCode;
import me.carda.awesome_notifications.awesome_notifications_core.exceptions.ExceptionFactory;
import me.carda.awesome_notifications.awesome_notifications_core.utils.StringUtils;

public class NotificationChannelGroupModel extends AbstractModel {

    private static final String TAG = "NotificationChannelGroupModel";

    public String channelGroupName;
    public String channelGroupKey;

    public NotificationChannelGroupModel(){
        super(StringUtils.getInstance());
    }

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
