class Definitions {
    
    var BROADCAST_FCM_TOKEN = "me.carda.awesome_notifications.firebase.TOKEN"
    var EXTRA_BROADCAST_FCM_TOKEN = "token"

    var MEDIA_VALID_NETWORK = "^https?:\\/\\/"//(www)?(\\.?[a-zA-Z0-9@:%.\\-_\\+~#=]{2,256}\\/?)+(\\?\\S+)$
    var MEDIA_VALID_FILE = "^file?:\\/\\/"
    var MEDIA_VALID_ASSET = "^asset?:\\/\\/"
    var MEDIA_VALID_RESOURCE = "^resource?:\\/\\/"

    var INITIALIZE_CHANNELS = "initializeChannels"

    var BROADCAST_CREATED_NOTIFICATION ="broadcast.awesome_notifications.CREATED_NOTIFICATION"
    var BROADCAST_DISPLAYED_NOTIFICATION ="broadcast.awesome_notifications.DISPLAYED_NOTIFICATION"
    var BROADCAST_KEEP_ON_TOP ="broadcast.awesome_notifications.KEEP_ON_TOP"
    var EXTRA_BROADCAST_MESSAGE = "notification"

    var PUSH_NOTIFICATION_CONTENT = "content"
    var PUSH_NOTIFICATION_SCHEDULE = "schedule"
    var PUSH_NOTIFICATION_BUTTONS = "actionButtons"

    var SHARED_DEFAULTS = "defaults"
    var SHARED_MANAGER = "sharedManager"
    var SHARED_CHANNELS = "channels"
    var SHARED_CREATED = "created"
    var SHARED_DISPLAYED = "displayed"
    var SHARED_SCHEDULED_NOTIFICATIONS = "schedules"

    var CHANNEL_FLUTTER_PLUGIN = "awesome_notifications"

    var CHANNEL_METHOD_INITIALIZE = "initialize"
    var CHANNEL_METHOD_GET_DRAWABLE_DATA = "getDrawableData"
    var CHANNEL_METHOD_CREATE_NOTIFICATION = "createNewNotification"

    var CHANNEL_METHOD_GET_FCM_TOKEN = "getFirebaseToken"
    var CHANNEL_METHOD_NEW_FCM_TOKEN = "newTokenReceived"
    var CHANNEL_METHOD_IS_FCM_AVAILABLE = "isFirebaseAvailable"

    var CHANNEL_METHOD_SET_NOTIFICATION_CHANNEL = "setNotificationChannel"
    var CHANNEL_METHOD_REMOVE_NOTIFICATION_CHANNEL = "removeNotificationChannel"

    var CHANNEL_METHOD_CANCEL_NOTIFICATION = "cancelNotification"
    var CHANNEL_METHOD_CANCEL_SCHEDULE = "cancelSchedule"
    var CHANNEL_METHOD_CANCEL_ALL_SCHEDULES = "cancelAllSchedules"
    var CHANNEL_METHOD_CANCEL_ALL_NOTIFICATIONS = "cancelAllNotifications"

    var CHANNEL_METHOD_NOTIFICATION_CREATED = "notificationCreated"
    var CHANNEL_METHOD_NOTIFICATION_DISPLAYED = "notificationDisplayed"
    var CHANNEL_METHOD_RECEIVED_ACTION = "receivedAction"

    var CHANNEL_METHOD_LIST_ALL_SCHEDULES = "listAllSchedules"

    var DEFAULT_ICON = "defaultIcon"
    var SELECT_NOTIFICATION = "SELECT_NOTIFICATION"
    var NOTIFICATION_BUTTON_ACTION_PREFIX = "ACTION_NOTIFICATION"

    var SHARED_PREFERENCES_CHANNEL_MANAGER = "channel_manager"

    var DATE_FORMAT = "yyyy-MM-dd HH:mm:ss"

    var NOTIFICATION_ICON_RESOURCE_ID = "iconResourceId"

    var NOTIFICATION_CREATED_SOURCE = "createdSource"
    var NOTIFICATION_CREATED_LIFECYCLE = "createdLifeCycle"
    var NOTIFICATION_DISPLAYED_LIFECYCLE = "displayedLifeCycle"
    var NOTIFICATION_ACTION_LIFECYCLE = "actionLifeCycle"
    var NOTIFICATION_CREATED_DATE = "createdDate"
    var NOTIFICATION_DISPLAYED_DATE = "displayedDate"
    var NOTIFICATION_ACTION_DATE = "actionDate"

    var NOTIFICATION_ID = "id"
    var NOTIFICATION_LAYOUT = "notificationLayout"
    var NOTIFICATION_TITLE = "title"
    var NOTIFICATION_BODY = "body"
    var NOTIFICATION_SUMMARY = "summary"
    var NOTIFICATION_CUSTOM_SOUND = "customSound"
    var NOTIFICATION_SHOW_WHEN = "showWen"
    var NOTIFICATION_ACTION_KEY = "actionKey"
    var NOTIFICATION_ACTION_INPUT = "actionInput"
    var NOTIFICATION_JSON = "notificationJson"

    var NOTIFICATION_ACTION_BUTTONS = "actionButtons"
    var NOTIFICATION_BUTTON_KEY = "key"
    var NOTIFICATION_BUTTON_ICON = "icon"
    var NOTIFICATION_BUTTON_LABEL = "label"
    var NOTIFICATION_BUTTON_TYPE = "buttonType"

    var NOTIFICATION_PAYLOAD = "payload"
    var NOTIFICATION_INITIAL_DATE_TIME = "initialDateTime"
    var NOTIFICATION_CRONTAB_SCHEDULE = "crontabSchedule"
    var NOTIFICATION_ENABLED = "enabled"
    var NOTIFICATION_AUTO_CANCEL = "autoCancel"
    var NOTIFICATION_LOCKED = "locked"
    var NOTIFICATION_ICON = "icon"
    var NOTIFICATION_PLAY_SOUND = "playSound"
    var NOTIFICATION_SOUND_SOURCE = "soundSource"
    var NOTIFICATION_ENABLE_VIBRATION = "enableVibration"
    var NOTIFICATION_VIBRATION_PATTERN = "vibrationPattern"
    var NOTIFICATION_GROUP_KEY = "groupKey"
    var NOTIFICATION_SET_AS_GROUP_SUMMARY = "setAsGroupSummary"
    var NOTIFICATION_GROUP_ALERT_BEHAVIOR = "groupAlertBehaviour"
    var NOTIFICATION_PRIVACY = "privacy"
    var NOTIFICATION_DEFAULT_PRIVACY = "defaultPrivacy"
    var NOTIFICATION_PRIVATE_MESSAGE = "privateMessage"
    var NOTIFICATION_ONLY_ALERT_ONCE = "onlyAlertOnce"
    var NOTIFICATION_CHANNEL_KEY = "channelKey"
    var NOTIFICATION_CHANNEL_NAME = "channelName"
    var NOTIFICATION_CHANNEL_DESCRIPTION = "channelDescription"
    var NOTIFICATION_CHANNEL_SHOW_BADGE = "channelShowBadge"
    var NOTIFICATION_IMPORTANCE = "importance"
    var NOTIFICATION_COLOR = "color"
    var NOTIFICATION_BACKGROUND_COLOR = "backgroundColor"
    var NOTIFICATION_DEFAULT_COLOR = "defaultColor"
    var NOTIFICATION_LARGE_ICON = "largeIcon"
    var NOTIFICATION_BIG_PICTURE = "bigPicture"
    var NOTIFICATION_HIDE_LARGE_ICON_ON_EXPAND = "hideLargeIconOnExpand"
    var NOTIFICATION_PROGRESS = "progress"
    var NOTIFICATION_ENABLE_LIGHTS = "enableLights"
    var NOTIFICATION_LED_COLOR = "ledColor"
    var NOTIFICATION_LED_ON_MS = "ledOnMs"
    var NOTIFICATION_LED_OFF_MS = "ledOffMs"
    var NOTIFICATION_TICKER = "ticker"
    var NOTIFICATION_ALLOW_WHILE_IDLE = "allowWhileIdle"

    var initialValues = [
        Definitions.NOTIFICATION_ID: 0,
        Definitions.NOTIFICATION_IMPORTANCE: NotificationImportance.Default,
        Definitions.NOTIFICATION_LAYOUT: NotificationLayout.Default,
        Definitions.NOTIFICATION_GROUP_ALERT_BEHAVIOR: GroupAlertBehaviour.All,
        Definitions.NOTIFICATION_DEFAULT_PRIVACY: NotificationPrivacy.Private,
        Definitions.NOTIFICATION_PRIVACY: NotificationPrivacy.Private,
        Definitions.NOTIFICATION_CHANNEL_KEY: "miscellaneous",
        Definitions.NOTIFICATION_CHANNEL_DESCRIPTION: "Notifications",
        Definitions.NOTIFICATION_CHANNEL_NAME: "Notifications",
        Definitions.NOTIFICATION_CHANNEL_SHOW_BADGE: false,
        Definitions.NOTIFICATION_HIDE_LARGE_ICON_ON_EXPAND: false,
        Definitions.NOTIFICATION_ENABLED: true,
        Definitions.NOTIFICATION_SHOW_WHEN: true,
        Definitions.NOTIFICATION_BUTTON_TYPE: ActionButtonType.Default,
        Definitions.NOTIFICATION_PAYLOAD: null,
        Definitions.NOTIFICATION_ENABLE_VIBRATION: true,
        Definitions.NOTIFICATION_DEFAULT_COLOR: 0xFF000000,
        Definitions.NOTIFICATION_LED_COLOR: 0xFFFFFFFF,
        Definitions.NOTIFICATION_ENABLE_LIGHTS: true,
        Definitions.NOTIFICATION_LED_OFF_MS: 700,
        Definitions.NOTIFICATION_LED_ON_MS: 300,
        Definitions.NOTIFICATION_PLAY_SOUND: true,
        Definitions.NOTIFICATION_AUTO_CANCEL: true,
        Definitions.NOTIFICATION_LOCKED: false,
        Definitions.NOTIFICATION_TICKER: "ticker",
        Definitions.NOTIFICATION_ALLOW_WHILE_IDLE: false,
        Definitions.NOTIFICATION_ONLY_ALERT_ONCE: false
    ]
}