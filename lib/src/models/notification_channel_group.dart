import 'package:awesome_notifications/src/definitions.dart';
import 'package:awesome_notifications/src/exceptions/awesome_exception.dart';
import 'package:awesome_notifications/src/models/model.dart';
import 'package:awesome_notifications/src/utils/assert_utils.dart';

class NotificationChannelGroup extends Model {
  String? channelGroupKey;
  String? channelGroupName;

  NotificationChannelGroup(
      {required String channelGroupKey, required String channelGroupName}) {
    this.channelGroupKey = channelGroupKey;
    this.channelGroupName = channelGroupName;
  }

  @override
  NotificationChannelGroup? fromMap(Map<String, dynamic> dataMap) {
    channelGroupKey = AwesomeAssertUtils.extractValue(
        NOTIFICATION_CHANNEL_GROUP_KEY, dataMap, String);
    channelGroupName = AwesomeAssertUtils.extractValue(
        NOTIFICATION_CHANNEL_GROUP_NAME, dataMap, String);

    return this;
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      NOTIFICATION_CHANNEL_GROUP_KEY: channelGroupKey,
      NOTIFICATION_CHANNEL_GROUP_NAME: channelGroupName
    };
  }

  @override
  void validate() {
    if (AwesomeAssertUtils.isNullOrEmptyOrInvalid(channelGroupKey, String))
      throw AwesomeNotificationsException(
          message: 'channelGroupKey is required');
    if (AwesomeAssertUtils.isNullOrEmptyOrInvalid(channelGroupName, String))
      throw AwesomeNotificationsException(
          message: 'channelGroupName is required');
  }
}
