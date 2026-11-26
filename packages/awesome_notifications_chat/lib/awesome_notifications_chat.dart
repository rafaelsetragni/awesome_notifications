/// Chat notifications for awesome_notifications.
///
/// Attach a [NotificationConversation] to a `Messaging` or `MessagingGroup`
/// notification: Android shows it as a conversation (MessagingStyle with a
/// conversation shortcut), iOS and macOS as a communication notification, and
/// Windows and Linux as a regular notification with the sender and the text.
library;

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'src/chat_keys.dart';
import 'src/notification_conversation.dart';

export 'src/notification_conversation.dart';
/// Moved to the core (shared with the calls add-on); re-exported here.
export 'package:awesome_notifications/awesome_notifications.dart'
    show NotificationPerson;

/// What the conversation notification can do on this platform.
class ChatCapabilities {
  /// The messages already shown stay in the notification.
  final bool history;

  /// The user can type a reply in the notification.
  final bool reply;

  /// The sender's avatar is shown.
  final bool avatar;

  /// It is a conversation of the system (Android Conversations section, iOS
  /// communication notification).
  final bool systemConversation;

  const ChatCapabilities({
    required this.history,
    required this.reply,
    required this.avatar,
    required this.systemConversation,
  });

  static const none =
      ChatCapabilities(history: false, reply: false, avatar: false, systemConversation: false);
}

/// The conversation operations the core doesn't have.
class AwesomeNotificationsChat {
  static final AwesomeNotificationsChat _instance =
      AwesomeNotificationsChat.private(const MethodChannel('awesome_notifications'));
  factory AwesomeNotificationsChat() => _instance;

  @visibleForTesting
  AwesomeNotificationsChat.private(this._channel);

  final MethodChannel _channel;

  /// Where the core runs (Android, iOS, macOS, Windows, Linux). The
  /// presentation varies: check [capabilities].
  static bool get isPlatformSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux);

  /// Adds the reply the user typed in the notification to the conversation
  /// (call it after sending the message). On Android it also ends the
  /// "sending" indicator.
  Future<void> addReply(String conversationId, NotificationMessage message) async {
    if (!isPlatformSupported) return;
    message.validate();
    await _channel.invokeMethod(ChatKeys.methodAddReply, {
      ChatKeys.id: conversationId,
      ChatKeys.message: message.toMap(),
    });
  }

  /// Removes the conversation's notification and forgets its history.
  Future<void> markAsRead(String conversationId) async {
    if (!isPlatformSupported) return;
    await _channel.invokeMethod(ChatKeys.methodMarkAsRead, conversationId);
  }

  /// Same as [markAsRead], and also removes the Android conversation shortcut
  /// (for example, after leaving a group).
  Future<void> removeConversation(String conversationId) async {
    if (!isPlatformSupported) return;
    await _channel.invokeMethod(ChatKeys.methodRemoveConversation, conversationId);
  }

  /// The ids of the conversations with a notification on screen.
  Future<List<String>> listActiveConversations() async {
    if (!isPlatformSupported) return const [];
    final ids = await _channel.invokeListMethod<String>(ChatKeys.methodListActiveConversations);
    return ids ?? const [];
  }

  /// What the conversation notification can do here.
  Future<ChatCapabilities> capabilities() async {
    if (!isPlatformSupported) return ChatCapabilities.none;
    final map = await _channel.invokeMapMethod<String, dynamic>(ChatKeys.methodCapabilities);
    if (map == null) return ChatCapabilities.none;
    return ChatCapabilities(
      history: map['history'] == true,
      reply: map['reply'] == true,
      avatar: map['avatar'] == true,
      systemConversation: map['systemConversation'] == true,
    );
  }

  /// The conversation a received action came from (null when it is not a chat
  /// notification).
  static String? conversationIdOf(ReceivedNotification received) =>
      received.payload?[ChatKeys.conversationId];
}
