class User {
  final int id;
  final String name;
  final String email;
  final String? jlptLevel;
  final String? university;
  final String? studyProgram;
  final String? bio;
  final String? avatarUrl;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.jlptLevel,
    this.university,
    this.studyProgram,
    this.bio,
    this.avatarUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as int,
        name: (json['name'] ?? '') as String,
        email: (json['email'] ?? '') as String,
        jlptLevel: json['jlpt_level'] as String?,
        university: json['university'] as String?,
        studyProgram: json['study_program'] as String?,
        bio: json['bio'] as String?,
        avatarUrl: json['avatar_url'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'jlpt_level': jlptLevel,
        'university': university,
        'study_program': studyProgram,
        'bio': bio,
        'avatar_url': avatarUrl,
      };
}
