package me.carda.awesome_notifications.awesome_notifications_android_core.models;

import android.content.Context;

import java.io.Serializable;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import me.carda.awesome_notifications.awesome_notifications_android_core.Definitions;
import me.carda.awesome_notifications.awesome_notifications_android_core.exceptions.AwesomeNotificationException;
import me.carda.awesome_notifications.awesome_notifications_android_core.utils.JsonUtils;
import me.carda.awesome_notifications.awesome_notifications_android_core.utils.ListUtils;
import me.carda.awesome_notifications.awesome_notifications_android_core.utils.MapUtils;
import me.carda.awesome_notifications.awesome_notifications_android_core.utils.StringUtils;

public abstract class AbstractModel implements Cloneable {

    public static Map<String, Object> defaultValues = new HashMap<>();

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

    public AbstractModel getClone () {
        try {
            return (AbstractModel)this.clone();
        }
        catch (CloneNotSupportedException ex) {
            ex.printStackTrace();
            return null;
        }
    }

    // ************** CHAIN OF RESPONSIBILITY PATTERN ***********************************

    public static void putDataOnMapObject(@NonNull String reference, @NonNull Map<String, Object> mapData, @Nullable Object value){
        if(value != null)
            mapData.put(reference, serializeValue(value));
    }

    public static Serializable serializeValue(@Nullable Object value){
        if(value == null) return null;

        Object serializedValue;

        if(value.getClass().isEnum())
            serializedValue = value.toString();
        else if(List.class.isAssignableFrom(value.getClass())){
            serializedValue = serializeList((List) value);
        }
        else if(Map.class.isAssignableFrom(value.getClass())){
            serializedValue = serializeMap((Map<String, Object>) value);
        }
        else if(AbstractModel.class.isAssignableFrom(value.getClass())){
            serializedValue = ((AbstractModel) value).toMap();
        }
        else serializedValue = value;

        if(serializedValue != null)
            if(Serializable.class.isAssignableFrom(serializedValue.getClass()))
                return (Serializable) serializedValue;

        return null;
    }

    public static Serializable serializeList(List originalList){
        if(ListUtils.isNullOrEmpty(originalList))
            return null;

        List<Object> serializedList = new ArrayList();
        for(Object item : originalList)
            serializedList.add(serializeValue(item));
        return (Serializable) serializedList;
    }

    public static Serializable serializeMap(Map<String, Object> originalMap){
        if(MapUtils.isNullOrEmpty(originalMap))
            return null;

        Map<String, Object> serializedMap = new HashMap<>();
        for(Map.Entry<String, Object> entry : originalMap.entrySet())
            putDataOnMapObject(entry.getKey(), serializedMap, entry.getValue());

        return (Serializable) serializedMap;
    }


    // **************************************************************************

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

        return MapUtils.extractValue(defaultValues, reference, expectedClass).orNull();
    }

    public static <T> T getEnumValueOrDefault(Map<String, Object> arguments, String reference, Class<T> enumerator, T[] values) {
        String key = MapUtils.extractValue(arguments, reference, String.class).orNull();
        T defaultValue =  MapUtils.extractValue(defaultValues, reference, enumerator).orNull();
        if(key == null) return defaultValue;

        for(T enumValue : values){
            if(enumValue.toString().toLowerCase().equals(key.toLowerCase())) return enumValue;
        }

        return defaultValue;
    }

    public abstract void validate(Context context) throws AwesomeNotificationException;

}
