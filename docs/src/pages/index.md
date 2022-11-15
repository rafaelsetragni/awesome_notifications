---
title: Getting started
# pageTitle: CacheAdvance - Never miss the cache again.
# description: Cache every single thing your app could ever do ahead of time, so your code never even has to run at all.
---

Let's get started with Awesome Notifications for Android and iOS. {% .lead %}

---

## Quick Start

{% quick-links %}

{% quick-link title="Installation" icon="installation" href="/docs/installation" description="Step-by-step guide to setting up the library with Flutter." /%}

{% quick-link title="Plugins" icon="plugins" href="/" description="Need to use Firebase Messaging for Push Notifications? Come follow me." /%}

{% quick-link title="Android" icon="android" href="/docs/android-setup" description="Setup your Android Project to send Notifications." /%}

{% quick-link title="iOS" icon="apple" href="/docs/ios-setup" description="Setup your iOS Project to send Notifications." /%}

{% /quick-links %}

---

## Features

- Create Local Notifications on Android, iOS and Web using Flutter.
- Send Push Notifications using add-on plugins, as awesome_notifications_fcm
- Add images, sounds, emoticons, buttons and different layouts on your notifications.
- Easy to use and highly customizable.
- Notifications could be created at any moment (on Foreground, Background or even when the application is terminated/killed).
- High trustworthy on receive notifications in any Application lifecycle.
- Notifications events are received on Flutter level code when they are created, displayed, dismissed or even tapped by the user.
- Notifications could be scheduled repeatedly or not, with second precision.

---

_Some **android** notification examples:_

![](https://raw.githubusercontent.com/rafaelsetragni/awesome_notifications/master/example/assets/readme/awesome-notifications-android-examples.jpg)

---

_Some **iOS** notification examples **(work in progress)**:_

![](https://raw.githubusercontent.com/rafaelsetragni/awesome_notifications/master/example/assets/readme/awesome-notifications-ios-examples.jpg)

---

## Notification Types Available

- Basic notification
- Big picture notification
- Media notification
- Big Text notification
- Inbox notification
- Messaging notification
- Messaging Group notification
- Notifications with action buttons
- Grouped notifications
- Progress bar notifications (only for Android)

All notifications could be created locally or via Firebase services, with all the features.

---

## 🛑 ATTENTION

**PLUGIN UNDER DEVELOPMENT**

![image](https://user-images.githubusercontent.com/40064496/155188371-48e22104-8bb8-4f38-ba1a-1795eeb7b81b.png)

_Working progress percentages of awesome notifications plugin_

{% callout type="warning" title="flutter_local_notifications" %}
awesome_notifications plugin is incompatible with flutter_local_notifications, as both plugins will compete each other to accquire global notification resources to send notifications and to receive notification actions.

So, you MUST not use flutter_local_notifications with awesome_notifications. Awesome Notifications contains all features available in flutter_local_notifications plugin and more, so you can replace totally flutter_local_notifications in your project.
{% /callout %}

{% callout type="warning" title="firebase_messaging" %}
The support for firebase_messaging plugin is now deprecated, but all other firebase plugins are still being supported. And this happened by the same reason as flutter_local_notifications, as both plugins will compete each other to accquire global notification resources.

To use FCM services with Awesome Notifications, you need use the Awesome Notifications FCM add-on plugin.

Only using awesome_notifications_fcm you will be capable to achieve all Firebase Cloud Messaging features + all Awesome Notifications features. To keep using firebase_messaging, you gonna need to do workarounds with silent push notifications, and this is disrecommended to display visual notifications and will result in several background penalities to your application.

So, you MUST not use firebase_messaging with awesome_notifications. Use awesome_notifications with awesome_notifications_fcm instead.
{% /callout %}

---

## ✅ Next steps

- Include Web support
- Finish the add-on plugin to enable Firebase Cloud Message with all the awesome features available. (accomplished)
- Add an option to choose if a notification action should bring the app to foreground or not. (accomplished)
- Include support for another push notification services (Wonderpush, One Signal, IBM, AWS, Azure, etc)
- Replicate all Android layouts for iOS (almost accomplished)
- Custom layouts for notifications

---

## 💰 Donate via PayPal or BuyMeACoffee

Help us to improve and maintain our work with donations of any amount, via Paypal.
Your donation will be mainly used to purchase new devices and equipments, which we will use to test and ensure that our plugins works correctly on all platforms and their respective versions.

[![Buy me a Coffee](/donate-coffee.svg)](https://www.paypal.com/donate/?business=9BKB6ZCQLLMZY&no_recurring=0&item_name=Help+us+to+improve+and+maintain+Awesome+Notifications+with+donations+of+any+amount.&currency_code=USD) \
[![Donate with PayPal](/donate-paypal.svg)](https://www.buymeacoffee.com/rafaelsetragni) {% .badges %}

---

## Getting help

### Submit an issue

```
// TODO
```

### Join the community

To stay tuned with new updates and get our community support, please subscribe into our [Discord Chat Server](https://discord.com/invite/3eJuAGqZKy)
