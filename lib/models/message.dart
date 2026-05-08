class Message {
  final String id;
  final String text;
  final bool isMine;
  bool isRead;
  final DateTime timestamp;

  Message({
    required this.id,
    required this.text,
    required this.isMine,
    required this.isRead,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'isMine': isMine,
    'isRead': isRead,
    'timestamp': timestamp.toIso8601String(),
  };

  factory Message.fromJson(Map<String, dynamic> json) => Message(
    id: json['id'] as String,
    text: json['text'] as String,
    isMine: json['isMine'] as bool,
    isRead: json['isRead'] as bool,
    timestamp: DateTime.parse(json['timestamp'] as String),
  );
}