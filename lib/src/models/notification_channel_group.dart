import 'package:awesome_notifications/src/definitions.dart';
import 'package:awesome_notifications/src/exceptions/awesome_exception.dart';
import 'package:awesome_notifications/src/models/model.dart';
import 'package:awesome_notifications/src/utils/assert_utils.dart';

class NotificationChannelGroup extends Model {
  String? _channelGroupKey;
  String? _channelGroupName;

  String? get channelGroupKey {
    return _channelGroupKey;
  }

  String? get channelGroupName {
    return _channelGroupName;
  }

  NotificationChannelGroup(
      {required String channelGroupKey, required String channelGroupName}) {
    _channelGroupKey = channelGroupKey;
    _channelGroupName = channelGroupName;
  }

  @override
  NotificationChannelGroup? fromMap(Map<String, dynamic> mapData) {
    _channelGroupKey = AwesomeAssertUtils.extractValue(
        NOTIFICATION_CHANNEL_GROUP_KEY, mapData);
    _channelGroupName = AwesomeAssertUtils.extractValue(
        NOTIFICATION_CHANNEL_GROUP_NAME, mapData);

    return this;
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      NOTIFICATION_CHANNEL_GROUP_KEY: _channelGroupKey,
      NOTIFICATION_CHANNEL_GROUP_NAME: _channelGroupName
    };
  }

  @override
  void validate() {
    if (AwesomeAssertUtils.isNullOrEmptyOrInvalid(_channelGroupKey)) {
      throw const AwesomeNotificationsException(
          message: 'channelGroupKey is required');
    }
    if (AwesomeAssertUtils.isNullOrEmptyOrInvalid(_channelGroupName)) {
      throw const AwesomeNotificationsException(
          message: 'channelGroupName is required');
    }
  }
}
