---
title: 🚚 Migrating from version 0.6.X to 0.7.X
# description: Quidem magni aut exercitationem maxime rerum eos.
---

- Now it's possible to receive action events without bring the app to foreground. Check our action type's topic to know more.
- All streams (createdStream, displayedStream, actionStream and dismissedStream) was replaced by `global static methods`. You must replace your old stream methods by static and global methods, in other words, they must be `static Future<void>` and use `async`/`await` and you MUST use `@pragma("vm:entry-point")` to preserve dart addressing.

  (To use context and redirect the user to another page inside static methods, please use flutter navigatorKey or another third party library, such as GetX. Check our [How to show Local Notifications](#-how-to-show-local-notifications) topic to know more).

- Now all the notification events are delivered only after the first setListeners being called.
- The ButtonType class was renamed to ActionType.
- The action type `InputField` is deprecated. Now you just need to set the property `requireInputText` to true to achieve the same, but now it works combined with all another action types.
- The support for `firebase_messaging` plugin is now deprecated, but all other firebase plugins still being supported. You need use the [Awesome's FCM add-on plugin](https://pub.dev/packages/awesome_notifications_fcm) to achieve all firebase messaging features, without violate the platform rules. This is the only way to fully integrated with awesome notifications, running all in native level.
