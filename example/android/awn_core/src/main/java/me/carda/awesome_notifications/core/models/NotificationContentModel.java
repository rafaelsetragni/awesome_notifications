package me.carda.awesome_notifications.core.models;

import android.content.Context;

import java.util.ArrayList;
import java.util.Calendar;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import me.carda.awesome_notifications.core.Definitions;
import me.carda.awesome_notifications.core.enumerators.ActionType;
import me.carda.awesome_notifications.core.enumerators.MediaSource;
import me.carda.awesome_notifications.core.enumerators.NotificationCategory;
import me.carda.awesome_notifications.core.enumerators.NotificationLayout;
import me.carda.awesome_notifications.core.enumerators.NotificationLifeCycle;
import me.carda.awesome_notifications.core.enumerators.NotificationPrivacy;
import me.carda.awesome_notifications.core.enumerators.NotificationSource;
import me.carda.awesome_notifications.core.exceptions.AwesomeNotificationsException;
import me.carda.awesome_notifications.core.exceptions.ExceptionCode;
import me.carda.awesome_notifications.core.exceptions.ExceptionFactory;
import me.carda.awesome_notifications.core.logs.Logger;
import me.carda.awesome_notifications.core.managers.ChannelManager;
import me.carda.awesome_notifications.core.utils.BitmapUtils;
import me.carda.awesome_notifications.core.utils.CalendarUtils;
import me.carda.awesome_notifications.core.utils.ListUtils;

@SuppressWarnings("unchecked")
public class NotificationContentModel extends AbstractModel {

    private static final String TAG = "NotificationContentModel";

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
    public Integer color;
    public Integer backgroundColor;
    public Integer progress;
    public Integer badge;
    public String ticker;

    public Boolean roundedLargeIcon;
    public Boolean roundedBigPicture;

    public ActionType actionType;

    public NotificationPrivacy privacy;
    public String privateMessage;

    public NotificationLayout notificationLayout;

    public NotificationSource createdSource;
    public NotificationLifeCycle createdLifeCycle;
    public Calendar createdDate;

    public NotificationLifeCycle displayedLifeCycle;
    public Calendar displayedDate;

    public NotificationCategory category;

    public boolean registerCreatedEvent(NotificationLifeCycle lifeCycle, NotificationSource createdSource){

        // Creation register can only happen once
        if(this.createdDate == null){

            this.createdDate = CalendarUtils.getInstance().getCurrentCalendar();
            this.createdLifeCycle = lifeCycle;
            this.createdSource = createdSource;

            return true;
        }
        return false;
    }

    public boolean registerDisplayedEvent(NotificationLifeCycle lifeCycle){
        this.displayedDate = CalendarUtils.getInstance().getCurrentCalendar();
        this.displayedLifeCycle = lifeCycle;
        return true;
    }

    @Override
    public NotificationContentModel fromMap(Map<String, Object> arguments) {
        if(arguments == null || arguments.isEmpty())
            return null;

        processRetroCompatibility(arguments);

        id                    = getValueOrDefault(arguments, Definitions.NOTIFICATION_ID, Integer.class, 0);
        actionType            = getValueOrDefault(arguments, Definitions.NOTIFICATION_ACTION_TYPE, ActionType.class, ActionType.Default);
        createdDate           = getValueOrDefault(arguments, Definitions.NOTIFICATION_CREATED_DATE, Calendar.class, null);
        displayedDate         = getValueOrDefault(arguments, Definitions.NOTIFICATION_DISPLAYED_DATE, Calendar.class, null);
        createdLifeCycle      = getValueOrDefault(arguments, Definitions.NOTIFICATION_CREATED_LIFECYCLE, NotificationLifeCycle.class, null);
        displayedLifeCycle    = getValueOrDefault(arguments, Definitions.NOTIFICATION_DISPLAYED_LIFECYCLE, NotificationLifeCycle.class, null);
        createdSource         = getValueOrDefault(arguments, Definitions.NOTIFICATION_CREATED_SOURCE, NotificationSource.class, NotificationSource.Local);
        channelKey            = getValueOrDefault(arguments, Definitions.NOTIFICATION_CHANNEL_KEY, String.class, "miscellaneous");
        color                 = getValueOrDefault(arguments, Definitions.NOTIFICATION_COLOR, Integer.class, null);
        backgroundColor       = getValueOrDefault(arguments, Definitions.NOTIFICATION_BACKGROUND_COLOR, Integer.class, null);
        title                 = getValueOrDefault(arguments, Definitions.NOTIFICATION_TITLE, String.class, null);
        body                  = getValueOrDefault(arguments, Definitions.NOTIFICATION_BODY, String.class, null);
        summary               = getValueOrDefault(arguments, Definitions.NOTIFICATION_SUMMARY, String.class, null);
        playSound             = getValueOrDefault(arguments, Definitions.NOTIFICATION_PLAY_SOUND, Boolean.class, true);
        customSound           = getValueOrDefault(arguments, Definitions.NOTIFICATION_CUSTOM_SOUND, String.class, null);
        wakeUpScreen          = getValueOrDefault(arguments, Definitions.NOTIFICATION_WAKE_UP_SCREEN, Boolean.class, false);
        fullScreenIntent      = getValueOrDefault(arguments, Definitions.NOTIFICATION_FULL_SCREEN_INTENT, Boolean.class, false);
        showWhen              = getValueOrDefault(arguments, Definitions.NOTIFICATION_SHOW_WHEN, Boolean.class, true);
        locked                = getValueOrDefault(arguments, Definitions.NOTIFICATION_LOCKED, Boolean.class, false);
        displayOnForeground   = getValueOrDefault(arguments, Definitions.NOTIFICATION_DISPLAY_ON_FOREGROUND, Boolean.class, true);
        displayOnBackground   = getValueOrDefault(arguments, Definitions.NOTIFICATION_DISPLAY_ON_BACKGROUND, Boolean.class, true);
        hideLargeIconOnExpand = getValueOrDefault(arguments, Definitions.NOTIFICATION_HIDE_LARGE_ICON_ON_EXPAND, Boolean.class, false);
        notificationLayout    = getValueOrDefault(arguments, Definitions.NOTIFICATION_LAYOUT, NotificationLayout.class, NotificationLayout.Default);
        privacy               = getValueOrDefault(arguments, Definitions.NOTIFICATION_PRIVACY, NotificationPrivacy.class, NotificationPrivacy.Private);
        category              = getValueOrDefault(arguments, Definitions.NOTIFICATION_CATEGORY, NotificationCategory.class, null);
        privateMessage        = getValueOrDefault(arguments, Definitions.NOTIFICATION_PRIVATE_MESSAGE, String.class, null);
        icon                  = getValueOrDefault(arguments, Definitions.NOTIFICATION_ICON, String.class, null);
        largeIcon             = getValueOrDefault(arguments, Definitions.NOTIFICATION_LARGE_ICON, String.class, null);
        bigPicture            = getValueOrDefault(arguments, Definitions.NOTIFICATION_BIG_PICTURE, String.class, null);
        payload               = getValueOrDefault(arguments, Definitions.NOTIFICATION_PAYLOAD, Map.class, null);
        autoDismissible       = getValueOrDefault(arguments, Definitions.NOTIFICATION_AUTO_DISMISSIBLE, Boolean.class, true);
        progress              = getValueOrDefault(arguments, Definitions.NOTIFICATION_PROGRESS, Integer.class, null);
        badge                 = getValueOrDefault(arguments, Definitions.NOTIFICATION_BADGE, Integer.class, null);
        groupKey              = getValueOrDefault(arguments, Definitions.NOTIFICATION_GROUP_KEY, String.class, null);
        ticker                = getValueOrDefault(arguments, Definitions.NOTIFICATION_TICKER, String.class, null);
        roundedLargeIcon      = getValueOrDefault(arguments, Definitions.NOTIFICATION_ROUNDED_LARGE_ICON, Boolean.class, false);
        roundedBigPicture     = getValueOrDefault(arguments, Definitions.NOTIFICATION_ROUNDED_BIG_PICTURE, Boolean.class, false);

        messages = mapToMessages(getValueOrDefault(arguments, Definitions.NOTIFICATION_MESSAGES, List.class, null));

        return this;
    }

    // Retro-compatibility with 0.6.X
    public void processRetroCompatibility(Map<String, Object> arguments){

        if (arguments.containsKey("autoCancel")) {
            Logger.i("AwesomeNotifications", "autoCancel is deprecated. Please use autoDismissible instead.");
            autoDismissible   = getValueOrDefault(arguments, "autoCancel", Boolean.class, true);
        }
    }

    @Override
    public Map<String, Object> toMap(){
        Map<String, Object> returnedObject = new HashMap<>();

        putDataOnSerializedMap(Definitions.NOTIFICATION_ID, returnedObject, this.id);
        putDataOnSerializedMap(Definitions.NOTIFICATION_RANDOM_ID, returnedObject, this.isRandomId);
        putDataOnSerializedMap(Definitions.NOTIFICATION_TITLE, returnedObject, this.title);
        putDataOnSerializedMap(Definitions.NOTIFICATION_BODY, returnedObject, this.body);
        putDataOnSerializedMap(Definitions.NOTIFICATION_SUMMARY, returnedObject, this.summary);
        putDataOnSerializedMap(Definitions.NOTIFICATION_SHOW_WHEN, returnedObject, this.showWhen);
        putDataOnSerializedMap(Definitions.NOTIFICATION_WAKE_UP_SCREEN, returnedObject, this.wakeUpScreen);
        putDataOnSerializedMap(Definitions.NOTIFICATION_FULL_SCREEN_INTENT, returnedObject, this.fullScreenIntent);
        putDataOnSerializedMap(Definitions.NOTIFICATION_ACTION_TYPE, returnedObject, this.actionType);
        putDataOnSerializedMap(Definitions.NOTIFICATION_LOCKED, returnedObject, this.locked);
        putDataOnSerializedMap(Definitions.NOTIFICATION_PLAY_SOUND, returnedObject, this.playSound);
        putDataOnSerializedMap(Definitions.NOTIFICATION_CUSTOM_SOUND, returnedObject, this.customSound);
        putDataOnSerializedMap(Definitions.NOTIFICATION_TICKER, returnedObject, this.ticker);
        putDataOnSerializedMap(Definitions.NOTIFICATION_PAYLOAD, returnedObject, this.payload);
        putDataOnSerializedMap(Definitions.NOTIFICATION_AUTO_DISMISSIBLE, returnedObject, this.autoDismissible);
        putDataOnSerializedMap(Definitions.NOTIFICATION_LAYOUT, returnedObject, this.notificationLayout);
        putDataOnSerializedMap(Definitions.NOTIFICATION_CREATED_SOURCE, returnedObject, this.createdSource);
        putDataOnSerializedMap(Definitions.NOTIFICATION_CREATED_LIFECYCLE, returnedObject, this.createdLifeCycle);
        putDataOnSerializedMap(Definitions.NOTIFICATION_DISPLAYED_LIFECYCLE, returnedObject, this.displayedLifeCycle);
        putDataOnSerializedMap(Definitions.NOTIFICATION_DISPLAYED_DATE, returnedObject, this.displayedDate);
        putDataOnSerializedMap(Definitions.NOTIFICATION_CREATED_DATE, returnedObject,this.createdDate);
        putDataOnSerializedMap(Definitions.NOTIFICATION_CHANNEL_KEY, returnedObject, this.channelKey);
        putDataOnSerializedMap(Definitions.NOTIFICATION_CATEGORY, returnedObject, this.category);
        putDataOnSerializedMap(Definitions.NOTIFICATION_AUTO_DISMISSIBLE, returnedObject, this.autoDismissible);
        putDataOnSerializedMap(Definitions.NOTIFICATION_DISPLAY_ON_FOREGROUND, returnedObject, this.displayOnForeground);
        putDataOnSerializedMap(Definitions.NOTIFICATION_DISPLAY_ON_BACKGROUND, returnedObject, this.displayOnBackground);
        putDataOnSerializedMap(Definitions.NOTIFICATION_COLOR, returnedObject, this.color);
        putDataOnSerializedMap(Definitions.NOTIFICATION_BACKGROUND_COLOR, returnedObject, this.backgroundColor);
        putDataOnSerializedMap(Definitions.NOTIFICATION_ICON, returnedObject, this.icon);
        putDataOnSerializedMap(Definitions.NOTIFICATION_LARGE_ICON, returnedObject, this.largeIcon);
        putDataOnSerializedMap(Definitions.NOTIFICATION_BIG_PICTURE, returnedObject, this.bigPicture);
        putDataOnSerializedMap(Definitions.NOTIFICATION_PROGRESS, returnedObject, this.progress);
        putDataOnSerializedMap(Definitions.NOTIFICATION_BADGE, returnedObject, this.badge);
        putDataOnSerializedMap(Definitions.NOTIFICATION_GROUP_KEY, returnedObject, this.groupKey);
        putDataOnSerializedMap(Definitions.NOTIFICATION_PRIVACY, returnedObject, this.privacy);
        putDataOnSerializedMap(Definitions.NOTIFICATION_PRIVATE_MESSAGE, returnedObject, this.privateMessage);
        putDataOnSerializedMap(Definitions.NOTIFICATION_ROUNDED_LARGE_ICON, returnedObject, this.roundedLargeIcon);
        putDataOnSerializedMap(Definitions.NOTIFICATION_ROUNDED_BIG_PICTURE, returnedObject, this.roundedBigPicture);

        putDataOnSerializedMap(Definitions.NOTIFICATION_MESSAGES, returnedObject, this.messages);

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
    public void validate(Context context) throws AwesomeNotificationsException {
        if(id == null)
            throw ExceptionFactory
                    .getInstance()
                    .createNewAwesomeException(
                            TAG,
                            ExceptionCode.CODE_MISSING_ARGUMENTS,
                            "Notification id is required",
                            ExceptionCode.DETAILED_REQUIRED_ARGUMENTS+".notificationContent.id");

        if(ChannelManager
                .getInstance()
                .getChannelByKey(context, channelKey) == null)
            throw ExceptionFactory
                    .getInstance()
                    .createNewAwesomeException(
                            TAG,
                            ExceptionCode.CODE_INVALID_ARGUMENTS,
                            "Notification channel '"+channelKey+"' does not exist.",
                            ExceptionCode.DETAILED_INVALID_ARGUMENTS+".notificationContent."+channelKey);

        validateIcon(context);

        if(notificationLayout == null) {
            notificationLayout = NotificationLayout.Default;
        } else {
            if(notificationLayout == NotificationLayout.BigPicture) {
                validateRequiredImages(context);
            }
        }

        validateBigPicture(context);
        validateLargeIcon(context);

    }

    private void validateIcon(Context context) throws AwesomeNotificationsException {

        if(!stringUtils.isNullOrEmpty(icon)){
            if(
                BitmapUtils.getInstance().getMediaSourceType(icon) != MediaSource.Resource ||
                !BitmapUtils.getInstance().isValidBitmap(context, icon)
            ){
                throw ExceptionFactory
                        .getInstance()
                        .createNewAwesomeException(
                                TAG,
                                ExceptionCode.CODE_INVALID_ARGUMENTS,
                                "Small icon ('"+icon+"') must be a valid media native resource type.",
                                ExceptionCode.DETAILED_INVALID_ARGUMENTS+".smallIcon");
            }
        }
    }

    private void validateRequiredImages(Context context) throws AwesomeNotificationsException {
        if(stringUtils.isNullOrEmpty(largeIcon) && stringUtils.isNullOrEmpty(bigPicture))
            throw ExceptionFactory
                    .getInstance()
                    .createNewAwesomeException(
                            TAG,
                            ExceptionCode.CODE_MISSING_ARGUMENTS,
                            "bigPicture or largeIcon is required",
                            ExceptionCode.DETAILED_REQUIRED_ARGUMENTS+".image.required");
    }

    private void validateBigPicture(Context context) throws AwesomeNotificationsException {  
        if(
            !stringUtils.isNullOrEmpty(bigPicture) && 
            !BitmapUtils.getInstance().isValidBitmap(context, bigPicture)
        )
            throw ExceptionFactory
                    .getInstance()
                    .createNewAwesomeException(
                            TAG,
                            ExceptionCode.CODE_INVALID_ARGUMENTS,
                            "bigPicture is invalid",
                            ExceptionCode.DETAILED_INVALID_ARGUMENTS+".invalid.bigPicture");
    }

    private void validateLargeIcon(Context context) throws AwesomeNotificationsException {
        if(
            !stringUtils.isNullOrEmpty(largeIcon) && 
            !BitmapUtils.getInstance().isValidBitmap(context, largeIcon)
        )
            throw ExceptionFactory
                    .getInstance()
                    .createNewAwesomeException(
                            TAG,
                            ExceptionCode.CODE_INVALID_ARGUMENTS,
                            "largeIcon is invalid",
                            ExceptionCode.DETAILED_INVALID_ARGUMENTS+".invalid.largeIcon");
    }
}
