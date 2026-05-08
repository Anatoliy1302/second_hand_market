class Booking {
  final String id;
  final String itemId;
  final String itemTitle;
  final String renterName;
  final String ownerName;
  final double depositAmount;
  bool depositBlocked;
  bool depositReturned;
  String status;
  final DateTime createdAt;

  Booking({
    required this.id,
    required this.itemId,
    required this.itemTitle,
    required this.renterName,
    required this.ownerName,
    required this.depositAmount,
    this.depositBlocked = false,
    this.depositReturned = false,
    this.status = 'active',
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'itemId': itemId,
    'itemTitle': itemTitle,
    'renterName': renterName,
    'ownerName': ownerName,
    'depositAmount': depositAmount,
    'depositBlocked': depositBlocked,
    'depositReturned': depositReturned,
    'status': status,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Booking.fromJson(Map<String, dynamic> json) => Booking(
    id: json['id'] as String,
    itemId: json['itemId'] as String,
    itemTitle: json['itemTitle'] as String,
    renterName: json['renterName'] as String,
    ownerName: json['ownerName'] as String,
    depositAmount: (json['depositAmount'] as num).toDouble(),
    depositBlocked: json['depositBlocked'] as bool? ?? false,
    depositReturned: json['depositReturned'] as bool? ?? false,
    status: json['status'] as String? ?? 'active',
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}