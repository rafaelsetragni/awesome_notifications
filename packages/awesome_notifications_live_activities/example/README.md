# Awesome Live (example)

Three live activities in one file (`lib/main.dart`): a delivery (segmented progress, countdown, Next step and Cancel buttons), a match (a scoreboard: the versus layout, drawn by the package on Android 16+ too with `androidLiveUpdate: false`) and a focus timer (the app's own layout: `android/app/src/main/res/layout/focus_timer.xml` and `FocusTimerView` in `ios/LiveActivityWidget`). Each keeps its state in the notification's payload, so its buttons work from the Lock Screen or the notification shade, even with the app killed.

The iOS project already has the Widget Extension (`ios/LiveActivityWidget`) and an App Group (`group.me.carda.awesomeNotificationsLiveActivitiesExample`); to run it on a device, set your Team and an App Group of your own on both targets. See the [package README](../README.md) for the setup.
