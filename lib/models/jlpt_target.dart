class JlptChecklistItem {
  final int id;
  final String name;
  final bool isDone;

  JlptChecklistItem({required this.id, required this.name, this.isDone = false});

  factory JlptChecklistItem.fromJson(Map<String, dynamic> json) =>
      JlptChecklistItem(
        id: json['id'] as int,
        name: (json['name'] ?? '') as String,
        isDone: (json['is_done'] ?? false) as bool,
      );
}

class JlptTarget {
  final int id;
  final String level;
  final String? title;
  final String? targetDate;
  final bool isActive;
  final int? daysLeft;
  final int progressPercent;
  final List<JlptChecklistItem> checklistItems;

  JlptTarget({
    required this.id,
    required this.level,
    this.title,
    this.targetDate,
    this.isActive = true,
    this.daysLeft,
    this.progressPercent = 0,
    this.checklistItems = const [],
  });

  factory JlptTarget.fromJson(Map<String, dynamic> json) => JlptTarget(
        id: json['id'] as int,
        level: (json['level'] ?? 'N3') as String,
        title: json['title'] as String?,
        targetDate: json['target_date'] as String?,
        isActive: (json['is_active'] ?? true) as bool,
        daysLeft: json['days_left'] as int?,
        progressPercent: (json['progress_percent'] ?? 0) as int,
        checklistItems: (json['checklist_items'] as List?)
                ?.map((e) => JlptChecklistItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );

  Map<String, dynamic> toJson() => {
        'level': level,
        'title': title,
        'target_date': targetDate,
      };
}
