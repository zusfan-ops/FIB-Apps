class GrammarPattern {
  final int id;
  final String pattern;
  final String? meaning;
  final String? structure;
  final String? usage;
  final List<Map<String, String>> examples;
  final String? notes;
  final bool isBungo;
  final List<String> tags;

  GrammarPattern({
    required this.id,
    required this.pattern,
    this.meaning,
    this.structure,
    this.usage,
    this.examples = const [],
    this.notes,
    this.isBungo = false,
    this.tags = const [],
  });

  factory GrammarPattern.fromJson(Map<String, dynamic> json) => GrammarPattern(
        id: json['id'] as int,
        pattern: (json['pattern'] ?? '') as String,
        meaning: json['meaning'] as String?,
        structure: json['structure'] as String?,
        usage: json['usage'] as String?,
        examples: (json['examples'] as List?)
                ?.map((e) => Map<String, String>.from(e as Map))
                .toList() ??
            const [],
        notes: json['notes'] as String?,
        isBungo: (json['is_bungo'] ?? false) as bool,
        tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      );

  Map<String, dynamic> toJson() => {
        'pattern': pattern,
        'meaning': meaning,
        'structure': structure,
        'usage': usage,
        'examples': examples,
        'notes': notes,
        'is_bungo': isBungo,
        'tags': tags,
      };
}
