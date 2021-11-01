import 'package:awesome_notifications/awesome_notifications.dart';

@Deprecated('PushNotification class was deprecated, since '
    'all push features will be moved to the companion plugin. '
    'Use NotificationModel class instead.')
class PushNotification extends NotificationModel {
  PushNotification(
      {required NotificationContent content,
      NotificationSchedule? schedule,
      List<NotificationActionButton>? actionButtons})
      : super(
            content: content, schedule: schedule, actionButtons: actionButtons);
}
