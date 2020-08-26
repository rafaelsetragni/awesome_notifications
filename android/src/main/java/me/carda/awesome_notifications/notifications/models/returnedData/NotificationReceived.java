package me.carda.awesome_notifications.notifications.models.returnedData;

import java.util.Map;

import me.carda.awesome_notifications.notifications.models.NotificationContentModel;

// Just created because of Json process
public class NotificationReceived extends NotificationContentModel {

    public NotificationReceived(NotificationContentModel contentModel){
        /*
        if(contentModel == null)
            throw new PushNotificationException("Notification Received was lost");
        */
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
    }

    public static NotificationReceived fromMap(Map<String, Object> arguments) {
        NotificationContentModel contentModel = NotificationContentModel.fromMap(arguments);
        return new NotificationReceived(contentModel);
    }
}
