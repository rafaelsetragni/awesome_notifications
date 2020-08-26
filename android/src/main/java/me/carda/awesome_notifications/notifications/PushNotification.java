package me.carda.awesome_notifications.notifications;

import android.content.Context;

import com.google.common.reflect.TypeToken;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import me.carda.awesome_notifications.Definitions;
import me.carda.awesome_notifications.notifications.exceptions.PushNotificationException;
import me.carda.awesome_notifications.notifications.models.NotificationButtonModel;
import me.carda.awesome_notifications.notifications.models.NotificationContentModel;
import me.carda.awesome_notifications.notifications.models.NotificationScheduleModel;
import me.carda.awesome_notifications.utils.JsonUtils;
import me.carda.awesome_notifications.utils.StringUtils;

public class PushNotification {

    public NotificationContentModel content;
    public NotificationScheduleModel schedule;
    public List<NotificationButtonModel> actionButtons;

    public static PushNotification fromMap(Map<String, Object> parameters){

        PushNotification pushNotification = new PushNotification();

        pushNotification.content = extractNotificationContent(Definitions.PUSH_NOTIFICATION_CONTENT, parameters);

        // required
        if(pushNotification.content == null) return null;

        pushNotification.schedule = extractNotificationSchedule(Definitions.PUSH_NOTIFICATION_SCHEDULE, parameters);
        pushNotification.actionButtons = extractNotificationButtons(Definitions.PUSH_NOTIFICATION_BUTTONS, parameters);

        return pushNotification;
    }

    public Map<String, Object> toMap(){

        if(content == null) return null;

        return new HashMap<String, Object>(){{

            put(Definitions.PUSH_NOTIFICATION_CONTENT, content.toMap());

            if(schedule != null)
                put(Definitions.PUSH_NOTIFICATION_SCHEDULE, schedule.toMap());

            if(actionButtons != null && !actionButtons.isEmpty()){
                List<Object> buttonsData = new ArrayList<>();
                for(NotificationButtonModel button : actionButtons){
                    buttonsData.add(button.toMap());
                }
                put(Definitions.PUSH_NOTIFICATION_BUTTONS, buttonsData);
            }
        }};
    }

    private static NotificationContentModel extractNotificationContent(String reference, Map<String, Object> parameters) {
        if(!parameters.containsKey(reference)) return null;
        Object obj = parameters.get(reference);

        if(!(obj instanceof Map<?,?>)) return null;
        Map<String, Object> map = (Map<String, Object>) obj;
        if(map.isEmpty()) return null;
        else return NotificationContentModel.fromMap(map);
    }

    private static NotificationScheduleModel extractNotificationSchedule(String reference, Map<String, Object> parameters) {
        if(!parameters.containsKey(reference)) return null;
        Object obj = parameters.get(reference);

        if(!(obj instanceof Map<?,?>)) return null;
        Map<String, Object> map = (Map<String, Object>) obj;
        if(map.isEmpty()) return null;
        else return NotificationScheduleModel.fromMap(map);
    }

    @SuppressWarnings("unchecked")
    private static List<NotificationButtonModel> extractNotificationButtons(String reference, Map<String, Object> parameters) {
        if(!parameters.containsKey(reference)) return null;
        Object obj = parameters.get(reference);

        if(!(obj instanceof List<?>)) return null;
        List<Object> actionButtonsData = (List<Object>) obj;

        List<NotificationButtonModel> actionButtons = new ArrayList<>();

        for (Object objButton: actionButtonsData) {
            if(!(objButton instanceof Map<?,?>)) return null;

            Map<String, Object> map = (Map<String, Object>) objButton;
            if(map.isEmpty()) continue;

            NotificationButtonModel button = NotificationButtonModel.fromMap(map);
            actionButtons.add(button);
        }

        if(actionButtons.isEmpty()) return null;

        return actionButtons;
    }

    public String toJson() {
        return JsonUtils.toJson(this);
        /*
        Map<String, Object> data = this.toMap();

        Gson gson = Model.buildGson();
        return gson.toJson(data);
        */
    }

    public static PushNotification fromJson(String json){
        if(StringUtils.isNullOrEmpty(json)) return null;
        return JsonUtils.fromJson(new TypeToken<PushNotification>(){}.getType(), json);
    }

    public void validate(Context context) throws PushNotificationException {
        if(this.content == null)
            throw new PushNotificationException("Push Notification content cannot be null or empty");

        this.content.validate(context);

        if(this.schedule != null)
            this.schedule.validate(context);

        if(this.actionButtons != null){
            for(NotificationButtonModel button : this.actionButtons){
                button.validate(context);
            }
        }
    }

}
