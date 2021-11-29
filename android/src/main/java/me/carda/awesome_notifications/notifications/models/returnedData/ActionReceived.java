package me.carda.awesome_notifications.notifications.models.returnedData;

import java.util.Map;

import me.carda.awesome_notifications.Definitions;
import me.carda.awesome_notifications.notifications.enumerators.ActionButtonType;
import me.carda.awesome_notifications.notifications.enumerators.NotificationLifeCycle;
import me.carda.awesome_notifications.notifications.models.NotificationContentModel;
import me.carda.awesome_notifications.utils.MapUtils;

public class ActionReceived extends NotificationReceived {

    public String buttonKeyPressed;
    public String buttonKeyInput;

    public ActionButtonType actionButtonType;

    // The value autoDismiss must return as original. Because
    // of that, this variable is being used as temporary
    public boolean shouldAutoDismiss = true;

    public NotificationLifeCycle actionLifeCycle;
    public NotificationLifeCycle dismissedLifeCycle;
    public String actionDate;
    public String dismissedDate;

    public ActionReceived(){}

    public ActionReceived(NotificationContentModel contentModel){

        this.id = contentModel.id;
        this.channelKey = contentModel.channelKey;
        this.title = contentModel.title;
        this.body = contentModel.body;
        this.summary = contentModel.summary;
        this.showWhen = contentModel.showWhen;
        this.payload = contentModel.payload;
        this.largeIcon = contentModel.largeIcon;
        this.bigPicture = contentModel.bigPicture;
        this.hideLargeIconOnExpand = contentModel.hideLargeIconOnExpand;
        this.autoDismissible = contentModel.autoDismissible;
        this.color = contentModel.color;
        this.backgroundColor = contentModel.backgroundColor;
        this.progress = contentModel.progress;
        this.ticker = contentModel.ticker;
        this.locked = contentModel.locked;

        this.fullScreenIntent = contentModel.fullScreenIntent;
        this.wakeUpScreen = contentModel.wakeUpScreen;
        this.category = contentModel.category;

        this.notificationLayout = contentModel.notificationLayout;

        this.displayOnBackground = contentModel.displayOnBackground;
        this.displayOnForeground = contentModel.displayOnForeground;

        this.displayedLifeCycle = contentModel.displayedLifeCycle;
        this.displayedDate = contentModel.displayedDate;

        this.createdSource = contentModel.createdSource;
        this.createdLifeCycle = contentModel.createdLifeCycle;
        this.createdDate = contentModel.createdDate;

        this.shouldAutoDismiss = this.autoDismissible;
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
        returnedObject.put(Definitions.NOTIFICATION_ACTION_DATE, this.actionDate);
        returnedObject.put(Definitions.NOTIFICATION_DISMISSED_DATE, this.dismissedDate);

        return returnedObject;
    }

    @Override
    public ActionReceived fromMap(Map<String, Object> arguments) {
        super.fromMap(arguments);

        buttonKeyPressed = MapUtils.extractValue(arguments, Definitions.NOTIFICATION_BUTTON_KEY_PRESSED, String.class).orNull();
        buttonKeyInput = MapUtils.extractValue(arguments, Definitions.NOTIFICATION_BUTTON_KEY_INPUT, String.class).orNull();
        actionDate    = MapUtils.extractValue(arguments, Definitions.NOTIFICATION_ACTION_DATE, String.class).orNull();
        dismissedDate = MapUtils.extractValue(arguments, Definitions.NOTIFICATION_DISMISSED_DATE, String.class).orNull();

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
