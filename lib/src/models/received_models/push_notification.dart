import '../notification_content.dart';
import '../notification_model.dart';

@Deprecated('PushNotification class was deprecated, since '
    'all push features will be moved to the companion plugin. '
    'Use NotificationModel class instead.')
class PushNotification extends NotificationModel {
  PushNotification(
      {required NotificationContent super.content,
      super.schedule,
      super.actionButtons});
}
