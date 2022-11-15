---
title: 🏗 Notification Structures
# description: Quidem magni aut exercitationem maxime rerum eos.
---

## Content

{% callout type="warning" title="Required" %}
The `content` in push data is required
{% /callout %}

| Attribute                     | Required | Description                                                                                                                                          | Type                | Value Limits             | Default                 |
| ----------------------------- | -------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------- | ------------------------ | ----------------------- |
| id                            | YES      | Number that identifies a unique notification                                                                                                         | int                 | 1 - 2.147.483.647        |                         |
| channelKey                    | YES      | String key that identifies a channel where not. will be displayed                                                                                    | String              | channel must be enabled  | basic_channel           |
| title                         | NO       | The title of notification                                                                                                                            | String              | unlimited                |                         |
| body                          | NO       | The body content of notification                                                                                                                     | String              | unlimited                |                         |
| summary                       | NO       | A summary to be displayed when the content is protected by privacy                                                                                   | String              | unlimited                |                         |
| category                      | NO       | The notification category that best describes the nature of the notification for O.S.                                                                | Enumerator          | NotificationCategory     |                         |
| badge                         | NO       | Set a badge value over app icon                                                                                                                      | int                 | 0 - 999.999              |                         |
| showWhen                      | NO       | Hide/show the time elapsed since notification was displayed                                                                                          | bool                | true or false            | true                    |
| displayOnForeground           | NO       | Hide/show the notification if the app is in the Foreground (streams are preserved )                                                                  | bool                | true or false            | true                    |
| displayOnBackground           | NO       | Hide/show the notification if the app is in the Background (streams are preserved ). OBS: Only available for iOS with background special permissions | bool                | true or false            | true                    |
| icon                          | NO       | Small icon to be displayed on the top of notification (Android only)                                                                                 | String              | must be a resource image |                         |
| largeIcon                     | NO       | Large icon displayed at right middle of compact notification                                                                                         | String              | unlimited                |                         |
| bigPicture                    | NO       | Big image displayed on expanded notification                                                                                                         | String              | unlimited                |                         |
| autoDismissible               | NO       | Notification should auto dismiss when gets tapped by the user (has no effect for reply actions on Android)                                           | bool                | true or false            | true                    |
| color                         | NO       | Notification text color                                                                                                                              | Color               | 0x000000 to 0xFFFFFF     | 0x000000 (Colors.black) |
| backgroundColor               | NO       | Notification background color                                                                                                                        | Color               | 0x000000 to 0xFFFFFF     | 0xFFFFFF (Colors.white) |
| payload                       | NO       | Hidden payload content                                                                                                                               | Map<String, String> | Only String for values   | null                    |
| notificationLayout            | NO       | Layout type of notification                                                                                                                          | Enumerator          | NotificationLayout       | Default                 |
| hideLargeIconOnExpand         | NO       | Hide/show the large icon when notification gets expanded                                                                                             | bool                | true or false            | false                   |
| locked                        | NO       | Blocks the user to dismiss the notification                                                                                                          | bool                | true or false            | false                   |
| progress                      | NO       | Current value of progress bar (percentage). Null for indeterminate.                                                                                  | int                 | 0 - 100                  | null                    |
| ticker                        | NO       | Text to be displayed on top of the screen when a notification arrives                                                                                | String              | unlimited                |                         |
| actionType (Only for Android) | NO       | Notification action response type                                                                                                                    | Enumerator          | ActionType               | Default                 |

---

## Action Buttons

{% callout type="note" title="Optional" %}
The actionButtons in push data is optional
{% /callout %}

- Is necessary at least one \*required attribute

| Attribute         | Required | Description                                                                          | Type       | Value Limits             | Default |
| ----------------- | -------- | ------------------------------------------------------------------------------------ | ---------- | ------------------------ | ------- |
| key               | YES      | Text key to identifies what action the user took when tapped the notification        | String     | unlimited                |         |
| label             | \*YES    | Text to be displayed over the action button                                          | String     | unlimited                |         |
| icon              | \*YES    | Icon to be displayed inside the button                                               | String     | must be a resource image |         |
| color             | NO       | Label text color (only for Android)                                                  | Color      | 0x000000 to 0xFFFFFF     |         |
| enabled           | NO       | On Android, deactivates the button. On iOS, the button disappear                     | bool       | true or false            | true    |
| autoDismissible   | NO       | Notification should auto cancel when gets tapped by the user                         | bool       | true or false            | true    |
| showInCompactView | NO       | For MediaPlayer notifications on Android, sets the button as visible in compact view | bool       | true or false            | true    |
| isDangerousOption | NO       | Mark the button as a dangerous option, displaying the text in red                    | bool       | true or false            | false   |
| actionType        | NO       | Notification action response type                                                    | Enumerator | ActionType               | Default |

---

## Schedules

### Interval

_`schedule` in Push data is optional_

| Attribute      | Required | Description                                                                | Type          | Value Limits / Format                     | Default |
| -------------- | -------- | -------------------------------------------------------------------------- | ------------- | ----------------------------------------- | ------- |
| interval       | YES      | Time interval between each notification (minimum of 60 sec case repeating) | Int (seconds) | Positive unlimited                        |         |
| allowWhileIdle | NO       | Displays the notification, even when the device is low battery             | bool          | true or false                             | false   |
| repeats        | NO       | Defines if the notification should play only once or keeps repeating       | bool          | true or false                             | false   |
| timeZone       | NO       | Time zone identifier (ISO 8601)                                            | String        | "America/Sao_Paulo", "GMT-08:00" or "UTC" | "UTC"   |

---

### Calendar

_`schedule` in Push data is optional_

- Is necessary at least one \*required attribute
- If the calendar time condition is not defined, then any value is considered valid in the filtering process for the respective time component

| Attribute      | Required | Description                                                          | Type    | Value Limits / Format                     | Default |
| -------------- | -------- | -------------------------------------------------------------------- | ------- | ----------------------------------------- | ------- |
| era,           | \*YES    | Schedule era condition                                               | Integer | 0 - 99999                                 |         |
| year,          | \*YES    | Schedule year condition                                              | Integer | 0 - 99999                                 |         |
| month,         | \*YES    | Schedule month condition                                             | Integer | 1 - 12                                    |         |
| day,           | \*YES    | Schedule day condition                                               | Integer | 1 - 31                                    |         |
| hour,          | \*YES    | Schedule hour condition                                              | Integer | 0 - 23                                    |         |
| minute,        | \*YES    | Schedule minute condition                                            | Integer | 0 - 59                                    |         |
| second,        | \*YES    | Schedule second condition                                            | Integer | 0 - 59                                    |         |
| weekday,       | \*YES    | Schedule weekday condition                                           | Integer | 1 - 7                                     |         |
| weekOfMonth,   | \*YES    | Schedule weekOfMonth condition                                       | Integer | 1 - 6                                     |         |
| weekOfYear,    | \*YES    | Schedule weekOfYear condition                                        | Integer | 1 - 53                                    |         |
| allowWhileIdle | NO       | Displays the notification, even when the device is low battery       | bool    | true or false                             | false   |
| repeats        | NO       | Defines if the notification should play only once or keeps repeating | bool    | true or false                             | false   |
| timeZone       | NO       | Time zone identifier (ISO 8601)                                      | String  | "America/Sao_Paulo", "GMT-08:00" or "UTC" | "UTC"   |

---

### Crontab

{% callout type="note" title="Android" %}
Crontab is only available on Android
{% /callout %}

_`schedule` in Push data is optional_

- Is necessary at least one \*required attribute
- Cron expression must respect the format (with seconds precision) as described in [this article](https://www.baeldung.com/cron-expressions)

| Attribute          | Required | Description                                                          | Type   | Value Limits / Format                     | Default |
| ------------------ | -------- | -------------------------------------------------------------------- | ------ | ----------------------------------------- | ------- |
| initialDateTime    | NO       | Initial limit date of valid dates (does not fire any notification)   | String | YYYY-MM-DD hh:mm:ss                       |         |
| expirationDateTime | NO       | Final limit date of valid dates (does not fire any notification)     | String | YYYY-MM-DD hh:mm:ss                       |         |
| crontabExpression  | \*YES    | Crontab rule to generate new valid dates (with seconds precision)    | bool   | true or false                             | false   |
| preciseSchedules   | \*YES    | List of precise valid dates to fire                                  | bool   | true or false                             | false   |
| allowWhileIdle     | NO       | Displays the notification, even when the device is low battery       | bool   | true or false                             | false   |
| repeats            | NO       | Defines if the notification should play only once or keeps repeating | bool   | true or false                             | false   |
| timeZone           | NO       | Time zone identifier (ISO 8601)                                      | String | "America/Sao_Paulo", "GMT-08:00" or "UTC" | "UTC"   |
