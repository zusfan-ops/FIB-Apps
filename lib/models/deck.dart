import 'dart:ui';

class Deck {
  final int id;
  final String name;
  final String? description;
  final String color;
  final String cardType;
  final bool isShared;
  final int cardsCount;

  Deck({
    required this.id,
    required this.name,
    this.description,
    this.color = '#4F6EF7',
    this.cardType = 'kosakata',
    this.isShared = false,
    this.cardsCount = 0,
  });

  factory Deck.fromJson(Map<String, dynamic> json) => Deck(
        id: json['id'] as int,
        name: (json['name'] ?? '') as String,
        description: json['description'] as String?,
        color: (json['color'] ?? '#4F6EF7') as String,
        cardType: (json['card_type'] ?? 'kosakata') as String,
        isShared: (json['is_shared'] ?? false) as bool,
        cardsCount: (json['cards_count'] ?? 0) as int,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'color': color,
        'card_type': cardType,
      };

  Color colorValue() => _hexToColor(color);

  static Color hexToColor(String hex) => _hexToColor(hex);

  static Color _hexToColor(String hex) {
    final h = hex.replaceFirst('#', '');
    final v = int.tryParse(h.length == 6 ? 'FF$h' : h, radix: 16) ?? 0xFF4F6EF7;
    return Color(v);
  }
}
