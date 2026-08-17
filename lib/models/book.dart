import 'dart:ui';

class Book {
  final int id;
  final String title;
  final String? author;
  final String? authorJp;
  final String genre;
  final String? originalLanguage;
  final int? totalPages;
  final int currentPage;
  final String status;
  final String coverColor;
  final String? notes;
  final int chaptersCount;
  final int progressPercent;

  Book({
    required this.id,
    required this.title,
    this.author,
    this.authorJp,
    this.genre = 'novel',
    this.originalLanguage,
    this.totalPages,
    this.currentPage = 0,
    this.status = 'to_read',
    this.coverColor = '#E8604C',
    this.notes,
    this.chaptersCount = 0,
    this.progressPercent = 0,
  });

  factory Book.fromJson(Map<String, dynamic> json) => Book(
        id: json['id'] as int,
        title: (json['title'] ?? '') as String,
        author: json['author'] as String?,
        authorJp: json['author_jp'] as String?,
        genre: (json['genre'] ?? 'novel') as String,
        originalLanguage: json['original_language'] as String?,
        totalPages: json['total_pages'] as int?,
        currentPage: (json['current_page'] ?? 0) as int,
        status: (json['status'] ?? 'to_read') as String,
        coverColor: (json['cover_color'] ?? '#E8604C') as String,
        notes: json['notes'] as String?,
        chaptersCount: (json['chapters_count'] ?? 0) as int,
        progressPercent: (json['progress_percent'] ?? 0) as int,
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'author': author,
        'author_jp': authorJp,
        'genre': genre,
        'original_language': originalLanguage,
        'total_pages': totalPages,
        'current_page': currentPage,
        'status': status,
        'cover_color': coverColor,
        'notes': notes,
      };

  String get statusLabel => switch (status) {
        'to_read' => 'Belum dibaca',
        'reading' => 'Sedang dibaca',
        'completed' => 'Selesai',
        _ => status,
      };

  String get genreLabel => switch (genre) {
        'novel' => 'Novel',
        'cerpen' => 'Cerpen',
        'puisi' => 'Puisi',
        'esai' => 'Esai',
        'manga' => 'Manga',
        'lainnya' => 'Lainnya',
        _ => genre,
      };

  Color get colorValue => _hexToColor(coverColor);

  static Color hexToColor(String hex) => _hexToColor(hex);

  static Color _hexToColor(String hex) {
    final h = hex.replaceFirst('#', '');
    final v = int.tryParse(h.length == 6 ? 'FF$h' : h, radix: 16) ?? 0xFFE8604C;
    return Color(v);
  }
}
