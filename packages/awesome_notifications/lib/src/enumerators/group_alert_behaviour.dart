/// Sets the group alert behavior for this notification. Use this method to mute this notification if alerts for this notification's group should be handled by a different notification. This is only applicable for notifications that belong to a group.
/// [GroupAlertBehavior.All] All notifications in a group with sound or vibration ought to make sound or vibrate (respectively), so this notification will not be muted when it is in a group.
/// [GroupAlertBehavior.Summary] All children notification in a group should be silenced (no sound or vibration) even if they would otherwise make sound or vibrate.
/// [GroupAlertBehavior.Children] The summary notification in a group should be silenced (no sound or vibration) even if they would otherwise make sound or vibrate
enum GroupAlertBehavior {
  /// All notifications in a group with sound or vibration ought to make sound or vibrate (respectively), so this notification will not be muted when it is in a group.
  All,

  /// All children notification in a group should be silenced (no sound or vibration) even if they would otherwise make sound or vibrate.
  Summary,

  /// The summary notification in a group should be silenced (no sound or vibration) even if they would otherwise make sound or vibrate
  Children
}
