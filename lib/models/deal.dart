class Deal {
  final String id;
  final String itemId;
  final String itemTitle;
  final String sellerName;
  final String buyerName;
  String status; // "active", "completed", "dispute"
  final DateTime createdAt;
  DateTime? completedAt;

  Deal({
    required this.id,
    required this.itemId,
    required this.itemTitle,
    required this.sellerName,
    required this.buyerName,
    this.status = 'active',
    required this.createdAt,
    this.completedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'itemId': itemId,
    'itemTitle': itemTitle,
    'sellerName': sellerName,
    'buyerName': buyerName,
    'status': status,
    'createdAt': createdAt.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
  };

  factory Deal.fromJson(Map<String, dynamic> json) => Deal(
    id: json['id'] as String,
    itemId: json['itemId'] as String,
    itemTitle: json['itemTitle'] as String,
    sellerName: json['sellerName'] as String,
    buyerName: json['buyerName'] as String,
    status: json['status'] as String? ?? 'active',
    createdAt: DateTime.parse(json['createdAt'] as String),
    completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt'] as String) : null,
  );
}