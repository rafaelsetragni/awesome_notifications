/// Map keys of the `liveActivity` block, the channel methods and the event
/// channel, shared with the native side.
abstract final class LiveActivityKeys {
  static const liveActivity = 'liveActivity';

  // NotificationLiveActivity
  static const activityId = 'activityId';
  static const state = 'state';
  static const progress = 'progress';
  static const timer = 'timer';
  static const metrics = 'metrics';
  static const shortText = 'shortText';
  static const accentColor = 'accentColor';

  /// Milliseconds since the epoch (UTC).
  static const staleAt = 'staleAt';
  static const relevance = 'relevance';
  static const alert = 'alert';
  static const dismissal = 'dismissal';
  static const pushChannel = 'pushChannel';
  static const androidLiveUpdate = 'androidLiveUpdate';
  static const customLayout = 'customLayout';

  /// `standard` or `versus` (see `LiveActivityLayout`).
  static const layout = 'layout';

  // LiveActivityProgress
  static const segments = 'segments';
  static const points = 'points';
  static const trackerIcon = 'trackerIcon';
  static const startIcon = 'startIcon';
  static const endIcon = 'endIcon';
  static const length = 'length';
  static const position = 'position';
  static const color = 'color';

  // LiveActivityTimer (milliseconds since the epoch, UTC)
  static const start = 'start';
  static const end = 'end';
  static const countDown = 'countDown';

  // LiveActivityMetric
  static const label = 'label';
  static const value = 'value';
  static const unit = 'unit';
  static const image = 'image';

  // LiveActivityDismissal: `default`, `immediate` or milliseconds (UTC).
  static const dismissalDefault = 'default';
  static const dismissalImmediate = 'immediate';

  /// Added to the content payload so an action tells which activity it came
  /// from.
  static const payloadActivityId = 'activityId';

  // Channel methods of AwesomeNotificationsLiveActivities
  static const methodEnd = 'liveActivityEnd';
  static const methodList = 'liveActivityList';
  static const methodCapabilities = 'liveActivityCapabilities';
  static const methodAreEnabled = 'liveActivityAreEnabled';
  static const methodRequestPermission = 'liveActivityRequestPermission';
  static const methodPushToStartToken = 'liveActivityPushToStartToken';
  static const methodPushToken = 'liveActivityPushToken';

  /// Event channel of the push tokens and the state changes.
  static const eventsChannel = 'awesome_notifications_live_activities/events';

  /// An event's kind: [kindPushToStartToken], [kindPushToken] or [kindState].
  static const kind = 'kind';
  static const kindPushToStartToken = 'pushToStartToken';
  static const kindPushToken = 'pushToken';
  static const kindState = 'state';
  static const token = 'token';

  // liveActivityCapabilities
  static const capSystemSurface = 'systemSurface';
  static const capProgressSegments = 'progressSegments';
  static const capMetrics = 'metrics';
  static const capButtons = 'buttons';
  static const capPush = 'push';
}
