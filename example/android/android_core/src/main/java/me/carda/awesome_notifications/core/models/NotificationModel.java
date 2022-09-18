package me.carda.awesome_notifications.core.models;

import android.content.Context;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import me.carda.awesome_notifications.core.Definitions;
import me.carda.awesome_notifications.core.exceptions.AwesomeNotificationsException;
import me.carda.awesome_notifications.core.exceptions.ExceptionCode;
import me.carda.awesome_notifications.core.exceptions.ExceptionFactory;

public class NotificationModel extends AbstractModel {

    private static final String TAG = "NotificationModel";

    public boolean groupSummary = false;
    public String remoteHistory;

    public NotificationContentModel content;
    public NotificationScheduleModel schedule;
    public List<NotificationButtonModel> actionButtons;

    public NotificationModel(){}

    public NotificationModel ClonePush(){
        return new NotificationModel().fromMap(this.toMap());
    }

    @Override
    @Nullable
    public NotificationModel fromMap(Map<String, Object> parameters){
        content = extractNotificationContent(parameters);
        if(content == null) return null;

        schedule = extractNotificationSchedule(parameters);
        actionButtons = extractNotificationButtons(parameters);

        return this;
    }

    @Override
    public Map<String, Object> toMap(){
        if(content == null) return null;
        Map<String, Object> dataMap = new HashMap<>();

        putDataOnSerializedMap(Definitions.NOTIFICATION_MODEL_CONTENT, dataMap, content);
        putDataOnSerializedMap(Definitions.NOTIFICATION_MODEL_SCHEDULE, dataMap, schedule);
        putDataOnSerializedMap(Definitions.NOTIFICATION_MODEL_BUTTONS, dataMap, actionButtons);

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

    private static NotificationContentModel extractNotificationContent(
            @NonNull Map<String, Object> parameters
    ){
        if(!parameters.containsKey(Definitions.NOTIFICATION_MODEL_CONTENT)) return null;
        Object obj = parameters.get(Definitions.NOTIFICATION_MODEL_CONTENT);

        if(!(obj instanceof Map<?,?>)) return null;

        @SuppressWarnings("unchecked")
        Map<String, Object> map = (Map<String, Object>) obj;

        if(map.isEmpty()) return null;
        else return new NotificationContentModel().fromMap(map);
    }

    private static NotificationScheduleModel extractNotificationSchedule(
            @NonNull Map<String, Object> parameters
    ){
        if(!parameters.containsKey(Definitions.NOTIFICATION_MODEL_SCHEDULE)) return null;
        Object obj = parameters.get(Definitions.NOTIFICATION_MODEL_SCHEDULE);

        if(!(obj instanceof Map<?,?>)) return null;

        @SuppressWarnings("unchecked")
        Map<String, Object> map = (Map<String, Object>) obj;

        return NotificationScheduleModel.getScheduleModelFromMap(map);
    }

    @SuppressWarnings("unchecked")
    private static List<NotificationButtonModel> extractNotificationButtons(
            @NonNull Map<String, Object> parameters
    ){
        if(!parameters.containsKey(Definitions.NOTIFICATION_MODEL_BUTTONS)) return null;
        Object obj = parameters.get(Definitions.NOTIFICATION_MODEL_BUTTONS);

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

    public void validate(
            Context context
    ) throws AwesomeNotificationsException {
        if(this.content == null)
            throw ExceptionFactory
                    .getInstance()
                    .createNewAwesomeException(
                            TAG,
                            ExceptionCode.CODE_INVALID_ARGUMENTS,
                            "Notification content is required",
                            ExceptionCode.DETAILED_INVALID_ARGUMENTS+".notificationContent");

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
