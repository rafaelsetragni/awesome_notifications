---
title: 😃 Emojis (Emoticons) #
# description: Quidem magni aut exercitationem maxime rerum eos.
---

To send emojis in your local notifications, concatenate the class `Emoji` with your text. For push notifications, copy the emoji (unicode text) from [unicode.org](https://www.unicode.org/emoji/charts/full-emoji-list.html) and send it or use the format `\u{1f6f8}`.

{% callout type="note" title="Note " %}
Not all emojis work with all platforms. Please, test the specific emoji before using it in production.
{% /callout %}

```dart
await AwesomeNotifications().createNotification(
  content: NotificationContent(
    id: id,
    channelKey: 'basic_channel',
    title: 'Emojis are awesome too! '+ Emojis.smille_face_with_tongue + Emojis.smille_rolling_on_the_floor_laughing + Emojis.emotion_red_heart,
    body: 'Simple body with a bunch of Emojis! ${Emojis.transport_police_car} ${Emojis.animals_dog} ${Emojis.flag_UnitedStates} ${Emojis.person_baby}',
    bigPicture: 'https://tecnoblog.net/wp-content/uploads/2019/09/emoji.jpg',
    notificationLayout: NotificationLayout.BigPicture,
  ),
);
```
