class PhotoComment {
  final int id;
  final int userId;
  final String comment;
  final String? userName;
  final String? userUniversity;
  final String createdAt;

  PhotoComment({
    required this.id,
    required this.userId,
    required this.comment,
    this.userName,
    this.userUniversity,
    required this.createdAt,
  });

  factory PhotoComment.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    return PhotoComment(
      id: json['id'] as int? ?? 0,
      userId: json['user_id'] as int? ?? 0,
      comment: json['comment'] as String? ?? '',
      userName: user?['name'] as String?,
      userUniversity: user?['university'] as String?,
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}

class CampusPhoto {
  final int id;
  final int userId;
  final String title;
  final String? description;
  final String photoUrl;
  final String? eventDate;
  final String location;
  final String category;
  int likesCount;
  int commentsCount;
  bool isLiked;
  final String shareUrl;
  final bool isPublic;
  final String? uploaderName;
  final String? uploaderUniversity;
  final String? uploaderStudyProgram;
  final String? uploaderNim;
  final String? uploaderAvatar;
  final String? uploaderJlpt;
  final String createdAt;
  final List<PhotoComment> comments;

  CampusPhoto({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.photoUrl,
    this.eventDate,
    this.location = 'FIB UNDIP',
    this.category = 'kegiatan',
    this.likesCount = 0,
    this.commentsCount = 0,
    this.isLiked = false,
    this.shareUrl = '',
    this.isPublic = true,
    this.uploaderName,
    this.uploaderUniversity,
    this.uploaderStudyProgram,
    this.uploaderNim,
    this.uploaderAvatar,
    this.uploaderJlpt,
    required this.createdAt,
    this.comments = const [],
  });

  factory CampusPhoto.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    final rawComments = json['comments'] as List<dynamic>? ?? [];
    return CampusPhoto(
      id: json['id'] as int,
      userId: json['user_id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      photoUrl: json['photo_url'] as String? ?? '',
      eventDate: json['event_date'] as String?,
      location: json['location'] as String? ?? 'FIB UNDIP',
      category: json['category'] as String? ?? 'kegiatan',
      likesCount: json['likes_count'] as int? ?? 0,
      commentsCount: json['comments_count'] as int? ?? rawComments.length,
      isLiked: json['is_liked'] as bool? ?? false,
      shareUrl: json['share_url'] as String? ?? 'https://fib.ordr.my.id/p/${json['id']}',
      isPublic: json['is_public'] as bool? ?? true,
      uploaderName: user?['name'] as String?,
      uploaderUniversity: user?['university'] as String?,
      uploaderStudyProgram: user?['study_program'] as String?,
      uploaderNim: user?['nim'] as String?,
      uploaderAvatar: user?['avatar_url'] as String?,
      uploaderJlpt: user?['jlpt_level'] as String?,
      createdAt: json['created_at'] as String? ?? '',
      comments: rawComments
          .map((c) => PhotoComment.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'photo_url': photoUrl,
        'event_date': eventDate,
        'location': location,
        'category': category,
        'is_public': isPublic,
      };
}
