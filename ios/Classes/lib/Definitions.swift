
enum Definitions {
    
    static let  BROADCAST_FCM_TOKEN = "me.carda.awesome_notifications.firebase.TOKEN"
    static let  EXTRA_BROADCAST_FCM_TOKEN = "token"

    static let  MEDIA_VALID_NETWORK = "^https?:\\/\\/"//(www)?(\\.?[a-zA-Z0-9@:%.\\-_\\+~#=]{2,256}\\/?)+(\\?\\S+)$
    static let  MEDIA_VALID_FILE = "^file:\\/\\/"
    static let  MEDIA_VALID_ASSET = "^asset:\\/\\/"
    static let  MEDIA_VALID_RESOURCE = "^resource:\\/\\/"

    static let  INITIALIZE_CHANNELS = "initializeChannels"
    
    static let  USER_DEFAULT_TAG = "group.AwesomeNotifications." + Bundle.main.getBundleName()
    static let  DEFAULT_CATEGORY_IDENTIFIER = "DEFAULT"

    static let  IOS_BACKGROUND_SCHEDULER = "awesome_notifications.scheduler"
    static let  BROADCAST_CREATED_NOTIFICATION = "broadcast.awesome_notifications.CREATED_NOTIFICATION"
    static let  BROADCAST_DISPLAYED_NOTIFICATION = "broadcast.awesome_notifications.DISPLAYED_NOTIFICATION"
    static let  BROADCAST_KEEP_ON_TOP = "broadcast.awesome_notifications.KEEP_ON_TOP"
    static let  EXTRA_BROADCAST_MESSAGE = "notification"

    static let  NOTIFICATION_MODEL_CONTENT = "content"
    static let  NOTIFICATION_MODEL_SCHEDULE = "schedule"
    static let  NOTIFICATION_MODEL_BUTTONS = "actionButtons"

    static let  SHARED_DEFAULTS = "defaults"
    static let  SHARED_MANAGER = "sharedManager"
    static let  SHARED_CHANNELS = "channels"
    static let  SHARED_CREATED = "created"
    static let  SHARED_DISPLAYED = "displayed"
    static let  SHARED_SCHEDULED_NOTIFICATIONS = "schedules"
    static let  SHARED_SCHEDULED_DISPLAYED = "scheduledDisplayed"
    static let  SHARED_SCHEDULED_DISPLAYED_REFERENCE = "pendingList"

    static let  NOTIFICATION_SCHEDULE_INITIAL_DATE = "createdDate"
    static let  NOTIFICATION_SCHEDULE_TIMEZONE = "timeZone"
    static let  NOTIFICATION_SCHEDULE_ERA = "era"
    static let  NOTIFICATION_SCHEDULE_YEAR = "year"
    static let  NOTIFICATION_SCHEDULE_MONTH = "month"
    static let  NOTIFICATION_SCHEDULE_DAY = "day"
    static let  NOTIFICATION_SCHEDULE_HOUR = "hour"
    static let  NOTIFICATION_SCHEDULE_MINUTE = "minute"
    static let  NOTIFICATION_SCHEDULE_SECOND = "second"
    static let  NOTIFICATION_SCHEDULE_MILLISECOND = "millisecond"
    static let  NOTIFICATION_SCHEDULE_WEEKDAY = "weekday"
    static let  NOTIFICATION_SCHEDULE_WEEKOFMONTH = "weekOfMonth"
    static let  NOTIFICATION_SCHEDULE_WEEKOFYEAR = "weekOfYear"
    static let  NOTIFICATION_SCHEDULE_INTERVAL = "interval"
    static let  NOTIFICATION_SCHEDULE_REPEATS = "repeats"
    
    static let  NOTIFICATION_CRONTAB_EXPRESSION = "crontabExpression"
    static let  NOTIFICATION_PRECISE_SCHEDULES = "preciseSchedules"
    static let  NOTIFICATION_INITIAL_DATE_TIME = "initialDateTime"
    static let  NOTIFICATION_EXPIRATION_DATE_TIME = "expirationDateTime"
    
    static let  CHANNEL_FLUTTER_PLUGIN = "awesome_notifications"

    static let  CHANNEL_METHOD_INITIALIZE = "initialize"
    static let  CHANNEL_METHOD_GET_DRAWABLE_DATA = "getDrawableData"
    static let  CHANNEL_METHOD_GET_PLATFORM_VERSION = "getPlatformVersion"
    static let  CHANNEL_METHOD_CREATE_NOTIFICATION = "createNewNotification"

    static let  CHANNEL_METHOD_GET_FCM_TOKEN = "getFirebaseToken"
    static let  CHANNEL_METHOD_NEW_FCM_TOKEN = "newTokenReceived"
    static let  CHANNEL_METHOD_IS_FCM_AVAILABLE = "isFirebaseAvailable"

    static let  CHANNEL_METHOD_SET_NOTIFICATION_CHANNEL = "setNotificationChannel"
    static let  CHANNEL_METHOD_REMOVE_NOTIFICATION_CHANNEL = "removeNotificationChannel"

    static let  CHANNEL_METHOD_GET_BADGE_COUNT = "getBadgeCount"
    static let  CHANNEL_METHOD_SET_BADGE_COUNT = "setBadgeCount"
    static let  CHANNEL_METHOD_INCREMENT_BADGE_COUNT = "incBadgeCount"
    static let  CHANNEL_METHOD_DECREMENT_BADGE_COUNT = "decBadgeCount"
    static let  CHANNEL_METHOD_GET_NEXT_DATE = "getNextDate"
    static let  CHANNEL_METHOD_RESET_BADGE = "resetBadge"
    
    static let  CHANNEL_METHOD_SHOW_NOTIFICATION_PAGE = "showNotificationPage"
    static let  CHANNEL_METHOD_SHOW_ALARM_PAGE = "showAlarmPage"
    static let  CHANNEL_METHOD_SHOW_GLOBAL_DND_PAGE = "showGlobalDndPage"
    static let  CHANNEL_METHOD_IS_NOTIFICATION_ALLOWED = "isNotificationAllowed"
    static let  CHANNEL_METHOD_REQUEST_NOTIFICATIONS = "requestNotifications"
    static let  CHANNEL_METHOD_CHECK_PERMISSIONS = "checkPermissions"
    static let  CHANNEL_METHOD_SHOULD_SHOW_RATIONALE = "shouldShowRationale"

    static let  CHANNEL_METHOD_DISMISS_NOTIFICATION = "dismissNotification"
    static let  CHANNEL_METHOD_CANCEL_SCHEDULE = "cancelSchedule"
    static let  CHANNEL_METHOD_CANCEL_NOTIFICATION = "cancelNotification"
    static let  CHANNEL_METHOD_DISMISS_NOTIFICATIONS_BY_CHANNEL_KEY = "dismissNotificationsByChannelKey"
    static let  CHANNEL_METHOD_CANCEL_NOTIFICATIONS_BY_CHANNEL_KEY = "cancelNotificationsByChannelKey"
    static let  CHANNEL_METHOD_CANCEL_SCHEDULES_BY_CHANNEL_KEY = "cancelSchedulesByChannelKey"
    static let  CHANNEL_METHOD_DISMISS_NOTIFICATIONS_BY_GROUP_KEY = "dismissNotificationsByGroupKey"
    static let  CHANNEL_METHOD_CANCEL_NOTIFICATIONS_BY_GROUP_KEY = "cancelNotificationsByGroupKey"
    static let  CHANNEL_METHOD_CANCEL_SCHEDULES_BY_GROUP_KEY = "cancelSchedulesByGroupKey"
    static let  CHANNEL_METHOD_DISMISS_ALL_NOTIFICATIONS = "dismissAllNotifications"
    static let  CHANNEL_METHOD_CANCEL_ALL_SCHEDULES = "cancelAllSchedules"
    static let  CHANNEL_METHOD_CANCEL_ALL_NOTIFICATIONS = "cancelAllNotifications"

    static let  CHANNEL_METHOD_NOTIFICATION_CREATED = "notificationCreated"
    static let  CHANNEL_METHOD_NOTIFICATION_DISPLAYED = "notificationDisplayed"
    static let  CHANNEL_METHOD_NOTIFICATION_DISMISSED = "notificationDismissed"
    static let  CHANNEL_METHOD_RECEIVED_ACTION = "receivedAction"
    
    static let  CHANNEL_METHOD_GET_UTC_TIMEZONE_IDENTIFIER = "getUtcTimeZoneIdentifier"
    static let  CHANNEL_METHOD_GET_LOCAL_TIMEZONE_IDENTIFIER = "getLocalTimeZoneIdentifier"
    
    static let  CHANNEL_METHOD_LIST_ALL_SCHEDULES = "listAllSchedules"

    static let  DEFAULT_ICON = "defaultIcon"
    static let  BADGE_COUNT = "badgeCount"
    static let  SELECT_NOTIFICATION = "SELECT_NOTIFICATION"
    static let  NOTIFICATION_BUTTON_ACTION_PREFIX = "ACTION_NOTIFICATION"

    static let  SHARED_PREFERENCES_CHANNEL_MANAGER = "channel_manager"
    
    static let  DATE_FORMAT = "yyyy-MM-dd HH:mm:ss"
    
    static let  DATE_FORMAT_TIMEZONE = "yyyy-MM-dd HH:mm:ss ZZZZ"

    static let  NOTIFICATION_ICON_RESOURCE_ID = "iconResourceId"

    static let  NOTIFICATION_CREATED_SOURCE = "createdSource"
    static let  NOTIFICATION_CREATED_LIFECYCLE = "createdLifeCycle"
    static let  NOTIFICATION_DISPLAYED_LIFECYCLE = "displayedLifeCycle"
    static let  NOTIFICATION_ACTION_LIFECYCLE = "actionLifeCycle"
    static let  NOTIFICATION_CREATED_DATE = "createdDate"
    static let  NOTIFICATION_DISPLAYED_DATE = "displayedDate"
    static let  NOTIFICATION_ACTION_DATE = "actionDate"

    static let  NOTIFICATION_ID = "id"
    static let  NOTIFICATION_LAYOUT = "notificationLayout"
    static let  NOTIFICATION_TITLE = "title"
    static let  NOTIFICATION_BODY = "body"
    static let  NOTIFICATION_SUMMARY = "summary"
    static let  NOTIFICATION_CUSTOM_SOUND = "customSound"
    static let  NOTIFICATION_SHOW_WHEN = "showWen"
    static let  NOTIFICATION_BUTTON_KEY_PRESSED = "buttonKeyPressed"
    static let  NOTIFICATION_BUTTON_KEY_INPUT = "buttonKeyInput"
    static let  NOTIFICATION_JSON = "notificationJson"

    static let  NOTIFICATION_ACTION_BUTTONS = "actionButtons"
    static let  NOTIFICATION_BUTTON_KEY = "key"
    static let  NOTIFICATION_BUTTON_ICON = "icon"
    static let  NOTIFICATION_BUTTON_LABEL = "label"
    static let  NOTIFICATION_BUTTON_TYPE = "buttonType"
    static let  NOTIFICATION_SHOW_IN_COMPACT_VIEW = "showInCompactView"
    static let  NOTIFICATION_IS_DANGEROUS_OPTION = "isDangerousOption"
    static let  NOTIFICATION_PERMISSIONS = "permissions"

    static let  NOTIFICATION_PAYLOAD = "payload"
    static let  NOTIFICATION_INITIAL_FIXED_DATE = "fixedDate"
    static let  NOTIFICATION_CREATED_DATE_TIME = "createdDateTime"
    static let  NOTIFICATION_ENABLED = "enabled"
    static let  NOTIFICATION_AUTO_DISMISSIBLE = "autoDismissible"
    static let  NOTIFICATION_LOCKED = "locked"
    static let  NOTIFICATION_DISPLAY_ON_FOREGROUND = "displayOnForeground"
    static let  NOTIFICATION_DISPLAY_ON_BACKGROUND = "displayOnBackground"
    static let  NOTIFICATION_ICON = "icon"
    static let  NOTIFICATION_FULL_SCREEN_INTENT = "fullScreenIntent"
    static let  NOTIFICATION_WAKE_UP_SCREEN = "wakeUpScreen"
    static let  NOTIFICATION_PLAY_SOUND = "playSound"
    static let  NOTIFICATION_SOUND_SOURCE = "soundSource"
    static let  NOTIFICATION_DEFAULT_RINGTONE_TYPE = "defaultRingtoneType"
    static let  NOTIFICATION_ENABLE_VIBRATION = "enableVibration"
    static let  NOTIFICATION_VIBRATION_PATTERN = "vibrationPattern"
    static let  NOTIFICATION_GROUP_KEY = "groupKey"
    static let  NOTIFICATION_GROUP_SORT = "groupSort"
    static let  NOTIFICATION_GROUP_ALERT_BEHAVIOR = "groupAlertBehaviour"
    static let  NOTIFICATION_PRIVACY = "privacy"
    static let  NOTIFICATION_DEFAULT_PRIVACY = "defaultPrivacy"
    static let  NOTIFICATION_PRIVATE_MESSAGE = "privateMessage"
    static let  NOTIFICATION_ONLY_ALERT_ONCE = "onlyAlertOnce"
    static let  NOTIFICATION_CHANNEL_KEY = "channelKey"
    static let  NOTIFICATION_CHANNEL_NAME = "channelName"
    static let  NOTIFICATION_CHANNEL_DESCRIPTION = "channelDescription"
    static let  NOTIFICATION_CHANNEL_SHOW_BADGE = "channelShowBadge"
    static let  NOTIFICATION_CHANNEL_CRITICAL_ALERTS = "criticalAlerts"
    static let  NOTIFICATION_IMPORTANCE = "importance"
    static let  NOTIFICATION_COLOR = "color"
    static let  NOTIFICATION_BACKGROUND_COLOR = "backgroundColor"
    static let  NOTIFICATION_DEFAULT_COLOR = "defaultColor"
    static let  NOTIFICATION_LARGE_ICON = "largeIcon"
    static let  NOTIFICATION_BIG_PICTURE = "bigPicture"
    static let  NOTIFICATION_HIDE_LARGE_ICON_ON_EXPAND = "hideLargeIconOnExpand"
    static let  NOTIFICATION_PROGRESS = "progress"
    static let  NOTIFICATION_ENABLE_LIGHTS = "enableLights"
    static let  NOTIFICATION_LED_COLOR = "ledColor"
    static let  NOTIFICATION_LED_ON_MS = "ledOnMs"
    static let  NOTIFICATION_LED_OFF_MS = "ledOffMs"
    static let  NOTIFICATION_TICKER = "ticker"
    static let  NOTIFICATION_ALLOW_WHILE_IDLE = "allowWhileIdle"

    static let  initialValues = [
        Definitions.NOTIFICATION_ID: 0,
        Definitions.NOTIFICATION_SCHEDULE_REPEATS: false,
        Definitions.NOTIFICATION_IMPORTANCE: NotificationImportance.Default,
        Definitions.NOTIFICATION_LAYOUT: NotificationLayout.Default,
        Definitions.NOTIFICATION_GROUP_SORT: GroupSort.Desc,
        Definitions.NOTIFICATION_GROUP_ALERT_BEHAVIOR: GroupAlertBehaviour.All,
        Definitions.NOTIFICATION_DEFAULT_PRIVACY: NotificationPrivacy.Private,
        Definitions.NOTIFICATION_PRIVACY: NotificationPrivacy.Private,
        Definitions.NOTIFICATION_CREATED_LIFECYCLE: NotificationLifeCycle.AppKilled,
        Definitions.NOTIFICATION_DISPLAYED_LIFECYCLE: NotificationLifeCycle.AppKilled,
        Definitions.NOTIFICATION_ACTION_LIFECYCLE: NotificationLifeCycle.AppKilled,
        Definitions.NOTIFICATION_DISPLAY_ON_FOREGROUND: true,
        Definitions.NOTIFICATION_DISPLAY_ON_BACKGROUND: true,
        Definitions.NOTIFICATION_CHANNEL_KEY: "miscellaneous",
        Definitions.NOTIFICATION_CHANNEL_DESCRIPTION: "Notifications",
        Definitions.NOTIFICATION_CHANNEL_NAME: "Notifications",
        Definitions.NOTIFICATION_DEFAULT_RINGTONE_TYPE: DefaultRingtoneType.Notification,
        Definitions.NOTIFICATION_CHANNEL_SHOW_BADGE: false,
        Definitions.NOTIFICATION_HIDE_LARGE_ICON_ON_EXPAND: false,
        Definitions.NOTIFICATION_ENABLED: true,
        Definitions.NOTIFICATION_SHOW_WHEN: true,
        Definitions.NOTIFICATION_BUTTON_TYPE: ActionButtonType.Default,
        Definitions.NOTIFICATION_PAYLOAD: nil,
        Definitions.NOTIFICATION_ENABLE_VIBRATION: true,
        Definitions.NOTIFICATION_DEFAULT_COLOR: 0x000000,
        Definitions.NOTIFICATION_LED_COLOR: 0xFFFFFF,
        Definitions.NOTIFICATION_ENABLE_LIGHTS: true,
        Definitions.NOTIFICATION_LED_OFF_MS: 700,
        Definitions.NOTIFICATION_LED_ON_MS: 300,
        Definitions.NOTIFICATION_PLAY_SOUND: true,
        Definitions.NOTIFICATION_AUTO_DISMISSIBLE: true,
        Definitions.NOTIFICATION_LOCKED: false,
        Definitions.NOTIFICATION_TICKER: "ticker",
        Definitions.NOTIFICATION_ALLOW_WHILE_IDLE: false,
        Definitions.NOTIFICATION_ONLY_ALERT_ONCE: false,
        Definitions.NOTIFICATION_IS_DANGEROUS_OPTION: false,
        Definitions.NOTIFICATION_WAKE_UP_SCREEN: false
    ] as [String : Any?]
}
