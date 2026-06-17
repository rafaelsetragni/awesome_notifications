/// Application life cycle at new notification change state
enum NotificationLifeCycle {
  Foreground,
  Background,
  Terminated;

  @Deprecated('AppKilled is deprecated, use Terminated instead')
  // ignore: non_constant_identifier_names
  static NotificationLifeCycle get AppKilled =>
      NotificationLifeCycle.Terminated;
}
