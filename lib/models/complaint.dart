class Complaint {
  final String id;
  final String againstUser;
  final String fromUser;
  final String itemId;
  final String reason;
  final String description;
  final DateTime createdAt;
  String status; // "pending", "reviewed", "resolved"

  Complaint({
    required this.id,
    required this.againstUser,
    required this.fromUser,
    required this.itemId,
    required this.reason,
    required this.description,
    required this.createdAt,
    this.status = 'pending',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'againstUser': againstUser,
    'fromUser': fromUser,
    'itemId': itemId,
    'reason': reason,
    'description': description,
    'createdAt': createdAt.toIso8601String(),
    'status': status,
  };

  factory Complaint.fromJson(Map<String, dynamic> json) => Complaint(
    id: json['id'] as String,
    againstUser: json['againstUser'] as String,
    fromUser: json['fromUser'] as String,
    itemId: json['itemId'] as String,
    reason: json['reason'] as String,
    description: json['description'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    status: json['status'] as String? ?? 'pending',
  );
}