---
title: 📅 Scheduling a Notification
# description: Quidem magni aut exercitationem maxime rerum eos.
---

Schedules could be created from a UTC or local time zone, and specifying a time interval or setting a calendar filter. Notifications could be scheduled even remotely.
Attention: for iOS, is not possible to define the correct `displayedDate`, because is not possible to run exactly at same time with the notification schedules when it arrives in the user status bar.

To send notifications schedules, you need to instantiate one of the classes bellow in the notification property 'schedule':

- **NotificationCalendar:** Creates a notification scheduled to be displayed when the set date components matches the current date. If a time component is set to null, so any value is considered valid to produce the next valid date. Only one value is allowed by each component.
- **NotificationInterval:** Creates a notification scheduled to be displayed at each interval time, starting from the next valid interval.
- **NotificationAndroidCrontab:** Creates a notification scheduled to be displayed based on a list of precise dates or a crontab rule, with seconds precision. To know more about how to create a valid crontab rule, take a look at [this article](https://www.baeldung.com/cron-expressions).

Also, all of then could be configured using:

- **timeZone:** describe which time zone that schedule is based (valid examples: America/Sao_Paulo, America/Los_Angeles, GMT+01:00, Europe/London, UTC)
- **allowWhileIdle:** Determines if notification will send, even when the device is in critical situation, such as low battery.
- **repeats:** Determines if the schedule should be repeat after be displayed. If there is no more valid date compatible with the schedule rules, the notification is automatically canceled.

For time zones, please note that:

- Dates with UTC time zones are triggered at the same time in all parts of the planet and are not affected by daylight rules.
- Dates with local time zones, defined such "GMT-07: 00", are not affected by daylight rules.
- Dates with local time zones, defined such "Europe / Lisbon", are affected by daylight rules, especially when scheduled based on a calendar filter.

Here are some practical examples of how to create a notification scheduled:

```dart
String localTimeZone = await AwesomeNotifications().getLocalTimeZoneIdentifier();
String utcTimeZone = await AwesomeNotifications().getLocalTimeZoneIdentifier();

await AwesomeNotifications().createNotification(
  content: NotificationContent(
    id: id,
    channelKey: 'scheduled',
    title: 'Notification at every single minute',
    body: 'This notification was schedule to repeat at every single minute.',
    notificationLayout: NotificationLayout.BigPicture,
    bigPicture: 'asset://assets/images/melted-clock.png',
  ),
  schedule: NotificationInterval(interval: 60, timeZone: localTimeZone, repeats: true),
);
```

```dart
await AwesomeNotifications().createNotification(
  content: NotificationContent(
    id: id,
    channelKey: 'scheduled',
    title: 'wait 5 seconds to show',
    body: 'now is 5 seconds later',
    wakeUpScreen: true,
    category: NotificationCategory.Alarm,
  ),
  schedule: NotificationInterval(
    interval: 5,
    timeZone: localTimeZone,
    preciseAlarm: true,
    timezone: await AwesomeNotifications().getLocalTimeZoneIdentifier()
  ),
);
```

```dart
await AwesomeNotifications().createNotification(
  content: NotificationContent(
    id: id,
    channelKey: 'scheduled',
    title: 'Notification at exactly every single minute',
    body: 'This notification was schedule to repeat at every single minute at clock.',
    notificationLayout: NotificationLayout.BigPicture,
    bigPicture: 'asset://assets/images/melted-clock.png'.
  ),
  schedule: NotificationCalendar(second: 0, timeZone: localTimeZone, repeats: true));
```

```dart
await AwesomeNotifications().createNotification(
  content: NotificationContent(
    id: id,
    channelKey: 'scheduled',
    title: 'Just in time!',
    body: 'This notification was schedule to shows at ' +
        (Utils.DateUtils.parseDateToString(scheduleTime.toLocal()) ?? '?') +
        ' $timeZoneIdentifier (' +
        (Utils.DateUtils.parseDateToString(scheduleTime.toUtc()) ?? '?') +
        ' utc)',
    wakeUpScreen: true,
    category: NotificationCategory.Reminder,
    notificationLayout: NotificationLayout.BigPicture,
    bigPicture: 'asset://assets/images/delivery.jpeg',
    payload: {'uuid': 'uuid-test'},
    autoDismissible: false,
  ),
  schedule: NotificationCalendar.fromDate(date: scheduleTime));
```

---

## ⏰ Schedule Precision

It's important to keep in mind that some Android distributions could ignore or delay the schedule execution, if their algorithms judge it necessary to save the battery life, etc, and this intervention is even more common for repeating schedules. Im most cases this behavior is recommended, since as a battery-hungry app can denigrate the app and the manufacturer's image. Therefore, you need to consider this fact in your business logic.

But, for some cases where the schedules precision is a MUST requirement, you can use some features to ensure the execution in the correct time:

- Set the notification's category to a critical category, such as Alarm, Reminder or Call.
- Set the `preciseAlarm` property to true. For Android versions greater or equal than 12, you need to explicitly request the user consent to enable this feature. You can request the permission with `requestPermissionToSendNotifications` or take the user to the permission page calling `showAlarmPage`.
- Set `criticalAlerts` channel property and notification content property to true. This feature allows you to show notification and play sounds even when the device is on silent / Do not Disturb mode. Because of it, this feature is considered highly sensitive and you must request Apple a special authorization to use it. On Android, for versions greater or equal than 11, you need to explicitly request the user consent to enable this feature. You can request the permission with `requestPermissionToSendNotifications`.

To enable precise alarms, you need to add the `SCHEDULE_EXACT_ALARM` permission into your `AndroidManifest.xml` file, inside the `Android/app/src/main/` folder

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
   package="com.example">
   <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
   <application>
       ...
   </application>
</manifest>
```

To enable critical alerts, you need to add the `ACCESS_NOTIFICATION_POLICY` permission into your `AndroidManifest.xml` file, inside the `Android/app/src/main/` folder

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
   package="com.example">
   <uses-permission android:name="android.permission.ACCESS_NOTIFICATION_POLICY"/>
   <application>
       ...
   </application>
</manifest>
```

For iOS, you must submit a request authorization to Apple to enable it, as described [in this post](https://medium.com/@shashidharyamsani/implementing-ios-critical-alerts-7d82b4bb5026).

---

## 📝 Important Notes:

1. Schedules may be severaly delayed or denied if the device/application is in battery saver mode or locked to perform background tasks. Teach your users with a good rationale to not set these modes and tell them the consequences of doing so. Some battery saving modes may differ between manufacturers, for example Samsung and Xiaomi (the last one sets the battery saving mode automatically for each new app installed).
2. If you're running your app in debug mode, right after close it all schedules may be erased by Android OS. Thats happen to ensure the same execution in debug mode for each debug startup. To make schedule tests on Android while terminated, remember to open your app without debug it.
3. If your app doesn't need to be as accurate to display schedule notifications, don't request for exact notifications. Be reasonable.
4. Remember to categorize your notifications correctly to avoid scheduling delays.
5. Critical alerts are still under development and should not be used in production mode.

---

## Old schedule Cron (pre 0.0.6)

Due to the way that background task and notification schedules works on iOS, wasn't possible yet to enable officially all the old Cron features on iOS while the app is in Background and even when the app is terminated (Killed).
Thanks to this, the complex schedules based on cron tab rules are only available on Android by the class `NotificationAndroidCrontab`.

A support ticket was opened for Apple in order to resolve this issue, but they don't even care about. You can follow the progress of the process [here](https://github.com/rafaelsetragni/awesome_notifications/issues/16).
