class Item {
  final String id;
  final String title;
  final double price;
  final String category;
  final List<String> imagePaths;
  final String description;
  final String sellerName;
  final String location;
  final String phoneNumber;
  double sellerRating;
  int reviewCount;
  List<Map<String, dynamic>> reviews;
  final DateTime createdAt;
  bool isFavorite;
  final String type;
  final double? deposit;

  Item({
    required this.id,
    required this.title,
    required this.price,
    required this.category,
    required this.imagePaths,
    required this.description,
    required this.sellerName,
    required this.location,
    required this.phoneNumber,
    required this.sellerRating,
    this.reviewCount = 0,
    this.reviews = const [],
    required this.createdAt,
    this.isFavorite = false,
    this.type = 'sale',
    this.deposit,
  });

  String get imagePath => imagePaths.isNotEmpty ? imagePaths.first : '';
  String get priceLabel => type == 'rent' ? '₽/день' : '₽';
  String get depositLabel => type == 'rent' && deposit != null ? 'Залог: ${deposit!.toInt()} ₽' : '';

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'price': price,
    'category': category,
    'imagePaths': imagePaths,
    'description': description,
    'sellerName': sellerName,
    'location': location,
    'phoneNumber': phoneNumber,
    'sellerRating': sellerRating,
    'reviewCount': reviewCount,
    'reviews': reviews,
    'createdAt': createdAt.toIso8601String(),
    'isFavorite': isFavorite,
    'type': type,
    'deposit': deposit,
  };

  factory Item.fromJson(Map<String, dynamic> json) => Item(
    id: json['id'] as String,
    title: json['title'] as String,
    price: (json['price'] as num).toDouble(),
    category: json['category'] as String,
    imagePaths: List<String>.from(json['imagePaths'] ?? []),
    description: json['description'] as String? ?? '',
    sellerName: json['sellerName'] as String,
    location: json['location'] as String? ?? '',
    phoneNumber: json['phoneNumber'] as String? ?? '',
    sellerRating: (json['sellerRating'] as num?)?.toDouble() ?? 0,
    reviewCount: json['reviewCount'] as int? ?? 0,
    reviews: List<Map<String, dynamic>>.from(json['reviews'] ?? []),
    createdAt: DateTime.parse(json['createdAt'] as String),
    isFavorite: json['isFavorite'] as bool? ?? false,
    type: json['type'] as String? ?? 'sale',
    deposit: (json['deposit'] as num?)?.toDouble(),
  );
}