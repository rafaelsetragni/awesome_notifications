package me.carda.awesome_notifications;

import java.util.HashMap;
import java.util.Map;

import me.carda.awesome_notifications.notifications.enumerators.ActionButtonType;
import me.carda.awesome_notifications.notifications.enumerators.DefaultRingtoneType;
import me.carda.awesome_notifications.notifications.enumerators.GroupAlertBehaviour;
import me.carda.awesome_notifications.notifications.enumerators.GroupSort;
import me.carda.awesome_notifications.notifications.enumerators.NotificationImportance;
import me.carda.awesome_notifications.notifications.enumerators.NotificationLayout;
import me.carda.awesome_notifications.notifications.enumerators.NotificationPrivacy;
import me.carda.awesome_notifications.utils.DateUtils;

public interface Definitions {

    String BROADCAST_FCM_TOKEN = "me.carda.awesome_notifications.services.firebase.TOKEN";
    String EXTRA_BROADCAST_FCM_TOKEN = "token";
    String EXTRA_ANDROID_MEDIA_BUTTON = "android.intent.action.MEDIA_BUTTON";

    String MEDIA_VALID_NETWORK = "^https?:\\/\\/";//(www)?(\\.?[a-zA-Z0-9@:%.\\-_\\+~#=]{2,256}\\/?)+(\\?\\S+)$
    String MEDIA_VALID_FILE = "^file?:\\/\\/";
    String MEDIA_VALID_ASSET = "^asset?:\\/\\/";
    String MEDIA_VALID_RESOURCE = "^resource?:\\/\\/";

    String BADGE_COUNT = "badgeCount";
    String INITIALIZE_DEBUG_MODE = "debug";
    String INITIALIZE_DEFAULT_ICON = "defaultIcon";
    String INITIALIZE_CHANNELS = "initializeChannels";
    String INITIALIZE_CHANNEL_GROUPS = "initializeChannelGroups";

    String BROADCAST_CREATED_NOTIFICATION   = "broadcast.awesome_notifications.CREATED_NOTIFICATION";
    String BROADCAST_DISPLAYED_NOTIFICATION = "broadcast.awesome_notifications.DISPLAYED_NOTIFICATION";
    String BROADCAST_DISMISSED_NOTIFICATION = "broadcast.awesome_notifications.DISMISSED_NOTIFICATION";
    String BROADCAST_MEDIA_BUTTON = "broadcast.awesome_notifications.MEDIA_BUTTON";
    String BROADCAST_KEEP_ON_TOP ="broadcast.awesome_notifications.KEEP_ON_TOP";
    String EXTRA_BROADCAST_MESSAGE = "notification";

    String NOTIFICATION_MODEL_CONTENT = "content";
    String NOTIFICATION_MODEL_SCHEDULE = "schedule";
    String NOTIFICATION_MODEL_BUTTONS = "actionButtons";

    String SHARED_DEFAULTS = "defaults";
    String SHARED_MANAGER = "sharedManager";
    String SHARED_CHANNELS = "channels";
    String SHARED_CREATED = "created";
    String SHARED_CHANNEL_GROUP = "channelGroup";
    String SHARED_DISPLAYED = "displayed";
    String SHARED_DISMISSED = "dismissed";
    String SHARED_SCHEDULED_NOTIFICATIONS = "schedules";

    String CHANNEL_FLUTTER_PLUGIN = "awesome_notifications";

    String CHANNEL_METHOD_INITIALIZE = "initialize";
    String CHANNEL_METHOD_GET_DRAWABLE_DATA = "getDrawableData";
    String CHANNEL_METHOD_ENABLE_WAKELOCK = "enableWakelock";
    String CHANNEL_METHOD_CREATE_NOTIFICATION = "createNewNotification";

    String CHANNEL_METHOD_GET_UTC_TIMEZONE_IDENTIFIER = "getUtcTimeZoneIdentifier";
    String CHANNEL_METHOD_GET_LOCAL_TIMEZONE_IDENTIFIER = "getLocalTimeZoneIdentifier";

    String CHANNEL_METHOD_GET_FCM_TOKEN = "getFirebaseToken";
    String CHANNEL_METHOD_NEW_FCM_TOKEN = "newTokenReceived";
    String CHANNEL_METHOD_IS_FCM_AVAILABLE = "isFirebaseAvailable";

    String CHANNEL_METHOD_SET_NOTIFICATION_CHANNEL = "setNotificationChannel";
    String CHANNEL_METHOD_REMOVE_NOTIFICATION_CHANNEL = "removeNotificationChannel";

    String CHANNEL_METHOD_SHOW_NOTIFICATION_PAGE = "showNotificationPage";
    String CHANNEL_METHOD_SHOW_ALARM_PAGE = "showAlarmPage";
    String CHANNEL_METHOD_SHOW_GLOBAL_DND_PAGE = "showGlobalDndPage";
    String CHANNEL_METHOD_IS_NOTIFICATION_ALLOWED = "isNotificationAllowed";
    String CHANNEL_METHOD_REQUEST_NOTIFICATIONS = "requestNotifications";
    String CHANNEL_METHOD_CHECK_PERMISSIONS = "checkPermissions";
    String CHANNEL_METHOD_SHOULD_SHOW_RATIONALE = "shouldShowRationale";

    String CHANNEL_METHOD_GET_BADGE_COUNT = "getBadgeCount";
    String CHANNEL_METHOD_SET_BADGE_COUNT = "setBadgeCount";
    String CHANNEL_METHOD_INCREMENT_BADGE_COUNT = "incBadgeCount";
    String CHANNEL_METHOD_DECREMENT_BADGE_COUNT = "decBadgeCount";
    String CHANNEL_METHOD_RESET_BADGE = "resetBadge";

    String CHANNEL_METHOD_GET_NEXT_DATE = "getNextDate";
    String CHANNEL_METHOD_DISMISS_NOTIFICATION = "dismissNotification";
    String CHANNEL_METHOD_CANCEL_NOTIFICATION = "cancelNotification";
    String CHANNEL_METHOD_CANCEL_SCHEDULE = "cancelSchedule";
    String CHANNEL_METHOD_DISMISS_NOTIFICATIONS_BY_CHANNEL_KEY = "dismissNotificationsByChannelKey";
    String CHANNEL_METHOD_CANCEL_NOTIFICATIONS_BY_CHANNEL_KEY = "cancelNotificationsByChannelKey";
    String CHANNEL_METHOD_CANCEL_SCHEDULES_BY_CHANNEL_KEY = "cancelSchedulesByChannelKey";
    String CHANNEL_METHOD_DISMISS_NOTIFICATIONS_BY_GROUP_KEY = "dismissNotificationsByGroupKey";
    String CHANNEL_METHOD_CANCEL_NOTIFICATIONS_BY_GROUP_KEY = "cancelNotificationsByGroupKey";
    String CHANNEL_METHOD_CANCEL_SCHEDULES_BY_GROUP_KEY = "cancelSchedulesByGroupKey";
    String CHANNEL_METHOD_DISMISS_ALL_NOTIFICATIONS = "dismissAllNotifications";
    String CHANNEL_METHOD_CANCEL_ALL_SCHEDULES = "cancelAllSchedules";
    String CHANNEL_METHOD_CANCEL_ALL_NOTIFICATIONS = "cancelAllNotifications";

    String CHANNEL_METHOD_NOTIFICATION_CREATED = "notificationCreated";
    String CHANNEL_METHOD_NOTIFICATION_DISPLAYED = "notificationDisplayed";
    String CHANNEL_METHOD_NOTIFICATION_DISMISSED = "notificationDismissed";
    String CHANNEL_METHOD_RECEIVED_ACTION = "receivedAction";
    String CHANNEL_METHOD_MEDIA_BUTTON = "mediaButton";

    String CHANNEL_METHOD_START_FOREGROUND = "startForeground";
    String CHANNEL_METHOD_STOP_FOREGROUND = "stopForeground";

    String CHANNEL_METHOD_LIST_ALL_SCHEDULES = "listAllSchedules";
    String CHANNEL_FORCE_UPDATE = "forceUpdate";

    String FIREBASE_ENABLED = "FIREBASE_ENABLED";
    String SELECT_NOTIFICATION = "SELECT_NOTIFICATION";
    String DISMISSED_NOTIFICATION = "DISMISSED_NOTIFICATION";
    String MEDIA_BUTTON = "MEDIA_BUTTON";
    String NOTIFICATION_BUTTON_ACTION_PREFIX = "ACTION_NOTIFICATION";

    String SHARED_PREFERENCES_CHANNEL_MANAGER = "channel_manager";

    String DATE_FORMAT = "yyyy-MM-dd HH:mm:ss";

    String NOTIFICATION_ICON_RESOURCE_ID = "iconResourceId";

    String NOTIFICATION_SCHEDULE_CREATED_DATE = "createdDate";
    String NOTIFICATION_SCHEDULE_ERA = "era";
    String NOTIFICATION_SCHEDULE_TIMEZONE = "timeZone";
    String NOTIFICATION_SCHEDULE_PRECISE_ALARM = "preciseAlarm";
    String NOTIFICATION_SCHEDULE_YEAR = "year";
    String NOTIFICATION_SCHEDULE_MONTH = "month";
    String NOTIFICATION_SCHEDULE_DAY = "day";
    String NOTIFICATION_SCHEDULE_HOUR = "hour";
    String NOTIFICATION_SCHEDULE_MINUTE = "minute";
    String NOTIFICATION_SCHEDULE_SECOND = "second";
    String NOTIFICATION_SCHEDULE_MILLISECOND = "millisecond";
    String NOTIFICATION_SCHEDULE_WEEKDAY = "weekday";
    String NOTIFICATION_SCHEDULE_WEEKOFMONTH = "weekOfMonth";
    String NOTIFICATION_SCHEDULE_WEEKOFYEAR = "weekOfYear";
    String NOTIFICATION_SCHEDULE_INTERVAL = "interval";
    String NOTIFICATION_SCHEDULE_REPEATS = "repeats";

    String NOTIFICATION_CREATED_SOURCE = "createdSource";
    String NOTIFICATION_CREATED_LIFECYCLE = "createdLifeCycle";
    String NOTIFICATION_DISPLAYED_LIFECYCLE = "displayedLifeCycle";
    String NOTIFICATION_DISMISSED_LIFECYCLE = "dismissedLifeCycle";
    String NOTIFICATION_ACTION_LIFECYCLE = "actionLifeCycle";
    String NOTIFICATION_CREATED_DATE = "createdDate";
    String NOTIFICATION_ACTION_DATE = "actionDate";
    String NOTIFICATION_DISPLAYED_DATE = "displayedDate";
    String NOTIFICATION_DISMISSED_DATE = "dismissedDate";

    String NOTIFICATION_ID = "id";
    String NOTIFICATION_RANDOM_ID = "randomId";
    String NOTIFICATION_LAYOUT = "notificationLayout";
    String NOTIFICATION_TITLE = "title";
    String NOTIFICATION_BODY = "body";
    String NOTIFICATION_TIMESTAMP = "timestamp";
    String NOTIFICATION_SUMMARY = "summary";
    String NOTIFICATION_SHOW_WHEN = "showWhen";
    String NOTIFICATION_BUTTON_KEY_PRESSED = "buttonKeyPressed";
    String NOTIFICATION_BUTTON_KEY_INPUT = "buttonKeyInput";
    String NOTIFICATION_JSON = "notificationJson";

    String NOTIFICATION_MESSAGES = "messages";
    String NOTIFICATION_BUTTON_KEY = "key";
    String NOTIFICATION_BUTTON_ICON = "icon";
    String NOTIFICATION_BUTTON_LABEL = "label";
    String NOTIFICATION_BUTTON_TYPE = "buttonType";

    String NOTIFICATION_PAYLOAD = "payload";
    String NOTIFICATION_INITIAL_FIXED_DATE = "fixedDate";

    String NOTIFICATION_INITIAL_DATE_TIME = "initialDateTime";
    String NOTIFICATION_EXPIRATION_DATE_TIME = "expirationDateTime";
    String NOTIFICATION_CRONTAB_EXPRESSION = "crontabExpression";
    String NOTIFICATION_PRECISE_SCHEDULES = "preciseSchedules";
    String NOTIFICATION_ENABLED = "enabled";
    String NOTIFICATION_AUTO_DISMISSIBLE = "autoDismissible";
    String NOTIFICATION_IS_DANGEROUS_OPTION = "isDangerousOption";
    String NOTIFICATION_PERMISSIONS = "permissions";

    String NOTIFICATION_SHOW_IN_COMPACT_VIEW = "showInCompactView";
    String NOTIFICATION_LOCKED = "locked";
    String NOTIFICATION_DISPLAY_ON_FOREGROUND = "displayOnForeground";
    String NOTIFICATION_DISPLAY_ON_BACKGROUND = "displayOnBackground";
    String NOTIFICATION_ICON = "icon";
    String NOTIFICATION_FULL_SCREEN_INTENT = "fullScreenIntent";
    String NOTIFICATION_WAKE_UP_SCREEN = "wakeUpScreen";
    String NOTIFICATION_PLAY_SOUND = "playSound";
    String NOTIFICATION_SOUND_SOURCE = "soundSource";
    String NOTIFICATION_ENABLE_VIBRATION = "enableVibration";
    String NOTIFICATION_VIBRATION_PATTERN = "vibrationPattern";
    String NOTIFICATION_GROUP_KEY = "groupKey";
    String NOTIFICATION_GROUP_SORT = "groupSort";
    String NOTIFICATION_GROUP_ALERT_BEHAVIOR = "groupAlertBehavior";
    String NOTIFICATION_PRIVACY = "privacy";
    String NOTIFICATION_CATEGORY = "category";
    String NOTIFICATION_CUSTOM_SOUND = "customSound";
    String NOTIFICATION_DEFAULT_PRIVACY = "defaultPrivacy";
    String NOTIFICATION_DEFAULT_RINGTONE_TYPE = "defaultRingtoneType";
    String NOTIFICATION_PRIVATE_MESSAGE = "privateMessage";
    String NOTIFICATION_ONLY_ALERT_ONCE = "onlyAlertOnce";
    String NOTIFICATION_CHANNEL_KEY = "channelKey";
    String NOTIFICATION_CHANNEL_NAME = "channelName";
    String NOTIFICATION_CHANNEL_DESCRIPTION = "channelDescription";
    String NOTIFICATION_CHANNEL_SHOW_BADGE = "channelShowBadge";
    String NOTIFICATION_CHANNEL_GROUP_NAME = "channelGroupName";
    String NOTIFICATION_CHANNEL_GROUP_KEY = "channelGroupKey";
    String NOTIFICATION_CHANNEL_CRITICAL_ALERTS = "criticalAlerts";
    String NOTIFICATION_IMPORTANCE = "importance";
    String NOTIFICATION_COLOR = "color";
    String NOTIFICATION_BACKGROUND_COLOR = "backgroundColor";
    String NOTIFICATION_DEFAULT_COLOR = "defaultColor";
    String NOTIFICATION_APP_ICON = "defaultIcon";
    String NOTIFICATION_LARGE_ICON = "largeIcon";
    String NOTIFICATION_BIG_PICTURE = "bigPicture";
    String NOTIFICATION_HIDE_LARGE_ICON_ON_EXPAND = "hideLargeIconOnExpand";
    String NOTIFICATION_PROGRESS = "progress";
    String NOTIFICATION_ENABLE_LIGHTS = "enableLights";
    String NOTIFICATION_LED_COLOR = "ledColor";
    String NOTIFICATION_LED_ON_MS = "ledOnMs";
    String NOTIFICATION_LED_OFF_MS = "ledOffMs";
    String NOTIFICATION_TICKER = "ticker";
    String NOTIFICATION_ALLOW_WHILE_IDLE = "allowWhileIdle";

    Map<String, Object> initialValues = new HashMap<String, Object>(){{
        put(Definitions.FIREBASE_ENABLED, true);
        put(Definitions.NOTIFICATION_SCHEDULE_REPEATS, true);
        put(Definitions.NOTIFICATION_ID, 0);
        put(Definitions.NOTIFICATION_IMPORTANCE, NotificationImportance.Default);
        put(Definitions.NOTIFICATION_LAYOUT, NotificationLayout.Default);
        put(Definitions.NOTIFICATION_GROUP_SORT, GroupSort.Desc);
        put(Definitions.NOTIFICATION_GROUP_ALERT_BEHAVIOR, GroupAlertBehaviour.All);
        put(Definitions.NOTIFICATION_DEFAULT_PRIVACY, NotificationPrivacy.Private);
        //put(Definitions.NOTIFICATION_PRIVACY, NotificationPrivacy.Private);
        put(Definitions.NOTIFICATION_CHANNEL_KEY, "miscellaneous");
        put(Definitions.NOTIFICATION_CHANNEL_DESCRIPTION, "Notifications");
        put(Definitions.NOTIFICATION_CHANNEL_NAME, "Notifications");
        put(Definitions.NOTIFICATION_CHANNEL_SHOW_BADGE, false);
        put(Definitions.NOTIFICATION_DISPLAY_ON_FOREGROUND, true);
        put(Definitions.NOTIFICATION_DISPLAY_ON_BACKGROUND, true);
        put(Definitions.NOTIFICATION_HIDE_LARGE_ICON_ON_EXPAND, false);
        put(Definitions.NOTIFICATION_ENABLED, true);
        put(Definitions.NOTIFICATION_SHOW_WHEN, true);
        put(Definitions.NOTIFICATION_BUTTON_TYPE, ActionButtonType.Default);
        put(Definitions.NOTIFICATION_PAYLOAD, null);
        put(Definitions.NOTIFICATION_ENABLE_VIBRATION, true);
        put(Definitions.NOTIFICATION_DEFAULT_COLOR, 0xFF000000);
        put(Definitions.NOTIFICATION_LED_COLOR, 0xFFFFFFFF);
        put(Definitions.NOTIFICATION_ENABLE_LIGHTS, true);
        put(Definitions.NOTIFICATION_LED_OFF_MS, 700);
        put(Definitions.NOTIFICATION_LED_ON_MS, 300);
        put(Definitions.NOTIFICATION_PLAY_SOUND, true);
        put(Definitions.NOTIFICATION_AUTO_DISMISSIBLE, true);
        put(Definitions.NOTIFICATION_DEFAULT_RINGTONE_TYPE, DefaultRingtoneType.Notification);
        put(Definitions.NOTIFICATION_SCHEDULE_TIMEZONE, DateUtils.localTimeZone.toString());
        put(Definitions.NOTIFICATION_TICKER, "ticker");
        put(Definitions.NOTIFICATION_ALLOW_WHILE_IDLE, false);
        put(Definitions.NOTIFICATION_ONLY_ALERT_ONCE, false);
        put(Definitions.NOTIFICATION_SHOW_IN_COMPACT_VIEW, true);
        put(Definitions.NOTIFICATION_IS_DANGEROUS_OPTION, false);
        put(Definitions.NOTIFICATION_WAKE_UP_SCREEN, false);
        put(Definitions.NOTIFICATION_CHANNEL_CRITICAL_ALERTS, false);
    }};
}
