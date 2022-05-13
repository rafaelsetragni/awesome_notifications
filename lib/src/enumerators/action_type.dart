// ignore_for_file: deprecated_member_use_from_same_package
/// Defines the notification button's type
/// [ActionType.Default] Is the default action type, forcing the app to goes foreground.
/// [ActionType.SilentAction] Do not forces the app to go foreground, but runs on main thread, accept visual elements and can be interrupt if main app gets terminated.
/// [ActionType.SilentBackgroundAction] Do not forces the app to go foreground and runs on background, not accepting any visual elements. The execution is done on background thread.
/// [ActionType.KeepOnTop] Fires the respective action without close the notification status bar and don't bring the app to foreground.
/// [ActionType.DisabledAction] When pressed, the notification just close itself on the tray, without fires any action event.
/// [ActionType.DismissAction] Behaves as the same way as a user dismissing action, dismissing the respective notification and firing the dismissMethod. Ignores autoDismissible property.
/// [ActionType.InputField] (Deprecated) When the button is pressed, it opens a dialog shortcut to send an text response.
enum ActionType {
  /// Is the default action type, forcing the app to goes foreground.
  Default,

  /// (Deprecated) When the button is pressed, it opens a dialog shortcut to send an text response.
  @Deprecated('Use the property requireInputText instead.')
  InputField,

  /// When pressed, the notification just close itself on the tray, without fires any action event.
  DisabledAction,

  /// Fires the respective action without close the notification status bar and don't bring the app to foreground.
  KeepOnTop,

  /// Do not forces the app to go foreground, but runs on main thread, accept visual elements and can be interrupt if main app gets terminated.
  SilentAction,

  /// Do not forces the app to go foreground and runs on background, not accepting any visual elements. The execution is totally
  /// apart from app lifecycle and will not be interrupt if the app goes terminated / killed.
  SilentBackgroundAction,

  /// Behaves as the same way as a user dismiss action, dismissing the respective notification
  /// and firing dismissMethod. Ignores autoDismissible property.
  DismissAction
}
