class ClassSchedule {
  final int id;
  final int userId;
  final String subject;
  final String? code;
  final String? lecturer;
  final String? room;
  final int dayOfWeek; // 1 = Senin, ..., 7 = Minggu
  final String startTime;
  final String endTime;
  final int credits;
  final int reminderMinutes;
  final String color;
  final String? notes;
  final bool isImminent;
  final int minutesUntilStart;

  const ClassSchedule({
    required this.id,
    required this.userId,
    required this.subject,
    this.code,
    this.lecturer,
    this.room,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.credits = 2,
    this.reminderMinutes = 120,
    this.color = '#4F6EF7',
    this.notes,
    this.isImminent = false,
    this.minutesUntilStart = 0,
  });

  factory ClassSchedule.fromJson(Map<String, dynamic> json) {
    return ClassSchedule(
      id: json['id'] as int,
      userId: json['user_id'] as int? ?? 0,
      subject: json['subject'] as String? ?? '',
      code: json['code'] as String?,
      lecturer: json['lecturer'] as String?,
      room: json['room'] as String?,
      dayOfWeek: json['day_of_week'] as int? ?? 1,
      startTime: json['start_time'] as String? ?? '08:00',
      endTime: json['end_time'] as String? ?? '09:40',
      credits: json['credits'] as int? ?? 2,
      reminderMinutes: json['reminder_minutes'] as int? ?? 120,
      color: json['color'] as String? ?? '#4F6EF7',
      notes: json['notes'] as String?,
      isImminent: json['is_imminent'] as bool? ?? false,
      minutesUntilStart: json['minutes_until_start'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'subject': subject,
        'code': code,
        'lecturer': lecturer,
        'room': room,
        'day_of_week': dayOfWeek,
        'start_time': startTime,
        'end_time': endTime,
        'credits': credits,
        'reminder_minutes': reminderMinutes,
        'color': color,
        'notes': notes,
      };

  String get dayName {
    switch (dayOfWeek) {
      case 1:
        return 'Senin';
      case 2:
        return 'Selasa';
      case 3:
        return 'Rabu';
      case 4:
        return 'Kamis';
      case 5:
        return 'Jumat';
      case 6:
        return 'Sabtu';
      case 7:
        return 'Minggu';
      default:
        return 'Senin';
    }
  }

  String get formattedTime {
    final s = startTime.length >= 5 ? startTime.substring(0, 5) : startTime;
    final e = endTime.length >= 5 ? endTime.substring(0, 5) : endTime;
    return '$s - $e';
  }
}
