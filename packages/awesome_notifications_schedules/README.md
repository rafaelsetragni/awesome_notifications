# ⏰ awesome_notifications_schedules

Notification scheduling for [awesome_notifications](https://pub.dev/packages/awesome_notifications).

[![pub package](https://img.shields.io/pub/v/awesome_notifications_schedules.svg)](https://pub.dev/packages/awesome_notifications_schedules)
![Full tests workflow](https://github.com/rafaelsetragni/awesome_notifications/actions/workflows/dart.yml/badge.svg?branch=master)
![codecov badge](https://codecov.io/gh/rafaelsetragni/awesome_notifications/branch/master/graph/badge.svg?flag=awesome_notifications_schedules)

Deliver notifications later — by a time interval or a calendar date, once or
repeating. Scheduling is attached to a normal `createNotification` call through
the `extensions:` slot; the native decorator (installed automatically by this
package) intercepts the build and registers the delayed delivery. The core stays
scheduling‑agnostic.

## Getting started

Add both the core and this decorator to your `pubspec.yaml`:

```yaml
dependencies:
  awesome_notifications: ^0.10.0
  awesome_notifications_schedules: ^0.10.0
```

## Usage

Schedule by passing a `NotificationInterval` or `NotificationCalendar` as an
extension to the core's `createNotification`:

```dart
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:awesome_notifications_schedules/awesome_notifications_schedules.dart';

// Fire in 10 seconds.
await AwesomeNotifications().createNotification(
  content: NotificationContent(id: 1, channelKey: 'basic', title: 'Hi'),
  extensions: [
    NotificationInterval(interval: const Duration(seconds: 10), allowWhileIdle: true),
  ],
);

// Fire every day at 09:00.
await AwesomeNotifications().createNotification(
  content: NotificationContent(id: 2, channelKey: 'basic', title: 'Daily'),
  extensions: [
    NotificationCalendar(hour: 9, minute: 0, second: 0, repeats: true),
  ],
);
```

Manage pending schedules through `AwesomeNotificationsSchedules()`:

```dart
final schedules = AwesomeNotificationsSchedules();

await schedules.getNextDate(NotificationCalendar(hour: 9)); // preview next fire
await schedules.listScheduledNotifications();
await schedules.cancelSchedule(1);
await schedules.cancelAllSchedules();
```

See the `example/` app for a runnable, single‑file demo.
