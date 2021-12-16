package me.carda.awesome_notifications.awesome_notifications_android_core.models;

import android.content.Context;

import java.util.HashMap;
import java.util.Map;

import me.carda.awesome_notifications.awesome_notifications_android_core.Definitions;
import me.carda.awesome_notifications.awesome_notifications_android_core.exceptions.AwesomeNotificationException;

public class DefaultsModel extends AbstractModel {

    public String appIcon;
    public long silentDataCallback;
    public long reverseDartCallback;

    public DefaultsModel(){}

    public DefaultsModel(String defaultAppIcon, long dartCallbackHandle){
        this.appIcon = defaultAppIcon;
        this.reverseDartCallback = dartCallbackHandle;
    }

    @Override
    public AbstractModel fromMap(Map<String, Object> arguments) {
        appIcon  = getValueOrDefault(arguments, Definitions.NOTIFICATION_APP_ICON, String.class);
        silentDataCallback  = getValueOrDefault(arguments, Definitions.SILENT_HANDLE, Long.class);
        reverseDartCallback = getValueOrDefault(arguments, Definitions.DART_BG_HANDLE, Long.class);

        return this;
    }

    @Override
    public Map<String, Object> toMap() {
        Map<String, Object> returnedObject = new HashMap<>();

        returnedObject.put(Definitions.NOTIFICATION_APP_ICON, appIcon);
        returnedObject.put(Definitions.SILENT_HANDLE, silentDataCallback);
        returnedObject.put(Definitions.DART_BG_HANDLE, reverseDartCallback);
        return returnedObject;
    }

    @Override
    public String toJson() {
        return templateToJson();
    }

    @Override
    public DefaultsModel fromJson(String json){
        return (DefaultsModel) super.templateFromJson(json);
    }

    @Override
    public void validate(Context context) throws AwesomeNotificationException {

    }
}
