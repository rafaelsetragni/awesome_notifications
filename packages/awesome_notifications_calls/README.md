# 📞 awesome_notifications_calls

![Awesome Notifications](https://raw.githubusercontent.com/rafaelsetragni/awesome_notifications/30bf59533a2d324f2de0ded285511bef6ede2e98/assets/readme/awesome-notifications-banner.jpg)

The system's own call screen for your app's calls, on **Android, iOS, macOS, Windows,
Linux and the Web**, from one model.

[![pub package](https://img.shields.io/pub/v/awesome_notifications_calls.svg)](https://pub.dev/packages/awesome_notifications_calls)
![Full tests workflow](https://github.com/rafaelsetragni/awesome_notifications/actions/workflows/dart.yml/badge.svg?branch=master)
![codecov badge](https://codecov.io/gh/rafaelsetragni/awesome_notifications/branch/master/graph/badge.svg?flag=awesome_notifications_calls)

**The package doesn't carry the call:** your audio / video stack (WebRTC, agora,
livekit, SIP, your own) connects it; this package shows the call where the system shows
calls and sends the user's answers back to your app.

<br>

### **Key Features:**

* **The system's call UI on mobile:** Android's call notification (CallStyle) that rings
  over the lock screen, iOS CallKit (the native incoming call screen, Recents, the
  in-call indicator).
* **Calls that ring with the app killed:** a high-priority FCM data push on Android, a
  VoIP push (PushKit) on iOS, reported to CallKit natively before any Dart runs.
* **Headsets, cars and watches** answer and hang up through Android Telecom and CallKit.
* **The strongest call notification on desktop and Web:** a ringing `incomingCall` toast
  on Windows, a critical resident notification on Linux, a time-sensitive notification
  on macOS, a notification that stays on screen on the Web.
* **Answers where you want them:** in `onActionReceivedMethod` (also with the app
  killed), in a stream, or both.
* **Ring timeout and missed calls** handled for you.

<br>

# 📙 Table of Contents

- [📱 Platform support](#-platform-support)
- [🛠 Getting started](#-getting-started)
  - [🤖 Configuring Android](#-configuring-android)
  - [🍎 Configuring iOS](#-configuring-ios)
  - [🖥 Configuring macOS](#-configuring-macos)
  - [🪟 Windows, 🐧 Linux and 🌐 Web](#-windows--linux-and--web)
- [📞 Showing a call](#-showing-a-call)
  - [The moments of a call](#the-moments-of-a-call)
  - [Receiving the answers](#receiving-the-answers)
  - [Ending a call](#ending-a-call)
  - [Missed calls](#missed-calls)
- [📨 Calls by push](#-calls-by-push)
- [🔍 How it works on each platform](#-how-it-works-on-each-platform)
- [🏗 Model reference](#-model-reference)
- [🩺 Troubleshooting](#-troubleshooting)

<br>
<br>

# 📱 Platform support

| Feature | Android | iOS | macOS | Windows | Linux | Web |
|---|:-:|:-:|:-:|:-:|:-:|:-:|
| System call UI | ✅ CallStyle | ✅ CallKit | ❌ | ❌ | ❌ | ❌ |
| Incoming call notification | ✅ | ✅ (`systemCallUI: false`) | ✅ | 🧪 `incomingCall` toast | ✅ | ✅ (no buttons, see [Web](#-windows--linux-and--web)) |
| Rings over the lock screen | ✅ full-screen intent | ✅ | ❌ | ❌ | ❌ | ❌ |
| Ongoing call with timer | ✅ | ✅ | ❌ (Hang up only) | ❌ (Hang up only) | ❌ (Hang up only) | ❌ |
| Mute / hold from the system | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| Bluetooth / car / watch | ✅ Telecom | ✅ CallKit | ❌ | ❌ | ❌ | ❌ |
| Rings with the app killed | ✅ FCM | ✅ VoIP push | ❌ | ❌ | ❌ | ❌ |
| Outgoing calls | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Ring timeout + missed call | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |

✅ supported · 🧪 preview (implemented, still being validated) · ❌ not possible on this platform

Use `AwesomeNotificationsCalls().capabilities()` to adapt your UI to the current
platform.

<br>
<br>

# 🛠 Getting started

1. Add the core and this package to your `pubspec.yaml`:

```yaml
dependencies:
  awesome_notifications: ^1.0.0-dev.1        # the core
  awesome_notifications_calls: ^1.0.0-dev.1  # this package (same version line as the core)
```

2. Get the packages:

```bash
flutter pub get
```

3. Create a channel for the calls. On Android it rings with the phone's ringtone:

```dart
NotificationChannel(
  channelKey: 'calls',
  channelName: 'Calls',
  channelDescription: 'Incoming and ongoing calls',
  importance: NotificationImportance.Max,
  defaultRingtoneType: DefaultRingtoneType.Ringtone,
)
```

<br>

## 🤖 Configuring Android

Declare in `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.USE_FULL_SCREEN_INTENT" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_PHONE_CALL" />
<uses-permission android:name="android.permission.MANAGE_OWN_CALLS" />
```

- **`USE_FULL_SCREEN_INTENT`** rings over the lock screen. From Android 14 the user can
  turn it off (it is granted only to calling and alarm apps): check it with
  `canUseFullScreenIntent()` and open the system page with `requestFullScreenIntent()`.
  Without it, the call is a heads-up notification.
- **`FOREGROUND_SERVICE` and `FOREGROUND_SERVICE_PHONE_CALL`** keep the call alive while
  it lasts (a `phoneCall` foreground service). Android 12+ shows the ongoing call style
  only with that service; without it, an ongoing call is a regular notification with
  buttons.
- **`MANAGE_OWN_CALLS`** registers the call with Android Telecom: Bluetooth headsets,
  cars and watches can answer and hang up, and the system routes the audio. Android 14+
  also needs it for the `phoneCall` service type.
- The Telecom library adds `BLUETOOTH_CONNECT` and `MODIFY_AUDIO_SETTINGS` to your
  manifest. If you don't route the call's audio yourself, you can remove them:
  `<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" tools:node="remove" />`.

The call screen over the lock screen is your app's own activity: the package turns on
`showWhenLocked` / `turnScreenOn` while a call is shown and turns them off afterwards.
Nothing to add for it.

<br>

## 🍎 Configuring iOS

**1. Background modes.** In Xcode, **Runner** target → **Signing & Capabilities** →
**+ Capability** → **Background Modes**, check **Voice over IP** and **Audio, AirPlay,
and Picture in Picture**. Xcode adds to `ios/Runner/Info.plist`:

```xml
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
    <string>voip</string>
</array>
```

**2. Push Notifications** capability (for VoIP pushes), and **Time Sensitive
Notifications** if you use `systemCallUI: false`.

**3. Start the calls package at launch,** in `ios/Runner/AppDelegate.swift`. A VoIP push
can launch your app in the background, before Flutter registers its plugins, and iOS
terminates an app that doesn't report each VoIP push to CallKit at once:

```swift
import awesome_notifications_calls

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    AwesomeNotificationsCallsPlugin.registerAtLaunch()
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

**4. Start the call's audio only in `audioActivated`.** CallKit owns the audio session
of a call: configure it, and start your media, when the `audioActivated` command
arrives (see [Receiving the answers](#receiving-the-answers)).

> **China:** CallKit isn't allowed in apps on the China App Store. Send those builds'
> calls with `systemCallUI: false`: the call becomes a time-sensitive notification with
> Accept / Decline. VoIP pushes always go through CallKit, so use regular pushes there.

<br>

## 🖥 Configuring macOS

Nothing required. CallKit isn't available to macOS apps: a call is a time-sensitive
notification with Accept / Decline, then Hang up. Add the **Time Sensitive
Notifications** capability so it breaks through Focus.

<br>

## 🪟 Windows, 🐧 Linux and 🌐 Web

Nothing to configure.

- **Windows:** the incoming call is a toast with the `incomingCall` scenario: it stays on
  screen and rings in a loop until answered.
- **Linux:** a notification with critical urgency that stays (resident), with the
  `phone-incoming-call` sound. GNOME and KDE honor both; other notification servers vary.
- **Web:** a notification that stays on screen (`requireInteraction`, Chrome and Edge).
  Browsers allow buttons only on service-worker notifications, which the core doesn't
  have yet: a click on the notification brings your page to the front, and you answer
  from the page.

On desktop and Web the call exists only while the app (or page) runs.

<br>
<br>

# 📞 Showing a call

A call is a regular `createNotification` with a `NotificationCall` in `extensions`:

```dart
await AwesomeNotifications().createNotification(
  content: NotificationContent(id: 300, channelKey: 'calls'),
  extensions: [
    NotificationCall(
      callId: 'c-2026-001',
      caller: const NotificationPerson(
        key: 'ana',
        name: 'Ana',
        avatar: 'https://example.com/ana.jpg',
      ),
      handle: 'tel:+5511999999999',
      video: false,
      state: CallState.incoming,
    ),
  ],
);
```

`NotificationPerson` is the core's model, the same one the chat package uses.

<br>

## The moments of a call

Send the call again, with the **same notification id and `callId`**, on every change:

| State | What the system shows |
|---|---|
| `incoming` | Rings: the call screen / notification, over the lock screen where possible. Starts the ring timeout. |
| `outgoing` | A call the user started in the app, not answered yet ("Calling…"). |
| `ongoing` | In progress, with a timer from `startedAt`. |
| `held` | In progress, on hold. |
| `ended` | Over: the system call ends and its notification goes away. |
| `missed` | Not answered: the call ends and the [missed call notification](#missed-calls) is shown. |

```dart
// The other side answered your outgoing call:
await AwesomeNotifications().createNotification(
  content: NotificationContent(id: 300, channelKey: 'calls'),
  extensions: [
    NotificationCall(
      callId: 'c-2026-001',
      caller: ana,
      state: CallState.ongoing,
      startedAt: DateTime.now(),
    ),
  ],
);
```

<br>

## Receiving the answers

The package applies each answer to the system call **first** (so the call screen reacts
at once), then tells your app:

| Action | When | The system call is already… |
|---|---|---|
| `accept` | the user answered | ongoing: connect the call, then send it as `ongoing` with `startedAt` |
| `decline` | the user refused a ringing call | over |
| `hangUp` | the user ended the call | over |
| `mute` / `unmute` | from the system UI | toggled |
| `hold` / `unhold` | from the system UI | toggled |
| `timeout` | the ring timed out | over, missed |
| `audioActivated` / `audioDeactivated` | iOS: CallKit activated / deactivated the call's audio session | — |

Each call chooses where its answers go with `commandTarget`:

```dart
@pragma('vm:entry-point')
Future<void> onActionReceivedMethod(ReceivedAction action) async {
  final command = AwesomeNotificationsCalls.commandOf(action);
  if (command == null) return; // not a call answer
  switch (command.action) {
    case CallAction.accept:
      await myCallService.connect(command.callId);
    case CallAction.decline:
    case CallAction.hangUp:
      await myCallService.hangUp(command.callId);
    default:
      break;
  }
}
```

- **`CallCommandTarget.actionEvent`** (default): the core's action event, as above. It
  reaches your app also when it was killed (Android: in the background isolate; Answer
  opens the app).
- **`CallCommandTarget.stream`**: only while the app runs:

```dart
AwesomeNotificationsCalls().commands.listen((command) { /* ... */ });
```

- **`CallCommandTarget.both`**: both.

A tap on the call's notification (not on a button) is a regular action: read its call
with `AwesomeNotificationsCalls.callIdOf(action)`.

<br>

## Ending a call

```dart
await AwesomeNotificationsCalls().endCall('c-2026-001',
    reason: CallEndReason.remoteEnded);
```

| Reason | Use when | CallKit |
|---|---|---|
| `remoteEnded` | the other side hung up | `remoteEnded` |
| `declinedElsewhere` | declined on another of the user's devices | `declinedElsewhere` |
| `answeredElsewhere` | answered on another of the user's devices | `answeredElsewhere` |
| `unanswered` | the caller gave up before an answer (shows the missed call) | `unanswered` |
| `failed` | the call could not be connected | `failed` |

Cancelling or dismissing the call's notification with the core (`cancel`, `dismiss`,
`cancelAll`…) also ends the call. `activeCalls()` lists the calls the system shows now.

<br>

## Missed calls

When a ringing call times out (`ringTimeout`, 60 s by default), is sent as `missed`, or
is ended with `CallEndReason.unanswered`, the package shows a missed call notification
on the same channel: the caller's name (or `groupName`), "Missed call" and the caller's
avatar. Its id is the same on every platform, derived from the `callId`. Turn it off
with `missedNotification: false`.

The words the package shows where the system has none of its own (desktop, Web, the
missed call, Android's extra buttons) are in `CallTexts`:

```dart
NotificationCall(
  // ...
  texts: const CallTexts(
    incoming: 'Chamada recebida',
    missed: 'Chamada perdida',
    accept: 'Atender',
    decline: 'Recusar',
    hangUp: 'Desligar',
  ),
)
```

<br>
<br>

# 📨 Calls by push

A call must ring with the app killed, so it comes by push.

### Android: FCM

With `awesome_notifications_fcm` installed, send a **data-only, high-priority** message
with `content` and `call` (the [model's keys](#-model-reference)) as JSON strings:

```json
{
  "message": {
    "token": "<the device's FCM token>",
    "android": { "priority": "high" },
    "data": {
      "content": "{\"id\": 300, \"channelKey\": \"calls\"}",
      "call": "{\"callId\": \"c-2026-001\", \"caller\": {\"key\": \"ana\", \"name\": \"Ana\", \"avatar\": \"https://example.com/ana.jpg\"}, \"handle\": \"tel:+5511999999999\", \"state\": \"incoming\", \"video\": false}"
    }
  }
}
```

No top-level `notification` block: the Firebase SDK would show it by itself, without the
call. Send `ended` the same way when the caller gives up.

### iOS: VoIP push (PushKit)

FCM can't send VoIP pushes: send them to APNs directly, to the token from
`AwesomeNotificationsCalls().voipToken()` (and `onVoipToken` when it changes):

```
apns-push-type: voip
apns-topic: <your bundle id>.voip
apns-priority: 10
apns-expiration: 0
```

```json
{
  "content": { "id": 300, "channelKey": "calls" },
  "call": {
    "callId": "c-2026-001",
    "caller": { "key": "ana", "name": "Ana", "uri": "tel:+5511999999999" },
    "state": "incoming",
    "video": false
  }
}
```

- The package reports **every** VoIP push to CallKit at once, as iOS requires: a push
  without a valid `call` still rings for an instant and ends as failed. Don't use VoIP
  pushes for anything but incoming calls.
- To stop a ringing call (the caller gave up, answered elsewhere), send a regular push
  or call `endCall` when your app hears it; a VoIP push with `ended` rings first.
- The APNs key needs the VoIP service enabled.
- The iOS simulator doesn't receive VoIP pushes and has no CallKit call screen: test on
  a device.

<br>
<br>

# 🔍 How it works on each platform

**Android**
- **Incoming:** a CallStyle notification (Answer / Decline, the caller's photo), with
  the full-screen intent over the lock screen, ringing with the channel's sound in a
  loop until answered.
- **Ongoing:** CallStyle with Hang up and the timer, kept alive by the `phoneCall`
  foreground service. CallStyle shows one button besides Hang up: Mute, or Resume while
  on hold.
- **Telecom:** core-telecom on Android 8+, with the platform's own call management on
  14+. Bluetooth, car and watch answers arrive as the same commands.
- **Ring timeout:** a timer while the app runs, plus an alarm that fires even if the
  process died. When exact alarms aren't allowed, it may be late by a few minutes.

**iOS**
- **CallKit:** the system's incoming call screen, the in-call indicator, Recents. Mute
  and hold come from the CallKit screen.
- **PushKit:** owned by the package, which reports each VoIP push to CallKit before your
  Dart code runs.
- **`systemCallUI: false`:** a time-sensitive notification instead (China).

**macOS:** a time-sensitive notification with Accept / Decline, then Hang up.

**Windows:** an `incomingCall` toast that loops the ringtone, with Accept / Decline;
then a quiet toast with Hang up.

**Linux:** a critical, resident notification with Accept / Decline and the
`phone-incoming-call` sound; then a quiet resident notification with Hang up.

**Web:** a notification that stays on screen until clicked; a click brings the page to
the front.

On every platform the core's created / displayed events fire for the call's
notification, as for any other.

<br>
<br>

# 🏗 Model reference

**`NotificationCall`**

| Field | Type | Required | Notes |
|---|---|:-:|---|
| `callId` | `String` | yes | One system call per id. Use a new id for each call. |
| `caller` | `NotificationPerson` | yes | Name and avatar shown while ringing. |
| `state` | `CallState` | yes | See [the moments of a call](#the-moments-of-a-call). |
| `handle` | `String` | no | `tel:`, `mailto:` or your own id: the CallKit handle and the Telecom address. The caller's key when absent. |
| `video` | `bool` | no (`false`) | Video call UI and icons. |
| `groupName` | `String` | no | A group call's name, shown instead of the caller's. |
| `startedAt` | `DateTime` | no | The ongoing call's timer. |
| `ringTimeout` | `Duration` | no (60 s) | Then the call is missed. |
| `missedNotification` | `bool` | no (`true`) | Show the missed call notification. |
| `controls` | `Set<CallControl>` | no (all) | `accept`, `decline`, `hangUp`, `mute`, `hold`. An incoming call needs `accept` or `decline`. |
| `commandTarget` | `CallCommandTarget` | no (`actionEvent`) | See [Receiving the answers](#receiving-the-answers). |
| `systemCallUI` | `bool` | no (`true`) | iOS: `false` shows a notification instead of CallKit (China). |
| `texts` | `CallTexts` | no (English) | The words shown where the system has none. |

**`AwesomeNotificationsCalls`**

| Method | What it does |
|---|---|
| `commandOf(ReceivedAction)` | The call answer in an action event, or null. |
| `callIdOf(ReceivedNotification)` | The call of a notification or action, or null. |
| `commands` | The answers of `stream` calls, while the app runs. |
| `endCall(callId, {reason})` | Ends the call everywhere. |
| `activeCalls()` | The calls the system shows now. |
| `voipToken()` / `onVoipToken` | iOS PushKit token (null elsewhere). |
| `canUseFullScreenIntent()` / `requestFullScreenIntent()` | Android 14+ full-screen permission (true elsewhere). |
| `capabilities()`, `isPlatformSupported` | What this platform can show. |

**Errors** (`INVALID_ARGUMENTS`):

| Code | When |
|---|---|
| `arguments.invalid.notificationCall` | the call is invalid (the message says why) |
| `arguments.invalid.notificationCall.schedule` | a call with a schedule: calls ring now, they can't be scheduled |

<br>
<br>

# 🩺 Troubleshooting

**The call doesn't ring over the lock screen (Android 14+).** The user (or the system)
turned off full-screen notifications for your app: check `canUseFullScreenIntent()` and
call `requestFullScreenIntent()`.

**The ongoing call is a plain notification (Android 12+).** The `phoneCall` foreground
service couldn't start: declare `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_PHONE_CALL` and
`MANAGE_OWN_CALLS`.

**The app is terminated when a VoIP push arrives (iOS).** Call
`AwesomeNotificationsCallsPlugin.registerAtLaunch()` in the AppDelegate (step 3 of
[Configuring iOS](#-configuring-ios)).

**No sound or no audio in the call (iOS).** Start your audio in `audioActivated`, not
on `accept`: CallKit activates the session after the answer.

**`INVALID_ARGUMENTS` / `arguments.invalid.notificationCall.schedule`.** Calls can't be
scheduled. Ring the call when it happens (by push when the app may be closed).
