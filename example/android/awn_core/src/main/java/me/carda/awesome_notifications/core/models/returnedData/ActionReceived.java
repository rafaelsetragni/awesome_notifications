package me.carda.awesome_notifications.core.models.returnedData;

import android.content.Intent;

import java.util.Calendar;
import java.util.Map;

import me.carda.awesome_notifications.core.Definitions;
import me.carda.awesome_notifications.core.enumerators.NotificationLifeCycle;
import me.carda.awesome_notifications.core.exceptions.AwesomeNotificationsException;
import me.carda.awesome_notifications.core.models.NotificationContentModel;
import me.carda.awesome_notifications.core.utils.CalendarUtils;

public class ActionReceived extends NotificationReceived {

    public String buttonKeyPressed;
    public String buttonKeyInput;

    // The value autoDismiss must return as original. Because
    // of that, this variable is being used as temporary
    public boolean shouldAutoDismiss = true;

    public NotificationLifeCycle actionLifeCycle;
    public NotificationLifeCycle dismissedLifeCycle;
    public Calendar actionDate;
    public Calendar dismissedDate;

    public ActionReceived(){}

    public ActionReceived(NotificationContentModel contentModel, Intent originalIntent){
        super(contentModel, originalIntent);

        this.shouldAutoDismiss = this.autoDismissible;
    }

    public void registerUserActionEvent(NotificationLifeCycle lifeCycle){
        CalendarUtils calendarUtils = CalendarUtils.getInstance();
        try {
            this.actionLifeCycle = lifeCycle;
            this.actionDate =
                calendarUtils.getCurrentCalendar(
                        calendarUtils.getUtcTimeZone());
        } catch (AwesomeNotificationsException e) {
            e.printStackTrace();
        }
    }

    public void registerDismissedEvent(NotificationLifeCycle lifeCycle){
        CalendarUtils calendarUtils = CalendarUtils.getInstance();
        try {
            this.dismissedLifeCycle = lifeCycle;
            this.dismissedDate =
                    calendarUtils.getCurrentCalendar(
                            calendarUtils.getUtcTimeZone());
        } catch (AwesomeNotificationsException e) {
            e.printStackTrace();
        }
    }

    @Override
    public Map<String, Object> toMap(){
        Map<String, Object> dataMap = super.toMap();

        putDataOnSerializedMap(Definitions.NOTIFICATION_ACTION_LIFECYCLE, dataMap, actionLifeCycle);
        putDataOnSerializedMap(Definitions.NOTIFICATION_DISMISSED_LIFECYCLE, dataMap, dismissedLifeCycle);
        putDataOnSerializedMap(Definitions.NOTIFICATION_BUTTON_KEY_PRESSED, dataMap, buttonKeyPressed);
        putDataOnSerializedMap(Definitions.NOTIFICATION_BUTTON_KEY_INPUT, dataMap, buttonKeyInput);
        putDataOnSerializedMap(Definitions.NOTIFICATION_ACTION_DATE, dataMap, actionDate);
        putDataOnSerializedMap(Definitions.NOTIFICATION_DISMISSED_DATE, dataMap, dismissedDate);

        return dataMap;
    }

    @Override
    public ActionReceived fromMap(Map<String, Object> arguments) {
        super.fromMap(arguments);

        buttonKeyPressed   = getValueOrDefault(arguments, Definitions.NOTIFICATION_BUTTON_KEY_PRESSED, String.class, null);
        buttonKeyInput     = getValueOrDefault(arguments, Definitions.NOTIFICATION_BUTTON_KEY_INPUT, String.class, null);
        actionDate         = getValueOrDefault(arguments, Definitions.NOTIFICATION_ACTION_DATE, Calendar.class, null);
        dismissedDate      = getValueOrDefault(arguments, Definitions.NOTIFICATION_DISMISSED_DATE, Calendar.class, null);
        actionLifeCycle    = getValueOrDefault(arguments, Definitions.NOTIFICATION_ACTION_LIFECYCLE, NotificationLifeCycle.class, null);
        dismissedLifeCycle = getValueOrDefault(arguments, Definitions.NOTIFICATION_DISMISSED_LIFECYCLE, NotificationLifeCycle.class, null);

        return this;
    }

    @Override
    public String toJson() {
        return templateToJson();
    }

    @Override
    public ActionReceived fromJson(String json){
        return (ActionReceived) super.templateFromJson(json);
    }
}
