package me.carda.awesome_notifications.notifications.models.returnedData;

import java.util.List;
import java.util.Map;

import me.carda.awesome_notifications.Definitions;
import me.carda.awesome_notifications.notifications.enumeratos.NotificationLayout;
import me.carda.awesome_notifications.notifications.enumeratos.NotificationLifeCycle;
import me.carda.awesome_notifications.notifications.enumeratos.NotificationPrivacy;
import me.carda.awesome_notifications.notifications.enumeratos.NotificationSource;
import me.carda.awesome_notifications.notifications.models.Model;
import me.carda.awesome_notifications.notifications.models.NotificationContentModel;
import me.carda.awesome_notifications.notifications.models.PushNotification;
import me.carda.awesome_notifications.utils.DateUtils;
import me.carda.awesome_notifications.utils.MapUtils;

public class ActionReceived extends NotificationContentModel {

    public String actionKey;
    public String actionInput;

    public NotificationLifeCycle actionLifeCycle;
    public NotificationLifeCycle dismissedLifeCycle;
    public String actionDate;
    public String dismissedDate;
    public String mediaAction;

    public ActionReceived(){}

    public ActionReceived(NotificationContentModel contentModel){

        this.id = contentModel.id;
        this.channelKey = contentModel.channelKey;
        this.title = contentModel.title;
        this.body = contentModel.body;
        this.summary = contentModel.summary;
        this.showWhen = contentModel.showWhen;
        this.actionButtons = contentModel.actionButtons;
        this.payload = contentModel.payload;
        this.largeIcon = contentModel.largeIcon;
        this.bigPicture = contentModel.bigPicture;
        this.hideLargeIconOnExpand = contentModel.hideLargeIconOnExpand;
        this.autoCancel = contentModel.autoCancel;
        this.color = contentModel.color;
        this.progress = contentModel.progress;
        this.ticker = contentModel.ticker;
        this.locked = contentModel.locked;

        this.notificationLayout = contentModel.notificationLayout;

        this.displayOnBackground = contentModel.displayOnBackground;
        this.displayOnForeground = contentModel.displayOnForeground;

        this.displayedLifeCycle = contentModel.displayedLifeCycle;
        this.displayedDate = contentModel.displayedDate;

        this.createdSource = contentModel.createdSource;
        this.createdLifeCycle = contentModel.createdLifeCycle;
        this.createdDate = contentModel.createdDate;
    }

    @Override
    public Map<String, Object> toMap(){
        Map<String, Object> returnedObject = super.toMap();

        returnedObject.put(Definitions.NOTIFICATION_ACTION_LIFECYCLE,
                this.actionLifeCycle != null ? this.actionLifeCycle.toString() : null);

        returnedObject.put(Definitions.NOTIFICATION_DISMISSED_LIFECYCLE,
                this.dismissedLifeCycle != null ? this.dismissedLifeCycle.toString() : null);

        returnedObject.put(Definitions.NOTIFICATION_ACTION_KEY, this.actionKey);
        returnedObject.put(Definitions.NOTIFICATION_ACTION_INPUT, this.actionInput);
        returnedObject.put(Definitions.NOTIFICATION_ACTION_DATE, this.actionDate);
        returnedObject.put(Definitions.NOTIFICATION_DISMISSED_DATE, this.dismissedDate);
        returnedObject.put(Definitions.NOTIFICATION_MEDIA_ACTION, this.mediaAction);

        return returnedObject;
    }

    @Override
    public ActionReceived fromMap(Map<String, Object> arguments) {
        super.fromMap(arguments);

        actionKey     = MapUtils.extractValue(arguments, Definitions.NOTIFICATION_ACTION_KEY, String.class).orNull();
        actionInput   = MapUtils.extractValue(arguments, Definitions.NOTIFICATION_ACTION_INPUT, String.class).orNull();
        actionDate    = MapUtils.extractValue(arguments, Definitions.NOTIFICATION_ACTION_DATE, String.class).orNull();
        dismissedDate = MapUtils.extractValue(arguments, Definitions.NOTIFICATION_DISMISSED_DATE, String.class).orNull();
        mediaAction   = MapUtils.extractValue(arguments, Definitions.NOTIFICATION_MEDIA_ACTION, String.class).orNull();

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
