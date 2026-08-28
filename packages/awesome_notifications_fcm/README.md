# 🔔 awesome_notifications_fcm

Firebase Cloud Messaging (push) for [awesome_notifications](https://pub.dev/packages/awesome_notifications).

[![pub package](https://img.shields.io/pub/v/awesome_notifications_fcm.svg)](https://pub.dev/packages/awesome_notifications_fcm)
![Full tests workflow](https://github.com/rafaelsetragni/awesome_notifications/actions/workflows/dart.yml/badge.svg?branch=master)
![codecov badge](https://codecov.io/gh/rafaelsetragni/awesome_notifications/branch/master/graph/badge.svg?flag=awesome_notifications_fcm)

Receive Firebase pushes and **display them through the awesome_notifications
engine** — same channels, layouts, action buttons, images and lifecycle events
as a local notification. The plugin is a *preprocessor*: it turns an incoming
Firebase message into a core notification and hands it to `createNotification`
natively, so `onNotificationCreated` / `onActionReceived` fire exactly as they do
for local notifications. The core stays push‑agnostic.

## Features

- **FCM & native (APNs) token** events + on‑demand token retrieval.
- **Silent (data‑only) messages**, handled even while the app is terminated (in a
  dedicated background Dart isolate).
- **Server‑driven notifications**: a push can carry a full awesome payload
  (`content` / `actionButtons` / `schedule` / `localizations`), as structured
  JSON strings or dot‑flattened keys, merged over the standard FCM notification
  block.
- **Topic** subscribe / unsubscribe and token deletion.

## Getting started

```yaml
dependencies:
  awesome_notifications: ^1.0.0
  awesome_notifications_fcm: ^1.0.0
  firebase_core: ^4.4.0
```

Firebase is required. Add your Firebase config and enable push:

- **Android** — add `android/app/google-services.json` and apply the
  `com.google.gms.google-services` Gradle plugin in your app.
- **iOS** — add `GoogleService-Info.plist`, and enable the **Push Notifications**
  and **Background Modes → Remote notifications** capabilities. Requires iOS 15+.

## Usage

The handlers **must be top‑level or static functions** so the background isolate
can resolve them while the app is terminated.

```dart
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:awesome_notifications_fcm/awesome_notifications_fcm.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> onFcmToken(String token) async => print('FCM token: $token');

@pragma('vm:entry-point')
Future<void> onSilentData(FcmSilentData silent) async {
  print('Silent push: ${silent.data} (source ${silent.createdSource})');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  await AwesomeNotifications().initialize(null, [
    NotificationChannel(
      channelKey: 'push',
      channelName: 'Push',
      channelDescription: 'Firebase notifications',
    ),
  ]);

  await AwesomeNotificationsFcm().initialize(
    onFcmTokenHandle: onFcmToken,
    onFcmSilentDataHandle: onSilentData,
    debug: true,
  );

  runApp(const MyApp());
}
```

### Token, topics and availability

```dart
final fcm = AwesomeNotificationsFcm();

final available = await fcm.isFirebaseAvailable;
final token     = await fcm.requestFirebaseAppToken();

await fcm.subscribeToTopic('news');
await fcm.unsubscribeToTopic('news');
await fcm.deleteToken();
```

### Sending a notification from your server

Send an FCM **data** message whose keys hold the awesome payload. The `content`
section is required to display; `actionButtons` / `schedule` / `localizations`
are optional.

```json
{
  "data": {
    "content": "{\"id\":1,\"channelKey\":\"push\",\"title\":\"Hello\",\"body\":\"From the server\"}",
    "actionButtons": "[{\"key\":\"OPEN\",\"label\":\"Open\"}]"
  }
}
```

A data message **without** displayable content is delivered to
`onFcmSilentDataHandle` instead.

## How it works

| Layer | Role |
|---|---|
| Dart | Thin channel facade + the background‑isolate entry point for silent data. |
| Android | A `FirebaseMessagingService` parses each push and posts it through the Flutter‑free core engine (no Flutter engine required — works while terminated). |
| iOS | The plugin forwards APNs/FCM pushes to the shared `IosAwnCore` engine; silent data runs in a headless engine. |

> **Scope:** iOS Notification Service Extension (rich media on the lock screen)
> and remote‑control keys (server‑triggered dismiss/cancel) are planned in a
> follow‑up.
