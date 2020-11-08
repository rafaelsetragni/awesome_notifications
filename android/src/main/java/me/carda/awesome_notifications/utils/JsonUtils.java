package me.carda.awesome_notifications.utils;

import com.google.common.reflect.TypeToken;
import com.google.gson.Gson;
import com.google.gson.GsonBuilder;

import java.lang.reflect.Type;
import java.util.ArrayList;
import java.util.List;

import androidx.annotation.NonNull;
import me.carda.awesome_notifications.externalLibs.RuntimeTypeAdapterFactory;
import me.carda.awesome_notifications.notifications.models.Model;
import me.carda.awesome_notifications.notifications.models.NotificationButtonModel;
import me.carda.awesome_notifications.notifications.models.NotificationChannelModel;
import me.carda.awesome_notifications.notifications.models.NotificationContentModel;
import me.carda.awesome_notifications.notifications.models.NotificationScheduleModel;
import me.carda.awesome_notifications.notifications.models.returnedData.ActionReceived;
import me.carda.awesome_notifications.notifications.models.returnedData.NotificationReceived;

public class JsonUtils {

    @NonNull
    private static Gson buildGson() {
        RuntimeTypeAdapterFactory<Model> notificationModelAdapter =
                RuntimeTypeAdapterFactory
                        .of(Model.class)
                        .registerSubtype(NotificationButtonModel.class, "Button")
                        .registerSubtype(NotificationChannelModel.class, "Channel")
                        .registerSubtype(NotificationContentModel.class, "Content")
                        .registerSubtype(NotificationScheduleModel.class, "Schedule")
                        .registerSubtype(NotificationReceived.class, "NReceived")
                        .registerSubtype(ActionReceived.class, "AReceived");

        GsonBuilder builder = new GsonBuilder().registerTypeAdapterFactory(notificationModelAdapter);
        return builder.create();
    }

    public static <T> List<T> fromJsonList(Type type, String jsonData){
        Gson gson = buildGson();
        ArrayList<T> modelList = gson.fromJson(jsonData, type);
        return modelList;
    }

    public static <T> T fromJson(Type type, String jsonData){
        Gson gson = buildGson();
        T model = gson.fromJson(jsonData, type);
        return model;
    }

    public static <T> String toJson(List<T> modelList){
        Gson gson = buildGson();
        String notificationDetailsJson = gson.toJson(modelList);
        return notificationDetailsJson;
    }

    public static <T> String toJson(T model){
        Gson gson = buildGson();
        String notificationDetailsJson = gson.toJson(model);
        return notificationDetailsJson;
    }
}
