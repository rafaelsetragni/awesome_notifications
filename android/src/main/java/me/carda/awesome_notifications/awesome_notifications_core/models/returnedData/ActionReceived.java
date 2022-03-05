package me.carda.awesome_notifications.awesome_notifications_core.models.returnedData;

import java.util.Calendar;
import java.util.Map;

import me.carda.awesome_notifications.awesome_notifications_core.Definitions;
import me.carda.awesome_notifications.awesome_notifications_core.enumerators.NotificationLifeCycle;
import me.carda.awesome_notifications.awesome_notifications_core.exceptions.AwesomeNotificationsException;
import me.carda.awesome_notifications.awesome_notifications_core.models.NotificationContentModel;
import me.carda.awesome_notifications.awesome_notifications_core.utils.CalendarUtils;
import me.carda.awesome_notifications.awesome_notifications_core.utils.MapUtils;

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

    public ActionReceived(NotificationContentModel contentModel){
        super(contentModel);

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
        Map<String, Object> returnedObject = super.toMap();

        returnedObject.put(Definitions.NOTIFICATION_ACTION_LIFECYCLE,
                this.actionLifeCycle != null ? this.actionLifeCycle.toString() : null);

        returnedObject.put(Definitions.NOTIFICATION_DISMISSED_LIFECYCLE,
                this.dismissedLifeCycle != null ? this.dismissedLifeCycle.toString() : null);

        returnedObject.put(Definitions.NOTIFICATION_BUTTON_KEY_PRESSED, this.buttonKeyPressed);
        returnedObject.put(Definitions.NOTIFICATION_BUTTON_KEY_INPUT, this.buttonKeyInput);
        returnedObject.put(Definitions.NOTIFICATION_ACTION_DATE,  CalendarUtils.getInstance().calendarToString(this.actionDate));
        returnedObject.put(Definitions.NOTIFICATION_DISMISSED_DATE, CalendarUtils.getInstance().calendarToString(this.dismissedDate));

        return returnedObject;
    }

    @Override
    public ActionReceived fromMap(Map<String, Object> arguments) {
        super.fromMap(arguments);

        buttonKeyPressed = MapUtils.extractValue(arguments, Definitions.NOTIFICATION_BUTTON_KEY_PRESSED, String.class).orNull();
        buttonKeyInput = MapUtils.extractValue(arguments, Definitions.NOTIFICATION_BUTTON_KEY_INPUT, String.class).orNull();
        actionDate    = MapUtils.extractValue(arguments, Definitions.NOTIFICATION_ACTION_DATE, Calendar.class).orNull();
        dismissedDate = MapUtils.extractValue(arguments, Definitions.NOTIFICATION_DISMISSED_DATE, Calendar.class).orNull();

        actionLifeCycle = getEnumValueOrDefault(arguments, Definitions.NOTIFICATION_ACTION_LIFECYCLE,
                NotificationLifeCycle.class, NotificationLifeCycle.values());
        dismissedLifeCycle = getEnumValueOrDefault(arguments, Definitions.NOTIFICATION_DISMISSED_LIFECYCLE,
                NotificationLifeCycle.class, NotificationLifeCycle.values());

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
