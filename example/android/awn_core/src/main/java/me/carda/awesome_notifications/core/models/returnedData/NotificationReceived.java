package me.carda.awesome_notifications.core.models.returnedData;

import android.content.Intent;

import java.util.Map;

import me.carda.awesome_notifications.core.models.NotificationContentModel;

// Just created because of Json process
public class NotificationReceived extends NotificationContentModel {

    public Intent originalIntent;

    public NotificationReceived(){}

    public NotificationReceived(NotificationContentModel contentModel, Intent originalIntent){

        this.originalIntent = originalIntent;

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
