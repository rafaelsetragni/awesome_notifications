---
title: ⌛️ Progress Bar Notifications
# description: Quidem magni aut exercitationem maxime rerum eos.
---

To show progress bar using local notifications, you need to create a notification with Layout `ProgressBar` and set a progress ammount between 0 and 100, or set it's progress as indeterminated.

To update your notificaiton progress you need to create a new notification with same id and you **MUST** not exceed 1 second between each update, otherwise your notifications will be randomly blocked by OS.

Below is an example of how to update your progress notification:

```dart
int currentStep = 0;
Timer? updateNotificationAfter1Second;
Future<void> showProgressNotification(int id) async {
  int maxStep = 10;
  int fragmentation = 4;
  for (var simulatedStep = 1;
      simulatedStep <= maxStep * fragmentation + 1;
      simulatedStep++) {
    currentStep = simulatedStep;
    await Future.delayed(Duration(milliseconds: 1000 ~/ fragmentation));

    if(updateNotificationAfter1Second != null) continue;

    updateNotificationAfter1Second = Timer(
      const Duration(seconds: 1),
      () {
        _updateCurrentProgressBar(
          id: id,
          simulatedStep: currentStep,
          maxStep: maxStep * fragmentation
        );
        updateNotificationAfter1Second?.cancel();
        updateNotificationAfter1Second = null;
      }
    );
  }
}

void _updateCurrentProgressBar({
  required int id,
  required int simulatedStep,
  required int maxStep,
}) {
  if (simulatedStep < maxStep) {
    AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: 'progress_bar',
        title: 'Download finished',
        body: 'filename.txt',
        category: NotificationCategory.Progress,
        payload: {
          'file': 'filename.txt',
          'path': '-rmdir c://ruwindows/system32/huehuehue'
        },
        locked: false,
      ),
    );
  } else {
    int progress = min((simulatedStep / maxStep * 100).round(), 100);
    AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: 'progress_bar',
        title: 'Downloading fake file in progress ($progress%)',
        body: 'filename.txt',
        category: NotificationCategory.Progress,
        payload: {
          'file': 'filename.txt',
          'path': '-rmdir c://ruwindows/system32/huehuehue'
        },
        notificationLayout: NotificationLayout.ProgressBar,
        progress: progress,
        locked: true,
      ),
    );
  }
}
```
