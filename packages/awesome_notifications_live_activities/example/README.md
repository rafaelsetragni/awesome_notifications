# Awesome Live (example)

Three live activities in one file (`lib/main.dart`): a delivery (segmented progress, countdown, Next step and Cancel buttons), a match (two metrics, a running clock, goal buttons) and a focus timer (a countdown only). Each keeps its state in the notification's payload, so its buttons work from the Lock Screen or the notification shade, even with the app killed.

The iOS project already has the Widget Extension (`ios/LiveActivityWidget`) and an App Group (`group.me.carda.awesomeNotificationsLiveActivitiesExample`); to run it on a device, set your Team and an App Group of your own on both targets. See the [package README](../README.md) for the setup.
