class PlanTask {
  final int id;
  final String title;
  final String? description;
  final String column;
  final int order;
  final String? dueDate;
  final int? scheduleItemId;

  PlanTask({
    required this.id,
    required this.title,
    this.description,
    this.column = 'todo',
    this.order = 0,
    this.dueDate,
    this.scheduleItemId,
  });

  factory PlanTask.fromJson(Map<String, dynamic> json) => PlanTask(
        id: json['id'] as int,
        title: (json['title'] ?? '') as String,
        description: json['description'] as String?,
        column: (json['column'] ?? 'todo') as String,
        order: (json['order'] ?? 0) as int,
        dueDate: json['due_date'] as String?,
        scheduleItemId: json['schedule_item_id'] as int?,
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'column': column,
        'due_date': dueDate,
        'schedule_item_id': scheduleItemId,
      };
}
