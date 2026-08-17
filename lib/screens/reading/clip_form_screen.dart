import 'package:flutter/material.dart';

import '../../models/clip.dart';
import '../../models/deck.dart';
import '../../services/api_client.dart';

class ClipFormScreen extends StatefulWidget {
  final Clip? clip;
  final int? bookId;

  const ClipFormScreen({super.key, this.clip, this.bookId});

  @override
  State<ClipFormScreen> createState() => _ClipFormScreenState();
}

class _ClipFormScreenState extends State<ClipFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _expression;
  late final TextEditingController _reading;
  late final TextEditingController _meaning;
  late final TextEditingController _context;
  late final TextEditingController _translation;
  int? _bookId;
  int? _chapterId;
  int? _deckId;
  List<Map<String, dynamic>>? _books;
  List<Map<String, dynamic>>? _chapters;
  List<Deck>? _decks;
  bool _loading = false;
  bool _toDeck = false;

  bool get _isEdit => widget.clip != null;

  @override
  void initState() {
    super.initState();
    final c = widget.clip;
    _expression = TextEditingController(text: c?.expression ?? '');
    _reading = TextEditingController(text: c?.reading ?? '');
    _meaning = TextEditingController(text: c?.meaning ?? '');
    _context = TextEditingController(text: c?.contextSentence ?? '');
    _translation = TextEditingController(text: c?.translation ?? '');
    _bookId = widget.bookId ?? c?.bookId;
    _loadOptions();
  }

  @override
  void dispose() {
    _expression.dispose();
    _reading.dispose();
    _meaning.dispose();
    _context.dispose();
    _translation.dispose();
    super.dispose();
  }

  Future<void> _loadOptions() async {
    try {
      final books = await ApiClient.instance.get('/books') as List;
      final decksData = await ApiClient.instance.get('/decks') as List;
      List<Map<String, dynamic>> chapters = [];
      if (_bookId != null) {
        chapters = await _fetchChapters(_bookId!);
      }
      if (mounted) {
        setState(() {
          _books = books.cast<Map<String, dynamic>>();
          _decks = decksData.map((e) => Deck.fromJson(e as Map<String, dynamic>)).toList();
          _chapters = chapters;
        });
      }
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>> _fetchChapters(int bookId) async {
    try {
      final data =
          await ApiClient.instance.get('/books/$bookId/chapters') as List;
      return data.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<void> _onBookChanged(int? bookId) async {
    setState(() {
      _bookId = bookId;
      _chapterId = null;
    });
    final chapters = bookId == null ? <Map<String, dynamic>>[] : await _fetchChapters(bookId);
    if (mounted) setState(() => _chapters = chapters);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final body = {
      'expression': _expression.text.trim(),
      'reading': _reading.text.trim().isEmpty ? null : _reading.text.trim(),
      'meaning': _meaning.text.trim().isEmpty ? null : _meaning.text.trim(),
      'context_sentence': _context.text.trim().isEmpty ? null : _context.text.trim(),
      'translation': _translation.text.trim().isEmpty ? null : _translation.text.trim(),
      'book_id': _bookId,
      'chapter_id': _chapterId,
      if (_toDeck) 'to_deck_id': _deckId,
    };

    try {
      if (_isEdit) {
        body.remove('book_id');
        body.remove('chapter_id');
        body.remove('to_deck_id');
        await ApiClient.instance.put('/clips/${widget.clip!.id}', body);
      } else {
        await ApiClient.instance.post('/clips', body);
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
      appBar: AppBar(title: Text(_isEdit ? 'Edit Klip' : 'Klip Kata')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _expression,
                decoration: const InputDecoration(labelText: 'Ekspresi (kata/frasa)'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _reading,
                decoration: const InputDecoration(labelText: 'Bacaan (hiragana)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _meaning,
                decoration: const InputDecoration(labelText: 'Arti'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _context,
                decoration: const InputDecoration(
                  labelText: 'Kalimat konteks (JP)',
                  hintText: 'Kalimat asli saat kamu menemukan kata ini',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _translation,
                decoration: const InputDecoration(labelText: 'Terjemahan konteks'),
                maxLines: 2,
              ),
              if (!_isEdit) ...[
                const SizedBox(height: 20),
                const Text('Sumber (opsional)',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                DropdownButtonFormField<int?>(
                  initialValue: _bookId,
                  decoration: const InputDecoration(labelText: 'Buku'),
                  items: [
                    const DropdownMenuItem<int?>(value: null, child: Text('— tanpa buku —')),
                    ...?_books?.map((b) => DropdownMenuItem<int?>(
                          value: b['id'] as int,
                          child: Text(b['title'] as String),
                        )),
                  ],
                  onChanged: _onBookChanged,
                ),
                const SizedBox(height: 12),
                if (_bookId != null)
                  DropdownButtonFormField<int?>(
                    initialValue: _chapterId,
                    decoration: const InputDecoration(labelText: 'Bab'),
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('— tanpa bab —')),
                      ...?_chapters?.map((c) => DropdownMenuItem<int?>(
                            value: c['id'] as int,
                            child: Text(c['title'] as String),
                          )),
                    ],
                    onChanged: (v) => setState(() => _chapterId = v),
                  ),
                const SizedBox(height: 16),
                SwitchListTile(
                  value: _toDeck,
                  onChanged: (v) => setState(() => _toDeck = v),
                  title: const Text('Langsung masuk deck SRS'),
                  subtitle: const Text('Menutup celah baca → hafal'),
                  contentPadding: EdgeInsets.zero,
                ),
                if (_toDeck) ...[
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int?>(
                    initialValue: _deckId,
                    decoration: const InputDecoration(labelText: 'Pilih deck'),
                    items: [
                      ...?_decks?.map((d) => DropdownMenuItem<int?>(
                            value: d.id,
                            child: Text(d.name),
                          )),
                    ],
                    onChanged: (v) => setState(() => _deckId = v),
                  ),
                ],
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _loading ? null : _save,
                child: _loading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(_isEdit ? 'Simpan' : 'Simpan Klip'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
