/// Determines the importance to show immeadetly the notification to the user
/// [Default]: shows everywhere, makes noise, but does not visually intrude.
/// [Higher]: shows everywhere, makes noise and peeks. May use full screen intents.
/// [Low]: Shows in the shade, and potentially in the status bar (see shouldHideSilentStatusBarIcons()), but is not audibly intrusive.
/// [Min]: only shows in the shade, below the fold. This should not be used with Service#startForeground(int, Notification) since a foreground service is supposed to be something the user cares about so it does not make semantic sense to mark its notification as minimum importance. If you do this as of Android version Build.VERSION_CODES.O, the system will show a higher-priority notification about your app running in the background.
/// [None]: A notification with no importance: does not show in the shade.
enum NotificationImportance {
  None,
  Min,
  Low,
  Default,
  High,
  Max,
}
