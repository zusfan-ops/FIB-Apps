import 'package:flutter/material.dart';

import '../../models/book.dart';
import '../../services/api_client.dart';
import '../../widgets/common.dart';
import 'book_form_screen.dart';
import 'book_detail_screen.dart';
import 'clip_form_screen.dart';
import 'clip_list_screen.dart';

class ReadingHomeScreen extends StatefulWidget {
  const ReadingHomeScreen({super.key});

  @override
  State<ReadingHomeScreen> createState() => _ReadingHomeScreenState();
}

class _ReadingHomeScreenState extends State<ReadingHomeScreen>
    with SingleTickerProviderStateMixin {
  List<Book>? _books;
  Object? _error;
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() {
      if (_tab.indexIsChanging) _reloadActive();
    });
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final data = await ApiClient.instance.get('/books') as List;
      if (mounted) {
        setState(() => _books =
            data.map((e) => Book.fromJson(e as Map<String, dynamic>)).toList());
      }
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  void _reloadActive() => _load();

  Future<void> _addBook() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const BookFormScreen()),
    );
    if (result == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Baca & Klip'),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: 'Buku'),
            Tab(text: 'Klip'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _tab.index == 0
            ? _addBook
            : () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const ClipFormScreen()))
                .then((_) => _reloadActive()),
        icon: const Icon(Icons.add),
        label: Text(_tab.index == 0 ? 'Buku' : 'Klip'),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _buildBooks(),
          ClipListScreen(onChanged: _reloadActive),
        ],
      ),
    );
  }

  Widget _buildBooks() {
    if (_error != null) {
      return ListView(children: [ErrorView(message: _error.toString(), onRetry: _load)]);
    }
    if (_books == null) return const LoadingView();

    final reading = _books!.where((b) => b.status == 'reading').toList();
    final toRead = _books!.where((b) => b.status == 'to_read').toList();
    final completed = _books!.where((b) => b.status == 'completed').toList();

    return ListView(
      padding: const EdgeInsets.only(bottom: 88),
      children: [
        if (_books!.isEmpty)
          const EmptyState(
              message: 'Belum ada buku. Tambahkan karya yang ingin kamu baca!',
              icon: Icons.menu_book_outlined),
        if (reading.isNotEmpty) ...[
          const SectionHeader(title: 'Sedang Dibaca'),
          ...reading.map((b) => _bookCard(b)),
        ],
        if (toRead.isNotEmpty) ...[
          const SectionHeader(title: 'Daftar Baca'),
          ...toRead.map((b) => _bookCard(b)),
        ],
        if (completed.isNotEmpty) ...[
          const SectionHeader(title: 'Selesai'),
          ...completed.map((b) => _bookCard(b)),
        ],
      ],
    );
  }

  Widget _bookCard(Book book) {
    return Card(
      child: ListTile(
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => BookDetailScreen(book: book)))
            .then((_) => _load()),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: book.colorValue.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            book.genre == 'puisi' ? Icons.auto_stories_outlined : Icons.menu_book,
            color: book.colorValue,
          ),
        ),
        title: Text(book.title, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(
            [
              if (book.author != null) book.author!,
              book.genreLabel,
              if (book.progressPercent > 0) '${book.progressPercent}%',
            ].join(' · '),
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
        trailing: book.status == 'completed'
            ? const Icon(Icons.check_circle, color: Color(0xFF10B981))
            : const Icon(Icons.chevron_right, color: Colors.grey),
      ),
    );
  }
}
