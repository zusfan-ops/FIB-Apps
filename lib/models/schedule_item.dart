class ScheduleItem {
  final int id;
  final String title;
  final String? description;
  final String date;
  final String? time;
  final String type;
  final String? course;
  final String? location;
  final String priority;
  final bool isDone;

  ScheduleItem({
    required this.id,
    required this.title,
    this.description,
    required this.date,
    this.time,
    this.type = 'tugas',
    this.course,
    this.location,
    this.priority = 'medium',
    this.isDone = false,
  });

  factory ScheduleItem.fromJson(Map<String, dynamic> json) => ScheduleItem(
        id: json['id'] as int,
        title: (json['title'] ?? '') as String,
        description: json['description'] as String?,
        date: (json['date'] ?? '').toString().substring(0, 10),
        time: json['time'] as String?,
        type: (json['type'] ?? 'tugas') as String,
        course: json['course'] as String?,
        location: json['location'] as String?,
        priority: (json['priority'] ?? 'medium') as String,
        isDone: (json['is_done'] ?? false) as bool,
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'date': date,
        'time': time,
        'type': type,
        'course': course,
        'location': location,
        'priority': priority,
      };

  String get typeLabel => switch (type) {
        'kuliah' => 'Kuliah',
        'deadline' => 'Deadline',
        'tugas' => 'Tugas',
        'uts' => 'UTS',
        'uas' => 'UAS',
        'kegiatan' => 'Kegiatan',
        'pengingat' => 'Pengingat',
        _ => type,
      };

  String get timeLabel {
    if (time == null || time!.isEmpty) return '';
    return time!.substring(0, 5);
  }
}
