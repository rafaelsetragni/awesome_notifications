import 'package:awesome_notifications/awesome_notifications.dart';

import 'chat_keys.dart';
import 'notification_person.dart';

/// One message of a conversation.
class NotificationMessage {
  /// Who sent it: the conversation's `me` for a message the user sent.
  final NotificationPerson sender;

  /// The text, without markup.
  final String text;

  /// When it was sent; now when absent. Sent in UTC, like every date of the
  /// plugin.
  final DateTime? timestamp;

  /// An image sent with the message (Android shows it in the conversation; iOS
  /// attaches it to the notification).
  final String? image;

  const NotificationMessage({
    required this.sender,
    required this.text,
    this.timestamp,
    this.image,
  });

  Map<String, dynamic> toMap() => {
        ChatKeys.sender: sender.toMap(),
        ChatKeys.text: text,
        if (timestamp != null)
          ChatKeys.timestamp: AwesomeDateUtils.parseDateToString(timestamp!.toUtc()),
        if (image != null) ChatKeys.image: image,
      };

  void validate() {
    sender.validate('message sender');
    if (text.trim().isEmpty) {
      throw const AwesomeNotificationsException(message: 'The message needs a non-empty text');
    }
  }
}

/// How a new message relates to the conversation already on screen.
enum ConversationHistory {
  /// Added to the messages already shown (Android keeps the last 25).
  append,

  /// Shown alone, replacing them.
  replace,
}

/// A chat message, attached to a notification through `createNotification`'s
/// `extensions`.
///
/// With this package installed, the `Messaging` (one-to-one) and
/// `MessagingGroup` (group) layouts require it, and it is only accepted with
/// one of them:
///
/// ```dart
/// await AwesomeNotifications().createNotification(
///   content: NotificationContent(
///     id: 10,
///     channelKey: 'chat',
///     notificationLayout: NotificationLayout.MessagingGroup,
///   ),
///   extensions: [
///     NotificationConversation(
///       id: 'family',
///       title: 'Family',
///       me: me,
///       participants: [ana],
///       message: NotificationMessage(sender: ana, text: 'On my way'),
///     ),
///   ],
/// );
/// ```
class NotificationConversation implements NotificationExtension {
  /// A stable id of the conversation: the Android conversation shortcut and
  /// the iOS conversation identifier / thread.
  final String id;

  /// The user of the device.
  final NotificationPerson me;

  /// The new message.
  final NotificationMessage message;

  /// The group's name; required with `MessagingGroup`.
  final String? title;

  /// The other people of the conversation; required with `MessagingGroup`.
  final List<NotificationPerson> participants;

  /// The group's picture.
  final String? image;

  final ConversationHistory history;

  /// Publishes the Android conversation shortcut that puts the notification
  /// in the Conversations section (Android 11+).
  final bool shortcut;

  const NotificationConversation({
    required this.id,
    required this.me,
    required this.message,
    this.title,
    this.participants = const [],
    this.image,
    this.history = ConversationHistory.append,
    this.shortcut = true,
  });

  /// Throws [AwesomeNotificationsException] when the conversation is invalid.
  /// Whether it suits the layout is checked natively (where push messages are
  /// checked too).
  void validate() {
    if (id.trim().isEmpty) {
      throw const AwesomeNotificationsException(message: 'The conversation needs a non-empty id');
    }
    me.validate('conversation me');
    message.validate();
    final keys = <String>{me.key};
    for (final person in participants) {
      person.validate('participant');
      if (!keys.add(person.key)) {
        throw AwesomeNotificationsException(
            message: 'The person key "${person.key}" is repeated in the conversation');
      }
    }
  }

  /// Validates, then serializes under the `conversation` key (called by the
  /// core's `createNotification`, before anything reaches the platform).
  @override
  Map<String, dynamic> toMap() {
    validate();
    return {
      ChatKeys.conversation: {
        ChatKeys.id: id,
        ChatKeys.me: me.toMap(),
        ChatKeys.message: message.toMap(),
        if (title != null) ChatKeys.title: title,
        ChatKeys.participants: [for (final p in participants) p.toMap()],
        if (image != null) ChatKeys.image: image,
        ChatKeys.history: history.name,
        ChatKeys.shortcut: shortcut,
      },
    };
  }
}
