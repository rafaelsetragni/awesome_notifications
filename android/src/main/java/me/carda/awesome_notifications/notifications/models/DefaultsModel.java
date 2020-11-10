package me.carda.awesome_notifications.notifications.models;

import android.content.Context;

import java.util.HashMap;
import java.util.Map;

import me.carda.awesome_notifications.Definitions;
import me.carda.awesome_notifications.notifications.exceptions.PushNotificationException;

public class DefaultsModel extends Model {

    public String appIcon;

    public DefaultsModel(){}

    public DefaultsModel(String defaultAppIcon){
        this.appIcon = defaultAppIcon;
    }

    @Override
    public Model fromMap(Map<String, Object> arguments) {
        appIcon  = getValueOrDefault(arguments, Definitions.NOTIFICATION_APP_ICON, String.class);

        return this;
    }

    @Override
    public Map<String, Object> toMap() {
        Map<String, Object> returnedObject = new HashMap<>();

        returnedObject.put(Definitions.NOTIFICATION_APP_ICON, appIcon);
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
    public void validate(Context context) throws PushNotificationException {

    }
}
