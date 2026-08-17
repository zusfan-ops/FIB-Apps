class ThesisProfile {
  final int id;
  final String? title;
  final String? advisor1;
  final String? advisor2;
  final String? targetDefenseDate;
  final String? notes;

  const ThesisProfile({
    required this.id,
    this.title,
    this.advisor1,
    this.advisor2,
    this.targetDefenseDate,
    this.notes,
  });

  factory ThesisProfile.fromJson(Map<String, dynamic> json) {
    return ThesisProfile(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String?,
      advisor1: json['advisor_1'] as String?,
      advisor2: json['advisor_2'] as String?,
      targetDefenseDate: json['target_defense_date'] as String?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'advisor_1': advisor1,
        'advisor_2': advisor2,
        'target_defense_date': targetDefenseDate,
        'notes': notes,
      };
}
