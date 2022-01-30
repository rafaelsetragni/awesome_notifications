/// Defines the notification button's type
/// [ActionType.Default] Default action type. Force the app to goes foreground
/// [ActionType.InputField] Button when pressed opens a dialog shortcut to send an text response
/// [ActionType.DisabledAction] Button when pressed should just close the notification in tray, but do not fires respective action
/// [ActionType.KeepOnTop] Button, when pressed, fires the respective action without close the notification
/// [ActionType.SilentAction] Do not forces the app to go foreground, but runs on main thread, accept visual elements and can be interrupt if main app gets terminated.
/// [ActionType.SilentBackgroundAction] Do not forces the app to go foreground and runs on background, not accepting any visual elements. The execution is totally.
/// [ActionType.DismissAction] Behaves as the same way as a user dismiss action, dismissing the respective notification and firing dismissMethod. Ignores autoDismissible property.
enum ActionType {
  /// Default action type. Force the app to goes foreground
  Default,

  /// Button when pressed opens a dialog shortcut to send an text response
  @Deprecated('Use the property requireInputText instead.')
  InputField,

  /// Button when pressed should just close the notification in tray, but do not fires respective action
  DisabledAction,

  /// Button, when pressed, fires the respective action without close the notification
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
