import '../exceptions/awesome_notifications_exception.dart';


/// Someone taking part in a notification: a conversation's sender, a call's
/// caller.
///
/// The same model becomes an `androidx.core.app.Person` on Android and an
/// `INPerson` on iOS and macOS, so an app describes people once. Add-ons
/// (chat, calls) carry it in their own blocks.
class NotificationPerson {
  /// The map keys, shared with the native side.
  static const String keyKey = 'key',
      keyName = 'name',
      keyAvatar = 'avatar',
      keyUri = 'uri',
      keyIsBot = 'isBot',
      keyIsImportant = 'isImportant';

  /// A stable, unique identifier of the person (an account id, for example).
  final String key;

  /// The name shown in the notification.
  final String name;

  /// The avatar: `asset://`, `file://`, `https://` or `resource://`, like the
  /// other images of the plugin.
  final String? avatar;

  /// A `tel:`, `mailto:` or contact URI. iOS uses a phone or e-mail one as the
  /// person's handle.
  final String? uri;

  /// A machine rather than a human (Android only).
  final bool isBot;

  /// Someone the user talks to often (Android only).
  final bool isImportant;

  const NotificationPerson({
    required this.key,
    required this.name,
    this.avatar,
    this.uri,
    this.isBot = false,
    this.isImportant = false,
  });

  Map<String, dynamic> toMap() => {
        keyKey: key,
        keyName: name,
        if (avatar != null) keyAvatar: avatar,
        if (uri != null) keyUri: uri,
        keyIsBot: isBot,
        keyIsImportant: isImportant,
      };

  /// Null when [map] is not a valid person.
  static NotificationPerson? fromMap(Map<String, dynamic>? map) {
    if (map == null) return null;
    final key = map[keyKey], name = map[keyName];
    if (key is! String || name is! String) return null;
    return NotificationPerson(
      key: key,
      name: name,
      avatar: map[keyAvatar] as String?,
      uri: map[keyUri] as String?,
      isBot: map[keyIsBot] == true,
      isImportant: map[keyIsImportant] == true,
    );
  }

  /// Throws [AwesomeNotificationsException] when a required field is empty.
  void validate(String role) {
    if (key.trim().isEmpty) {
      throw AwesomeNotificationsException(message: 'The $role needs a non-empty key');
    }
    if (name.trim().isEmpty) {
      throw AwesomeNotificationsException(message: 'The $role needs a non-empty name');
    }
  }

  @override
  bool operator ==(Object other) =>
      other is NotificationPerson &&
      other.key == key &&
      other.name == name &&
      other.avatar == avatar &&
      other.uri == uri &&
      other.isBot == isBot &&
      other.isImportant == isImportant;

  @override
  int get hashCode => Object.hash(key, name, avatar, uri, isBot, isImportant);
}
