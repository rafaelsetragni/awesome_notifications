import 'package:awesome_notifications/awesome_notifications.dart';

import 'chat_keys.dart';

/// Someone taking part in a conversation.
///
/// The same model becomes an `androidx.core.app.Person` on Android and an
/// `INPerson` on iOS and macOS, so an app describes people once.
class NotificationPerson {
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
        ChatKeys.key: key,
        ChatKeys.name: name,
        if (avatar != null) ChatKeys.avatar: avatar,
        if (uri != null) ChatKeys.uri: uri,
        ChatKeys.isBot: isBot,
        ChatKeys.isImportant: isImportant,
      };

  /// Null when [map] is not a valid person.
  static NotificationPerson? fromMap(Map<String, dynamic>? map) {
    if (map == null) return null;
    final key = map[ChatKeys.key], name = map[ChatKeys.name];
    if (key is! String || name is! String) return null;
    return NotificationPerson(
      key: key,
      name: name,
      avatar: map[ChatKeys.avatar] as String?,
      uri: map[ChatKeys.uri] as String?,
      isBot: map[ChatKeys.isBot] == true,
      isImportant: map[ChatKeys.isImportant] == true,
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
