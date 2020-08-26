package me.carda.awesome_notifications.notifications.models;

import android.content.Context;

import java.util.HashMap;
import java.util.Map;

import me.carda.awesome_notifications.Definitions;
import me.carda.awesome_notifications.notifications.enumeratos.ActionButtonType;
import me.carda.awesome_notifications.notifications.exceptions.PushNotificationException;
import me.carda.awesome_notifications.utils.StringUtils;

public class NotificationButtonModel extends Model {

    public String key;
    public String icon;
    public String label;
    public Boolean enabled;
    public Boolean autoCancel;
    public ActionButtonType buttonType;

    public static NotificationButtonModel fromMap(Map<String, Object> arguments){
        return (NotificationButtonModel) new NotificationButtonModel().fromMapImplementation(arguments);
    }

    @Override
    Model fromMapImplementation(Map<String, Object> arguments) {

        key        = getValueOrDefault(arguments, Definitions.NOTIFICATION_BUTTON_KEY, String.class);
        icon       = getValueOrDefault(arguments, Definitions.NOTIFICATION_BUTTON_ICON, String.class);
        label      = getValueOrDefault(arguments, Definitions.NOTIFICATION_BUTTON_LABEL, String.class);

        buttonType = getEnumValueOrDefault(arguments, Definitions.NOTIFICATION_BUTTON_TYPE,
                ActionButtonType.class, ActionButtonType.values());

        enabled = getValueOrDefault(arguments, Definitions.NOTIFICATION_ENABLED, Boolean.class);
        autoCancel = getValueOrDefault(arguments, Definitions.NOTIFICATION_AUTO_CANCEL, Boolean.class);

        return this;
    }

    @Override
    public Map<String, Object> toMap() {
        Map<String, Object> returnedObject = new HashMap<>();

        returnedObject.put(Definitions.NOTIFICATION_BUTTON_KEY, key);
        returnedObject.put(Definitions.NOTIFICATION_BUTTON_ICON, icon);
        returnedObject.put(Definitions.NOTIFICATION_BUTTON_LABEL, label);

        returnedObject.put(Definitions.NOTIFICATION_BUTTON_TYPE,
                this.buttonType != null ? this.buttonType.toString() : "Default");

        returnedObject.put(Definitions.NOTIFICATION_ENABLED, enabled);
        returnedObject.put(Definitions.NOTIFICATION_AUTO_CANCEL, autoCancel);

        return returnedObject;
    }

    @Override
    public void validate(Context context) throws PushNotificationException {
        if(StringUtils.isNullOrEmpty(key))
            throw new PushNotificationException("Button action key cannot be null or empty");

        if(StringUtils.isNullOrEmpty(label))
            throw new PushNotificationException("Button label cannot be null or empty");
    }
}
