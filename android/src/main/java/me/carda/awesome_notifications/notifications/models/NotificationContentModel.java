package me.carda.awesome_notifications.notifications.models;

import android.content.Context;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;
import java.util.List;

import me.carda.awesome_notifications.Definitions;
import me.carda.awesome_notifications.AwesomeNotificationsPlugin;
import me.carda.awesome_notifications.notifications.enumerators.MediaSource;
import me.carda.awesome_notifications.notifications.enumerators.NotificationCategory;
import me.carda.awesome_notifications.notifications.enumerators.NotificationLayout;
import me.carda.awesome_notifications.notifications.enumerators.NotificationLifeCycle;
import me.carda.awesome_notifications.notifications.enumerators.NotificationPrivacy;
import me.carda.awesome_notifications.notifications.enumerators.NotificationSource;
import me.carda.awesome_notifications.notifications.exceptions.AwesomeNotificationException;
import me.carda.awesome_notifications.notifications.managers.ChannelManager;
import me.carda.awesome_notifications.utils.BitmapUtils;
import me.carda.awesome_notifications.utils.DateUtils;
import me.carda.awesome_notifications.utils.IntegerUtils;
import me.carda.awesome_notifications.utils.ListUtils;
import me.carda.awesome_notifications.utils.MapUtils;
import me.carda.awesome_notifications.utils.StringUtils;

@SuppressWarnings("unchecked")
public class NotificationContentModel extends AbstractModel {

    public boolean isRefreshNotification = false;
    public boolean isRandomId = false;

    public Integer id;
    public String channelKey;
    public String title;
    public String body;
    public String summary;
    public Boolean showWhen;
    public List<NotificationMessageModel> messages;
    public Map<String, String> payload;
    public String groupKey;
    public String customSound;
    public Boolean playSound;
    public String icon;
    public String largeIcon;
    public Boolean locked;
    public String bigPicture;
    public Boolean wakeUpScreen;
    public Boolean fullScreenIntent;
    public Boolean hideLargeIconOnExpand;
    public Boolean autoDismissible;
    public Boolean displayOnForeground;
    public Boolean displayOnBackground;
    public Long color;
    public Long backgroundColor;
    public Integer progress;
    public String ticker;

    public NotificationPrivacy privacy;
    public String privateMessage;

    public NotificationLayout notificationLayout;

    public NotificationCategory notificationCategory;

    public NotificationSource createdSource;
    public NotificationLifeCycle createdLifeCycle;
    public NotificationLifeCycle displayedLifeCycle;
    public NotificationCategory category;

    public String createdDate;
    public String displayedDate;

    public Boolean roundedLargeIcon;
    public Boolean roundedBigPicture;

    public NotificationContentModel(){}

    @Override
    public NotificationContentModel fromMap(Map<String, Object> arguments) {

        id = getValueOrDefault(arguments, Definitions.NOTIFICATION_ID, Integer.class);
        if(id < 0) {
            id = IntegerUtils.generateNextRandomId();
        }

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


        title = getValueOrDefault(arguments, Definitions.NOTIFICATION_TITLE, String.class);
        body  = getValueOrDefault(arguments, Definitions.NOTIFICATION_BODY, String.class);
        summary = getValueOrDefault(arguments, Definitions.NOTIFICATION_SUMMARY, String.class);

        playSound = getValueOrDefault(arguments, Definitions.NOTIFICATION_PLAY_SOUND, Boolean.class);
        customSound = getValueOrDefault(arguments, Definitions.NOTIFICATION_CUSTOM_SOUND, String.class);

        wakeUpScreen = getValueOrDefault(arguments, Definitions.NOTIFICATION_WAKE_UP_SCREEN, Boolean.class);
        fullScreenIntent = getValueOrDefault(arguments, Definitions.NOTIFICATION_FULL_SCREEN_INTENT, Boolean.class);

        showWhen = getValueOrDefault(arguments, Definitions.NOTIFICATION_SHOW_WHEN, Boolean.class);
        locked = getValueOrDefault(arguments, Definitions.NOTIFICATION_LOCKED, Boolean.class);

        displayOnForeground = getValueOrDefault(arguments, Definitions.NOTIFICATION_DISPLAY_ON_FOREGROUND, Boolean.class);
        displayOnBackground = getValueOrDefault(arguments, Definitions.NOTIFICATION_DISPLAY_ON_BACKGROUND, Boolean.class);

        hideLargeIconOnExpand = getValueOrDefault(arguments, Definitions.NOTIFICATION_HIDE_LARGE_ICON_ON_EXPAND, Boolean.class);

        notificationLayout =
                getEnumValueOrDefault(arguments, Definitions.NOTIFICATION_LAYOUT, NotificationLayout.class, NotificationLayout.values());

        privacy =
                getEnumValueOrDefault(arguments, Definitions.NOTIFICATION_PRIVACY, NotificationPrivacy.class, NotificationPrivacy.values());

        category =
                getEnumValueOrDefault(arguments, Definitions.NOTIFICATION_CATEGORY, NotificationCategory.class, NotificationCategory.values());

        privateMessage = getValueOrDefault(arguments, Definitions.NOTIFICATION_PRIVATE_MESSAGE, String.class);

        icon  = getValueOrDefault(arguments, Definitions.NOTIFICATION_ICON, String.class);
        largeIcon  = getValueOrDefault(arguments, Definitions.NOTIFICATION_LARGE_ICON, String.class);
        bigPicture = getValueOrDefault(arguments, Definitions.NOTIFICATION_BIG_PICTURE, String.class);

        payload = getValueOrDefault(arguments, Definitions.NOTIFICATION_PAYLOAD, Map.class);

        autoDismissible = getValueOrDefault(arguments, Definitions.NOTIFICATION_AUTO_DISMISSIBLE, Boolean.class);

        progress    = getValueOrDefault(arguments, Definitions.NOTIFICATION_PROGRESS, Integer.class);

        groupKey = getValueOrDefault(arguments, Definitions.NOTIFICATION_GROUP_KEY, String.class);

        ticker = getValueOrDefault(arguments, Definitions.NOTIFICATION_TICKER, String.class);

        messages = mapToMessages(getValueOrDefault(arguments, Definitions.NOTIFICATION_MESSAGES, List.class));

        roundedLargeIcon = getValueOrDefault(arguments, Definitions.NOTIFICATION_ROUNDED_LARGE_ICON, Boolean.class);
        roundedBigPicture = getValueOrDefault(arguments, Definitions.NOTIFICATION_ROUNDED_BIG_PICTURE, Boolean.class);

        return this;
    }

    @Override
    public Map<String, Object> toMap(){
        Map<String, Object> returnedObject = new HashMap<>();

        returnedObject.put(Definitions.NOTIFICATION_ID, this.id);
        returnedObject.put(Definitions.NOTIFICATION_RANDOM_ID, this.isRandomId);
        returnedObject.put(Definitions.NOTIFICATION_TITLE, this.title);
        returnedObject.put(Definitions.NOTIFICATION_BODY, this.body);
        returnedObject.put(Definitions.NOTIFICATION_SUMMARY, this.summary);

        returnedObject.put(Definitions.NOTIFICATION_SHOW_WHEN, this.showWhen);
        returnedObject.put(Definitions.NOTIFICATION_WAKE_UP_SCREEN, this.wakeUpScreen);
        returnedObject.put(Definitions.NOTIFICATION_FULL_SCREEN_INTENT, this.fullScreenIntent);


        returnedObject.put(Definitions.NOTIFICATION_LOCKED, this.locked);

        returnedObject.put(Definitions.NOTIFICATION_PLAY_SOUND, this.playSound);
        returnedObject.put(Definitions.NOTIFICATION_CUSTOM_SOUND, this.customSound);

        returnedObject.put(Definitions.NOTIFICATION_TICKER, this.ticker);
        returnedObject.put(Definitions.NOTIFICATION_PAYLOAD, this.payload);
        returnedObject.put(Definitions.NOTIFICATION_AUTO_DISMISSIBLE, this.autoDismissible);

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

        returnedObject.put(Definitions.NOTIFICATION_CHANNEL_KEY, this.channelKey);

        returnedObject.put(Definitions.NOTIFICATION_ROUNDED_LARGE_ICON, this.roundedLargeIcon);
        returnedObject.put(Definitions.NOTIFICATION_ROUNDED_BIG_PICTURE, this.roundedBigPicture);

        if(this.category != null)
            returnedObject.put(Definitions.NOTIFICATION_CATEGORY,
                    this.category.toString());

        if(this.autoDismissible != null)
            returnedObject.put(Definitions.NOTIFICATION_AUTO_DISMISSIBLE, this.autoDismissible);

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

        if(this.groupKey != null)
            returnedObject.put(Definitions.NOTIFICATION_GROUP_KEY, this.groupKey);

        if(this.privacy != null)
            returnedObject.put(Definitions.NOTIFICATION_PRIVACY,
                    this.privacy.toString());

        if(this.privateMessage != null)
            returnedObject.put(Definitions.NOTIFICATION_PRIVATE_MESSAGE, this.privateMessage);

        if(this.messages != null)
            returnedObject.put(Definitions.NOTIFICATION_MESSAGES, messagesToMap(this.messages));

        return returnedObject;
    }

    public static List<Map> messagesToMap(List<NotificationMessageModel> messages){
        List<Map> returnedMessages = new ArrayList<>();
        if(!ListUtils.isNullOrEmpty(messages)){
            for (NotificationMessageModel messageModel : messages) {
                returnedMessages.add(messageModel.toMap());
            }
        }
        return returnedMessages;
    }

    public static List<NotificationMessageModel> mapToMessages(List<Map> messagesData){
        List<NotificationMessageModel> messages = new ArrayList<>();
        if(!ListUtils.isNullOrEmpty(messagesData))
            for(Map<String, Object> messageData : messagesData){
                NotificationMessageModel messageModel =
                        new NotificationMessageModel().fromMap(messageData);
                messages.add(messageModel);
            }
        return messages;
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
    public void validate(Context context) throws AwesomeNotificationException {

        if(ChannelManager.getChannelByKey(context, channelKey) == null)
            throw new AwesomeNotificationException("Notification channel '"+channelKey+"' does not exist.");

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

    private void validateIcon(Context context) throws AwesomeNotificationException {

        if(!StringUtils.isNullOrEmpty(icon)){
            if(
                BitmapUtils.getMediaSourceType(icon) != MediaSource.Resource ||
                !BitmapUtils.isValidBitmap(context, icon)
            ){
                throw new AwesomeNotificationException("Small icon ('"+icon+"') must be a valid media native resource type.");
            }
        }
    }

    private void validateBigPicture(Context context) throws AwesomeNotificationException {
        if(
            (StringUtils.isNullOrEmpty(largeIcon) && StringUtils.isNullOrEmpty(bigPicture)) ||
            (!StringUtils.isNullOrEmpty(largeIcon) && !BitmapUtils.isValidBitmap(context, largeIcon)) ||
            (!StringUtils.isNullOrEmpty(bigPicture) && !BitmapUtils.isValidBitmap(context, bigPicture))
        ){
            throw new AwesomeNotificationException("Invalid big picture '"+bigPicture+"' or large icon '"+largeIcon+"'");
        }
    }

    private void validateLargeIcon(Context context) throws AwesomeNotificationException {
        if(
                (!StringUtils.isNullOrEmpty(largeIcon) && !BitmapUtils.isValidBitmap(context, largeIcon))
        )
            throw new AwesomeNotificationException("Invalid large icon '"+largeIcon+"'");
    }
}
