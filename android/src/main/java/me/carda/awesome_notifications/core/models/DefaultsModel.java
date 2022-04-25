package me.carda.awesome_notifications.core.models;

import android.content.Context;

import androidx.annotation.Nullable;

import java.util.HashMap;
import java.util.Map;

import me.carda.awesome_notifications.core.Definitions;
import me.carda.awesome_notifications.core.exceptions.AwesomeNotificationsException;
import me.carda.awesome_notifications.core.utils.StringUtils;

public class DefaultsModel extends AbstractModel {

    public String appIcon;
    public String silentDataCallback = "0";
    public String reverseDartCallback = "0";
    public String backgroundHandleClass;

    public DefaultsModel(){
        super(StringUtils.getInstance());
    }

    public DefaultsModel(
            @Nullable String defaultAppIcon,
            @Nullable Long reverseDartCallback,
            @Nullable Long silentDataCallback,
            @Nullable String backgroundHandleClass
    ){
        super(StringUtils.getInstance());

        this.appIcon = defaultAppIcon;
        this.silentDataCallback = silentDataCallback == null ? null : silentDataCallback.toString();
        this.reverseDartCallback = reverseDartCallback == null ? null : reverseDartCallback.toString();
        this.backgroundHandleClass = backgroundHandleClass;
    }

    @Override
    public AbstractModel fromMap(Map<String, Object> arguments) {
        appIcon  = getValueOrDefault(arguments, Definitions.NOTIFICATION_APP_ICON, String.class);
        silentDataCallback  = getValueOrDefault(arguments, Definitions.SILENT_HANDLE, String.class);
        reverseDartCallback = getValueOrDefault(arguments, Definitions.BACKGROUND_HANDLE, String.class);
        backgroundHandleClass = getValueOrDefault(arguments, Definitions.NOTIFICATION_BG_HANDLE_CLASS, String.class);

        return this;
    }

    @Override
    public Map<String, Object> toMap() {
        Map<String, Object> returnedObject = new HashMap<>();

        returnedObject.put(Definitions.NOTIFICATION_APP_ICON, appIcon);
        returnedObject.put(Definitions.SILENT_HANDLE, silentDataCallback);
        returnedObject.put(Definitions.BACKGROUND_HANDLE, reverseDartCallback);
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
