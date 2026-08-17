import 'package:flutter/material.dart';

import '../../models/card_item.dart';
import '../../models/deck.dart';
import '../../services/api_client.dart';

class CardFormScreen extends StatefulWidget {
  final Deck deck;
  final CardItem? card;

  const CardFormScreen({super.key, required this.deck, this.card});

  @override
  State<CardFormScreen> createState() => _CardFormScreenState();
}

class _CardFormScreenState extends State<CardFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _front;
  late final TextEditingController _on;
  late final TextEditingController _kun;
  late final TextEditingController _meaning;
  late final TextEditingController _example;
  late final TextEditingController _exampleTranslation;
  late final TextEditingController _tags;
  bool _loading = false;

  bool get _isEdit => widget.card != null;

  @override
  void initState() {
    super.initState();
    final c = widget.card;
    _front = TextEditingController(text: c?.front ?? '');
    _on = TextEditingController(text: c?.readings?.on ?? '');
    _kun = TextEditingController(text: c?.readings?.kun ?? '');
    _meaning = TextEditingController(text: c?.meaning ?? '');
    _example = TextEditingController(text: c?.exampleSentence ?? '');
    _exampleTranslation = TextEditingController(text: c?.exampleTranslation ?? '');
    _tags = TextEditingController(text: c?.tags.join(', ') ?? '');
  }

  @override
  void dispose() {
    _front.dispose();
    _on.dispose();
    _kun.dispose();
    _meaning.dispose();
    _example.dispose();
    _exampleTranslation.dispose();
    _tags.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final body = {
      'front': _front.text.trim(),
      'readings': {
        'on': _on.text.trim().isEmpty ? null : _on.text.trim(),
        'kun': _kun.text.trim().isEmpty ? null : _kun.text.trim(),
      },
      'meaning': _meaning.text.trim().isEmpty ? null : _meaning.text.trim(),
      'example_sentence': _example.text.trim().isEmpty ? null : _example.text.trim(),
      'example_translation': _exampleTranslation.text.trim().isEmpty ? null : _exampleTranslation.text.trim(),
      'tags': _tags.text
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList(),
    };

    try {
      if (_isEdit) {
        await ApiClient.instance.put('/cards/${widget.card!.id}', body);
      } else {
        await ApiClient.instance.post('/decks/${widget.deck.id}/cards', body);
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
      appBar: AppBar(title: Text(_isEdit ? 'Edit Kartu' : 'Kartu Baru')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _front,
                decoration: const InputDecoration(labelText: 'Depan (kanji / kata)'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _on,
                      decoration: const InputDecoration(labelText: 'Bacaan on'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _kun,
                      decoration: const InputDecoration(labelText: 'Bacaan kun'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _meaning,
                decoration: const InputDecoration(labelText: 'Arti'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _example,
                decoration: const InputDecoration(labelText: 'Contoh kalimat (JP)'),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _exampleTranslation,
                decoration: const InputDecoration(labelText: 'Terjemahan contoh'),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _tags,
                decoration: const InputDecoration(
                  labelText: 'Tag (pisahkan dengan koma)',
                  hintText: 'sastra, kanji, N3',
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _loading ? null : _save,
                child: _loading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(_isEdit ? 'Simpan' : 'Tambah Kartu'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
