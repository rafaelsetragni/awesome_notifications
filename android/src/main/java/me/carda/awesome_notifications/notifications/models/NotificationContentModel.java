package me.carda.awesome_notifications.notifications.models;

import android.content.Context;

import java.util.HashMap;
import java.util.Map;
import java.util.List;

import me.carda.awesome_notifications.Definitions;
import me.carda.awesome_notifications.AwesomeNotificationsPlugin;
import me.carda.awesome_notifications.notifications.enumeratos.MediaSource;
import me.carda.awesome_notifications.notifications.enumeratos.NotificationLayout;
import me.carda.awesome_notifications.notifications.enumeratos.NotificationLifeCycle;
import me.carda.awesome_notifications.notifications.enumeratos.NotificationPrivacy;
import me.carda.awesome_notifications.notifications.enumeratos.NotificationSource;
import me.carda.awesome_notifications.notifications.exceptions.PushNotificationException;
import me.carda.awesome_notifications.notifications.managers.ChannelManager;
import me.carda.awesome_notifications.utils.AudioUtils;
import me.carda.awesome_notifications.utils.BitmapUtils;
import me.carda.awesome_notifications.utils.BooleanUtils;
import me.carda.awesome_notifications.utils.DateUtils;
import me.carda.awesome_notifications.utils.MapUtils;
import me.carda.awesome_notifications.utils.StringUtils;

@SuppressWarnings("unchecked")
public class NotificationContentModel extends Model {

    public Integer id;
    public String channelKey;
    public String title;
    public String body;
    public String summary;
    public Boolean showWhen;
    public List<Object> actionButtons;
    public Map<String, String> payload;
    public Boolean playSound;
    public String icon;
    public String largeIcon;
    public Boolean locked;
    public String bigPicture;
    public Boolean hideLargeIconOnExpand;
    public Boolean autoCancel;
    public Boolean displayOnForeground;
    public Boolean displayOnBackground;
    public Long color;
    public Long backgroundColor;
    public Integer progress;
    public String ticker;

    public NotificationPrivacy privacy;
    public String privateMessage;

    public NotificationLayout notificationLayout;

    public NotificationSource createdSource;
    public NotificationLifeCycle createdLifeCycle;
    public NotificationLifeCycle displayedLifeCycle;
    public String createdDate;
    public String displayedDate;

    public NotificationContentModel(){}

    @Override
    public NotificationContentModel fromMap(Map<String, Object> arguments) {

        createdDate = MapUtils.extractValue(arguments, Definitions.NOTIFICATION_CREATED_DATE, String.class)
                            .or(DateUtils.getUTCDate());

        displayedDate = MapUtils.extractValue(arguments, Definitions.NOTIFICATION_DISPLAYED_DATE, String.class)
                            .orNull();

        createdLifeCycle = getEnumValueOrDefault(arguments, Definitions.NOTIFICATION_CREATED_LIFECYCLE,
                NotificationLifeCycle.class, NotificationLifeCycle.values());

        displayedLifeCycle = getEnumValueOrDefault(arguments, Definitions.NOTIFICATION_DISPLAYED_LIFECYCLE,
                NotificationLifeCycle.class, NotificationLifeCycle.values());

        createdSource = getEnumValueOrDefault(arguments, Definitions.NOTIFICATION_CREATED_SOURCE,
                NotificationSource.class, NotificationSource.values());

        channelKey = getValueOrDefault(arguments, Definitions.NOTIFICATION_CHANNEL_KEY, String.class);
        color = getValueOrDefault(arguments, Definitions.NOTIFICATION_COLOR, Long.class);
        backgroundColor = getValueOrDefault(arguments, Definitions.NOTIFICATION_BACKGROUND_COLOR, Long.class);

        id    = getValueOrDefault(arguments, Definitions.NOTIFICATION_ID, Integer.class);
        title = getValueOrDefault(arguments, Definitions.NOTIFICATION_TITLE, String.class);
        body  = getValueOrDefault(arguments, Definitions.NOTIFICATION_BODY, String.class);
        summary = getValueOrDefault(arguments, Definitions.NOTIFICATION_SUMMARY, String.class);

        playSound = getValueOrDefault(arguments, Definitions.NOTIFICATION_PLAY_SOUND, Boolean.class);

        showWhen = getValueOrDefault(arguments, Definitions.NOTIFICATION_SHOW_WHEN, Boolean.class);
        locked = getValueOrDefault(arguments, Definitions.NOTIFICATION_LOCKED, Boolean.class);

        displayOnForeground = getValueOrDefault(arguments, Definitions.NOTIFICATION_DISPLAY_ON_FOREGROUND, Boolean.class);
        displayOnBackground = getValueOrDefault(arguments, Definitions.NOTIFICATION_DISPLAY_ON_BACKGROUND, Boolean.class);

        hideLargeIconOnExpand = getValueOrDefault(arguments, Definitions.NOTIFICATION_HIDE_LARGE_ICON_ON_EXPAND, Boolean.class);

        notificationLayout =
                getEnumValueOrDefault(arguments, Definitions.NOTIFICATION_LAYOUT, NotificationLayout.class, NotificationLayout.values());

        privacy =
                getEnumValueOrDefault(arguments, Definitions.NOTIFICATION_PRIVACY, NotificationPrivacy.class, NotificationPrivacy.values());

        privateMessage = getValueOrDefault(arguments, Definitions.NOTIFICATION_PRIVATE_MESSAGE, String.class);

        icon  = getValueOrDefault(arguments, Definitions.NOTIFICATION_ICON, String.class);
        largeIcon  = getValueOrDefault(arguments, Definitions.NOTIFICATION_LARGE_ICON, String.class);
        bigPicture = getValueOrDefault(arguments, Definitions.NOTIFICATION_BIG_PICTURE, String.class);

        actionButtons = getValueOrDefault(arguments, Definitions.NOTIFICATION_ACTION_BUTTONS, List.class);

        payload = getValueOrDefault(arguments, Definitions.NOTIFICATION_PAYLOAD, Map.class);

        autoCancel = getValueOrDefault(arguments, Definitions.NOTIFICATION_AUTO_CANCEL, Boolean.class);

        progress    = getValueOrDefault(arguments, Definitions.NOTIFICATION_PROGRESS, Integer.class);

        ticker = getValueOrDefault(arguments, Definitions.NOTIFICATION_TICKER, String.class);

        return this;
    }

    @Override
    public Map<String, Object> toMap(){
        Map<String, Object> returnedObject = new HashMap<>();

        returnedObject.put(Definitions.NOTIFICATION_ID, this.id);
        returnedObject.put(Definitions.NOTIFICATION_TITLE, this.title);
        returnedObject.put(Definitions.NOTIFICATION_BODY, this.body);
        returnedObject.put(Definitions.NOTIFICATION_SUMMARY, this.summary);

        returnedObject.put(Definitions.NOTIFICATION_SHOW_WHEN, this.showWhen);

        returnedObject.put(Definitions.NOTIFICATION_LOCKED, this.locked);

        returnedObject.put(Definitions.NOTIFICATION_PLAY_SOUND, this.playSound);

        returnedObject.put(Definitions.NOTIFICATION_TICKER, this.ticker);
        returnedObject.put(Definitions.NOTIFICATION_PAYLOAD, this.payload);
        returnedObject.put(Definitions.NOTIFICATION_AUTO_CANCEL, this.autoCancel);

        returnedObject.put(Definitions.NOTIFICATION_LAYOUT,
                this.notificationLayout != null ? this.notificationLayout.toString() : "Default");

        returnedObject.put(Definitions.NOTIFICATION_CREATED_SOURCE,
                this.createdSource != null ? this.createdSource.toString() : "Local");

        returnedObject.put(Definitions.NOTIFICATION_CREATED_LIFECYCLE,
                this.createdLifeCycle != null ? this.createdLifeCycle.toString() : AwesomeNotificationsPlugin.appLifeCycle.toString());

        returnedObject.put(Definitions.NOTIFICATION_DISPLAYED_LIFECYCLE,
                this.displayedLifeCycle != null ? this.displayedLifeCycle.toString() : null);

        returnedObject.put(Definitions.NOTIFICATION_DISPLAYED_DATE, this.displayedDate);
        returnedObject.put(Definitions.NOTIFICATION_CREATED_DATE, this.createdDate);

        if(this.actionButtons != null)
            returnedObject.put(Definitions.NOTIFICATION_ACTION_BUTTONS, this.actionButtons);

        if(this.autoCancel != null)
            returnedObject.put(Definitions.NOTIFICATION_AUTO_CANCEL, this.autoCancel);

        if(this.displayOnForeground != null)
            returnedObject.put(Definitions.NOTIFICATION_DISPLAY_ON_FOREGROUND, this.displayOnForeground);

        if(this.displayOnBackground != null)
            returnedObject.put(Definitions.NOTIFICATION_DISPLAY_ON_BACKGROUND, this.displayOnBackground);

        if(this.color != null)
            returnedObject.put(Definitions.NOTIFICATION_COLOR, this.color);
        if(this.backgroundColor != null)
            returnedObject.put(Definitions.NOTIFICATION_BACKGROUND_COLOR, this.backgroundColor);

        if(this.icon != null)
            returnedObject.put(Definitions.NOTIFICATION_ICON, this.icon);

        if(this.largeIcon != null)
            returnedObject.put(Definitions.NOTIFICATION_LARGE_ICON, this.largeIcon);

        if(this.bigPicture != null)
            returnedObject.put(Definitions.NOTIFICATION_BIG_PICTURE, this.bigPicture);

        if(this.progress != null)
            returnedObject.put(Definitions.NOTIFICATION_PROGRESS, this.progress);

        if(this.channelKey != null)
            returnedObject.put(Definitions.NOTIFICATION_CHANNEL_KEY, this.channelKey);

        if(this.privacy != null)
            returnedObject.put(Definitions.NOTIFICATION_PRIVACY,
                    this.privacy != null ? this.privacy.toString() : null);

        if(this.privateMessage != null)
            returnedObject.put(Definitions.NOTIFICATION_PRIVATE_MESSAGE, this.privateMessage);

        return returnedObject;
    }

    @Override
    public String toJson() {
        return templateToJson();
    }

    @Override
    public NotificationContentModel fromJson(String json){
        return (NotificationContentModel) super.templateFromJson(json);
    }

    @Override
    public void validate(Context context) throws PushNotificationException {

        if(ChannelManager.getChannelByKey(context, channelKey) == null)
            throw new PushNotificationException("Notification channel '"+channelKey+"' does not exists.");

        validateIcon(context);

        switch (notificationLayout){

            case Default:
                break;

            case BigPicture:
                validateBigPicture(context);
                break;

            case BigText:
                break;

            case Inbox:
                break;

            case Messaging:
                break;
        }

        validateLargeIcon(context);

    }

    private void validateIcon(Context context) throws PushNotificationException {

        if(!StringUtils.isNullOrEmpty(icon)){
            if(
                BitmapUtils.getMediaSourceType(icon) != MediaSource.Resource ||
                !BitmapUtils.isValidBitmap(context, icon)
            ){
                throw new PushNotificationException("Small icon ('"+icon+"') must be a valid media native resource type.");
            }
        }
    }

    private void validateBigPicture(Context context) throws PushNotificationException {
        if(
            (StringUtils.isNullOrEmpty(largeIcon) && StringUtils.isNullOrEmpty(bigPicture)) ||
            (!StringUtils.isNullOrEmpty(largeIcon) && !BitmapUtils.isValidBitmap(context, largeIcon)) ||
            (!StringUtils.isNullOrEmpty(bigPicture) && !BitmapUtils.isValidBitmap(context, bigPicture))
        ){
            throw new PushNotificationException("Invalid big picture '"+bigPicture+"' or large icon '"+largeIcon+"'");
        }
    }

    private void validateLargeIcon(Context context) throws PushNotificationException {
        if(
                (!StringUtils.isNullOrEmpty(largeIcon) && !BitmapUtils.isValidBitmap(context, largeIcon))
        )
            throw new PushNotificationException("Invalid large icon '"+largeIcon+"'");
    }
}
