class DictionaryEntry {
  final int id;
  final String term;
  final String? readingOn;
  final String? readingKun;
  final String meaning;
  final String? exampleSentence;
  final String? exampleTranslation;
  final String category; // kanji, kosakata
  final String jlptLevel; // N5..N1

  const DictionaryEntry({
    required this.id,
    required this.term,
    this.readingOn,
    this.readingKun,
    required this.meaning,
    this.exampleSentence,
    this.exampleTranslation,
    this.category = 'kosakata',
    this.jlptLevel = 'N5',
  });

  factory DictionaryEntry.fromJson(Map<String, dynamic> json) {
    return DictionaryEntry(
      id: json['id'] as int,
      term: json['term'] as String? ?? '',
      readingOn: json['reading_on'] as String?,
      readingKun: json['reading_kun'] as String?,
      meaning: json['meaning'] as String? ?? '',
      exampleSentence: json['example_sentence'] as String?,
      exampleTranslation: json['example_translation'] as String?,
      category: json['category'] as String? ?? 'kosakata',
      jlptLevel: json['jlpt_level'] as String? ?? 'N5',
    );
  }

  String get readingLabel {
    final parts = <String>[
      if (readingKun != null && readingKun!.isNotEmpty) readingKun!,
      if (readingOn != null && readingOn!.isNotEmpty) readingOn!,
    ];
    return parts.join(' / ');
  }
}
