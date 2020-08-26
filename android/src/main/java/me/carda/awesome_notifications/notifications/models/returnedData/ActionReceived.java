package me.carda.awesome_notifications.notifications.models.returnedData;

import java.util.Map;

import me.carda.awesome_notifications.Definitions;
import me.carda.awesome_notifications.notifications.enumeratos.NotificationLifeCycle;
import me.carda.awesome_notifications.notifications.models.NotificationContentModel;
import me.carda.awesome_notifications.utils.DateUtils;

public class ActionReceived extends NotificationContentModel {

    public String actionKey;
    public String buttonInput;

    public NotificationLifeCycle actionLifeCycle;
    public String actionDate;

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

        this.displayedLifeCycle = contentModel.displayedLifeCycle;
        this.displayedDate = contentModel.displayedDate;

        this.createdSource = contentModel.createdSource;
        this.createdLifeCycle = contentModel.createdLifeCycle;
        this.createdDate = contentModel.createdDate;

        this.actionDate = DateUtils.getUTCDate();
    }

    public static ActionReceived fromMap(Map<String, Object> arguments) {
        NotificationContentModel contentModel = NotificationContentModel.fromMap(arguments);
        return new ActionReceived(contentModel);
    }

    @Override
    public Map<String, Object> toMap(){
        Map<String, Object> returnedObject = super.toMap();

        returnedObject.put(Definitions.NOTIFICATION_ACTION_LIFECYCLE,
                this.actionLifeCycle != null ? this.actionLifeCycle.toString() : null);

        returnedObject.put(Definitions.NOTIFICATION_ACTION_KEY, this.actionKey);
        returnedObject.put(Definitions.NOTIFICATION_ACTION_INPUT, this.buttonInput);
        returnedObject.put(Definitions.NOTIFICATION_ACTION_DATE, this.actionDate);

        return returnedObject;
    }

}
