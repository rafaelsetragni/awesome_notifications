/// Defines the notification button's type
/// [ActionButtonType.Default] Default button type
/// [ActionButtonType.InputField] Button when pressed opens a dialog shortcut to send an text response
/// [ActionButtonType.DisabledAction] Button when pressed should just close the notification in tray, but do not fires respective action
/// [ActionButtonType.KeepOnTop] Button, when pressed, fires the respective action without close the notification
enum ActionButtonType {
  /// Default button type
  Default,

  /// Button when pressed opens a dialog shortcut to send an text response
  InputField,

  /// Button when pressed should just close the notification in tray, but do not fires respective action
  DisabledAction,

  /// Button, when pressed, fires the respective action without close the notification
  KeepOnTop
}
