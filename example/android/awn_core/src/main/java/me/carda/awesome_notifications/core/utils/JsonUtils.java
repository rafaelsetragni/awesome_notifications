package me.carda.awesome_notifications.core.utils;

import com.google.common.reflect.TypeToken;
import com.google.gson.Gson;

import java.lang.reflect.Type;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Map;

import javax.annotation.Nullable;


public class JsonUtils {

    public static Map<String, Object> fromJson(String jsonData){
        Gson gson = new Gson();
        Type type = new TypeToken<Map<String, Object>>(){}.getType();
        return gson.fromJson(jsonData, type);
    }

    public static String toJson(Map<String, Object> model){
        return chainOfResponsibilityToJson(model);
    }

    // ************** CHAIN OF RESPONSIBILITY PATTERN ***********************************

    @SuppressWarnings("unchecked")
    static String chainOfResponsibilityToJson(@Nullable Object object){

        if(object == null) return "null";

        StringBuilder text = new StringBuilder();

        if(object instanceof Map<?, ?>){
            text.append(chainOfResponsibilityMapToJson((Map<String, Object>) object));
        } else
        if(object instanceof List){
            text.append(chainOfResponsibilityListToJson((List<Object>) object));
        } else {
            text.append(chainOfResponsibilityGenericsToJson(object));
        }

        return text.toString();
    }

    static String chainOfResponsibilityMapToJson(@Nullable Map<String, Object> map){

        if(map == null) return "null";

        List<String> parameters = new ArrayList<>();

        List<String> sortedKeys = new ArrayList<>(map.keySet());
        Collections.sort(sortedKeys);

        for (String key : sortedKeys) {
            Object value = map.get(key);

            StringBuilder text = new StringBuilder();
            text.append("\"").append(key).append("\":");

            if(value == null)
                text.append("null");
            else
                text.append(chainOfResponsibilityToJson(value));

            parameters.add(text.toString());
        }

        return "{"+ joinList(parameters) + "}";
    }

    static String chainOfResponsibilityListToJson(@Nullable List<Object> list){

        if(list == null) return "null";

        List<String> parameters = new ArrayList<>();
        for (Object parameter : list)
            parameters.add(chainOfResponsibilityGenericsToJson(parameter));

        return "["+ joinList(parameters) + "]";
    }

    static String chainOfResponsibilityGenericsToJson(@Nullable Object generic){

        if(generic == null) return "null";

        // Gson is only trustable at this lower level
        Gson gson = new Gson();

        if((generic instanceof Map) || (generic instanceof List)){
            return chainOfResponsibilityToJson(generic);
        } else
        if(generic instanceof Boolean){
            return gson.toJson(generic);
        } else
        if(generic instanceof Number){
            return gson.toJson(generic);
        } else
        if(generic instanceof String){
            return gson.toJson(generic);
        }

        return "null";
    }

    static String joinList(@Nullable List<String> input) {

        if (input == null || input.size() <= 0) return "";

        StringBuilder stringBuilder = new StringBuilder();

        int cursor = 0; int size = input.size() - 1;
        for (cursor = 0; cursor < size; cursor++)
            stringBuilder
                    .append(input.get(cursor))
                    .append(",");

        stringBuilder
                .append(input.get(cursor));

        return stringBuilder.toString();
    }
}
