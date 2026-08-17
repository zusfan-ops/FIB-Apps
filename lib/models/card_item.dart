import 'dart:ui';

class Readings {
  final String? on;
  final String? kun;

  Readings({this.on, this.kun});

  factory Readings.fromJson(Map<String, dynamic>? json) => Readings(
        on: json?['on'] as String?,
        kun: json?['kun'] as String?,
      );

  Map<String, dynamic>? toJson() =>
      (on == null && kun == null) ? null : {'on': on, 'kun': kun};

  String get display {
    final parts = <String>[];
    if (kun != null && kun!.isNotEmpty) parts.add('訓 $kun');
    if (on != null && on!.isNotEmpty) parts.add('音 $on');
    return parts.join(' · ');
  }
}

class CardItem {
  final int id;
  final int deckId;
  final String front;
  final Readings? readings;
  final String? meaning;
  final String? exampleSentence;
  final String? exampleTranslation;
  final List<String> tags;
  final String source;
  final int repetition;
  final int interval;
  final double easeFactor;
  final int lapses;
  final String? dueDate;
  final String state;

  CardItem({
    required this.id,
    required this.deckId,
    required this.front,
    this.readings,
    this.meaning,
    this.exampleSentence,
    this.exampleTranslation,
    this.tags = const [],
    this.source = 'manual',
    this.repetition = 0,
    this.interval = 0,
    this.easeFactor = 2.5,
    this.lapses = 0,
    this.dueDate,
    this.state = 'new',
  });

  factory CardItem.fromJson(Map<String, dynamic> json) => CardItem(
        id: json['id'] as int,
        deckId: (json['deck_id'] ?? 0) as int,
        front: (json['front'] ?? '') as String,
        readings: Readings.fromJson(json['readings'] as Map<String, dynamic>?),
        meaning: json['meaning'] as String?,
        exampleSentence: json['example_sentence'] as String?,
        exampleTranslation: json['example_translation'] as String?,
        tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        source: (json['source'] ?? 'manual') as String,
        repetition: (json['repetition'] ?? 0) as int,
        interval: (json['interval'] ?? 0) as int,
        easeFactor: ((json['ease_factor'] ?? 2.5) as num).toDouble(),
        lapses: (json['lapses'] ?? 0) as int,
        dueDate: json['due_date'] as String?,
        state: (json['state'] ?? 'new') as String,
      );

  String get stateLabel => switch (state) {
        'new' => 'Baru',
        'learning' => 'Belajar',
        'review' => 'Review',
        _ => state,
      };

  Color get stateColor => switch (state) {
        'new' => const Color(0xFF4F6EF7),
        'learning' => const Color(0xFFF59E0B),
        'review' => const Color(0xFF10B981),
        _ => const Color(0xFF6B7280),
      };
}
