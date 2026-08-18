class User {
  final int id;
  final String name;
  final String email;
  final String? nim;
  final String? phoneNumber;
  final String? jlptLevel;
  final String? university;
  final String? studyProgram;
  final String? semester;
  final String? angkatan;
  final String? bio;
  final String? avatarUrl;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.nim,
    this.phoneNumber,
    this.jlptLevel,
    this.university,
    this.studyProgram,
    this.semester,
    this.angkatan,
    this.bio,
    this.avatarUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as int,
        name: (json['name'] ?? '') as String,
        email: (json['email'] ?? '') as String,
        nim: json['nim'] as String?,
        phoneNumber: json['phone_number'] as String?,
        jlptLevel: json['jlpt_level'] as String?,
        university: json['university'] as String?,
        studyProgram: json['study_program'] as String?,
        semester: json['semester']?.toString(),
        angkatan: json['angkatan']?.toString(),
        bio: json['bio'] as String?,
        avatarUrl: json['avatar_url'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'nim': nim,
        'phone_number': phoneNumber,
        'jlpt_level': jlptLevel,
        'university': university,
        'study_program': studyProgram,
        'semester': semester,
        'angkatan': angkatan,
        'bio': bio,
        'avatar_url': avatarUrl,
      };
}
