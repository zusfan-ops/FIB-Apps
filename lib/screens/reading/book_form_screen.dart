import 'package:flutter/material.dart';

import '../../models/book.dart';
import '../../services/api_client.dart';

class BookFormScreen extends StatefulWidget {
  final Book? book;

  const BookFormScreen({super.key, this.book});

  @override
  State<BookFormScreen> createState() => _BookFormScreenState();
}

class _BookFormScreenState extends State<BookFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _author;
  late final TextEditingController _authorJp;
  late final TextEditingController _totalPages;
  late final TextEditingController _notes;
  String _genre = 'novel';
  String _status = 'to_read';
  String _color = '#4F6EF7';
  bool _loading = false;

  static const _colors = ['#4F6EF7', '#E8604C', '#10B981', '#F59E0B', '#8B5CF6', '#EC4899'];

  bool get _isEdit => widget.book != null;

  @override
  void initState() {
    super.initState();
    final b = widget.book;
    _title = TextEditingController(text: b?.title ?? '');
    _author = TextEditingController(text: b?.author ?? '');
    _authorJp = TextEditingController(text: b?.authorJp ?? '');
    _totalPages = TextEditingController(text: b?.totalPages?.toString() ?? '');
    _notes = TextEditingController(text: b?.notes ?? '');
    _genre = b?.genre ?? 'novel';
    _status = b?.status ?? 'to_read';
    _color = b?.coverColor ?? '#4F6EF7';
  }

  @override
  void dispose() {
    _title.dispose();
    _author.dispose();
    _authorJp.dispose();
    _totalPages.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final body = {
      'title': _title.text.trim(),
      'author': _author.text.trim().isEmpty ? null : _author.text.trim(),
      'author_jp': _authorJp.text.trim().isEmpty ? null : _authorJp.text.trim(),
      'genre': _genre,
      'total_pages': int.tryParse(_totalPages.text),
      'status': _status,
      'cover_color': _color,
      'notes': _notes.text.trim().isEmpty ? null : _notes.text.trim(),
    };

    try {
      if (_isEdit) {
        await ApiClient.instance.put('/books/${widget.book!.id}', body);
      } else {
        await ApiClient.instance.post('/books', body);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Buku' : 'Tambah Buku')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'Judul'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _author,
                      decoration: const InputDecoration(labelText: 'Penulis (romaji)'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _authorJp,
                      decoration: const InputDecoration(labelText: 'Penulis (kanji)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _genre,
                      decoration: const InputDecoration(labelText: 'Genre'),
                      items: const [
                        DropdownMenuItem(value: 'novel', child: Text('Novel')),
                        DropdownMenuItem(value: 'cerpen', child: Text('Cerpen')),
                        DropdownMenuItem(value: 'puisi', child: Text('Puisi')),
                        DropdownMenuItem(value: 'esai', child: Text('Esai')),
                        DropdownMenuItem(value: 'manga', child: Text('Manga')),
                        DropdownMenuItem(value: 'lainnya', child: Text('Lainnya')),
                      ],
                      onChanged: (v) => setState(() => _genre = v ?? 'novel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _totalPages,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Total halaman'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: const [
                  DropdownMenuItem(value: 'to_read', child: Text('Belum dibaca')),
                  DropdownMenuItem(value: 'reading', child: Text('Sedang dibaca')),
                  DropdownMenuItem(value: 'completed', child: Text('Selesai')),
                ],
                onChanged: (v) => setState(() => _status = v ?? 'to_read'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notes,
                decoration: const InputDecoration(labelText: 'Catatan (opsional)'),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              const Text('Warna sampul', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: _colors
                    .map((c) => Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: InkWell(
                            onTap: () => setState(() => _color = c),
                            borderRadius: BorderRadius.circular(22),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Book.hexToColor(c),
                                shape: BoxShape.circle,
                                border: _color == c
                                    ? Border.all(color: Colors.black87, width: 3)
                                    : null,
                              ),
                              child: _color == c
                                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                                  : null,
                            ),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: _loading ? null : _save,
                child: _loading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(_isEdit ? 'Simpan' : 'Tambah'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
