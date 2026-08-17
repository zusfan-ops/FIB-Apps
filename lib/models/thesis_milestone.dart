class ThesisMilestone {
  final int id;
  final String title;
  final String status; // todo, doing, done
  final int order;
  final String? notes;

  const ThesisMilestone({
    required this.id,
    required this.title,
    this.status = 'todo',
    this.order = 0,
    this.notes,
  });

  factory ThesisMilestone.fromJson(Map<String, dynamic> json) {
    return ThesisMilestone(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      status: json['status'] as String? ?? 'todo',
      order: json['order'] as int? ?? 0,
      notes: json['notes'] as String?,
    );
  }

  String get statusLabel => switch (status) {
        'doing' => 'Sedang Dikerjakan',
        'done' => 'Selesai',
        _ => 'Belum Dimulai',
      };
}
