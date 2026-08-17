import 'package:flutter/material.dart';

import '../../models/translation_exercise.dart';
import '../../services/api_client.dart';

class TranslationFormScreen extends StatefulWidget {
  final TranslationExercise? item;

  const TranslationFormScreen({super.key, this.item});

  @override
  State<TranslationFormScreen> createState() => _TranslationFormScreenState();
}

class _TranslationFormScreenState extends State<TranslationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _sourceText;
  late final TextEditingController _notes;
  String _status = 'draft';
  bool _loading = false;

  bool get _isEdit => widget.item != null;

  @override
  void initState() {
    super.initState();
    final it = widget.item;
    _title = TextEditingController(text: it?.title ?? '');
    _sourceText = TextEditingController(text: it?.sourceText ?? '');
    _notes = TextEditingController(text: it?.notes ?? '');
    _status = it?.status ?? 'draft';
  }

  @override
  void dispose() {
    _title.dispose();
    _sourceText.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final body = {
      'title': _title.text.trim(),
      'source_text': _sourceText.text,
      'source_lang': 'ja',
      'target_lang': 'id',
      'status': _status,
      'notes': _notes.text.trim().isEmpty ? null : _notes.text.trim(),
    };

    try {
      if (_isEdit) {
        await ApiClient.instance.put('/translations/${widget.item!.id}', body);
      } else {
        await ApiClient.instance.post('/translations', body);
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
      appBar: AppBar(title: Text(_isEdit ? 'Edit Latihan' : 'Latihan Terjemahan Baru')),
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
              TextFormField(
                controller: _sourceText,
                decoration: const InputDecoration(
                  labelText: 'Teks sumber (Jepang)',
                  hintText: 'Tempel teks Jepang yang ingin diterjemahkan...',
                  alignLabelWithHint: true,
                ),
                maxLines: 8,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: const [
                  DropdownMenuItem(value: 'draft', child: Text('Draf')),
                  DropdownMenuItem(value: 'in_progress', child: Text('Dikerjakan')),
                  DropdownMenuItem(value: 'done', child: Text('Selesai')),
                ],
                onChanged: (v) => setState(() => _status = v ?? 'draft'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notes,
                decoration: const InputDecoration(labelText: 'Catatan (opsional)'),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _loading ? null : _save,
                child: _loading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(_isEdit ? 'Simpan' : 'Buat Latihan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
