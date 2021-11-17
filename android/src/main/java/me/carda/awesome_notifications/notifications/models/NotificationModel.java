package me.carda.awesome_notifications.notifications.models;

import android.content.Context;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import me.carda.awesome_notifications.Definitions;
import me.carda.awesome_notifications.notifications.exceptions.AwesomeNotificationException;

public class NotificationModel extends AbstractModel {

    public boolean groupSummary = false;
    public String remoteHistory;

    public NotificationContentModel content;
    public NotificationScheduleModel schedule;
    public List<NotificationButtonModel> actionButtons;

    public NotificationModel(){}

    public NotificationModel ClonePush(){
        NotificationModel newPush = new NotificationModel();
        newPush.fromMap(this.toMap());
        return newPush;
    }

    @Override
    public NotificationModel fromMap(Map<String, Object> parameters){

        content = extractNotificationContent(Definitions.NOTIFICATION_MODEL_CONTENT, parameters);

        // required
        if(content == null) return null;

        schedule = extractNotificationSchedule(Definitions.NOTIFICATION_MODEL_SCHEDULE, parameters);
        actionButtons = extractNotificationButtons(Definitions.NOTIFICATION_MODEL_BUTTONS, parameters);

        return this;
    }

    @Override
    public Map<String, Object> toMap(){

        if(content == null) return null;
        Map<String, Object> dataMap = new HashMap<String, Object>();

        dataMap.put(Definitions.NOTIFICATION_MODEL_CONTENT, content.toMap());

        if(schedule != null)
            dataMap.put(Definitions.NOTIFICATION_MODEL_SCHEDULE, schedule.toMap());

        if(actionButtons != null && !actionButtons.isEmpty()){
            List<Object> buttonsData = new ArrayList<>();
            for(NotificationButtonModel button : actionButtons){
                buttonsData.add(button.toMap());
            }
            dataMap.put(Definitions.NOTIFICATION_MODEL_BUTTONS, buttonsData);
        }

        return dataMap;
    }

    @Override
    public String toJson() {
        return templateToJson();
    }

    @Override
    public NotificationModel fromJson(String json){
        return (NotificationModel) super.templateFromJson(json);
    }

    private static NotificationContentModel extractNotificationContent(String reference, Map<String, Object> parameters) {
        if(parameters == null || !parameters.containsKey(reference)) return null;
        Object obj = parameters.get(reference);

        if(!(obj instanceof Map<?,?>)) return null;

        @SuppressWarnings("unchecked")
        Map<String, Object> map = (Map<String, Object>) obj;

        if(map.isEmpty()) return null;
        else return new NotificationContentModel().fromMap(map);
    }

    private static NotificationScheduleModel extractNotificationSchedule(String reference, Map<String, Object> parameters) {
        if(parameters == null || !parameters.containsKey(reference)) return null;
        Object obj = parameters.get(reference);

        if(!(obj instanceof Map<?,?>)) return null;

        @SuppressWarnings("unchecked")
        Map<String, Object> map = (Map<String, Object>) obj;

        return NotificationScheduleModel.getScheduleModelFromMap(map);
    }

    @SuppressWarnings("unchecked")
    private static List<NotificationButtonModel> extractNotificationButtons(String reference, Map<String, Object> parameters) {
        if(parameters == null || !parameters.containsKey(reference)) return null;
        Object obj = parameters.get(reference);

        if(!(obj instanceof List<?>)) return null;
        List<Object> actionButtonsData = (List<Object>) obj;

        List<NotificationButtonModel> actionButtons = new ArrayList<>();

        for (Object objButton: actionButtonsData) {
            if(!(objButton instanceof Map<?,?>)) return null;

            Map<String, Object> map = (Map<String, Object>) objButton;
            if(map.isEmpty()) continue;

            NotificationButtonModel button = new NotificationButtonModel().fromMap(map);
            actionButtons.add(button);
        }

        if(actionButtons.isEmpty()) return null;

        return actionButtons;
    }

    public void validate(Context context) throws AwesomeNotificationException {
        if(this.content == null)
            throw new AwesomeNotificationException("Push Notification content cannot be null or empty");

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
