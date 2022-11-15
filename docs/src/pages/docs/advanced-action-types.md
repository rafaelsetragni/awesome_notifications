---
title: 👊 Notification Action Types
# description: Quidem magni aut exercitationem maxime rerum eos.
---

The notification action type defines how awesome notifications should handle the user actions.

{% callout type="note" title="Note" %}
For silent types, its necessary to hold the execution with await keyword, to prevent the isolates to shutdown itself before all work is done.
{% /callout %}

## Default

Is the default action type, forcing the app to goes foreground.

## SilentAction

Do not forces the app to go foreground, but runs on main thread, accept visual elements and can be interrupt if main app gets terminated.

## SilentBackgroundAction

Do not forces the app to go foreground and runs on background, not accepting any visual element. The execution is done on an exclusive dart isolate.

## KeepOnTop

Fires the respective action without close the notification status bar and don't bring the app to foreground.

## DisabledAction

When pressed, the notification just close itself on the tray, without fires any action event.

## DismissAction

Behaves as the same way as a user dismissing action, but dismissing the respective notification and firing the onDismissActionReceivedMethod. Ignores autoDismissible property.

## InputField

(Deprecated) When the button is pressed, it opens a dialog shortcut to send an text response. Use the property `requireInputText` instead.
