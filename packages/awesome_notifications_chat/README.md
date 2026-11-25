# 💬 awesome_notifications_chat

Chat notifications for [awesome_notifications](https://pub.dev/packages/awesome_notifications):
Android **conversations** and iOS / macOS **communication notifications**, from one
shared Person model.

[![pub package](https://img.shields.io/pub/v/awesome_notifications_chat.svg)](https://pub.dev/packages/awesome_notifications_chat)
![Full tests workflow](https://github.com/rafaelsetragni/awesome_notifications/actions/workflows/dart.yml/badge.svg?branch=master)
![codecov badge](https://codecov.io/gh/rafaelsetragni/awesome_notifications/branch/master/graph/badge.svg?flag=awesome_notifications_chat)

Show messages the way messaging apps do: with the sender's photo and name, the
group's name, the history of the conversation and a reply typed right in the
notification. You describe the people of a conversation once, in Dart, and the
package turns them into an `androidx.core.app.Person` on Android and an `INPerson`
on iOS and macOS.

<br>

### **Key Features:**

* **Android conversations:** `MessagingStyle` with each sender's name and avatar, a
  conversation shortcut that puts the notification in the **Conversations** section
  (Android 11+), and the history of the conversation in one notification.
* **iOS / macOS communication notifications:** the sender's photo replaces the app
  icon, with the sender and group names, threaded by conversation.
* **Reply from the notification:** the typed text reaches your app, and Android adds
  it to the conversation.
* **One-to-one and group conversations**, with the `Messaging` and
  `MessagingGroup` layouts.
* **The same Person model everywhere**, validated before it reaches the platform.

<br>
<br>

# 📙 Table of Contents

- [📱 Platform support](#-platform-support)
- [🛠 Getting started](#-getting-started)
  - [🤖 Configuring Android](#-configuring-android)
  - [🍎 Configuring iOS (required)](#-configuring-ios-required)
  - [🖥 Configuring macOS (required)](#-configuring-macos-required)
  - [✅ Checking the setup](#-checking-the-setup)
- [📨 Sending chat messages](#-sending-chat-messages)
  - [People](#people)
  - [A one-to-one conversation](#a-one-to-one-conversation)
  - [A group conversation](#a-group-conversation)
  - [Replying from the notification](#replying-from-the-notification)
  - [Marking a conversation as read](#marking-a-conversation-as-read)
- [🏗 Model reference](#-model-reference)
- [🔁 Migrating from the 0.12 Messaging layouts](#-migrating-from-the-012-messaging-layouts)
- [🩺 Troubleshooting](#-troubleshooting)

<br>
<br>

# 📱 Platform support

| Feature | Android | iOS | macOS | Windows | Linux | Web |
|---|:-:|:-:|:-:|:-:|:-:|:-:|
| Sender name and text | ✅ | ✅ | 🧪 | ⏳ | ⏳ | ⏳ |
| Sender avatar | ✅ (Android 9+) | ✅ | 🧪 | ⏳ | ⏳ | ⏳ |
| System conversation | ✅ Conversations section (Android 11+) | ✅ communication notification | 🧪 communication notification | ❌ | ❌ | ❌ |
| History in one notification | ✅ (last 25 messages) | ❌ (one notification per message, threaded) | ❌ (threaded) | ⏳ | ⏳ | ⏳ |
| Group name | ✅ | ✅ | 🧪 | ⏳ | ⏳ | ⏳ |
| Group picture | ✅ (conversation shortcut icon) | ✅ | ❌ | ⏳ | ⏳ | ⏳ |
| Reply from the notification | ✅ | ✅ | 🧪 | ⏳ | ⏳ | ❌ |
| Messages by push (`awesome_notifications_fcm`) | ⏳ | ⏳ (needs a Notification Service Extension) | ⏳ | ⏳ | ⏳ | ⏳ |
| Bubbles | ⏳ | ❌ | ❌ | ❌ | ❌ | ❌ |

✅ supported · 🧪 preview (implemented, still being validated) · ⏳ planned · ❌ not possible on this platform

- **iOS and macOS: communication notifications are mandatory.** Every message of this
  package is a communication notification. There is no fallback to a plain
  notification: when the app is not set up for them, creating the notification fails
  with an error. Follow the setup below before sending the first message.
- **Minimum versions:** iOS 15 and macOS 12. Android: the core's minimum (API 24);
  sender avatars need Android 9 and the Conversations section Android 11.
- Use `AwesomeNotificationsChat().capabilities()` to adapt your UI to what the current
  platform can do (history, reply, avatar, system conversation).

<br>
<br>

# 🛠 Getting started

1. Add the core and this package to your `pubspec.yaml`:

```yaml
dependencies:
  awesome_notifications: any       # the core
  awesome_notifications_chat: any  # this package (same version line as the core)
```

2. Get the packages:

```bash
flutter pub get
```

3. Configure each platform you ship, as described below. Android needs nothing beyond
   the core's setup; **iOS and macOS need a capability and an `Info.plist` entry**.

> **What changes when you add this package:** it takes over the
> `NotificationLayout.Messaging` and `NotificationLayout.MessagingGroup` layouts. From
> then on, a notification with one of those layouts **must** carry a
> `NotificationConversation` (see [Migrating from the 0.12 Messaging
> layouts](#-migrating-from-the-012-messaging-layouts)). Without this package, the core
> keeps showing those layouts exactly as 0.12 did.

<br>

## 🤖 Configuring Android

Nothing to add beyond the core's Android setup (minimum SDK, the
`POST_NOTIFICATIONS` permission request on Android 13+).

Recommended:

1. Create a dedicated channel for chat messages with `NotificationImportance.High`,
   so messages pop up on screen:

```dart
NotificationChannel(
  channelKey: 'chat',
  channelName: 'Chat',
  channelDescription: 'Chat messages',
  importance: NotificationImportance.High,
)
```

2. Keep one notification id per conversation (see [Sending chat
   messages](#-sending-chat-messages)): Android rebuilds the conversation's history from
   the notification that is already on screen.

How it works on Android: each message publishes (or updates) a **long-lived conversation
shortcut** whose id is the conversation id. That shortcut is what lets Android 11+ show
the notification in the Conversations section and let the user mark it as a priority
conversation. When you remove a conversation for good (leaving a group, deleting a
chat), call `removeConversation`, which also removes the shortcut. You can turn the
shortcut off for a conversation with `shortcut: false` (the notification is then still a
`MessagingStyle`, outside the Conversations section).

<br>

## 🍎 Configuring iOS (required)

Communication notifications need **iOS 15** and two things in your Xcode project: the
**Communication Notifications capability** and the **`INSendMessageIntent` user activity
type**. Do these steps once per app:

**1. Raise the iOS deployment target to 15.0.**

In Xcode, select the **Runner** project, then the **Runner** target, **General** tab,
**Minimum Deployments** → **iOS 15.0**. If your project uses CocoaPods, set it in
`ios/Podfile` too:

```ruby
platform :ios, '15.0'
```

**2. Add the Communication Notifications capability.**

1. Open `ios/Runner.xcworkspace` in Xcode.
2. Select the **Runner** target, then the **Signing & Capabilities** tab.
3. Make sure **Automatically manage signing** is on and your **Team** is selected.
4. Click **+ Capability** and add **Communication Notifications**.

Xcode creates (or updates) `ios/Runner/Runner.entitlements` with:

```xml
<key>com.apple.developer.usernotifications.communication</key>
<true/>
```

With automatic signing, Xcode also enables the capability on your App ID in the Apple
Developer portal. If you sign manually, enable **Communication Notifications** on the
App ID (Certificates, Identifiers & Profiles → Identifiers → your app) and download a new
provisioning profile.

**3. Declare the `INSendMessageIntent` activity type.**

Add to `ios/Runner/Info.plist`, inside the top-level `<dict>`:

```xml
<key>NSUserActivityTypes</key>
<array>
    <string>INSendMessageIntent</string>
</array>
```

If the key already exists, just add the `INSendMessageIntent` string to its array.

**4. (Push only) Notification Service Extension — planned.**

Messages that arrive by push become communication notifications only inside a
Notification Service Extension, with `"mutable-content": 1` in the payload. A ready-made
extension (shared with `awesome_notifications_fcm`) is planned; until it ships, chat
messages by push are not supported on iOS. Local messages (created by your app) work with
steps 1 to 3.

<br>

## 🖥 Configuring macOS (required)

Communication notifications need **macOS 12**.

**1. Raise the macOS deployment target to 12.0** (Runner target, **General** →
**Minimum Deployments**, and `platform :osx, '12.0'` in `macos/Podfile` if you use
CocoaPods).

**2. Add the capability and the network entitlement.** In Xcode, open
`macos/Runner.xcworkspace`, select the **Runner** target, **Signing & Capabilities**,
choose your **Team** (macOS needs a development certificate for this capability, not
"Sign to Run Locally"), then **+ Capability** → **Communication Notifications**. Add the
same keys to **both** `macos/Runner/DebugProfile.entitlements` and
`macos/Runner/Release.entitlements`:

```xml
<!-- Communication notifications -->
<key>com.apple.developer.usernotifications.communication</key>
<true/>
<!-- Download avatars from the network (the app is sandboxed) -->
<key>com.apple.security.network.client</key>
<true/>
```

**3. Declare the `INSendMessageIntent` activity type** in `macos/Runner/Info.plist`,
exactly as on iOS (step 3 above).

On macOS the group picture is not available (macOS has no API for it; it shows the
senders instead).

<br>

## ✅ Checking the setup

On iOS and macOS the package checks the setup before each message and fails the
`createNotification` call when something is missing:

```
PlatformException(INSUFFICIENT_PERMISSIONS,
  Communication notifications are not set up: add the Communication Notifications
  capability and INSendMessageIntent to NSUserActivityTypes (see the package README),
  insufficientPermissions.communicationNotifications)
```

What it can check: the `INSendMessageIntent` entry in `Info.plist` (iOS and macOS) and the
entitlement itself (macOS). iOS doesn't let an app read its own entitlements, so on iOS a
missing **capability** is not detected at runtime: the message then shows as a plain
notification, with the app icon instead of the sender's photo. If you see the app icon,
go back to step 2.

<br>
<br>

# 📨 Sending chat messages

A chat message is a regular `createNotification` from the core with:

- the `Messaging` layout (one-to-one) or the `MessagingGroup` layout (group), and
- a `NotificationConversation` in `extensions`.

Each conversation should always use **the same notification id**: on Android the new
message joins the history of the notification already on screen.

<br>

## People

```dart
const me = NotificationPerson(key: 'u-1', name: 'Rafael');

const ana = NotificationPerson(
  key: 'u-2',                                // a stable, unique id (an account id)
  name: 'Ana',
  avatar: 'https://example.com/ana.jpg',     // asset://, file://, https:// or resource://
  uri: 'tel:+5511999999999',                 // optional: tel:, mailto: or a contact URI
  isImportant: true,                         // Android: someone the user talks to often
);
```

`me` is the user of the device. Every person of a conversation needs a unique `key`.

<br>

## A one-to-one conversation

```dart
await AwesomeNotifications().createNotification(
  content: NotificationContent(
    id: 1,                                   // one id per conversation
    channelKey: 'chat',
    notificationLayout: NotificationLayout.Messaging,
  ),
  extensions: [
    NotificationConversation(
      id: 'conversation-ana',                // a stable conversation id
      me: me,
      participants: const [ana],
      message: const NotificationMessage(sender: ana, text: 'Are you coming?'),
    ),
  ],
);
```

The content's `title` and `body` can stay empty: the package fills them with the sender
(or group) name and the message text.

<br>

## A group conversation

```dart
await AwesomeNotifications().createNotification(
  content: NotificationContent(
    id: 2,
    channelKey: 'chat',
    notificationLayout: NotificationLayout.MessagingGroup,
  ),
  extensions: [
    NotificationConversation(
      id: 'family',
      title: 'Family',                       // required for MessagingGroup
      image: 'https://example.com/family.jpg',
      me: me,
      participants: const [ana, bia],        // required for MessagingGroup
      message: const NotificationMessage(sender: bia, text: 'Dinner at 8?'),
    ),
  ],
);
```

<br>

## Replying from the notification

Add a button with `requireInputText: true`. A `SilentAction` keeps the app in the
background while it handles the reply:

```dart
actionButtons: [
  NotificationActionButton(
    key: 'REPLY',
    label: 'Reply',
    requireInputText: true,
    actionType: ActionType.SilentAction,
  ),
],
```

In your action listener, send the message, then add it to the conversation:

```dart
@pragma('vm:entry-point')
static Future<void> onActionReceivedMethod(ReceivedAction action) async {
  final conversationId = AwesomeNotificationsChat.conversationIdOf(action);
  if (action.buttonKeyPressed == 'REPLY' && conversationId != null) {
    final text = action.buttonKeyInput;
    await myChatServer.send(conversationId, text);          // your app's logic
    await AwesomeNotificationsChat().addReply(
      conversationId,
      NotificationMessage(sender: me, text: text),
    );
  }
}
```

On Android, `addReply` adds the reply to the conversation and stops the "sending"
indicator; skip it and Android keeps showing that indicator. On iOS and macOS it does
nothing (the system never shows the user's own messages).

`conversationIdOf` reads the `conversationId` the package adds to the notification's
`payload` (unless you set that key yourself).

<br>

## Marking a conversation as read

```dart
await AwesomeNotificationsChat().markAsRead('family');         // removes its notifications
await AwesomeNotificationsChat().removeConversation('family'); // also forgets the conversation
final onScreen = await AwesomeNotificationsChat().listActiveConversations();
```

`removeConversation` also removes the Android conversation shortcut and the iOS donated
interactions. Use it when the conversation is gone for good, not just read.

<br>
<br>

# 🏗 Model reference

**`NotificationPerson`**

| Field | Type | Required | Android (`Person`) | iOS / macOS (`INPerson`) |
|---|---|:-:|---|---|
| `key` | String | yes | key | handle (when no `uri`) and custom identifier |
| `name` | String | yes | name | display name |
| `avatar` | String (media source) | no | icon, cropped round | image |
| `uri` | String (`tel:`, `mailto:`, contact) | no | uri | phone or e-mail handle |
| `isBot` | bool | no | bot | — |
| `isImportant` | bool | no | important | — |

**`NotificationMessage`**

| Field | Type | Required | Notes |
|---|---|:-:|---|
| `sender` | `NotificationPerson` | yes | `me` for a message the user sent |
| `text` | String | yes | plain text |
| `timestamp` | DateTime | no | now when absent |
| `image` | String (media source) | no | iOS: attached to the notification |

**`NotificationConversation`**

| Field | Type | Required | Notes |
|---|---|:-:|---|
| `id` | String | yes | Android shortcut id; iOS conversation identifier and thread |
| `me` | `NotificationPerson` | yes | the user of the device |
| `message` | `NotificationMessage` | yes | the new message |
| `title` | String | `MessagingGroup` | the group's name |
| `participants` | `List<NotificationPerson>` | `MessagingGroup` | the other people |
| `image` | String (media source) | no | the group's picture (not on macOS) |
| `history` | `ConversationHistory` | no (`append`) | Android: `append` to the notification on screen or `replace` it |
| `shortcut` | bool | no (`true`) | Android: publish the conversation shortcut |

Invalid models throw an `AwesomeNotificationsException` in Dart, before anything reaches
the platform. Natively (for messages that don't come from Dart), the same rules answer
`INVALID_ARGUMENTS`.

<br>
<br>

# 🔁 Migrating from the 0.12 Messaging layouts

In 0.12, the `Messaging` and `MessagingGroup` layouts used the content fields: `title` was
the sender, `body` the message, `largeIcon` the avatar and `summary` the group name, and
Android stacked the messages of a `groupKey` in one notification.

Without this package, 1.0 keeps exactly that behavior. With this package installed, those
layouts require a `NotificationConversation`:

| 0.12 content field | With this package |
|---|---|
| `title` (sender name) | `message.sender.name` |
| `body` (message) | `message.text` |
| `largeIcon` (sender avatar) | `message.sender.avatar` |
| `summary` (group name) | `title` of the conversation |
| `groupKey` (the conversation) | `id` of the conversation |

A `Messaging` / `MessagingGroup` notification without a conversation now fails with
`INVALID_ARGUMENTS` instead of showing the 0.12 layout. Installing the package is your
choice of the new behavior, so update every place that creates those layouts.

<br>
<br>

# 🩺 Troubleshooting

**`INSUFFICIENT_PERMISSIONS` / `insufficientPermissions.communicationNotifications` (iOS,
macOS)**
The setup is incomplete: check the `NSUserActivityTypes` entry in `Info.plist` and, on
macOS, the entitlement in both entitlements files. See [Configuring
iOS](#-configuring-ios-required).

**iOS shows the app icon instead of the sender's photo**
The Communication Notifications capability is missing or not in the provisioning profile
(iOS can't detect it at runtime). Add it in **Signing & Capabilities** and rebuild.

**macOS build error: "Provisioning profile ... doesn't include the Communication
Notifications capability" or "No Accounts"**
Sign in to your Apple account in **Xcode › Settings › Accounts**, select your Team in
**Signing & Capabilities** and build again (from the command line, add
`-allowProvisioningUpdates` to `xcodebuild`).

**`INVALID_ARGUMENTS` / `arguments.invalid.notificationConversation`**
A `Messaging` or `MessagingGroup` notification has no conversation, a conversation was
sent with another layout, a group misses its `title` or `participants`, or a person key
is repeated.

**Android: the notification is not in the Conversations section**
It needs Android 11+ and the conversation shortcut (`shortcut: true`, the default). Some
launchers limit the number of shortcuts; when publishing fails the message is still shown,
outside that section.

**Android keeps showing a spinner after a reply**
Call `addReply` after handling the typed text.

<br>

See the `example/` app for a runnable, single-file demo.
