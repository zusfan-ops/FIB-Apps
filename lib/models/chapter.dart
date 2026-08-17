class ChapterNote {
  final int id;
  final int? pageNo;
  final String content;

  ChapterNote({required this.id, this.pageNo, required this.content});

  factory ChapterNote.fromJson(Map<String, dynamic> json) => ChapterNote(
        id: json['id'] as int,
        pageNo: json['page_no'] as int?,
        content: (json['content'] ?? '') as String,
      );
}

class Chapter {
  final int id;
  final int bookId;
  final String title;
  final int sortOrder;
  final int? pageStart;
  final int? pageEnd;
  final bool isCompleted;
  final List<ChapterNote> notes;

  Chapter({
    required this.id,
    required this.bookId,
    required this.title,
    this.sortOrder = 0,
    this.pageStart,
    this.pageEnd,
    this.isCompleted = false,
    this.notes = const [],
  });

  factory Chapter.fromJson(Map<String, dynamic> json) => Chapter(
        id: json['id'] as int,
        bookId: (json['book_id'] ?? 0) as int,
        title: (json['title'] ?? '') as String,
        sortOrder: (json['sort_order'] ?? 0) as int,
        pageStart: json['page_start'] as int?,
        pageEnd: json['page_end'] as int?,
        isCompleted: (json['is_completed'] ?? false) as bool,
        notes: (json['notes'] as List?)
                ?.map((e) => ChapterNote.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );
}
