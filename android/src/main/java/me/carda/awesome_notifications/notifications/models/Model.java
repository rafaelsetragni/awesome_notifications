package me.carda.awesome_notifications.notifications.models;

import android.content.Context;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;

import java.util.Map;

import androidx.annotation.NonNull;
import me.carda.awesome_notifications.Definitions;
import me.carda.awesome_notifications.notifications.exceptions.PushNotificationException;
import me.carda.awesome_notifications.utils.MapUtils;

public abstract class Model {

    protected abstract Model fromMapImplementation(Map<String, Object> arguments);
    public abstract Map<String, Object> toMap();

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

    public abstract void validate(Context context) throws PushNotificationException ;

}
