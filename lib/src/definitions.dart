import 'package:awesome_notifications/src/enumerators/action_button_type.dart';
import 'package:awesome_notifications/src/enumerators/default_ringtone_type.dart';
import 'package:awesome_notifications/src/enumerators/group_alert_behaviour.dart';
import 'package:awesome_notifications/src/enumerators/group_sort.dart';
import 'package:awesome_notifications/src/enumerators/notification_importance.dart';
import 'package:awesome_notifications/src/enumerators/notification_privacy.dart';
import 'package:flutter/material.dart';

import 'enumerators/notification_layout.dart';

const BROADCAST_FCM_TOKEN =
    'me.carda.awesome_notifications.services.firebase.TOKEN';
const EXTRA_BROADCAST_FCM_TOKEN = 'token';

const BROADCAST_MESSAGE =
    'me.carda.awesome_notifications.services.firebase.NOTIFICATION';
const EXTRA_BROADCAST_MESSAGE = 'notification';

const INITIALIZE_DEBUG_MODE = "debug";
const INITIALIZE_DEFAULT_ICON = "defaultIcon";
const INITIALIZE_CHANNELS = "initializeChannels";
const INITIALIZE_CHANNELS_GROUPS = "initializeChannelGroups";

const NOTIFICATION_CONTENT = "content";
const NOTIFICATION_SCHEDULE = "schedule";
const NOTIFICATION_BUTTONS = "actionButtons";

const FOREGROUND_NOTIFICATION_DATA = "notificationData";
const FOREGROUND_START_TYPE = "startType";
const FOREGROUND_HAS_FOREGROUND = "hasForegroundServiceType";
const FOREGROUND_SERVICE_TYPE = "foregroundServiceType";

const APP_LIFECYCLE_FOREGROUND = 'FOREGROUND';
const APP_LIFECYCLE_BACKGROUND = 'BACKGROUND';
const APP_LIFECYCLE_APP_KILLED = 'APP_KILLED';

const PUSH_SOURCE_FIREBASE = 'Firebase';
const PUSH_SOURCE_ONE_SIGNAL = 'OneSignal';
const PUSH_SOURCE_LOCAL_NOTIFICATION = 'Local';

const SHARED_PREFERENCES_KEY = 'notification_plugin_cache';

const CHANNEL_FLUTTER_PLUGIN = 'awesome_notifications';

const CHANNEL_METHOD_INITIALIZE = 'initialize';
const CHANNEL_METHOD_GET_DRAWABLE_DATA = 'getDrawableData';
const CHANNEL_METHOD_GET_PLATFORM_VERSION = 'getPlatformVersion';

const CHANNEL_METHOD_SHOW_NOTIFICATION_PAGE = 'showNotificationPage';
const CHANNEL_METHOD_SHOW_ALARM_PAGE = 'showAlarmPage';
const CHANNEL_METHOD_SHOW_GLOBAL_DND_PAGE = 'showGlobalDndPage';
const CHANNEL_METHOD_IS_NOTIFICATION_ALLOWED = 'isNotificationAllowed';
const CHANNEL_METHOD_REQUEST_NOTIFICATIONS = 'requestNotifications';

const CHANNEL_METHOD_SET_NOTIFICATION_CHANNEL = 'setNotificationChannel';
const CHANNEL_METHOD_REMOVE_NOTIFICATION_CHANNEL = 'removeNotificationChannel';

const CHANNEL_METHOD_IS_FCM_AVAILABLE = 'isFirebaseAvailable';
const CHANNEL_METHOD_GET_FCM_TOKEN = 'getFirebaseToken';
const CHANNEL_METHOD_NEW_FCM_TOKEN = 'newTokenReceived';

const CHANNEL_METHOD_CREATE_NOTIFICATION = 'createNewNotification';

const CHANNEL_METHOD_NOTIFICATION_CREATED = 'notificationCreated';
const CHANNEL_METHOD_NOTIFICATION_DISPLAYED = 'notificationDisplayed';
const CHANNEL_METHOD_NOTIFICATION_DISMISSED = 'notificationDismissed';
const CHANNEL_METHOD_ACTION_RECEIVED = 'receivedAction';

const CHANNEL_METHOD_NOTIFICATION_AT_LAUNCH = 'notificationAtLaunch';

const CHANNEL_METHOD_LIST_ALL_SCHEDULES = 'listAllSchedules';

const CHANNEL_METHOD_GET_BADGE_COUNT = 'getBadgeCount';
const CHANNEL_METHOD_SET_BADGE_COUNT = 'setBadgeCount';
const CHANNEL_METHOD_INCREMENT_BADGE_COUNT = 'incBadgeCount';
const CHANNEL_METHOD_DECREMENT_BADGE_COUNT = 'decBadgeCount';
const CHANNEL_METHOD_RESET_BADGE = 'resetBadge';

const CHANNEL_METHOD_DISMISS_NOTIFICATION = 'dismissNotification';
const CHANNEL_METHOD_CANCEL_NOTIFICATION = 'cancelNotification';
const CHANNEL_METHOD_CANCEL_SCHEDULE = 'cancelSchedule';
const CHANNEL_METHOD_DISMISS_NOTIFICATIONS_BY_CHANNEL_KEY =
    'dismissNotificationsByChannelKey';
const CHANNEL_METHOD_CANCEL_NOTIFICATIONS_BY_CHANNEL_KEY =
    'cancelNotificationsByChannelKey';
const CHANNEL_METHOD_CANCEL_SCHEDULES_BY_CHANNEL_KEY =
    'cancelSchedulesByChannelKey';
const CHANNEL_METHOD_DISMISS_NOTIFICATIONS_BY_GROUP_KEY =
    'dismissNotificationsByGroupKey';
const CHANNEL_METHOD_CANCEL_NOTIFICATIONS_BY_GROUP_KEY =
    'cancelNotificationsByGroupKey';
const CHANNEL_METHOD_CANCEL_SCHEDULES_BY_GROUP_KEY =
    'cancelSchedulesByGroupKey';
const CHANNEL_METHOD_CHECK_PERMISSIONS = 'checkPermissions';
const CHANNEL_METHOD_SHOULD_SHOW_RATIONALE = 'shouldShowRationale';
const CHANNEL_METHOD_CANCEL_ALL_SCHEDULES = 'cancelAllSchedules';
const CHANNEL_METHOD_DISMISS_ALL_NOTIFICATIONS = 'dismissAllNotifications';
const CHANNEL_METHOD_CANCEL_ALL_NOTIFICATIONS = 'cancelAllNotifications';
const CHANNEL_METHOD_GET_NEXT_DATE = 'getNextDate';
const CHANNEL_FORCE_UPDATE = "forceUpdate";

const CHANNEL_METHOD_GET_UTC_TIMEZONE_IDENTIFIER = 'getUtcTimeZoneIdentifier';
const CHANNEL_METHOD_GET_LOCAL_TIMEZONE_IDENTIFIER =
    'getLocalTimeZoneIdentifier';

const CHANNEL_METHOD_START_FOREGROUND = 'startForeground';
const CHANNEL_METHOD_STOP_FOREGROUND = 'stopForeground';

const DRAWABLE_RESOURCE_REFERENCE = 'drawable';
const DEFAULT_ICON = 'defaultIcon';
const SELECT_NOTIFICATION = 'SELECT_NOTIFICATION';
const NOTIFICATION_BUTTON_ACTION_PREFIX = 'ACTION_NOTIFICATION';
const SCHEDULED_NOTIFICATIONS = 'scheduled_notifications';

const DATE_FORMAT = 'yyyy-MM-dd HH:mm:ss';

const INVALID_ICON_ERROR_CODE = 'INVALID_ICON';
const INVALID_LARGE_ICON_ERROR_CODE = 'INVALID_LARGE_ICON';
const INVALID_BIG_PICTURE_ERROR_CODE = 'INVALID_BIG_PICTURE';
const INVALID_SOUND_ERROR_CODE = 'INVALID_SOUND';
const INVALID_LED_DETAILS_ERROR_CODE = 'INVALID_LED_DETAILS';
const INVALID_LED_DETAILS_ERROR_MESSAGE =
    'Must specify both ledOnMs and ledOffMs to configure the blink cycle on older versions of Android before Oreo';
const INVALID_DRAWABLE_RESOURCE_ERROR_MESSAGE =
    'The resource %s could not be found. Please make sure it has been added as a drawable resource to your Android head project.';
const INVALID_RAW_RESOURCE_ERROR_MESSAGE =
    'The resource %s could not be found. Please make sure it has been added as a raw resource to your Android head project.';

const NOTIFICATION_SYSTEM_ID = 'id';
const NOTIFICATION_ICON_RESOURCE_ID = 'iconResourceId';

const NOTIFICATION_ID = 'id';
const NOTIFICATION_LAYOUT = 'notificationLayout';

const NOTIFICATION_DISPLAY_ON_FOREGROUND = 'displayOnForeground';
const NOTIFICATION_DISPLAY_ON_BACKGROUND = 'displayOnBackground';

const NOTIFICATION_CREATED_SOURCE = 'createdSource';
const NOTIFICATION_CREATED_LIFECYCLE = 'createdLifeCycle';
const NOTIFICATION_DISPLAYED_LIFECYCLE = 'displayedLifeCycle';
const NOTIFICATION_ACTION_LIFECYCLE = 'actionLifeCycle';
const NOTIFICATION_CREATED_DATE = 'createdDate';
const NOTIFICATION_DISPLAYED_DATE = 'displayedDate';
const NOTIFICATION_ACTION_DATE = 'actionDate';
const NOTIFICATION_DISMISSED_DATE = 'dismissedDate';
const NOTIFICATION_DISMISSED_LIFE_CYCLE = 'dismissedLifeCycle';

const NOTIFICATION_SCHEDULE_TIMEZONE = 'timeZone';
const NOTIFICATION_SCHEDULE_PRECISE_ALARM = 'preciseAlarm';
const NOTIFICATION_SCHEDULE_ERA = 'era';
const NOTIFICATION_SCHEDULE_YEAR = 'year';
const NOTIFICATION_SCHEDULE_MONTH = 'month';
const NOTIFICATION_SCHEDULE_DAY = 'day';
const NOTIFICATION_SCHEDULE_HOUR = 'hour';
const NOTIFICATION_SCHEDULE_MINUTE = 'minute';
const NOTIFICATION_SCHEDULE_SECOND = 'second';
const NOTIFICATION_SCHEDULE_MILLISECOND = 'millisecond';
const NOTIFICATION_SCHEDULE_WEEKDAY = 'weekday';
const NOTIFICATION_SCHEDULE_WEEKOFMONTH = 'weekOfMonth';
const NOTIFICATION_SCHEDULE_WEEKOFYEAR = 'weekOfYear';
const NOTIFICATION_SCHEDULE_INTERVAL = 'interval';
const NOTIFICATION_SCHEDULE_ALLOW_WHILE_IDLE = 'allowWhileIdle';
const NOTIFICATION_SCHEDULE_REPEATS = 'repeats';

const NOTIFICATION_CHANNEL_GROUP_KEY = 'channelGroupKey';
const NOTIFICATION_CHANNEL_GROUP_NAME = 'channelGroupName';

const NOTIFICATION_TITLE = 'title';
const NOTIFICATION_BODY = 'body';
const NOTIFICATION_SUMMARY = 'summary';
const NOTIFICATION_SHOW_WHEN = 'showWhen';
const NOTIFICATION_EXPANDABLE_BODY = 'expandableBody';
const NOTIFICATION_JSON = 'notificationJson';
const NOTIFICATION_PERMISSIONS = 'permissions';

const NOTIFICATION_ACTION_BUTTONS = 'actionButtons';
const NOTIFICATION_BUTTON_KEY = 'key';
const NOTIFICATION_BUTTON_LABEL = 'label';
const NOTIFICATION_BUTTON_KEY_PRESSED = 'buttonKeyPressed';
const NOTIFICATION_BUTTON_KEY_INPUT = 'buttonKeyInput';
const NOTIFICATION_BUTTON_INPUT = 'buttonKeyInput';
const NOTIFICATION_BUTTON_TYPE = 'buttonType';
const NOTIFICATION_ENABLED = "enabled";
const NOTIFICATION_IS_DANGEROUS_OPTION = "isDangerousOption";

const NOTIFICATION_PAYLOAD = 'payload';
const NOTIFICATION_INITIAL_FIXED_DATE = 'fixedDate';
const NOTIFICATION_INITIAL_DATE_TIME = 'initialDateTime';
const NOTIFICATION_EXPIRATION_DATE_TIME = 'expirationDateTime';
const NOTIFICATION_CRONTAB_EXPRESSION = 'crontabExpression';
const NOTIFICATION_PRECISE_SCHEDULES = 'preciseSchedules';
const NOTIFICATION_PLATFORM_CONFIGURATION = 'platformConfiguration';
const NOTIFICATION_PRIVATE_MESSAGE = "privateMessage";
const NOTIFICATION_DEFAULT_PRIVACY = "defaultPrivacy";
const NOTIFICATION_DEFAULT_RINGTONE_TYPE = "defaultRingtoneType";
const NOTIFICATION_PRIVACY = 'privacy';
const NOTIFICATION_CATEGORY = 'category';
const NOTIFICATION_AUTO_DISMISSIBLE = 'autoDismissible';
const NOTIFICATION_SHOW_IN_COMPACT_VIEW = 'showInCompactView';
const NOTIFICATION_LOCKED = 'locked';
const NOTIFICATION_ICON = 'icon';
const NOTIFICATION_WAKE_UP_SCREEN = 'wakeUpScreen';
const NOTIFICATION_FULL_SCREEN_INTENT = 'fullScreenIntent';
const NOTIFICATION_CRITICAL_ALERT = 'criticalAlert';
const NOTIFICATION_CHANNEL_CRITICAL_ALERTS = 'criticalAlerts';
const NOTIFICATION_PLAY_SOUND = 'playSound';
const NOTIFICATION_SOUND_SOURCE = 'soundSource';
const NOTIFICATION_ENABLE_VIBRATION = 'enableVibration';
const NOTIFICATION_VIBRATION_PATTERN = 'vibrationPattern';
const NOTIFICATION_GROUP_KEY = 'groupKey';
const NOTIFICATION_GROUP_SORT = 'groupSort';
const NOTIFICATION_GROUP_ALERT_BEHAVIOR = 'groupAlertBehavior';
const NOTIFICATION_ONLY_ALERT_ONCE = 'onlyAlertOnce';
const NOTIFICATION_CHANNEL_KEY = 'channelKey';
const NOTIFICATION_CHANNEL_NAME = 'channelName';
const NOTIFICATION_CHANNEL_DESCRIPTION = 'channelDescription';
const NOTIFICATION_CHANNEL_SHOW_BADGE = 'channelShowBadge';
const NOTIFICATION_IMPORTANCE = 'importance';
const NOTIFICATION_COLOR = 'color';
const NOTIFICATION_DEFAULT_COLOR = 'defaultColor';
const NOTIFICATION_BACKGROUND_COLOR = 'backgroundColor';
const NOTIFICATION_LARGE_ICON = 'largeIcon';
const NOTIFICATION_BIG_PICTURE = 'bigPicture';
const NOTIFICATION_CUSTOM_SOUND = 'customSound';
const NOTIFICATION_HIDE_LARGE_ICON_ON_EXPAND = 'hideLargeIconOnExpand';
const NOTIFICATION_SHOW_PROGRESS = 'showProgress';
const NOTIFICATION_MAX_PROGRESS = 'maxProgress';
const NOTIFICATION_PROGRESS = 'progress';
const NOTIFICATION_INDETERMINATE = 'indeterminate';
const NOTIFICATION_PERSON = 'person';
const NOTIFICATION_CONVERSATION_TITLE = 'conversationTitle';
const NOTIFICATION_GROUP_CONVERSATION = 'groupConversation';
const NOTIFICATION_MESSAGES = 'messages';
const NOTIFICATION_TEXT = 'text';
const NOTIFICATION_TIMESTAMP = 'timestamp';
const NOTIFICATION_BOT = 'bot';
const NOTIFICATION_IMPORTANT = 'important';
const NOTIFICATION_KEY = 'key';
const NOTIFICATION_NAME = 'name';
const NOTIFICATION_URI = 'uri';
const NOTIFICATION_DATA_MIME_TYPE = 'dataMimeType';
const NOTIFICATION_DATA_URI = 'dataUri';
const NOTIFICATION_CHANNEL_ACTION = 'channelAction';
const NOTIFICATION_ENABLE_LIGHTS = 'enableLights';
const NOTIFICATION_LED_COLOR = 'ledColor';
const NOTIFICATION_LED_ON_MS = 'ledOnMs';
const NOTIFICATION_LED_OFF_MS = 'ledOffMs';
const NOTIFICATION_TICKER = 'ticker';
const NOTIFICATION_ALLOW_WHILE_IDLE = 'allowWhileIdle';

class Definitions {
  static Map<String, Object?> initialValues = {
    NOTIFICATION_ID: 0,
    NOTIFICATION_GROUP_SORT: GroupSort.Desc,
    NOTIFICATION_GROUP_ALERT_BEHAVIOR: GroupAlertBehavior.All,
    NOTIFICATION_IMPORTANCE: NotificationImportance.Default,
    NOTIFICATION_LAYOUT: NotificationLayout.Default,
    NOTIFICATION_DEFAULT_PRIVACY: NotificationPrivacy.Private,
    NOTIFICATION_BUTTON_TYPE: ActionButtonType.Default,
    NOTIFICATION_PRIVACY: NotificationPrivacy.Private,
    NOTIFICATION_DEFAULT_RINGTONE_TYPE: DefaultRingtoneType.Notification,
    NOTIFICATION_CHANNEL_DESCRIPTION: 'Notifications',
    NOTIFICATION_CHANNEL_NAME: 'Notifications',
    NOTIFICATION_SHOW_WHEN: true,
    NOTIFICATION_CHANNEL_SHOW_BADGE: false,
    NOTIFICATION_ENABLED: true,
    NOTIFICATION_PAYLOAD: null,
    NOTIFICATION_ENABLE_VIBRATION: true,
    NOTIFICATION_COLOR: Colors.black,
    NOTIFICATION_LED_COLOR: Colors.white,
    NOTIFICATION_ENABLE_LIGHTS: true,
    NOTIFICATION_LED_OFF_MS: 700,
    NOTIFICATION_LED_ON_MS: 300,
    NOTIFICATION_PLAY_SOUND: true,
    NOTIFICATION_AUTO_DISMISSIBLE: true,
    NOTIFICATION_LOCKED: false,
    NOTIFICATION_TICKER: 'ticker',
    NOTIFICATION_ALLOW_WHILE_IDLE: false,
    NOTIFICATION_ONLY_ALERT_ONCE: false,
    NOTIFICATION_SHOW_IN_COMPACT_VIEW: true,
    NOTIFICATION_SCHEDULE_REPEATS: false,
    NOTIFICATION_BUTTON_KEY_PRESSED: '',
    NOTIFICATION_BUTTON_KEY_INPUT: '',
    NOTIFICATION_IS_DANGEROUS_OPTION: false,
    NOTIFICATION_WAKE_UP_SCREEN: false,
    NOTIFICATION_CRITICAL_ALERT: false,
    NOTIFICATION_CHANNEL_CRITICAL_ALERTS: false
  };
}
