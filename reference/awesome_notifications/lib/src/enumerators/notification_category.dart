/// One of the predefined notification categories that best describes this Notification. May be used by the system for ranking and filtering.
///
/// [Alarm] Alarm or timer.
/// [Call] incoming call (voice or video) or similar synchronous communication request
/// [Email] asynchronous bulk message (email).
/// [Error] error in background operation or authentication status.
/// [Event] calendar event.
/// [LocalSharing] temporarily sharing location.
/// [Message] incoming direct message (SMS, instant message, etc.).
/// [MissedCall] alert about some missed incoming call (voice or video) or similar synchronous communication request
/// [Navigation] map turn-by-turn navigation.
/// [Progress] progress of a long-running background operation.
/// [Promo] promotion or advertisement.
/// [Recommendation] a specific, timely recommendation for a single thing. For example, a news app might want to recommend a news story it believes the user will want to read next.
/// [Reminder] user-scheduled reminder.
/// [Service] indication of running background service.
/// [Social] social network or sharing update.
/// [Status] ongoing information about device or contextual status.
/// [StopWatch] running stopwatch.
/// [Transport] media transport control for playback.
/// [Workout] tracking a user's workout.
enum NotificationCategory {
  /// Alarm or timer.
  Alarm,

  /// incoming call (voice or video) or similar synchronous communication request
  Call,

  /// asynchronous bulk message (email).
  Email,

  /// error in background operation or authentication status.
  Error,

  /// calendar event.
  Event,

  /// temporarily sharing location.
  LocalSharing,

  /// incoming direct message (SMS, instant message, etc.).
  Message,

  /// alert about some missed incoming call (voice or video) or similar synchronous communication request
  MissedCall,

  /// map turn-by-turn navigation.
  Navigation,

  /// progress of a long-running background operation.
  Progress,

  /// promotion or advertisement.
  Promo,

  /// a specific, timely recommendation for a single thing. For example, a news app might want to recommend a news story it believes the user will want to read next.
  Recommendation,

  /// user-scheduled reminder.
  Reminder,

  /// indication of running background service.
  Service,

  /// social network or sharing update.
  Social,

  /// ongoing information about device or contextual status.
  Status,

  /// running stopwatch.
  StopWatch,

  /// media transport control for playback.
  Transport,

  /// tracking a user's workout.
  Workout,
}
