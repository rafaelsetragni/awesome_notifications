---
title: Main Philosophy
# description: Quidem magni aut exercitationem maxime rerum eos.
---

Considering all the many different devices available, with different hardware and software resources, this plugin ALWAYS shows the notification, trying to use all features available. If the feature is not available, the notification ignores that specific feature, but shows the rest of notification anyway.

Example: If the device has LED colored lights, use it. Otherwise, ignore the lights, but shows the notification with all another features available. In last case, shows at least the most basic notification.

Also, the Notification Channels follows the same rule. If there is no channel segregation of notifications, use the channel configuration as defaults configuration. If the device has channels, use it as expected to be.

And all notifications sent while the app was killed are registered and delivered as soon as possible to the Application, after the plugin initialization, respecting the delivery order.

This way, your Application will receive **all notifications events at Flutter level code**.
