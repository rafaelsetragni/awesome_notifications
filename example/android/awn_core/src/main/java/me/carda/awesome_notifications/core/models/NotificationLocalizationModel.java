package me.carda.awesome_notifications.core.models;

import android.content.Context;

import java.util.HashMap;
import java.util.Map;

import me.carda.awesome_notifications.core.Definitions;
import me.carda.awesome_notifications.core.exceptions.AwesomeNotificationsException;

public class NotificationLocalizationModel extends AbstractModel {
    private static final String TAG = "NotificationLocalization";

    public String title;
    public String body;
    public String summary;
    public String largeIcon;
    public String bigPicture;
    public Map<String, String> buttonLabels;

    @Override
    public NotificationLocalizationModel fromMap(Map<String, Object> arguments) {
        title        = getValueOrDefault(arguments, Definitions.NOTIFICATION_TITLE, String.class, null);
        body         = getValueOrDefault(arguments, Definitions.NOTIFICATION_BODY, String.class, null);
        summary      = getValueOrDefault(arguments, Definitions.NOTIFICATION_SUMMARY, String.class, null);
        largeIcon    = getValueOrDefault(arguments, Definitions.NOTIFICATION_LARGE_ICON, String.class, null);
        bigPicture   = getValueOrDefault(arguments, Definitions.NOTIFICATION_BIG_PICTURE, String.class, null);
        buttonLabels = getValueOrDefaultMap(arguments, Definitions.NOTIFICATION_BUTTON_LABELS, null);

        return this;
    }

    @Override
    public Map<String, Object> toMap() {
        Map<String, Object> dataMap = new HashMap<>();

        putDataOnSerializedMap(Definitions.NOTIFICATION_TITLE, dataMap, title);
        putDataOnSerializedMap(Definitions.NOTIFICATION_BODY, dataMap, body);
        putDataOnSerializedMap(Definitions.NOTIFICATION_SUMMARY, dataMap, summary);
        putDataOnSerializedMap(Definitions.NOTIFICATION_LARGE_ICON, dataMap, largeIcon);
        putDataOnSerializedMap(Definitions.NOTIFICATION_BIG_PICTURE, dataMap, bigPicture);
        putDataOnSerializedMap(Definitions.NOTIFICATION_BUTTON_LABELS, dataMap, buttonLabels);

        return dataMap;
    }

    @Override
    public String toJson() {
        return templateToJson();
    }

    @Override
    public NotificationLocalizationModel fromJson(String json){
        return (NotificationLocalizationModel) super.templateFromJson(json);
    }

    @Override
    public void validate(Context context) throws AwesomeNotificationsException {

    }
}
