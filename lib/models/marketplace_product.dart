import 'user.dart';

class MarketplaceProduct {
  final int id;
  final int userId;
  final String title;
  final String description;
  final int price;
  final String category;
  final String condition;
  final String? imageUrl;
  final String? contactWhatsapp;
  final String? location;
  final bool isSold;
  final DateTime createdAt;
  final User? user;

  const MarketplaceProduct({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.price,
    this.category = 'buku',
    this.condition = 'bekas_seperti_baru',
    this.imageUrl,
    this.contactWhatsapp,
    this.location,
    this.isSold = false,
    required this.createdAt,
    this.user,
  });

  factory MarketplaceProduct.fromJson(Map<String, dynamic> json) {
    return MarketplaceProduct(
      id: json['id'] as int,
      userId: json['user_id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: (json['price'] as num?)?.toInt() ?? 0,
      category: json['category'] as String? ?? 'buku',
      condition: json['condition'] as String? ?? 'bekas_seperti_baru',
      imageUrl: json['image_url'] as String?,
      contactWhatsapp: json['contact_whatsapp'] as String?,
      location: json['location'] as String?,
      isSold: json['is_sold'] == true || json['is_sold'] == 1,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())?.toLocal() ?? DateTime.now()
          : DateTime.now(),
      user: json['user'] != null && json['user'] is Map<String, dynamic>
          ? User.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'price': price,
        'category': category,
        'condition': condition,
        'image_url': imageUrl,
        'contact_whatsapp': contactWhatsapp,
        'location': location,
        'is_sold': isSold,
      };

  String get formattedPrice {
    if (price <= 0) return 'Gratis / Nego';
    final str = price.toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count % 3 == 0 && i != 0) buffer.write('.');
    }
    return 'Rp ${buffer.toString().split('').reversed.join()}';
  }

  String get categoryLabel => switch (category.toLowerCase()) {
        'buku' => 'Buku & Modul Kuliah',
        'merchandise' => 'Merchandise & Kriya',
        'elektronik' => 'Elektronik & Gadget',
        'fashion' => 'Pakaian & Aksesoris',
        'makanan' => 'Kuliner & Snack',
        'jasa' => 'Jasa / Proofreading',
        _ => 'Lainnya',
      };

  String get conditionLabel => switch (condition.toLowerCase()) {
        'baru' => 'Baru (Gress)',
        'bekas_seperti_baru' => 'Bekas Seperti Baru',
        'bekas_layak' => 'Bekas Masih Layak',
        _ => condition,
      };
}
