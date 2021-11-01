package me.carda.awesome_notifications.notifications.models.returnedData;

import java.util.HashMap;
import java.util.Map;

import me.carda.awesome_notifications.AwesomeNotificationsPlugin;
import me.carda.awesome_notifications.Definitions;
import me.carda.awesome_notifications.notifications.models.Model;
import me.carda.awesome_notifications.notifications.models.NotificationContentModel;
import me.carda.awesome_notifications.notifications.models.NotificationModel;

// Just created because of Json process
public class NotificationReceived extends NotificationContentModel {

    public NotificationReceived(){}

    public NotificationReceived(NotificationContentModel contentModel){
        /*
        if(contentModel == null)
            throw new NotificationModelException("Notification Received was lost");
        */
        this.id = contentModel.id;
        this.channelKey = contentModel.channelKey;
        this.groupKey = contentModel.groupKey;
        this.title = contentModel.title;
        this.body = contentModel.body;
        this.summary = contentModel.summary;
        this.showWhen = contentModel.showWhen;
        this.payload = contentModel.payload;
        this.largeIcon = contentModel.largeIcon;
        this.bigPicture = contentModel.bigPicture;
        this.hideLargeIconOnExpand = contentModel.hideLargeIconOnExpand;
        this.autoDismissable = contentModel.autoDismissable;
        this.color = contentModel.color;
        this.backgroundColor = contentModel.backgroundColor;
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

    @Override
    public NotificationReceived fromMap(Map<String, Object> parameters){
        return (NotificationReceived) super.fromMap(parameters);
    }

    @Override
    public Map<String, Object> toMap(){
        return super.toMap();
    }

    @Override
    public String toJson() {
        return templateToJson();
    }

    @Override
    public NotificationReceived fromJson(String json){
        return (NotificationReceived) super.templateFromJson(json);
    }
}
