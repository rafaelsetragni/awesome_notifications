---
title: ⚡️ Notification Events
# description: Quidem magni aut exercitationem maxime rerum eos.
---

The notification events are only delivered after `setListeners` method being called, and they are not always delivered at same time as they happen.
The awesome notifications event methods available to track your notifications are:

## onNotificationCreatedMethod

Fires when a notification is created

## onNotificationDisplayedMethod

Fires when a notification is displayed on system status bar

## onActionReceivedMethod

**REQUIRED** Fires when a notification is tapped by the user

## onDismissedActionReceivedMethod

Fires when a notification is dismissed by the user (sometimes the OS denies the deliver)

---

## Delivery conditions:

| Platform    | App in Foreground                         | App in Background                                  | App Terminated (Killed)                                          |
| ----------- | ----------------------------------------- | -------------------------------------------------- | ---------------------------------------------------------------- |
| **Android** | Fires all events immediately after occurs | Fires all events immediately after occurs          | Store events to be fired when app is on Foreground or Background |
| **iOS**     | Fires all events immediately after occurs | Store events to be fired when app is on Foreground | Store events to be fired when app is on Foreground               |

{% callout type="note" title="Exception" %}
`onActionReceivedMethod` fires all events immediately after occurs in any application life cycle, for all Platforms.
{% /callout %}
