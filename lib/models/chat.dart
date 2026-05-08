import 'message.dart';

class Chat {
  final String id;
  final String itemId;
  final String itemTitle;
  final String itemImage;
  final String participantName;
  final String participantPhone;
  List<Message> messages;
  final DateTime createdAt;
  String lastMessage;
  DateTime lastMessageTime;

  Chat({
    required this.id,
    required this.itemId,
    required this.itemTitle,
    required this.itemImage,
    required this.participantName,
    required this.participantPhone,
    required this.messages,
    required this.createdAt,
    String? lastMessage,
    DateTime? lastMessageTime,
  }) : lastMessage = lastMessage ?? '',
       lastMessageTime = lastMessageTime ?? createdAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'itemId': itemId,
    'itemTitle': itemTitle,
    'itemImage': itemImage,
    'participantName': participantName,
    'participantPhone': participantPhone,
    'messages': messages.map((m) => m.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'lastMessage': lastMessage,
    'lastMessageTime': lastMessageTime.toIso8601String(),
  };

  factory Chat.fromJson(Map<String, dynamic> json) => Chat(
    id: json['id'] as String,
    itemId: json['itemId'] as String,
    itemTitle: json['itemTitle'] as String,
    itemImage: json['itemImage'] as String,
    participantName: json['participantName'] as String,
    participantPhone: json['participantPhone'] as String,
    messages: (json['messages'] as List<dynamic>?)
        ?.map((m) => Message.fromJson(m as Map<String, dynamic>))
        .toList() ?? [],
    createdAt: DateTime.parse(json['createdAt'] as String),
    lastMessage: json['lastMessage'] as String?,
    lastMessageTime: json['lastMessageTime'] != null
        ? DateTime.parse(json['lastMessageTime'] as String)
        : null,
  );
}