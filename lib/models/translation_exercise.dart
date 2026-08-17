class TranslationRevision {
  final int id;
  final String content;
  final String? createdAt;

  TranslationRevision({required this.id, required this.content, this.createdAt});

  factory TranslationRevision.fromJson(Map<String, dynamic> json) =>
      TranslationRevision(
        id: json['id'] as int,
        content: (json['content'] ?? '') as String,
        createdAt: json['created_at'] as String?,
      );
}

class TranslationExercise {
  final int id;
  final String title;
  final String sourceText;
  final String? sourceLang;
  final String? targetLang;
  final String? myTranslation;
  final String? bestTranslation;
  final String status;
  final String? notes;
  final int revisionsCount;
  final List<TranslationRevision> revisions;

  TranslationExercise({
    required this.id,
    required this.title,
    required this.sourceText,
    this.sourceLang,
    this.targetLang,
    this.myTranslation,
    this.bestTranslation,
    this.status = 'draft',
    this.notes,
    this.revisionsCount = 0,
    this.revisions = const [],
  });

  factory TranslationExercise.fromJson(Map<String, dynamic> json) =>
      TranslationExercise(
        id: json['id'] as int,
        title: (json['title'] ?? '') as String,
        sourceText: (json['source_text'] ?? '') as String,
        sourceLang: json['source_lang'] as String?,
        targetLang: json['target_lang'] as String?,
        myTranslation: json['my_translation'] as String?,
        bestTranslation: json['best_translation'] as String?,
        status: (json['status'] ?? 'draft') as String,
        notes: json['notes'] as String?,
        revisionsCount: (json['revisions_count'] ?? 0) as int,
        revisions: (json['revisions'] as List?)
                ?.map((e) => TranslationRevision.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'source_text': sourceText,
        'source_lang': sourceLang,
        'target_lang': targetLang,
        'my_translation': myTranslation,
        'best_translation': bestTranslation,
        'status': status,
        'notes': notes,
      };

  String get statusLabel => switch (status) {
        'draft' => 'Draf',
        'in_progress' => 'Dikerjakan',
        'done' => 'Selesai',
        _ => status,
      };
}
