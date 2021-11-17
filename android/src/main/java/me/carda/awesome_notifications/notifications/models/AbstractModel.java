package me.carda.awesome_notifications.notifications.models;

import android.content.Context;

import java.util.Map;

import me.carda.awesome_notifications.Definitions;
import me.carda.awesome_notifications.notifications.exceptions.AwesomeNotificationException;
import me.carda.awesome_notifications.utils.JsonUtils;
import me.carda.awesome_notifications.utils.MapUtils;
import me.carda.awesome_notifications.utils.StringUtils;

public abstract class AbstractModel {

    public abstract AbstractModel fromMap(Map<String, Object> arguments);
    public abstract Map<String, Object> toMap();

    public abstract String toJson();
    public abstract AbstractModel fromJson(String json);

    protected String templateToJson(){
        return JsonUtils.toJson(this.toMap());
    }

    protected AbstractModel templateFromJson(String json) {
        if(StringUtils.isNullOrEmpty(json)) return null;
        Map<String, Object> map = JsonUtils.fromJson(json);
        return this.fromMap(map);
    }

    public AbstractModel onlyFromValidMap(Context context, Map<String, Object> arguments){

        // Set default values
        fromMap(arguments);

        try {
            validate(context);
            return this;
        }
        catch (Exception e){
            e.printStackTrace();
            return null;
        }
    }

    protected static <T> T getValueOrDefault(Map<String, Object> arguments, String reference, Class<T> expectedClass) {
        T value = MapUtils.extractValue(arguments, reference, expectedClass).orNull();

        if(value != null) return value;

        return MapUtils.extractValue(Definitions.initialValues, reference, expectedClass).orNull();
    }

    protected static <T> T getEnumValueOrDefault(Map<String, Object> arguments, String reference, Class<T> enumerator, T[] values) {
        String key = MapUtils.extractValue(arguments, reference, String.class).orNull();
        T defaultValue =  MapUtils.extractValue(Definitions.initialValues, reference, enumerator).orNull();
        if(key == null) return defaultValue;

        for(T enumValue : values){
            if(enumValue.toString().toLowerCase().equals(key.toLowerCase())) return enumValue;
        }

        return defaultValue;
    }

    public abstract void validate(Context context) throws AwesomeNotificationException;

}
