package me.carda.awesome_notifications.core.models;

import android.content.Context;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import java.util.HashMap;
import java.util.Map;

import me.carda.awesome_notifications.core.Definitions;
import me.carda.awesome_notifications.core.exceptions.AwesomeNotificationsException;

public class DefaultsModel extends AbstractModel {

    public String appIcon;
    public String silentDataCallback = "0";
    public String reverseDartCallback = "0";
    public String backgroundHandleClass;

    public DefaultsModel(){}

    public DefaultsModel(
            @Nullable String defaultAppIcon,
            @Nullable Long reverseDartCallback,
            @Nullable Long silentDataCallback,
            @Nullable String backgroundHandleClass
    ){
        this.appIcon = defaultAppIcon;
        this.silentDataCallback = silentDataCallback == null ? null : silentDataCallback.toString();
        this.reverseDartCallback = reverseDartCallback == null ? null : reverseDartCallback.toString();
        this.backgroundHandleClass = backgroundHandleClass;
    }

    @Override
    public AbstractModel fromMap(Map<String, Object> arguments) {
        appIcon               = getValueOrDefault(arguments, Definitions.NOTIFICATION_APP_ICON, String.class, null);
        silentDataCallback    = getValueOrDefault(arguments, Definitions.SILENT_HANDLE, String.class, null);
        reverseDartCallback   = getValueOrDefault(arguments, Definitions.BACKGROUND_HANDLE, String.class, null);
        backgroundHandleClass = getValueOrDefault(arguments, Definitions.NOTIFICATION_BG_HANDLE_CLASS, String.class, null);

        return this;
    }

    @Override
    public Map<String, Object> toMap() {
        Map<String, Object> dataMap = new HashMap<>();

        putDataOnSerializedMap(Definitions.NOTIFICATION_APP_ICON, dataMap, appIcon);
        putDataOnSerializedMap(Definitions.SILENT_HANDLE, dataMap, silentDataCallback);
        putDataOnSerializedMap(Definitions.BACKGROUND_HANDLE, dataMap, reverseDartCallback);
        putDataOnSerializedMap(Definitions.NOTIFICATION_BG_HANDLE_CLASS, dataMap, backgroundHandleClass);

        return dataMap;
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
