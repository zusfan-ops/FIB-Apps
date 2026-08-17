import 'package:flutter/material.dart';

import '../../models/book.dart';
import '../../models/chapter.dart';
import '../../services/api_client.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/global_bottom_nav_bar.dart';
import '../srs/review_screen.dart';
import 'clip_form_screen.dart';

class BookDetailScreen extends StatefulWidget {
  final Book book;

  const BookDetailScreen({super.key, required this.book});

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  List<Chapter>? _chapters;
  Object? _error;
  bool _showAddChapter = false;
  final _chapterTitle = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _chapterTitle.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final data = await ApiClient.instance
          .get('/books/${widget.book.id}/chapters') as List;
      if (mounted) {
        setState(() => _chapters = data
            .map((e) => Chapter.fromJson(e as Map<String, dynamic>))
            .toList());
      }
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _addChapter() async {
    if (_chapterTitle.text.trim().isEmpty) return;
    try {
      await ApiClient.instance.post('/books/${widget.book.id}/chapters', {
        'title': _chapterTitle.text.trim(),
      });
      _chapterTitle.clear();
      setState(() => _showAddChapter = false);
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _toggleChapter(Chapter chapter) async {
    try {
      await ApiClient.instance.post('/chapters/${chapter.id}/progress', {
        'is_completed': !chapter.isCompleted,
      });
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _addNote(Chapter chapter) async {
    final content = await _promptNote(context);
    if (content == null || content.trim().isEmpty) return;

    try {
      await ApiClient.instance
          .post('/chapters/${chapter.id}/notes', {'content': content.trim()});
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _deleteNote(int noteId) async {
    try {
      await ApiClient.instance.delete('/notes/$noteId');
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.book.title)),
      bottomNavigationBar: const GlobalBottomNavBar(selectedIndex: 2),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return ListView(children: [ErrorView(message: _error.toString(), onRetry: _load)]);
    }
    if (_chapters == null) return const LoadingView();

    final chapters = _chapters!;
    final completedCount = chapters.where((c) => c.isCompleted).length;

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        _buildHeader(),
        SectionHeader(
          title: 'Bab ($completedCount/${chapters.length})',
          trailing: TextButton.icon(
            onPressed: () => setState(() => _showAddChapter = !_showAddChapter),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Bab'),
          ),
        ),
        if (_showAddChapter)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chapterTitle,
                    decoration: const InputDecoration(hintText: 'Judul bab...'),
                  ),
                ),
                IconButton(
                  onPressed: _addChapter,
                  icon: const Icon(Icons.check, color: AppColors.primary),
                ),
              ],
            ),
          ),
        if (chapters.isEmpty)
          const EmptyState(message: 'Belum ada bab. Tambahkan bab pertama!',
              icon: Icons.library_books_outlined)
        else
          ...chapters.map((c) => _buildChapterCard(c)),
      ],
    );
  }

  Widget _buildHeader() {
    final book = widget.book;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [book.colorValue, book.colorValue.withValues(alpha: 0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(book.title,
              style: const TextStyle(
                  color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
          if (book.author != null)
            Text(book.author!,
                style: const TextStyle(color: Colors.white70, fontSize: 14)),
          if (book.authorJp != null)
            Text(book.authorJp!,
                style: const TextStyle(color: Colors.white60, fontSize: 12)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Halaman ${book.currentPage}${book.totalPages != null ? '/${book.totalPages}' : ''}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: (book.progressPercent / 100).clamp(0, 1),
                        minHeight: 8,
                        backgroundColor: Colors.white24,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                children: [
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context)
                        .push(MaterialPageRoute(
                            builder: (_) =>
                                ClipFormScreen(bookId: book.id)))
                        .then((_) {}),
                    icon: const Icon(Icons.content_copy, size: 18),
                    label: const Text('Klip'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: book.colorValue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context)
                        .push(MaterialPageRoute(builder: (_) => const ReviewScreen()))
                        .then((_) {}),
                    icon: const Icon(Icons.style, size: 18),
                    label: const Text('Review'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChapterCard(Chapter chapter) {
    return Card(
      child: ExpansionTile(
        leading: Checkbox(
          value: chapter.isCompleted,
          onChanged: (_) => _toggleChapter(chapter),
        ),
        title: Text(chapter.title,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          'Hlm. ${chapter.pageStart ?? '-'}${chapter.pageEnd != null ? '–${chapter.pageEnd}' : ''}',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
        children: [
          if (chapter.notes.isNotEmpty)
            ...chapter.notes.map((n) => ListTile(
                  dense: true,
                  leading: const Icon(Icons.sticky_note_2_outlined, size: 20, color: Colors.grey),
                  title: Text(n.content),
                  subtitle: n.pageNo != null ? Text('Hlm. ${n.pageNo}') : null,
                  trailing: IconButton(
                    icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                    onPressed: () => _deleteNote(n.id),
                  ),
                )),
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 16, right: 16),
            child: Row(
              children: [
                const Icon(Icons.add_comment_outlined, size: 18, color: AppColors.primary),
                const SizedBox(width: 6),
                TextButton(
                  onPressed: () => _addNote(chapter),
                  child: const Text('Tambah catatan analisis'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<String?> _promptNote(BuildContext context) async {
    final controller = TextEditingController();
    final pageController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Catatan analisis'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: pageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Halaman (opsional)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 4,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Isi catatan'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          FilledButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Simpan')),
        ],
      ),
    );
    return result;
  }
}
