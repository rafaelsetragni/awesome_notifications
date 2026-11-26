/// Map keys of the `conversation` block, shared with the native decorators.
abstract final class ChatKeys {
  static const conversation = 'conversation';

  // Conversation
  static const id = 'id';
  static const title = 'title';
  static const me = 'me';
  static const message = 'message';
  static const participants = 'participants';
  static const image = 'image';
  static const history = 'history';
  static const shortcut = 'shortcut';

  // Message
  static const sender = 'sender';
  static const text = 'text';
  static const timestamp = 'timestamp';

  /// Added to the content payload so actions tell which conversation they
  /// came from.
  static const conversationId = 'conversationId';

  // Channel methods of AwesomeNotificationsChat
  static const methodAddReply = 'chatAddReply';
  static const methodMarkAsRead = 'chatMarkAsRead';
  static const methodRemoveConversation = 'chatRemoveConversation';
  static const methodListActiveConversations = 'chatListActiveConversations';
  static const methodCapabilities = 'chatCapabilities';
}
