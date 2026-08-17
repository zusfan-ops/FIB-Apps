import 'package:flutter/material.dart';

import '../../models/grammar_pattern.dart';
import '../../services/api_client.dart';

class GrammarFormScreen extends StatefulWidget {
  final GrammarPattern? pattern;

  const GrammarFormScreen({super.key, this.pattern});

  @override
  State<GrammarFormScreen> createState() => _GrammarFormScreenState();
}

class _GrammarFormScreenState extends State<GrammarFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _pattern;
  late final TextEditingController _meaning;
  late final TextEditingController _structure;
  late final TextEditingController _usage;
  late final TextEditingController _notes;
  late final TextEditingController _tags;
  final List<Map<String, TextEditingController>> _examples = [];
  bool _isBungo = false;
  bool _loading = false;

  bool get _isEdit => widget.pattern != null;

  @override
  void initState() {
    super.initState();
    final p = widget.pattern;
    _pattern = TextEditingController(text: p?.pattern ?? '');
    _meaning = TextEditingController(text: p?.meaning ?? '');
    _structure = TextEditingController(text: p?.structure ?? '');
    _usage = TextEditingController(text: p?.usage ?? '');
    _notes = TextEditingController(text: p?.notes ?? '');
    _tags = TextEditingController(text: p?.tags.join(', ') ?? '');
    _isBungo = p?.isBungo ?? false;
    if (p != null && p.examples.isNotEmpty) {
      for (final e in p.examples) {
        _examples.add({
          'jp': TextEditingController(text: e['jp'] ?? ''),
          'id': TextEditingController(text: e['id'] ?? ''),
        });
      }
    }
  }

  @override
  void dispose() {
    _pattern.dispose();
    _meaning.dispose();
    _structure.dispose();
    _usage.dispose();
    _notes.dispose();
    _tags.dispose();
    for (final e in _examples) {
      e['jp']!.dispose();
      e['id']!.dispose();
    }
    super.dispose();
  }

  void _addExample() {
    setState(() {
      _examples.add({
        'jp': TextEditingController(),
        'id': TextEditingController(),
      });
    });
  }

  void _removeExample(int index) {
    setState(() => _examples.removeAt(index));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final body = {
      'pattern': _pattern.text.trim(),
      'meaning': _meaning.text.trim().isEmpty ? null : _meaning.text.trim(),
      'structure': _structure.text.trim().isEmpty ? null : _structure.text.trim(),
      'usage': _usage.text.trim().isEmpty ? null : _usage.text.trim(),
      'examples': _examples
          .map((e) => {
                'jp': e['jp']!.text.trim(),
                'id': e['id']!.text.trim(),
              })
          .where((e) => (e['jp'] ?? '').isNotEmpty)
          .toList(),
      'notes': _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      'is_bungo': _isBungo,
      'tags': _tags.text
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList(),
    };

    try {
      if (_isEdit) {
        await ApiClient.instance.put('/grammar/${widget.pattern!.id}', body);
      } else {
        await ApiClient.instance.post('/grammar', body);
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
      appBar: AppBar(title: Text(_isEdit ? 'Edit Pola' : 'Pola Grammar Baru')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _pattern,
                decoration: const InputDecoration(labelText: 'Pola (contoh: 〜てしまう)'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _meaning,
                decoration: const InputDecoration(labelText: 'Arti'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _structure,
                decoration: const InputDecoration(labelText: 'Struktur (contoh: 動詞て形 + しまう)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _usage,
                decoration: const InputDecoration(labelText: 'Penjelasan penggunaan'),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                value: _isBungo,
                onChanged: (v) => setState(() => _isBungo = v),
                title: const Text('Pola bungo (sastra klasik)'),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Contoh kalimat', style: TextStyle(fontWeight: FontWeight.w600)),
                  const Spacer(),
                  IconButton(
                    onPressed: _addExample,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              ..._examples.asMap().entries.map((entry) {
                final e = entry.value;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        TextField(
                          controller: e['jp'],
                          decoration: const InputDecoration(labelText: 'Kalimat (JP)'),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: e['id'],
                          decoration: const InputDecoration(labelText: 'Terjemahan (ID)'),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.grey),
                            onPressed: () => _removeExample(entry.key),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notes,
                decoration: const InputDecoration(labelText: 'Catatan (opsional)'),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _tags,
                decoration: const InputDecoration(
                  labelText: 'Tag (pisahkan koma)',
                  hintText: 'N4, pola umum, bungo',
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _loading ? null : _save,
                child: _loading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(_isEdit ? 'Simpan' : 'Simpan Pola'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
