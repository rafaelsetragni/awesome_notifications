/// Lets opt-in add-on packages attach extra data to a notification without the
/// core knowing what it is.
///
/// Pass instances through `createNotification(extensions: [...])`. The entries
/// returned by [toMap] are merged into the serialized notification map as
/// siblings of `content` / `schedule` / `actionButtons` — so avoid those reserved
/// keys. The native side (or a registered add-on) reads whatever was contributed.
abstract class NotificationExtension {
  /// Extra entries to merge into the serialized notification map.
  Map<String, dynamic> toMap();
}
