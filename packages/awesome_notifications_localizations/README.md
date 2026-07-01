# 🌎 awesome_notifications_localizations

Multi-language support for [awesome_notifications](https://pub.dev/packages/awesome_notifications).

Show your notifications in the user's language: translate the title, body,
summary, large icon, big picture and action button labels — all from a single
`createNotification` call.

<br>

## 📲 Installation

Add this package together with `awesome_notifications` to your `pubspec.yaml`:

```yaml
dependencies:
  awesome_notifications: ^1.0.0
  awesome_notifications_localizations: ^1.0.0
```

Initialize Awesome Notifications as usual (see the
[awesome_notifications](https://pub.dev/packages/awesome_notifications) docs).
Nothing else to configure.

<br>

## 🚀 Usage

```dart
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:awesome_notifications_localizations/awesome_notifications_localizations.dart';
```

### Choosing the language

Set the language your notifications should be shown in with `setLocalization`. It
takes a case-insensitive language code (e.g. `"en"`, `"pt-br"`, `"es"`). Pass
`null` to use the device's system language.

```dart
await AwesomeNotificationsLocalizations().setLocalization(languageCode: 'pt-br');
```

Read the language currently in use:

```dart
String currentLanguageCode =
    await AwesomeNotificationsLocalizations().getLocalization();
```

### Creating a translated notification

Create the notification as usual with `AwesomeNotifications().createNotification`,
and attach the translations through `extensions` with a `NotificationLocalizations`
holding a map keyed by language code. Each entry is a `NotificationLocalization`
with the translated content for that language. The notification is shown in the
current language; any field you don't translate keeps the default, and if the
current language isn't in the map the default content is used.

```dart
await AwesomeNotifications().createNotification(
  content: NotificationContent(
    id: 1,
    channelKey: 'basic_channel',
    title: 'This title is written in english',
    body: 'Now it is really easy to translate a notification content, '
        'including images and buttons!',
    summary: 'Awesome Notifications Translations',
    notificationLayout: NotificationLayout.BigPicture,
    bigPicture: 'asset://assets/images/awn-rocks-en.jpg',
    largeIcon: 'asset://assets/images/american.jpg',
    payload: {'uuid': 'user-profile-uuid'},
  ),
  actionButtons: [
    NotificationActionButton(key: 'AGREED1', label: 'I agree'),
    NotificationActionButton(key: 'AGREED2', label: 'I agree too'),
  ],
  extensions: [
    NotificationLocalizations({
      'pt-br': NotificationLocalization(
        title: 'Este título está escrito em português do Brasil!',
        body: 'Agora é muito fácil traduzir o conteúdo das notificações, '
            'incluindo imagens e botões!',
        summary: 'Traduções Awesome Notifications',
        bigPicture: 'asset://assets/images/awn-rocks-pt-br.jpg',
        largeIcon: 'asset://assets/images/brazilian.jpg',
        buttonLabels: {'AGREED1': 'Eu concordo!', 'AGREED2': 'Eu concordo também!'},
      ),
      'zh': NotificationLocalization(
        title: '这个标题是用中文写的',
        body: '现在，轻松翻译通知内容，包括图像和按钮！',
        bigPicture: 'asset://assets/images/awn-rocks-zh.jpg',
        largeIcon: 'asset://assets/images/chinese.jpg',
        buttonLabels: {'AGREED1': '我同意', 'AGREED2': '我也同意'},
      ),
      'ko': NotificationLocalization(
        title: '이 타이틀은 한국어로 작성되었습니다',
        body: '이제 이미지 및 버튼을 포함한 알림 콘텐츠를 쉽게 번역할 수 있습니다!',
        bigPicture: 'asset://assets/images/awn-rocks-ko.jpg',
        largeIcon: 'asset://assets/images/korean.jpg',
        buttonLabels: {'AGREED1': '동의합니다', 'AGREED2': '저도 동의합니다'},
      ),
    }),
  ],
);
```

> Notifications that don't need translation are created the same way, just
> without the `NotificationLocalizations` extension.

<br>

### `NotificationLocalization` fields

| Field          | Type                   | Description                                         |
| -------------- | ---------------------- | --------------------------------------------------- |
| `title`        | `String?`              | Translated title                                    |
| `body`         | `String?`              | Translated body                                     |
| `summary`      | `String?`              | Translated summary / subtitle                       |
| `largeIcon`    | `String?`              | Translated large icon (for images that hold text)   |
| `bigPicture`   | `String?`              | Translated big picture (for images that hold text)  |
| `buttonLabels` | `Map<String, String>?` | Translated action button labels, keyed by button key |

<br>

## 🔑 Localization keys (Android)

Instead of inlining the translated text, you can point to your app's Android
string resources with `titleLocKey` / `bodyLocKey` (and arguments with
`titleLocArgs` / `bodyLocArgs`). The strings of the current language are used.

```dart
await AwesomeNotifications().createNotification(
  content: NotificationContent(
    id: 1,
    channelKey: 'basic_channel',
    titleLocKey: 'notification_title',
    bodyLocKey: 'notification_body',
    titleLocArgs: ['title'],
    bodyLocArgs: ['body'],
  ),
  extensions: [
    // optional per-language images / button labels
    NotificationLocalizations({/* ... */}),
  ],
);
```

Add the strings to your Android resource folders, e.g.
`android/app/src/main/res/values-pt-rBR/strings.xml`:

```xml
<resources>
    <string name="notification_title">Este %@ está em Português do Brasil</string>
</resources>
```

When both are present, the `localizations` map wins over the loc-key text for any
field it provides.

<br>

## 📱 Platform support

| Feature                                            | Android | iOS |
| -------------------------------------------------- | :-----: | :-: |
| Translated title / body / summary / images         |   ✅    | ✅  |
| Translated action button labels                    |   ✅    | ✅  |
| `titleLocKey` / `bodyLocKey` from string resources |   ✅    | —  |

<br>

## 🔗 See also

- [awesome_notifications](https://pub.dev/packages/awesome_notifications) — the
  notifications plugin this package adds translations to.
