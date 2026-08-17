class CourseGrade {
  final int id;
  final String courseName;
  final int credits;
  final String semester;
  final String gradeLetter;
  final double gradePoint;

  const CourseGrade({
    required this.id,
    required this.courseName,
    required this.credits,
    required this.semester,
    required this.gradeLetter,
    required this.gradePoint,
  });

  factory CourseGrade.fromJson(Map<String, dynamic> json) {
    return CourseGrade(
      id: json['id'] as int,
      courseName: json['course_name'] as String? ?? '',
      credits: json['credits'] as int? ?? 2,
      semester: json['semester'] as String? ?? '',
      gradeLetter: json['grade_letter'] as String? ?? 'A',
      gradePoint: (json['grade_point'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'course_name': courseName,
        'credits': credits,
        'semester': semester,
        'grade_letter': gradeLetter,
      };
}

class SemesterSummary {
  final String semester;
  final List<CourseGrade> courses;
  final int credits;
  final double gpa;

  const SemesterSummary({
    required this.semester,
    required this.courses,
    required this.credits,
    required this.gpa,
  });

  factory SemesterSummary.fromJson(String semester, Map<String, dynamic> json) {
    return SemesterSummary(
      semester: semester,
      courses: (json['courses'] as List? ?? [])
          .map((e) => CourseGrade.fromJson(e as Map<String, dynamic>))
          .toList(),
      credits: json['credits'] as int? ?? 0,
      gpa: (json['gpa'] as num?)?.toDouble() ?? 0,
    );
  }
}
