# 🔔 awesome_notifications_fcm

![Awesome Notifications](https://raw.githubusercontent.com/rafaelsetragni/awesome_notifications/30bf59533a2d324f2de0ded285511bef6ede2e98/assets/readme/awesome-notifications-banner.jpg)

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
  awesome_notifications: ^1.0.0-dev.1
  awesome_notifications_fcm: ^1.0.0-dev.1
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

Push works on Android, iOS and macOS. On the other platforms the same calls
are safe: they answer "unavailable" (`false`, an empty token) instead of
throwing, so one code base runs everywhere. Use
`AwesomeNotificationsFcm.isPlatformSupported` to adapt the UI.

## Platform support

| Feature | Android | iOS | macOS | Windows | Linux | Web |
|---|:-:|:-:|:-:|:-:|:-:|:-:|
| FCM and native token | ✅ | ✅ (APNs) | ✅ (APNs) | ⏳ (WNS) | ⏳ (UnifiedPush) | ⏳ |
| Displayed push (images, buttons, events) | ✅ | ✅ | ✅ | ⏳ | ⏳ | ⏳ |
| Silent data, app running | ✅ | ✅ | ✅ | ⏳ | ⏳ | ⏳ |
| Silent data, app in background or terminated | ✅ | ✅ | ❌ | ⏳ | ⏳ | ❌ |
| Topics | ✅ | ✅ | ✅ | ⏳ | ⏳ | ⏳ |

✅ supported · 🧪 preview (implemented, still being validated against the 0.12 behavior) · ⏳ planned · ❌ not possible on this platform

- **macOS:**
  - macOS never launches a terminated app for a push, and there is no
    background Dart isolate there. So silent data only reaches a running app.
    Displayed pushes are shown in every state.
  - Enable the *Push Notifications* capability and keep
    `com.apple.security.network.client` in the entitlements. Add
    `macos/Runner/GoogleService-Info.plist`.
  - If the user once denied notifications, macOS never asks again: the
    permission request answers false right away until the user enables it in
    *System Settings → Notifications*.
- **Web (planned):** browsers require every push to show a notification, so
  silent data in the background is not possible there.
- **Windows and Linux (planned):** push will come through each platform's own
  service (WNS, UnifiedPush) behind this same API.

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

The sections can also be sent dot‑flattened (`"content.title": "Hello"`,
`"actionButtons.0.key": "OPEN"`); `"true"` / `"false"` become booleans and
`"null"` drops the key. Platform‑specific overrides go under `Android` / `iOS`
with the same shape (`{"content": {…}, "actionButtons": […]}`).

A data message **without** displayable content is delivered to
`onFcmSilentDataHandle` instead.

> **Keep it data‑only.** Don't add an FCM `notification` block (or an APNs
> `alert`): with the app in background or terminated, the Firebase SDK on
> Android and the OS on iOS display it themselves, without images, buttons or
> layouts, and the plugin never sees it. On iOS, send the message as a
> background push so the plugin can build it:
>
> ```json
> "apns": {
>   "headers": { "apns-push-type": "background", "apns-priority": "5" },
>   "payload": { "aps": { "content-available": 1 } }
> }
> ```
>
> iOS throttles background pushes and does not deliver them to an app the user
> force‑quit; rich pushes that survive that need the Notification Service
> Extension (planned, see Scope below).

### Trying it with Postman

[`example/postman/awesome_notifications_fcm.postman_collection.json`](example/postman/awesome_notifications_fcm.postman_collection.json)
has ready pushes (flattened and stringified payloads, localizations, platform
overrides and silent data) for the example app. Set `project_id`,
`bearer_token` (an OAuth2 access token with the `firebase.messaging` scope) and
`fcm_token` (printed by the example app). Its images are pinned to a commit of
this repository, so they don't expire.

## How it works

| Layer | Role |
|---|---|
| Dart | Thin channel facade + the background‑isolate entry point for silent data. |
| Android | A `FirebaseMessagingService` parses each push and posts it through the Flutter‑free core engine (no Flutter engine required — works while terminated). |
| iOS | The plugin forwards APNs/FCM pushes to the shared `IosAwnCore` engine; silent data runs in a headless engine. |
| macOS | Same engine and parser as iOS. The plugin hooks the app delegate's APNs callbacks (FlutterMacOS does not forward them), and silent data goes to the running engine. |

> **Scope:** iOS Notification Service Extension (rich media on the lock screen)
> and remote‑control keys (server‑triggered dismiss/cancel) are planned in a
> follow‑up.
