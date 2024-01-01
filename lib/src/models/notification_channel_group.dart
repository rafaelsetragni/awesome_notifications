import 'package:awesome_notifications/src/definitions.dart';
import 'package:awesome_notifications/src/exceptions/awesome_exception.dart';
import 'package:awesome_notifications/src/models/model.dart';
import 'package:awesome_notifications/src/utils/assert_utils.dart';

/// Represents a group of notification channels to be displayed at Android Notification Settings Page.
class NotificationChannelGroup extends Model {
  String? _channelGroupKey;
  String? _channelGroupName;

  /// Gets the unique key identifier of the channel group.
  String? get channelGroupKey {
    return _channelGroupKey;
  }

  /// Gets the name of the channel group.
  String? get channelGroupName {
    return _channelGroupName;
  }

  /// Constructs a [NotificationChannelGroup].
  ///
  /// [channelGroupKey]: Unique key identifier for the channel group.
  /// [channelGroupName]: Name of the channel group.
  NotificationChannelGroup(
      {required String channelGroupKey, required String channelGroupName}) {
    _channelGroupKey = channelGroupKey;
    _channelGroupName = channelGroupName;
  }

  /// Creates a [NotificationChannelGroup] instance from a map of data.
  @override
  NotificationChannelGroup? fromMap(Map<String, dynamic> mapData) {
    _channelGroupKey = AwesomeAssertUtils.extractValue(
        NOTIFICATION_CHANNEL_GROUP_KEY, mapData);
    _channelGroupName = AwesomeAssertUtils.extractValue(
        NOTIFICATION_CHANNEL_GROUP_NAME, mapData);

    return this;
  }

  /// Converts the [NotificationChannelGroup] instance to a map.
  @override
  Map<String, dynamic> toMap() {
    return {
      NOTIFICATION_CHANNEL_GROUP_KEY: _channelGroupKey,
      NOTIFICATION_CHANNEL_GROUP_NAME: _channelGroupName
    };
  }

  /// Validates the properties of the channel group.
  ///
  /// Throws an [AwesomeNotificationsException] if either the channelGroupKey or channelGroupName is missing.
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
