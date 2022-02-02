package me.carda.awesome_notifications.awesome_notifications_core.models;

import android.content.Context;

import java.util.HashMap;
import java.util.Map;

import me.carda.awesome_notifications.awesome_notifications_core.Definitions;
import me.carda.awesome_notifications.awesome_notifications_core.exceptions.AwesomeNotificationsException;

public class DefaultsModel extends AbstractModel {

    public String appIcon;
    public String silentDataCallback = "0";
    public String reverseDartCallback = "0";
    public String backgroundHandleClass;

    public DefaultsModel(){}

    public DefaultsModel(String defaultAppIcon, String dartCallbackHandle){
        this.appIcon = defaultAppIcon;
        this.reverseDartCallback = dartCallbackHandle;
    }

    @Override
    public AbstractModel fromMap(Map<String, Object> arguments) {
        appIcon  = getValueOrDefault(arguments, Definitions.NOTIFICATION_APP_ICON, String.class);
        silentDataCallback  = getValueOrDefault(arguments, Definitions.SILENT_HANDLE, String.class);
        reverseDartCallback = getValueOrDefault(arguments, Definitions.DART_BG_HANDLE, String.class);
        backgroundHandleClass = getValueOrDefault(arguments, Definitions.NOTIFICATION_BG_HANDLE_CLASS, String.class);

        return this;
    }

    @Override
    public Map<String, Object> toMap() {
        Map<String, Object> returnedObject = new HashMap<>();

        returnedObject.put(Definitions.NOTIFICATION_APP_ICON, appIcon);
        returnedObject.put(Definitions.SILENT_HANDLE, silentDataCallback);
        returnedObject.put(Definitions.DART_BG_HANDLE, reverseDartCallback);
        returnedObject.put(Definitions.NOTIFICATION_BG_HANDLE_CLASS, backgroundHandleClass);

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
    public void validate(Context context) throws AwesomeNotificationsException {

    }
}
