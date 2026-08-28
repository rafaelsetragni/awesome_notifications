import 'package:awesome_notifications/awesome_notifications.dart';

import '../fcm_definitions.dart';

/// A silent (data-only) push message.
///
/// Firebase data messages carry an arbitrary string map; this model extracts the
/// awesome_notifications envelope fields (id / created date / source / lifecycle)
/// and exposes the remaining custom entries under [data].
class FcmSilentData extends Model {
  int? _id;
  Map<String, String?>? _data;
  DateTime? _createdDate;
  NotificationSource? _createdSource;
  NotificationLifeCycle? _createdLifeCycle;

  int? get id => _id;
  Map<String, String?>? get data => _data;
  DateTime? get createdDate => _createdDate;
  NotificationSource? get createdSource => _createdSource;
  NotificationLifeCycle? get createdLifeCycle => _createdLifeCycle;

  @override
  FcmSilentData? fromMap(Map<String, dynamic> dataMap) {
    _id = dataMap[NOTIFICATION_ID] is int
        ? dataMap[NOTIFICATION_ID] as int
        : int.tryParse('${dataMap[NOTIFICATION_ID]}');

    if (_data != null) {
      _data!.clear();
    } else {
      _data = {};
    }

    for (final String key in dataMap.keys) {
      switch (key) {
        case NOTIFICATION_CREATED_DATE:
          _createdDate = AwesomeAssertUtils.extractValue<DateTime>(
              NOTIFICATION_CREATED_DATE, dataMap);
          break;

        case NOTIFICATION_CREATED_SOURCE:
          _createdSource = AwesomeAssertUtils.extractEnum<NotificationSource>(
              NOTIFICATION_CREATED_SOURCE, dataMap, NotificationSource.values);
          break;

        case NOTIFICATION_CREATED_LIFECYCLE:
          _createdLifeCycle =
              AwesomeAssertUtils.extractEnum<NotificationLifeCycle>(
                  NOTIFICATION_CREATED_LIFECYCLE,
                  dataMap,
                  NotificationLifeCycle.values);
          break;

        // Internal routing keys are never surfaced as user data.
        case NOTIFICATION_ID:
        case SILENT_HANDLE:
          break;

        default:
          _data![key] = dataMap[key]?.toString();
          break;
      }
    }

    return this;
  }

  @override
  Map<String, dynamic> toMap() {
    final Map<String, dynamic> map = <String, dynamic>{...?_data};
    map.addAll({
      NOTIFICATION_ID: _id?.toString(),
      NOTIFICATION_CREATED_DATE: _createdDate?.toString(),
      NOTIFICATION_CREATED_SOURCE: _createdSource?.name,
      NOTIFICATION_CREATED_LIFECYCLE: _createdLifeCycle?.name,
    });
    return map;
  }

  @override
  void validate() {}
}
