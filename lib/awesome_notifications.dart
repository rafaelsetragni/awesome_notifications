library awesome_notifications;

import 'dart:typed_data';

export 'src/awesome_notifications_core.dart';
export 'src/enumerators/action_button_type.dart';
export 'src/enumerators/group_alert_behaviour.dart';
export 'src/enumerators/media_source.dart';
export 'src/enumerators/emojis.dart';
export 'src/enumerators/default_ringtone_type.dart';
export 'src/enumerators/notification_importance.dart';
export 'src/enumerators/notification_layout.dart';
export 'src/enumerators/notification_life_cycle.dart';
export 'src/enumerators/notification_privacy.dart';
export 'src/enumerators/notification_source.dart';
export 'src/enumerators/notification_category.dart';
export 'src/enumerators/time_and_date.dart';
export 'src/enumerators/group_sort.dart';
export 'src/enumerators/notification_permission.dart';
export 'src/extensions/extension_navigator_state.dart';
export 'src/exceptions/awesome_exception.dart';
export 'src/helpers/bitmap_helper.dart';
export 'src/helpers/cron_helper.dart';
export 'src/models/notification_button.dart';
export 'src/models/notification_channel.dart';
export 'src/models/notification_channel_group.dart';
export 'src/models/notification_content.dart';
export 'src/models/notification_schedule.dart';
export 'src/models/notification_calendar.dart';
export 'src/models/notification_interval.dart';
export 'src/models/notification_android_crontab.dart';
export 'src/models/received_models/push_notification.dart';
export 'src/models/notification_model.dart';
export 'src/models/received_models/received_action.dart';
export 'src/models/received_models/received_notification.dart';
export 'src/utils/assert_utils.dart';
export 'src/utils/bitmap_utils.dart';
export 'src/utils/date_utils.dart';
export 'src/utils/map_utils.dart';
export 'src/utils/resource_image_provider.dart';
export 'src/utils/string_utils.dart';
export 'src/definitions.dart';

// Pause and Play vibration sequences
Int64List lowVibrationPattern = Int64List.fromList([0, 200, 200, 200]);
Int64List mediumVibrationPattern =
    Int64List.fromList([0, 500, 200, 200, 200, 200]);
Int64List highVibrationPattern =
    Int64List.fromList([0, 1000, 200, 200, 200, 200, 200, 200]);
