package me.carda.awesome_notifications.notifications.models;

import android.content.Context;

import java.util.HashMap;
import java.util.Map;

import me.carda.awesome_notifications.Definitions;
import me.carda.awesome_notifications.notifications.exceptions.AwesomeNotificationException;

public class DefaultsModel extends AbstractModel {

    public String appIcon;
    public Boolean firebaseEnabled;

    public DefaultsModel(){}

    public DefaultsModel(String defaultAppIcon){
        this.appIcon = defaultAppIcon;
    }

    @Override
    public AbstractModel fromMap(Map<String, Object> arguments) {
        appIcon  = getValueOrDefault(arguments, Definitions.NOTIFICATION_APP_ICON, String.class);
        firebaseEnabled  = getValueOrDefault(arguments, Definitions.FIREBASE_ENABLED, Boolean.class);

        return this;
    }

    @Override
    public Map<String, Object> toMap() {
        Map<String, Object> returnedObject = new HashMap<>();

        returnedObject.put(Definitions.NOTIFICATION_APP_ICON, appIcon);
        returnedObject.put(Definitions.FIREBASE_ENABLED, firebaseEnabled);
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
