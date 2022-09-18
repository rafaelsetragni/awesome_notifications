package me.carda.awesome_notifications.core.models;

import android.content.Context;

import java.util.HashMap;
import java.util.Map;

import me.carda.awesome_notifications.core.Definitions;
import me.carda.awesome_notifications.core.exceptions.AwesomeNotificationsException;

public class NotificationMessageModel extends AbstractModel {

    public String title;
    public String message;
    public String largeIcon;
    public Long timestamp;

    public NotificationMessageModel(){}

    public NotificationMessageModel(String title, String message, String largeIcon){

        this.title = title;
        this.message = message;
        this.largeIcon = largeIcon;
        this.timestamp = System.currentTimeMillis();
    }

    @Override
    public NotificationMessageModel fromMap(Map<String, Object> arguments) {

        title     = getValueOrDefault(arguments, Definitions.NOTIFICATION_TITLE, String.class, null);
        message   = getValueOrDefault(arguments, Definitions.NOTIFICATION_MESSAGES, String.class, null);
        largeIcon = getValueOrDefault(arguments, Definitions.NOTIFICATION_LARGE_ICON, String.class, null);
        timestamp = getValueOrDefault(arguments, Definitions.NOTIFICATION_TIMESTAMP, Long.class, null);

        return this;
    }

    @Override
    public Map<String, Object> toMap() {
        Map<String, Object> dataMap = new HashMap<>();

        putDataOnSerializedMap(Definitions.NOTIFICATION_TITLE, dataMap, title);
        putDataOnSerializedMap(Definitions.NOTIFICATION_MESSAGES, dataMap, message);
        putDataOnSerializedMap(Definitions.NOTIFICATION_LARGE_ICON, dataMap, largeIcon);
        putDataOnSerializedMap(Definitions.NOTIFICATION_TIMESTAMP, dataMap, timestamp);

        return dataMap;
    }

    @Override
    public String toJson() {
        return templateToJson();
    }

    @Override
    public NotificationButtonModel fromJson(String json){
        return (NotificationButtonModel) super.templateFromJson(json);
    }

    @Override
    public void validate(Context context) throws AwesomeNotificationsException {
    }

}
