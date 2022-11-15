---
title: 📡 Channels
#description: Quidem magni aut exercitationem maxime rerum eos.
---

Notification channels are means by which notifications are send, defining the characteristics that will be common among all notifications on that same channel.

A notification channel can be created and deleted at any time in the application, however it is required that at least one exists during the initialization of this plugin. If a notification is created using a invalid channel key, the notification is discarded.

For Android greater than 8 (SDK 26) its not possible to update notification channels after being created, except for name and description attributes.

On iOS there is no native channels, but awesome will handle your notification channels by the same way than Android. This way your app doesn't need to do workarounds to get the closest possible results in both platforms. You gonna write once and run anywhere.

Also, its possible to organize visualy the channel's in you Android's app channel page using NotificationChannelGroup in the AwesomeNotifications().initialize method and the property channelGroupKey in the respective channels. The channel group name can be updated at any time, but an channel only can be defined into a group when is created.

The main methods to manipulate notification channels are:

```dart
// Create or update a notification channel.
AwesomeNotifications().setChannel()

// Remove a notification channel, closing
// all current notifications on that same channel.
AwesomeNotifications().removeChannel()
```
