enum ChatRole { user, assistant }

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.moduleContext,
    this.cloudSyncPending = false,
  });

  final String id;
  final ChatRole role;
  final String content;
  final DateTime timestamp;
  final String? moduleContext;

  /// True when the message is saved locally but Firestore sync failed (retry later).
  final bool cloudSyncPending;
}
