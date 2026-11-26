/// Explicit status of a [NotificationPermission] on the current platform.
enum NotificationPermissionStatus {
  /// The permission is granted.
  granted,

  /// The permission was denied by the user or is disabled in system settings.
  denied,

  /// The permission has not been requested yet, or the platform cannot
  /// distinguish it from a denial until the first request dialog is shown.
  notDetermined,

  /// The permission is not supported on this platform or project configuration
  /// (for example, Critical Alerts without the Apple entitlement on iOS).
  notSupported,
}
