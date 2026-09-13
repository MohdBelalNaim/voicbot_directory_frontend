class RecentChat {
  final String customerId;
  final String customerName;
  final int colorIndex;
  String lastMessage;
  DateTime updatedAt;

  RecentChat({
    required this.customerId,
    required this.customerName,
    required this.colorIndex,
    required this.lastMessage,
    required this.updatedAt,
  });
}

class ChatHistoryStore {
  ChatHistoryStore._();
  static final instance = ChatHistoryStore._();

  final _chats = <RecentChat>[];
  List<RecentChat> get chats => List.unmodifiable(_chats);

  void record(String customerId, String customerName, int colorIndex, String message) {
    final i = _chats.indexWhere((c) => c.customerId == customerId);
    if (i >= 0) {
      _chats[i].lastMessage = message;
      _chats[i].updatedAt = DateTime.now();
      final chat = _chats.removeAt(i);
      _chats.insert(0, chat);
    } else {
      _chats.insert(0, RecentChat(
        customerId: customerId,
        customerName: customerName,
        colorIndex: colorIndex,
        lastMessage: message,
        updatedAt: DateTime.now(),
      ));
    }
  }
}
