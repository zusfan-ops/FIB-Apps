class Clip {
  final int id;
  final String expression;
  final String? reading;
  final String? meaning;
  final String? contextSentence;
  final String? translation;
  final int? bookId;
  final String? bookTitle;
  final int? cardId;
  final String? cardFront;
  final String? createdAt;

  Clip({
    required this.id,
    required this.expression,
    this.reading,
    this.meaning,
    this.contextSentence,
    this.translation,
    this.bookId,
    this.bookTitle,
    this.cardId,
    this.cardFront,
    this.createdAt,
  });

  factory Clip.fromJson(Map<String, dynamic> json) {
    final book = json['book'] as Map<String, dynamic>?;
    final card = json['card'] as Map<String, dynamic>?;
    return Clip(
      id: json['id'] as int,
      expression: (json['expression'] ?? '') as String,
      reading: json['reading'] as String?,
      meaning: json['meaning'] as String?,
      contextSentence: json['context_sentence'] as String?,
      translation: json['translation'] as String?,
      bookId: json['book_id'] as int?,
      bookTitle: book?['title'] as String?,
      cardId: json['card_id'] as int?,
      cardFront: card?['front'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'expression': expression,
        'reading': reading,
        'meaning': meaning,
        'context_sentence': contextSentence,
        'translation': translation,
        'book_id': bookId,
      };
}
