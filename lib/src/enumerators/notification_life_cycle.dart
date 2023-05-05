/// Application life cycle at new notification change state
enum NotificationLifeCycle {
  Foreground,
  Background,
  Terminated;

  @Deprecated('AppKilled is deprecated, use Terminated instead')
  static get AppKilled => NotificationLifeCycle.Terminated;
}
