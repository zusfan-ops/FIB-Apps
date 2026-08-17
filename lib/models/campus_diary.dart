class CampusDiary {
  final int id;
  final int userId;
  final String title;
  final String content;
  final String entryDate;
  final String mood;
  final String category;
  final List<String> tags;
  final bool isPinned;

  const CampusDiary({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    required this.entryDate,
    this.mood = 'semangat',
    this.category = 'kuliah',
    this.tags = const [],
    this.isPinned = false,
  });

  factory CampusDiary.fromJson(Map<String, dynamic> json) {
    var rawTags = json['tags'];
    List<String> parsedTags = [];
    if (rawTags is List) {
      parsedTags = rawTags.map((e) => e.toString()).toList();
    }

    return CampusDiary(
      id: json['id'] as int,
      userId: json['user_id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      entryDate: json['entry_date'] as String? ?? '',
      mood: json['mood'] as String? ?? 'semangat',
      category: json['category'] as String? ?? 'kuliah',
      tags: parsedTags,
      isPinned: json['is_pinned'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'content': content,
        'entry_date': entryDate,
        'mood': mood,
        'category': category,
        'tags': tags,
        'is_pinned': isPinned,
      };

  String get moodEmoji {
    switch (mood.toLowerCase()) {
      case 'semangat':
        return '🔥';
      case 'fokus':
        return '📚';
      case 'santai':
        return '☕';
      case 'produktif':
        return '🎯';
      case 'lelah':
        return '😴';
      default:
        return '🌸';
    }
  }
}
