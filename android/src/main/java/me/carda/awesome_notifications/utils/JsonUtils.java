package me.carda.awesome_notifications.utils;

import com.google.common.reflect.TypeToken;
import com.google.gson.Gson;

import java.lang.reflect.Type;
import java.util.Map;

public class JsonUtils {

    public static Map<String, Object> fromJson(String jsonData){
        Gson gson = new Gson();
        Type type = new TypeToken<Map<String, Object>>(){}.getType();
        return gson.fromJson(jsonData, type);
    }

    public static String toJson(Map<String, Object> model){
        Gson gson = new Gson();
        return gson.toJson(model);
    }
}
